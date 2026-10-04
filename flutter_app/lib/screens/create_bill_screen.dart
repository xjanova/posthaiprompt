// Thaiprompt POS — พักบิล / แยกบิล (current bill + parked bills) · Nova.
//
// Left: the live counter cart ("บิลปัจจุบัน") with its real totals and three
// actions — park it with a label (holdCart), split chosen quantities off into
// a new parked bill (splitToHeld), or go to payment (respecting
// checkoutBlockReason). Right: every parked bill (heldCarts) with label, age,
// items and value — resume it (the current cart is parked first, never lost)
// or delete it after a confirmation.
//
// A cart that was loaded from open kitchen tickets (table bills) is never
// parked/split: the tickets are still open, so parking would duplicate the
// bill. It can be released back to "open order" instead.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _HeldInfo {
  final int subtotal;
  final int items;
  final int missing;
  final List<String> preview;
  const _HeldInfo(this.subtotal, this.items, this.missing, this.preview);
}

_HeldInfo _heldInfo(PosStore store, HeldCart h) {
  var sub = 0;
  var items = 0;
  var missing = 0;
  final preview = <String>[];
  for (final j in h.lines) {
    final q = (j['qty'] as num?)?.toInt() ?? 0;
    final code = (j['code'] as String?) ?? '';
    final p = store.productByCode(code);
    final opts = ((j['options'] as List?) ?? const []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    items += q;
    if (p == null) {
      missing++;
      preview.add('$q× (สินค้าถูกลบ $code)');
      continue;
    }
    sub += q * (p.price + ((j['optionDelta'] as num?)?.toInt() ?? 0));
    preview.add('$q× ${p.name}${opts.isEmpty ? '' : ' (${opts.join(' · ')})'}');
  }
  return _HeldInfo(sub, items, missing, preview);
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  // ─────────────────────────── actions ───────────────────────────

  Future<void> _hold() async {
    final store = AppScope.read(context);
    if (store.cart.isEmpty) return;
    final suggestion = store.tableNumber != null ? 'โต๊ะ ${store.tableNumber}' : (store.linkedCustomer?.name ?? '');
    final label = await showNvTextDialog(
      context,
      title: 'พักบิล',
      subtitle: store.appliedCouponCode != null
          ? 'ตั้งชื่อบิลเพื่อเรียกคืนได้ง่าย (เว้นว่างได้)\nคูปอง ${store.appliedCouponCode} จะต้องใส่ใหม่เมื่อเรียกบิลคืน'
          : 'ตั้งชื่อบิลเพื่อเรียกคืนได้ง่าย (เว้นว่างได้)',
      initial: suggestion,
      hint: 'เช่น โต๊ะ 5 · คุณสมชาย · รอเพื่อนมาจ่าย',
      confirmLabel: 'พักบิล',
      art: 'payment',
    );
    if (label == null || !mounted) return;
    final h = AppScope.read(context).holdCart(label: label);
    if (h == null) {
      nvToast(context, 'ไม่มีรายการให้พัก', kind: NvToastKind.warning);
      return;
    }
    nvToast(context, 'พักบิล "${h.label}" แล้ว', kind: NvToastKind.success);
  }

  Future<void> _split() async {
    final store = AppScope.read(context);
    if (store.cartItemCount < 2) return;
    final res = await showNvDialog<_SplitResult>(
      context,
      title: 'แยกบิล',
      subtitle: 'เลือกจำนวนที่จะย้ายไปเป็นบิลใหม่ (พักไว้) — ส่วนที่เหลือชำระได้ทันที',
      art: 'payment',
      maxWidth: 580,
      body: _SplitForm(lines: List.of(store.cart)),
    );
    if (res == null || !mounted) return;
    final h = AppScope.read(context).splitToHeld(res.qty, label: res.label);
    if (h == null) {
      nvToast(context, 'ไม่ได้แยกรายการใด', kind: NvToastKind.warning);
      return;
    }
    nvToast(context, 'แยกเป็นบิล "${h.label}" แล้ว · พักไว้ทางขวา', kind: NvToastKind.success);
  }

  /// Give a ticket-loaded cart back to the open orders (tickets stay open).
  void _releaseToTickets() {
    final store = AppScope.read(context);
    final table = store.tableNumber;
    store.clearCart();
    if (table != null) {
      final t = store.tableByNumber(table);
      if (t != null && t.status == TableStatus.billing && store.openTicketsForTable(table).isNotEmpty) {
        store.setTableStatus(t, TableStatus.seated);
      }
    }
    nvToast(context, 'ปล่อยกลับเป็นออเดอร์ค้างแล้ว · เรียกเก็บได้ที่ "บิลย้อนหลัง"', kind: NvToastKind.info);
  }

  Future<void> _resume(HeldCart h) async {
    final store = AppScope.read(context);
    if (store.cart.isNotEmpty) {
      final fromTickets = store.activeTicketIds.isNotEmpty;
      final ok = await showNvConfirm(
        context,
        title: 'เรียกบิล "${h.label}"?',
        message: fromTickets
            ? 'ตะกร้าปัจจุบันเป็นออเดอร์ค้างจากโต๊ะ ระบบจะปล่อยกลับเป็นออเดอร์ค้างก่อน (ไม่หาย) แล้วเรียกบิลนี้ขึ้นมาแทน'
            : 'บิลปัจจุบัน (${store.cartItemCount} ชิ้น · ${baht(store.cartTotal)}) จะถูกพักไว้ก่อนโดยอัตโนมัติ แล้วเรียกบิลนี้ขึ้นมาแทน',
        confirmLabel: 'เรียกบิล',
        danger: false,
        icon: NvIcons.rightLeft,
      );
      if (!ok || !mounted) return;
      if (fromTickets) {
        final table = store.tableNumber;
        store.clearCart();
        if (table != null) {
          final t = store.tableByNumber(table);
          if (t != null && t.status == TableStatus.billing && store.openTicketsForTable(table).isNotEmpty) {
            store.setTableStatus(t, TableStatus.seated);
          }
        }
      }
    }
    if (!mounted) return;
    if (!store.heldCarts.contains(h)) {
      nvToast(context, 'บิลนี้ถูกเรียกคืนหรือลบไปแล้ว', kind: NvToastKind.warning);
      return;
    }
    final missing = _heldInfo(store, h).missing;
    store.resumeHeld(h);
    nvToast(
      context,
      missing > 0 ? 'เรียกบิลแล้ว · ข้าม $missing รายการที่ถูกลบจากเมนู' : 'เรียกบิล "${h.label}" แล้ว',
      kind: missing > 0 ? NvToastKind.warning : NvToastKind.success,
      actionLabel: 'ไปหน้าขาย',
      onAction: () {
        if (mounted) context.go('/cashier');
      },
    );
  }

  Future<void> _delete(HeldCart h) async {
    final store = AppScope.read(context);
    final info = _heldInfo(store, h);
    final ok = await showNvConfirm(
      context,
      title: 'ลบบิลพัก "${h.label}"?',
      message: '${info.items} ชิ้น · ${baht(info.subtotal)}\nบิลนี้จะถูกลบถาวร เรียกคืนไม่ได้',
      confirmLabel: 'ลบบิล',
    );
    if (!ok || !mounted) return;
    if (!store.heldCarts.contains(h)) return;
    store.deleteHeld(h);
    nvToast(context, 'ลบบิลพัก "${h.label}" แล้ว', kind: NvToastKind.success);
  }

  // ─────────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return NvScaffold(
      title: 'พักบิล / แยกบิล',
      eyebrow: 'บิลที่ยังไม่ชำระ',
      subtitle: 'พักบิลปัจจุบัน แยกบางรายการ หรือเรียกบิลที่พักไว้กลับมาขายต่อ',
      art: 'payment',
      actions: [
        NvButton.soft('หน้าขาย', icon: NvIcons.cashier, size: NvButtonSize.sm, onPressed: () => context.go('/cashier')),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 820;
        if (!wide) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _current(store, fill: false),
              const SizedBox(height: 18),
              _held(store, fill: false),
            ],
          );
        }
        final fill = c.maxHeight >= 560;
        final cw = (c.maxWidth * 0.38).clamp(340.0, 460.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: cw,
              child: fill
                  ? _current(store, fill: true)
                  : SingleChildScrollView(padding: const EdgeInsets.only(bottom: 16), child: _current(store, fill: false)),
            ),
            const SizedBox(width: 18),
            Expanded(child: _held(store, fill: true)),
          ],
        );
      }),
    );
  }

  Widget _note(NvTint tint, IconData icon, String text) {
    final c = nvTint(tint);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(Nv.rSm)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 13, color: c.fg)),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: Nv.ui(12.5, color: c.fg, weight: FontWeight.w600, height: 1.4))),
        ],
      ),
    );
  }

  Widget _current(PosStore store, {required bool fill}) {
    if (store.cart.isEmpty) {
      return NvSheet(
        child: NvEmptyState(
          mascot: 'empty',
          title: 'บิลปัจจุบันยังว่าง',
          message: 'เพิ่มสินค้าที่หน้าขาย หรือเรียกบิลที่พักไว้กลับมาขายต่อ',
          actionLabel: 'ไปหน้าขาย',
          actionIcon: NvIcons.cashier,
          onAction: () => context.go('/cashier'),
          size: 130,
        ),
      );
    }
    final fromTickets = store.activeTicketIds.isNotEmpty;
    final block = store.checkoutBlockReason;
    final needShift = store.requireShift && !store.hasOpenShift;
    final typeLabel = store.orderType == OrderType.dineIn && store.tableNumber != null
        ? 'โต๊ะ ${store.tableNumber} · ${store.guests} ท่าน'
        : store.orderType.label;
    final customer = store.linkedCustomer;

    final header = Row(
      children: [
        NvArt.icon('pos', size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('บิลปัจจุบัน', style: Nv.display(19)),
              Text('เลขที่ถัดไป ${store.openOrderId} · $typeLabel', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink3)),
            ],
          ),
        ),
        NvBadge('${store.cartItemCount} ชิ้น', tint: NvTint.gold, dot: false),
      ],
    );

    final notes = <Widget>[
      if (fromTickets)
        _note(NvTint.sapphire, NvIcons.info,
            'โหลดจากออเดอร์ค้าง ${store.activeTicketIds.join(', ')} — ชำระเพื่อปิดออเดอร์ หรือปล่อยกลับเป็นออเดอร์ค้าง (พัก/แยกไม่ได้เพราะออเดอร์ยังเปิดอยู่)'),
      if (customer != null) _note(NvTint.gold, NvIcons.user, 'สมาชิก ${customer.name}'),
    ];

    final lines = [
      for (var i = 0; i < store.cart.length; i++) ...[
        if (i > 0) const Divider(height: 1),
        _CartLineRow(line: store.cart[i]),
      ],
    ];

    final totals = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NvKeyValue('รวม', baht(store.cartSubtotal)),
        if (store.cartDiscount > 0)
          NvKeyValue('ส่วนลด${store.discountNote.isNotEmpty ? ' (${store.discountNote})' : ''}', '-${baht(store.cartDiscount)}',
              valueColor: Nv.lacquer),
        if (store.cartTax > 0)
          NvKeyValue(store.vatInclusive ? 'VAT (รวมในราคาแล้ว)' : 'VAT ${(store.vatRate * 100).round()}%', baht(store.cartTax)),
        const SizedBox(height: 6),
        NvNightCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          radius: Nv.rMd,
          child: Row(
            children: [
              Expanded(child: Text('ยอดสุทธิ', style: Nv.ui(15, color: Nv.onNight, weight: FontWeight.w700))),
              NvFoilText(baht(store.cartTotal), style: Nv.money(24)),
            ],
          ),
        ),
      ],
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NvButton.gold('ไปชำระเงิน',
            icon: NvIcons.cashier, size: NvButtonSize.lg, expand: true, onPressed: block.isEmpty ? () => context.go('/payment') : null),
        if (block.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(NvIcons.warning, size: 13, color: Nv.amber),
                const SizedBox(width: 8),
                Expanded(child: Text(block, style: Nv.ui(12.5, color: const Color(0xFF8A5A00), weight: FontWeight.w600))),
                if (needShift) NvButton.soft('เปิดกะ', icon: NvIcons.clock, size: NvButtonSize.sm, onPressed: () => context.go('/shift')),
              ],
            ),
          ),
        const SizedBox(height: 10),
        if (fromTickets)
          NvButton.soft('ปล่อยกลับเป็นออเดอร์ค้าง', icon: NvIcons.rotate, expand: true, onPressed: _releaseToTickets)
        else
          Row(
            children: [
              Expanded(child: NvButton.navy('พักบิล', icon: NvIcons.pause, expand: true, onPressed: _hold)),
              const SizedBox(width: 10),
              Expanded(
                child: NvButton.soft('แยกบิล',
                    icon: NvIcons.splitBill,
                    expand: true,
                    tooltip: store.cartItemCount < 2 ? 'ต้องมีอย่างน้อย 2 ชิ้นจึงแยกบิลได้' : null,
                    onPressed: store.cartItemCount >= 2 ? _split : null),
              ),
            ],
          ),
        const SizedBox(height: 8),
        NvButton.ghost('แก้ไขรายการที่หน้าขาย', icon: NvIcons.edit, size: NvButtonSize.sm, expand: true, onPressed: () => context.go('/cashier')),
      ],
    );

    return NvSheet(
      goldEdge: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          header,
          ...notes,
          const SizedBox(height: 10),
          if (fill)
            Expanded(child: ListView(padding: EdgeInsets.zero, children: lines))
          else
            ...lines,
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          totals,
          const SizedBox(height: 14),
          actions,
        ],
      ),
    );
  }

  Widget _held(PosStore store, {required bool fill}) {
    final list = store.heldCarts;
    final header = NvSectionTitle('บิลที่พักไว้', icon: NvIcons.pause, trailing: list.isEmpty ? null : '${list.length} บิล');
    if (list.isEmpty) {
      const empty = NvSheet(
        child: NvEmptyState(
          mascot: 'empty',
          title: 'ยังไม่มีบิลที่พักไว้',
          message: 'กด "พักบิล" เพื่อเก็บบิลปัจจุบันไว้ก่อน (เช่น ลูกค้ายังเลือกของไม่เสร็จ) แล้วรับลูกค้าคนถัดไปได้ทันที',
          size: 140,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, if (fill) const Expanded(child: empty) else empty],
      );
    }
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / 280).floor().clamp(1, 4);
      final grid = GridView.builder(
        shrinkWrap: !fill,
        physics: fill ? null : const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8, top: 2),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 258,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final h = list[i];
          final info = _heldInfo(store, h);
          final cust = h.customerId == null ? null : store.customerById(h.customerId!);
          return _HeldCard(
            held: h,
            info: info,
            customerName: cust?.name,
            onResume: () => _resume(h),
            onDelete: () => _delete(h),
          );
        },
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, if (fill) Expanded(child: grid) else grid],
      );
    });
  }
}

// ─────────────────────────── pieces ───────────────────────────

class _CartLineRow extends StatelessWidget {
  final CartLine line;
  const _CartLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final l = line;
    final detail = [...l.options, if (l.note.isNotEmpty) l.note].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 36, child: Text('${l.qty}×', style: Nv.money(13.5, color: Nv.goldInk))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.product.name, style: Nv.ui(14, weight: FontWeight.w600)),
                if (detail.isNotEmpty) Text(detail, style: Nv.ui(12, color: Nv.ink3)),
                if (l.qty > 1) Text('@ ${baht(l.unitPrice)}', style: Nv.money(11.5, color: Nv.ink3, weight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(baht(l.lineTotal), style: Nv.money(14)),
        ],
      ),
    );
  }
}

class _HeldCard extends StatelessWidget {
  final HeldCart held;
  final _HeldInfo info;
  final String? customerName;
  final VoidCallback onResume;
  final VoidCallback onDelete;
  const _HeldCard({required this.held, required this.info, required this.customerName, required this.onResume, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final h = held;
    final where = h.tableNumber != null ? 'โต๊ะ ${h.tableNumber}' : h.type.label;
    final shown = info.preview.take(3).toList();
    return NvSheet(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: Nv.gold100, shape: BoxShape.circle),
                child: const Icon(NvIcons.pause, size: 13, color: Nv.goldInk),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(h.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15.5, weight: FontWeight.w700)),
                    Text('${timeAgo(h.createdAt)} · $where', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final p in shown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(13)),
                    ),
                  if (info.preview.length > shown.length)
                    Text('+ อีก ${info.preview.length - shown.length} รายการ', style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w600)),
                  if (customerName != null)
                    Text('สมาชิก $customerName', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.goldInk, weight: FontWeight.w600)),
                  if (info.missing > 0)
                    Text('มี ${info.missing} รายการที่ถูกลบจากเมนู (จะถูกข้าม)', style: Nv.ui(12, color: Nv.amber, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('${info.items} ชิ้น · ยอดสินค้า', style: Nv.ui(12, color: Nv.ink3))),
              Text(baht(info.subtotal), style: Nv.money(18)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: NvButton.gold('เรียกคืน', icon: NvIcons.play, size: NvButtonSize.sm, expand: true, onPressed: onResume)),
              const SizedBox(width: 8),
              NvIconButton(NvIcons.trash, tooltip: 'ลบบิลพัก', size: 36, color: Nv.lacquer, onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitResult {
  final Map<CartLine, int> qty;
  final String label;
  const _SplitResult(this.qty, this.label);
}

class _SplitForm extends StatefulWidget {
  final List<CartLine> lines;
  const _SplitForm({required this.lines});

  @override
  State<_SplitForm> createState() => _SplitFormState();
}

class _SplitFormState extends State<_SplitForm> {
  late final Map<CartLine, int> _move = {for (final l in widget.lines) l: 0};
  final _label = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  int get _movedItems => _move.values.fold(0, (s, v) => s + v);
  int get _movedTotal => _move.entries.fold(0, (s, e) => s + e.value * e.key.unitPrice);
  int get _allItems => widget.lines.fold(0, (s, l) => s + l.qty);
  int get _allTotal => widget.lines.fold(0, (s, l) => s + l.lineTotal);

  void _set(CartLine l, int v) => setState(() {
        _move[l] = v.clamp(0, l.qty);
        _error = null;
      });

  void _submit() {
    if (_movedItems == 0) {
      setState(() => _error = 'เลือกอย่างน้อย 1 ชิ้นที่จะแยกออก');
      return;
    }
    if (_movedItems >= _allItems) {
      setState(() => _error = 'ต้องเหลืออย่างน้อย 1 ชิ้นในบิลปัจจุบัน (ถ้าจะพักทั้งบิล ใช้ "พักบิล")');
      return;
    }
    final qty = Map<CartLine, int>.of(_move)..removeWhere((_, v) => v <= 0);
    Navigator.of(context).pop(_SplitResult(qty, _label.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    Widget side(String label, int items, int total, {bool gold = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Nv.ui(12, color: Nv.ink3)),
            Text('$items ชิ้น', style: Nv.money(15, color: gold ? Nv.goldInk : Nv.ink)),
            Text(baht(total), style: Nv.money(13, color: Nv.ink2, weight: FontWeight.w600)),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.lines.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          Builder(builder: (_) {
            final l = widget.lines[i];
            final v = _move[l] ?? 0;
            final detail = [...l.options, if (l.note.isNotEmpty) l.note].join(' · ');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.product.name, style: Nv.ui(14, weight: FontWeight.w600)),
                        if (detail.isNotEmpty) Text(detail, style: Nv.ui(12, color: Nv.ink3)),
                        Text('มี ${l.qty} · @${baht(l.unitPrice)}', style: Nv.ui(12, color: Nv.ink3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  NvStepper(
                    value: v,
                    onMinus: v > 0 ? () => _set(l, v - 1) : null,
                    onPlus: v < l.qty ? () => _set(l, v + 1) : null,
                  ),
                  SizedBox(
                    width: 76,
                    child: Text(baht(v * l.unitPrice), textAlign: TextAlign.right, style: Nv.money(13.5, color: v == 0 ? Nv.ink4 : Nv.ink)),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(Nv.rSm), border: Border.all(color: Nv.line)),
          child: Row(
            children: [
              Expanded(child: side('แยกออกเป็นบิลใหม่ (พักไว้)', _movedItems, _movedTotal, gold: true)),
              const Icon(NvIcons.rightLeft, size: 14, color: Nv.ink4),
              const SizedBox(width: 12),
              Expanded(child: side('เหลือในบิลนี้', _allItems - _movedItems, _allTotal - _movedTotal)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('* ยอดก่อนส่วนลด/VAT — ระบบคำนวณส่วนลดและภาษีใหม่ตอนชำระแต่ละบิล', style: Nv.ui(11.5, color: Nv.ink3)),
        const SizedBox(height: 12),
        NvField(label: 'ชื่อบิลที่แยก (ถ้ามี)', controller: _label, hint: 'เช่น คุณบี · จ่ายแยก', icon: NvIcons.tag),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
          ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            NvButton.gold('แยกบิล', icon: NvIcons.splitBill, onPressed: _submit),
          ],
        ),
      ],
    );
  }
}
