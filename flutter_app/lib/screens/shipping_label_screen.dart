// Thaiprompt POS — ใบปะหน้าพัสดุ · /shipping/labels?id=DL-0001
//
// Resolves the delivery job from ?id= (else shows a picker of non-cancelled
// jobs), previews the real 100×150 mm label (lib/print/shipping_label_doc.dart)
// on a paper card and prints it through PrintService (label100x150) to the
// printer chosen in Settings — or via the system dialog — and shares the PDF.
// Missing address → warning with a jump to the delivery board to fix it.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/print/print_service.dart';
import '../models/extra_models.dart';
import '../print/receipt_doc.dart' show ShopInfo;
import '../print/shipping_label_doc.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

DeliveryJob? _jobById(PosStore s, String? id) {
  if (id == null || id.isEmpty) return null;
  for (final d in s.deliveries) {
    if (d.id == id) return d;
  }
  return null;
}

ShippingLabelDoc _docFor(PosStore s, DeliveryJob job) => ShippingLabelDoc(
      job: job,
      shop: ShopInfo.of(s),
      providerName: s.providerLabel(job.providerId),
      order: s.orderById(job.orderId),
    );

class ShippingLabelScreen extends StatefulWidget {
  const ShippingLabelScreen({super.key});

  @override
  State<ShippingLabelScreen> createState() => _ShippingLabelScreenState();
}

class _ShippingLabelScreenState extends State<ShippingLabelScreen> {
  bool _busy = false;

  Future<void> _print(DeliveryJob job, {required bool usePreset}) async {
    if (_busy) return;
    if (job.address.trim().isEmpty) {
      final ok = await showNvConfirm(
        context,
        title: 'ยังไม่มีที่อยู่ผู้รับ',
        message: 'ใบปะหน้าจะไม่มีที่อยู่จัดส่ง — แนะนำให้แก้ไขงานก่อน ต้องการพิมพ์ต่อหรือไม่',
        confirmLabel: 'พิมพ์ต่อ',
        danger: false,
      );
      if (!ok || !mounted) return;
    }
    final store = AppScope.read(context);
    setState(() => _busy = true);
    final res = await PrintService.printDoc(
      context,
      _docFor(store, job),
      jobName: 'ใบปะหน้า ${job.id}',
      medium: PrintMedium.label100x150,
      printerName: usePreset ? store.printerName : '',
      precache: ShippingLabelDoc.precache,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  Future<void> _share(DeliveryJob job) async {
    if (_busy) return;
    final store = AppScope.read(context);
    setState(() => _busy = true);
    final res = await PrintService.shareDoc(
      context,
      _docFor(store, job),
      fileName: 'label-${job.id}',
      medium: PrintMedium.label100x150,
      precache: ShippingLabelDoc.precache,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final id = GoRouterState.of(context).uri.queryParameters['id'];
    final job = _jobById(store, id);
    final compact = MediaQuery.sizeOf(context).width < 760;

    if (job == null) {
      return NvScaffold(
        title: 'ใบปะหน้าพัสดุ',
        eyebrow: 'SHIPPING LABEL',
        subtitle: 'เลือกงานจัดส่งเพื่อพิมพ์ใบปะหน้าขนาด 100×150 มม.',
        art: 'shipping',
        actions: [
          NvButton.ghost(compact ? '' : 'งานจัดส่ง', icon: NvIcons.delivery, tooltip: 'งานจัดส่ง', onPressed: () => context.go('/delivery')),
        ],
        body: _Picker(store: store, missingId: id),
      );
    }

    final doc = _docFor(store, job);
    final cancelled = job.status == DeliveryStatus.cancelled;

    final preview = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Nv.line),
        boxShadow: Nv.shadowLift,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FittedBox(fit: BoxFit.contain, child: doc),
      ),
    );

    final panel = _SidePanel(
      job: job,
      doc: doc,
      busy: _busy,
      cancelled: cancelled,
      printerName: store.printerName,
      onPrint: () => _print(job, usePreset: true),
      onPrintDialog: () => _print(job, usePreset: false),
      onShare: () => _share(job),
    );

    return NvScaffold(
      title: 'ใบปะหน้า ${job.id}',
      eyebrow: 'SHIPPING LABEL · 100×150 มม.',
      subtitle: 'บิล ${job.orderId} · ${job.customerName.isEmpty ? 'ไม่ระบุชื่อผู้รับ' : job.customerName}',
      art: 'shipping',
      actions: [
        NvButton.ghost(compact ? '' : 'เลือกงานอื่น', icon: NvIcons.list, tooltip: 'เลือกงานอื่น', onPressed: () => context.go('/shipping/labels')),
      ],
      body: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= 820) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: AspectRatio(aspectRatio: ShippingLabelDoc.width / ShippingLabelDoc.height, child: preview)),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(width: c.maxWidth >= 1200 ? 380 : 330, child: SingleChildScrollView(child: panel)),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AspectRatio(aspectRatio: ShippingLabelDoc.width / ShippingLabelDoc.height, child: preview),
              ),
            ),
            const SizedBox(height: 16),
            panel,
          ],
        );
      }),
    );
  }
}

// ───────────────────────────── side panel ─────────────────────────────

class _SidePanel extends StatelessWidget {
  final DeliveryJob job;
  final ShippingLabelDoc doc;
  final bool busy;
  final bool cancelled;
  final String printerName;
  final VoidCallback onPrint;
  final VoidCallback onPrintDialog;
  final VoidCallback onShare;

  const _SidePanel({
    required this.job,
    required this.doc,
    required this.busy,
    required this.cancelled,
    required this.printerName,
    required this.onPrint,
    required this.onPrintDialog,
    required this.onShare,
  });

  Widget _notice(Color bg, Color fg, IconData icon, String text, {Widget? action}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NvSheet(
          color: bg,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 14, color: fg)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(text, style: Nv.ui(13, color: Nv.ink2, height: 1.4))),
                ],
              ),
              if (action != null) ...[const SizedBox(height: 8), action],
            ],
          ),
        ),
      );

  /// Label/value row that ellipsizes long values (names, tracking numbers).
  Widget _kv(String label, String value, {bool mono = false, bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label, style: Nv.ui(13.5, color: strong ? Nv.ink : Nv.ink3, weight: strong ? FontWeight.w700 : FontWeight.w500)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: mono
                    ? Nv.money(strong ? 16 : 14, weight: strong ? FontWeight.w700 : FontWeight.w600)
                    : Nv.ui(14, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final order = doc.order;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cancelled)
          _notice(Nv.lacquerTint, Nv.lacquer, NvIcons.xCircle, 'งานนี้ถูกยกเลิกแล้ว — พิมพ์ใบปะหน้าไม่ได้'),
        if (job.address.trim().isEmpty)
          _notice(
            Nv.amberTint,
            Nv.amber,
            NvIcons.warning,
            'ยังไม่มีที่อยู่ผู้รับ — แก้ไขงานจัดส่งเพื่อเพิ่มที่อยู่ก่อนพิมพ์',
            action: NvButton.soft('แก้ไขที่หน้างานจัดส่ง', icon: NvIcons.edit, size: NvButtonSize.sm, onPressed: () => context.go('/delivery')),
          ),
        if (job.phone.trim().isEmpty && !cancelled)
          _notice(Nv.amberTint, Nv.amber, NvIcons.phone, 'ยังไม่มีเบอร์โทรผู้รับ — ผู้ส่งของอาจติดต่อผู้รับไม่ได้'),
        if (job.trackingNo.trim().isEmpty && !cancelled)
          _notice(Nv.sapphireTint, Nv.sapphire, NvIcons.barcode, 'ยังไม่มีเลขพัสดุ — บาร์โค้ดบนใบปะหน้าใช้รหัสงาน ${job.id} แทน'),
        if (order == null)
          _notice(Nv.amberTint, Nv.amber, NvIcons.receipt, 'ไม่พบบิล ${job.orderId} ในเครื่อง — จำนวนชิ้นและยอด COD จะไม่แสดง'),
        NvSheet(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(job.id, style: Nv.money(16))),
                  NvBadge(job.status.label,
                      tint: switch (job.status) {
                        DeliveryStatus.delivered => NvTint.jade,
                        DeliveryStatus.cancelled => NvTint.neutral,
                        DeliveryStatus.pending => NvTint.amber,
                        _ => NvTint.sapphire,
                      }),
                ],
              ),
              const SizedBox(height: 8),
              _kv('ผู้ให้บริการ', doc.providerName),
              _kv('บิล', job.orderId, mono: true),
              _kv('ผู้รับ', job.customerName.isEmpty ? '—' : job.customerName),
              _kv('เบอร์โทร', job.phone.isEmpty ? '—' : phoneFmt(job.phone), mono: true),
              _kv('จำนวน', order == null ? '—' : '${order.itemCount} ชิ้น'),
              _kv('น้ำหนัก', '${(job.weightGrams / 1000).toStringAsFixed(2)} กก.'),
              _kv('เก็บเงินปลายทาง', job.cod ? baht(doc.codAmount) : 'ไม่เก็บ', mono: job.cod, strong: job.cod),
              _kv('บาร์โค้ด', doc.barcodeData, mono: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NvButton.gold(
          'พิมพ์ใบปะหน้า',
          icon: NvIcons.print,
          size: NvButtonSize.lg,
          expand: true,
          loading: busy,
          onPressed: cancelled ? null : onPrint,
        ),
        const SizedBox(height: 6),
        Text(
          printerName.isEmpty ? 'จะเปิดหน้าต่างเลือกเครื่องพิมพ์ (ยังไม่ได้ตั้งเครื่องพิมพ์ในการตั้งค่า)' : 'ส่งไปที่ "$printerName" ตามการตั้งค่า',
          textAlign: TextAlign.center,
          style: Nv.ui(12, color: Nv.ink3),
        ),
        if (printerName.isNotEmpty) ...[
          const SizedBox(height: 8),
          NvButton.soft('พิมพ์ด้วยเครื่องอื่น (เลือกเครื่องพิมพ์ฉลาก)…', icon: NvIcons.print, expand: true, size: NvButtonSize.sm,
              onPressed: cancelled || busy ? null : onPrintDialog),
        ],
        const SizedBox(height: 8),
        NvButton.navy('บันทึก / แชร์ PDF', icon: NvIcons.filePdf, expand: true, onPressed: cancelled || busy ? null : onShare),
        const SizedBox(height: 8),
        NvButton.ghost('แก้ไขงานจัดส่ง', icon: NvIcons.edit, expand: true, onPressed: () => context.go('/delivery')),
      ],
    );
  }
}

// ───────────────────────────── picker ─────────────────────────────

class _Picker extends StatelessWidget {
  final PosStore store;
  final String? missingId;
  const _Picker({required this.store, this.missingId});

  @override
  Widget build(BuildContext context) {
    final jobs = store.deliveries.where((d) => d.status != DeliveryStatus.cancelled).toList();
    if (jobs.isEmpty) {
      return NvEmptyState(
        mascot: 'present',
        title: missingId == null ? 'ยังไม่มีงานจัดส่ง' : 'ไม่พบงาน $missingId',
        message: 'สร้างงานจัดส่งจากบิลที่ชำระแล้วก่อน แล้วจึงพิมพ์ใบปะหน้า',
        actionLabel: 'ไปหน้างานจัดส่ง',
        actionIcon: NvIcons.delivery,
        onAction: () => context.go('/delivery'),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (missingId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NvSheet(
              color: Nv.amberTint,
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                const Icon(NvIcons.warning, size: 15, color: Nv.amber),
                const SizedBox(width: 10),
                Expanded(child: Text('ไม่พบงานจัดส่ง "$missingId" — เลือกงานจากรายการด้านล่าง', style: Nv.ui(13, color: Nv.ink2))),
              ]),
            ),
          ),
        NvSectionTitle('เลือกงานจัดส่ง', icon: NvIcons.delivery, trailing: '${jobs.length} งาน'),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 1200 ? 3 : (c.maxWidth > 720 ? 2 : 1);
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final j in jobs)
                SizedBox(
                  width: w,
                  child: NvSheet(
                    padding: const EdgeInsets.all(14),
                    onTap: () => context.go('/shipping/labels?id=${j.id}'),
                    child: Row(
                      children: [
                        NvArt.icon('shipping', size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(j.id, style: Nv.money(14)),
                                const SizedBox(width: 8),
                                NvBadge(j.status.label, tint: j.status == DeliveryStatus.delivered ? NvTint.jade : NvTint.sapphire),
                              ]),
                              const SizedBox(height: 3),
                              Text(
                                '${j.customerName.isEmpty ? 'ไม่ระบุชื่อ' : j.customerName} · ${store.providerById(j.providerId)?.name ?? j.providerId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Nv.ui(13, weight: FontWeight.w600),
                              ),
                              Text(
                                j.address.isEmpty ? 'ยังไม่ระบุที่อยู่' : j.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Nv.ui(12, color: j.address.isEmpty ? Nv.lacquer : Nv.ink3),
                              ),
                            ],
                          ),
                        ),
                        const Icon(NvIcons.print, size: 15, color: Nv.goldInk),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}
