// Thaiprompt POS — Receipt (/receipt?id=A1042): after-sale screen.
//
// A night success banner (น้องพร้อม cheering, change due large for cash), a
// paper preview that is the exact print document (ReceiptDoc), and the real
// follow-ups: print / reprint (counted, marked สำเนา), share PDF, full tax
// invoice, refund, create + label a delivery job for delivery orders, and
// "ขายบิลถัดไป" back to the counter.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/print/print_service.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../print/print_actions.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

typedef _DeliveryInput = ({String name, String phone, String address, String providerId, String note});

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _printing = false;
  bool _sharing = false;

  Future<void> _print(Order order) async {
    if (_printing) return;
    setState(() => _printing = true);
    await printReceipt(context, order);
    if (!mounted) return;
    setState(() => _printing = false); // printCount changed → label + preview show สำเนา
  }

  Future<void> _share(Order order) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    await shareReceipt(context, order);
    if (!mounted) return;
    setState(() => _sharing = false);
  }

  Future<void> _createDelivery(Order order) async {
    final store = AppScope.read(context);
    final router = GoRouter.of(context);
    final input = await showNvDialog<_DeliveryInput>(
      context,
      title: 'สร้างงานจัดส่ง',
      subtitle: 'บิล ${order.id} · ${baht(order.total)}',
      art: 'delivery',
      maxWidth: 540,
      body: _DeliveryForm(order: order),
    );
    if (input == null || !mounted) return;
    if (store.deliveryForOrder(order.id) != null) {
      nvToast(context, 'บิลนี้มีงานจัดส่งอยู่แล้ว', kind: NvToastKind.info);
      return;
    }
    final job = store.createDelivery(
      order,
      customerName: input.name,
      phone: input.phone,
      address: input.address,
      providerId: input.providerId,
      note: input.note,
    );
    nvToast(
      context,
      'สร้างงานจัดส่ง ${job.id} แล้ว · ${store.providerById(job.providerId)?.name ?? job.providerId}',
      kind: NvToastKind.success,
      actionLabel: 'พิมพ์ใบปะหน้า',
      onAction: () => router.go('/shipping/labels?id=${job.id}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final id = GoRouterState.of(context).uri.queryParameters['id'];
    final order = (id == null ? null : store.orderById(id)) ?? store.lastOrder;
    if (order == null) {
      return NvScaffold(
        title: 'ใบเสร็จ',
        art: 'receipt',
        body: NvEmptyState(
          mascot: 'search',
          title: 'ไม่พบใบเสร็จ',
          message: 'ยังไม่มีบิลที่ชำระเงินในเครื่องนี้ หรือบิลนี้ไม่อยู่ในประวัติแล้ว',
          actionLabel: 'กลับไปหน้าขาย',
          actionIcon: NvIcons.cashier,
          onAction: () => context.go('/cashier'),
        ),
      );
    }

    return NvScaffold(
      title: 'ใบเสร็จ ${order.id}',
      eyebrow: thaiDateTime(order.createdAt),
      art: 'receipt',
      actions: [
        NvButton.ghost('บิลทั้งหมด', icon: NvIcons.list, size: NvButtonSize.sm, onPressed: () => context.go('/orders')),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final left = <Widget>[
          _Banner(order: order, store: store, compact: c.maxWidth < 620),
          const SizedBox(height: 16),
          _actions(store, order),
          const SizedBox(height: 16),
          NvButton.gold('ขายบิลถัดไป',
              icon: NvIcons.cashier, size: NvButtonSize.xl, expand: true, onPressed: () => context.go('/cashier')),
        ];
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: ListView(padding: const EdgeInsets.only(bottom: 16), children: left)),
              const SizedBox(width: 18),
              SizedBox(
                width: (c.maxWidth * 0.36).clamp(330.0, 430.0),
                child: _PaperPreview(order: order, scroll: true),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ...left,
            const SizedBox(height: 18),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _PaperPreview(order: order, scroll: false),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _actions(PosStore store, Order order) {
    final job = order.type == OrderType.delivery ? store.deliveryForOrder(order.id) : null;
    final reprint = order.printCount > 0;
    final tiles = <Widget>[
      _ActionTile(
        art: 'printer',
        title: reprint ? 'พิมพ์ซ้ำ' : 'พิมพ์ใบเสร็จ',
        subtitle: reprint
            ? 'พิมพ์แล้ว ${order.printCount} ครั้ง · ฉบับนี้จะระบุว่า "สำเนา"'
            : (store.printerName.isEmpty ? 'เลือกเครื่องพิมพ์จากหน้าต่างระบบ' : store.printerName),
        busy: _printing,
        onTap: () => _print(order),
      ),
      _ActionTile(
        art: 'receipt',
        title: 'แชร์ / บันทึก PDF',
        subtitle: 'ส่งใบเสร็จให้ลูกค้าทางแชตหรืออีเมล',
        busy: _sharing,
        onTap: () => _share(order),
      ),
      _ActionTile(
        art: 'tax',
        title: 'ใบกำกับภาษีเต็มรูป',
        subtitle: order.taxInvoiceNo != null ? 'ออกแล้ว ${order.taxInvoiceNo}' : 'สำหรับลูกค้าที่ต้องการชื่อ/เลขผู้เสียภาษี',
        onTap: () => context.go('/tax-invoice?id=${order.id}'),
      ),
      _ActionTile(
        art: 'refund',
        title: 'คืนเงิน',
        subtitle: order.status == OrderStatus.refunded
            ? 'บิลนี้คืนเงินครบแล้ว'
            : (order.refundAmount > 0 ? 'คืนไปแล้ว ${baht(order.refundAmount)} · คืนเพิ่มได้' : 'คืนทั้งบิลหรือบางรายการ (ต้องอนุมัติ)'),
        onTap: order.status == OrderStatus.paid ? () => context.go('/refund?id=${order.id}') : null,
      ),
      if (order.type == OrderType.delivery && job == null)
        _ActionTile(
          art: 'delivery',
          title: 'สร้างงานจัดส่ง',
          subtitle: 'ระบุผู้รับ ที่อยู่ และผู้ให้บริการขนส่ง',
          highlight: true,
          onTap: order.status == OrderStatus.paid ? () => _createDelivery(order) : null,
        ),
      if (job != null) ...[
        _ActionTile(
          art: 'delivery',
          title: 'งานจัดส่ง ${job.id}',
          subtitle: '${job.status.label} · ${store.providerById(job.providerId)?.name ?? job.providerId}',
          onTap: () => context.go('/delivery'),
        ),
        _ActionTile(
          art: 'shipping',
          title: 'พิมพ์ใบปะหน้า',
          subtitle: job.address.isEmpty ? 'ฉลากพร้อมบาร์โค้ดสำหรับพัสดุ' : job.address,
          onTap: () => context.go('/shipping/labels?id=${job.id}'),
        ),
      ],
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 640 ? 3 : (c.maxWidth >= 380 ? 2 : 1);
      const gap = 12.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    });
  }
}

// ─────────────────────────── pieces ───────────────────────────

class _Banner extends StatelessWidget {
  final Order order;
  final PosStore store;
  final bool compact;
  const _Banner({required this.order, required this.store, required this.compact});

  @override
  Widget build(BuildContext context) {
    final refunded = order.status == OrderStatus.refunded;
    final partial = order.isPartiallyRefunded;
    final cash = order.method == PaymentMethod.cash;
    final member = order.customerId == null ? null : store.customerById(order.customerId!);
    final status = refunded
        ? const NvBadge('คืนเงินแล้ว', tint: NvTint.lacquer)
        : partial
            ? NvBadge('คืนเงินบางส่วน ${baht(order.refundAmount)}', tint: NvTint.amber)
            : const NvBadge('ชำระแล้ว', tint: NvTint.jade);

    Widget stat(String label, String value, {bool hero = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Nv.ui(12.5, color: Nv.onNight3, weight: FontWeight.w600)),
            hero
                ? NvFoilText(value, style: Nv.money(compact ? 34 : 44))
                : Text(value, style: Nv.money(compact ? 18 : 22, color: Nv.onNight)),
          ],
        );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        status,
        const SizedBox(height: 8),
        Text(refunded ? 'บิลนี้คืนเงินแล้ว' : 'ชำระเงินสำเร็จ', style: Nv.display(compact ? 22 : 27, color: Nv.onNight)),
        const SizedBox(height: 2),
        Text(
          '${order.id} · ${order.method.label}${order.paymentRef != null ? ' · ${order.paymentRef}' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Nv.ui(13, color: Nv.onNight3),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 28,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: cash
              ? [
                  stat('เงินทอน', baht(order.change), hero: true),
                  stat('รับเงิน', baht(order.cashReceived)),
                  stat('ยอดชำระ', baht(order.total)),
                ]
              : [
                  stat('ยอดชำระ', baht(order.total), hero: true),
                  stat('ชำระด้วย', order.method.receiptLabel),
                ],
        ),
        if (member != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(NvIcons.crown, size: 13, color: Nv.gold300),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  '${member.name} · ${store.tierFor(member).name} · แต้มคงเหลือ ${groupDigits(member.points)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Nv.ui(13, color: Nv.onNight2, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(Nv.rXl),
      child: Container(
        decoration: BoxDecoration(
          gradient: Nv.night,
          borderRadius: BorderRadius.circular(Nv.rXl),
          border: Border.all(color: Nv.lineNightStrong),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 18 : 24, 20, compact ? 18 : 24, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: content),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    NvArt.mascot(refunded ? 'wai' : 'cheer', height: 150),
                  ],
                ],
              ),
            ),
            const NvKanokCorners(size: 60, opacity: 0.5, inset: EdgeInsets.all(4), bottom: false),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String art;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool busy;
  final bool highlight;

  const _ActionTile({
    required this.art,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.busy = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: NvSheet(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        radius: Nv.rMd,
        selected: highlight,
        onTap: enabled ? onTap : null,
        child: Row(
          children: [
            NvArt.icon(art, size: 48),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3, height: 1.3)),
                ],
              ),
            ),
            if (busy)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(NvIcons.angleRight, size: 14, color: enabled ? Nv.goldInk : Nv.ink4),
          ],
        ),
      ),
    );
  }
}

/// White paper card showing the exact print document, scaled to fit the width.
class _PaperPreview extends StatelessWidget {
  final Order order;
  final bool scroll;
  const _PaperPreview({required this.order, required this.scroll});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final width = rollMedium(store.paperWidthMm).renderWidth;
    final paper = FittedBox(
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: width,
        child: ColoredBox(
          color: Colors.white,
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: Nv.fontUi, color: Colors.black, fontSize: 20),
            child: receiptDocFor(context, order),
          ),
        ),
      ),
    );
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Nv.line),
        boxShadow: Nv.shadowLift,
      ),
      clipBehavior: Clip.antiAlias,
      child: scroll ? SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 6), child: paper) : paper,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: scroll ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(NvIcons.receipt, size: 13, color: Nv.goldInk),
              const SizedBox(width: 7),
              Expanded(
                child: Text('ตัวอย่างใบเสร็จ · กระดาษ ${store.paperWidthMm} มม.',
                    style: Nv.ui(12.5, color: Nv.ink3, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        if (scroll) Expanded(child: card) else card,
      ],
    );
  }
}

class _DeliveryForm extends StatefulWidget {
  final Order order;
  const _DeliveryForm({required this.order});

  @override
  State<_DeliveryForm> createState() => _DeliveryFormState();
}

class _DeliveryFormState extends State<_DeliveryForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  String? _provider;
  String? _error;

  @override
  void initState() {
    super.initState();
    final store = AppScope.read(context);
    final o = widget.order;
    final c = o.customerId == null ? null : store.customerById(o.customerId!);
    _name.text = c?.name ?? o.customerName ?? '';
    _phone.text = c?.phone.replaceAll(RegExp(r'\D'), '') ?? '';
    final providers = store.enabledProviders;
    _provider = providers.isNotEmpty ? providers.first.id : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    final address = _address.text.trim();
    if (_provider == null) {
      setState(() => _error = 'เลือกผู้ให้บริการขนส่ง');
      return;
    }
    if (phone.length < 9 || phone.length > 10) {
      setState(() => _error = 'กรอกเบอร์โทรผู้รับ 9–10 หลัก');
      return;
    }
    if (address.isEmpty) {
      setState(() => _error = 'กรอกที่อยู่จัดส่ง');
      return;
    }
    Navigator.of(context).pop<_DeliveryInput>(
      (name: _name.text.trim(), phone: phone, address: address, providerId: _provider!, note: _note.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final providers = store.enabledProviders;
    if (providers.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NvArt.mascot('empty', height: 110),
          const SizedBox(height: 8),
          Text('ยังไม่ได้เปิดผู้ให้บริการขนส่ง', style: Nv.display(17)),
          const SizedBox(height: 4),
          Text(
            store.isManager ? 'เปิดใช้อย่างน้อย 1 รายที่หน้า "ผู้ให้บริการขนส่ง" ก่อน' : 'ให้ผู้จัดการเปิดผู้ให้บริการขนส่งก่อน',
            textAlign: TextAlign.center,
            style: Nv.ui(13.5, color: Nv.ink3),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              NvButton.soft('ปิด', onPressed: () => Navigator.of(context).pop()),
              if (store.isManager)
                NvButton.gold('ไปตั้งค่าขนส่ง', icon: NvIcons.truck, onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.go('/shipping/providers');
                }),
            ],
          ),
        ],
      );
    }
    final selected = providers.any((p) => p.id == _provider) ? _provider : providers.first.id;
    final fee = store.providerById(selected!)?.baseFee ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NvField(label: 'ชื่อผู้รับ', controller: _name, icon: NvIcons.user),
        const SizedBox(height: 12),
        NvField(
          label: 'เบอร์โทรผู้รับ',
          controller: _phone,
          icon: NvIcons.phone,
          keyboard: TextInputType.phone,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        ),
        const SizedBox(height: 12),
        NvField(label: 'ที่อยู่จัดส่ง', controller: _address, icon: NvIcons.location, maxLines: 3),
        const SizedBox(height: 14),
        Text('ผู้ให้บริการ', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in providers)
              NvChip(
                p.name,
                icon: p.kind == 'self' ? NvIcons.store : (p.kind == 'food' ? NvIcons.delivery : NvIcons.truck),
                selected: p.id == selected,
                onTap: () => setState(() => _provider = p.id),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(fee > 0 ? 'ค่าส่งเริ่มต้น ${baht(fee)} (แก้ได้ที่หน้างานจัดส่ง)' : 'ไม่มีค่าส่งเริ่มต้น',
            style: Nv.ui(12, color: Nv.ink3)),
        const SizedBox(height: 12),
        NvField(label: 'หมายเหตุถึงผู้ส่ง (ไม่บังคับ)', controller: _note, icon: NvIcons.note),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!, style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
          ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            NvButton.gold('สร้างงานจัดส่ง', icon: NvIcons.check, onPressed: () {
              _provider = selected;
              _submit();
            }),
          ],
        ),
      ],
    );
  }
}
