// Thaiprompt POS — งานจัดส่ง · /delivery
//
// Board of real delivery jobs (store.deliveries) by status: รอไรเดอร์ →
// ไรเดอร์รับของ → กำลังจัดส่ง → ส่งสำเร็จ (cancelled jobs behind a filter).
// Each card: job / order id, receiver, phone, address, provider, tracking no.,
// fee, COD, age. Actions: advance status, edit (dialog → updateDelivery),
// print the shipping label (/shipping/labels?id=), copy tracking no. / link,
// cancel (confirm). "สร้างงานจัดส่ง" picks a paid order that has no job yet →
// form → createDelivery. No partner API: status and tracking are kept by staff.
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';

const _board = [DeliveryStatus.pending, DeliveryStatus.picking, DeliveryStatus.delivering, DeliveryStatus.delivered];

NvTint _statusTint(DeliveryStatus s) => switch (s) {
      DeliveryStatus.pending => NvTint.amber,
      DeliveryStatus.picking => NvTint.sapphire,
      DeliveryStatus.delivering => NvTint.gold,
      DeliveryStatus.delivered => NvTint.jade,
      DeliveryStatus.cancelled => NvTint.neutral,
    };

/// Verb for the "advance" button (what happens when tapped).
String _advanceLabel(DeliveryStatus s) => switch (s) {
      DeliveryStatus.pending => 'ไรเดอร์รับของแล้ว',
      DeliveryStatus.picking => 'ออกจัดส่ง',
      DeliveryStatus.delivering => 'ส่งสำเร็จ',
      _ => '',
    };

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  DeliveryStatus _tab = DeliveryStatus.pending;
  bool _showCancelled = false;
  String _query = '';
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // อายุงาน ("5 นาทีที่แล้ว") — รีเฟรชทุกนาที
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool _match(DeliveryJob j) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return j.id.toLowerCase().contains(q) ||
        j.orderId.toLowerCase().contains(q) ||
        j.customerName.toLowerCase().contains(q) ||
        j.trackingNo.toLowerCase().contains(q) ||
        (digits.length >= 3 && j.phone.replaceAll(RegExp(r'\D'), '').contains(digits));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final jobs = store.deliveries.where(_match).toList();
    List<DeliveryJob> of(DeliveryStatus s) => jobs.where((j) => j.status == s).toList();
    final cancelledCount = store.deliveries.where((j) => j.status == DeliveryStatus.cancelled).length;
    final compact = MediaQuery.sizeOf(context).width < 760;
    if (!_showCancelled && _tab == DeliveryStatus.cancelled) _tab = DeliveryStatus.pending;

    return NvScaffold(
      title: 'งานจัดส่ง',
      eyebrow: 'DELIVERY',
      subtitle: 'ติดตามงานส่งของ — สถานะและเลขพัสดุบันทึกโดยพนักงาน (ยังไม่เชื่อม API ผู้ให้บริการ)',
      art: 'delivery',
      actions: [
        if (!compact) NvButton.ghost('ใบปะหน้า', icon: NvIcons.print, onPressed: () => context.go('/shipping/labels')),
        if (!compact && store.isManager)
          NvButton.ghost('ผู้ให้บริการ', icon: NvIcons.shipping, onPressed: () => context.go('/shipping/providers')),
        NvButton.gold(compact ? '' : 'สร้างงานจัดส่ง', icon: NvIcons.plus, tooltip: 'สร้างงานจัดส่ง', onPressed: () => _createJob(context)),
      ],
      body: store.deliveries.isEmpty
          ? NvEmptyState(
              mascot: 'present',
              title: 'ยังไม่มีงานจัดส่ง',
              message: 'เลือกบิลที่ชำระแล้วเพื่อสร้างงานส่งของ กรอกที่อยู่ผู้รับ เลือกผู้ให้บริการ แล้วพิมพ์ใบปะหน้าได้ทันที',
              actionLabel: 'สร้างงานจัดส่ง',
              actionIcon: NvIcons.plus,
              onAction: () => _createJob(context),
            )
          : LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 1000;
              final toolbar = Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: NvSearchField(
                          hint: 'ค้นหา รหัสงาน · บิล · ชื่อ · เบอร์ · เลขพัสดุ',
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  NvChip(
                    'แสดงงานที่ยกเลิก',
                    icon: _showCancelled ? NvIcons.eye : NvIcons.eyeSlash,
                    selected: _showCancelled,
                    count: cancelledCount,
                    onTap: () => setState(() => _showCancelled = !_showCancelled),
                  ),
                ],
              );
              if (wide) {
                final cols = [..._board, if (_showCancelled) DeliveryStatus.cancelled];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    toolbar,
                    const SizedBox(height: 14),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < cols.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: _BoardColumn(status: cols[i], jobs: of(cols[i]))),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }
              final tabs = [..._board, if (_showCancelled) DeliveryStatus.cancelled];
              final current = of(_tab);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  toolbar,
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in tabs) ...[
                          NvChip(s.label, selected: _tab == s, count: of(s).length, onTap: () => setState(() => _tab = s)),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: current.isEmpty
                        ? NvEmptyState(mascot: 'sleepy', size: 120, title: 'ไม่มีงาน "${_tab.label}"', message: _query.isEmpty ? null : 'ลองล้างคำค้นหา')
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: current.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => _JobCard(job: current[i]),
                          ),
                  ),
                ],
              );
            }),
    );
  }
}

// ───────────────────────────── board column ─────────────────────────────

class _BoardColumn extends StatelessWidget {
  final DeliveryStatus status;
  final List<DeliveryJob> jobs;
  const _BoardColumn({required this.status, required this.jobs});

  @override
  Widget build(BuildContext context) {
    final tint = nvTint(_statusTint(status));
    return Container(
      decoration: BoxDecoration(
        color: Nv.ivoryDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Nv.rLg),
        border: Border.all(color: Nv.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: tint.fg, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(status.label, style: Nv.ui(14.5, weight: FontWeight.w700))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: tint.bg, borderRadius: BorderRadius.circular(Nv.rPill)),
                  child: Text('${jobs.length}', style: Nv.money(12, color: tint.fg)),
                ),
              ],
            ),
          ),
          Expanded(
            child: jobs.isEmpty
                ? Center(child: Text('ไม่มีงาน', style: Nv.ui(12.5, color: Nv.ink4)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _JobCard(job: jobs[i], dense: true),
                  ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── job card ─────────────────────────────

class _JobCard extends StatelessWidget {
  final DeliveryJob job;
  final bool dense;
  const _JobCard({required this.job, this.dense = false});

  Future<void> _copy(BuildContext context, String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    nvToast(context, 'คัดลอก$whatแล้ว', kind: NvToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final j = job;
    final provider = store.providerById(j.providerId);
    final order = store.orderById(j.orderId);
    final open = j.status != DeliveryStatus.delivered && j.status != DeliveryStatus.cancelled;
    final trackingUrl = (provider?.trackingUrl.isNotEmpty ?? false) && j.trackingNo.isNotEmpty
        ? provider!.trackingUrl.replaceAll('{no}', Uri.encodeComponent(j.trackingNo))
        : null;

    Widget line(IconData icon, Widget child, {Color iconColor = Nv.goldInk}) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 11.5, color: iconColor)),
              const SizedBox(width: 8),
              Expanded(child: child),
            ],
          ),
        );

    return NvSheet(
      padding: EdgeInsets.fromLTRB(dense ? 12 : 16, 12, dense ? 10 : 14, 10),
      radius: Nv.rMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(j.id, style: Nv.money(13.5)),
              const SizedBox(width: 8),
              if (!dense || j.status == DeliveryStatus.cancelled) NvBadge(j.status.label, tint: _statusTint(j.status)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(timeAgo(j.status == DeliveryStatus.delivered && j.deliveredAt != null ? j.deliveredAt! : j.createdAt),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: Nv.ui(11, color: Nv.ink3)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              NvBadge('บิล ${j.orderId}', tint: NvTint.neutral, icon: NvIcons.receipt),
              NvBadge(provider?.name ?? j.providerId, tint: NvTint.sapphire, icon: NvIcons.delivery),
              if (j.cod) NvBadge('COD ${order == null ? '' : baht(order.netTotal)}'.trim(), tint: NvTint.amber, icon: NvIcons.handDollar),
            ],
          ),
          const SizedBox(height: 8),
          Text(j.customerName.isEmpty ? 'ไม่ระบุชื่อผู้รับ' : j.customerName,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15, weight: FontWeight.w700, color: j.customerName.isEmpty ? Nv.ink3 : Nv.ink)),
          if (j.phone.isNotEmpty) line(NvIcons.phone, Text(phoneFmt(j.phone), style: Nv.money(13, color: Nv.ink2, weight: FontWeight.w500))),
          line(
            NvIcons.location,
            Text(j.address.isEmpty ? 'ยังไม่ระบุที่อยู่' : j.address,
                maxLines: dense ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Nv.ui(12.5, color: j.address.isEmpty ? Nv.lacquer : Nv.ink2, height: 1.35)),
            iconColor: j.address.isEmpty ? Nv.lacquer : Nv.goldInk,
          ),
          if (j.trackingNo.isNotEmpty)
            line(
              NvIcons.barcode,
              Row(
                children: [
                  Flexible(child: Text(j.trackingNo, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.money(12.5, color: Nv.ink))),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _copy(context, j.trackingNo, 'เลขพัสดุ ${j.trackingNo} '),
                    child: const Padding(padding: EdgeInsets.all(4), child: Icon(NvIcons.copy, size: 12, color: Nv.goldInk)),
                  ),
                  if (trackingUrl != null)
                    Tooltip(
                      message: 'คัดลอกลิงก์ติดตามพัสดุ',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _copy(context, trackingUrl, 'ลิงก์ติดตามพัสดุ'),
                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(NvIcons.link, size: 12, color: Nv.goldInk)),
                      ),
                    ),
                ],
              ),
            ),
          if (j.riderName.isNotEmpty) line(NvIcons.personWalking, Text('ผู้ส่ง: ${j.riderName}', style: Nv.ui(12.5, color: Nv.ink2))),
          line(
            NvIcons.moneyBill,
            Text('ค่าส่ง ${baht(j.fee)} · ${(j.weightGrams / 1000).toStringAsFixed(2)} กก.', style: Nv.ui(12.5, color: Nv.ink2)),
          ),
          if (j.note.isNotEmpty) line(NvIcons.note, Text(j.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3))),
          const SizedBox(height: 10),
          Row(
            children: [
              if (open)
                Expanded(
                  child: NvButton.gold(
                    _advanceLabel(j.status),
                    icon: NvIcons.arrowRight,
                    size: NvButtonSize.sm,
                    expand: true,
                    tooltip: 'เปลี่ยนเป็น "${j.status.next.label}"',
                    onPressed: () => _advance(context, j),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 6),
              NvIconButton(NvIcons.edit, size: 34, tooltip: 'แก้ไข', onPressed: j.status == DeliveryStatus.cancelled ? null : () => _editJob(context, j)),
              const SizedBox(width: 4),
              NvIconButton(NvIcons.print, size: 34, tooltip: 'พิมพ์ใบปะหน้า',
                  onPressed: j.status == DeliveryStatus.cancelled ? null : () => context.go('/shipping/labels?id=${j.id}')),
              if (open) ...[
                const SizedBox(width: 4),
                NvIconButton(NvIcons.xCircle, size: 34, tooltip: 'ยกเลิกงาน', color: Nv.lacquer, onPressed: () => _cancelJob(context, j)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── actions ─────────────────────────────

Future<void> _advance(BuildContext context, DeliveryJob j) async {
  final store = AppScope.read(context);
  if (j.status.next == DeliveryStatus.delivered && j.cod) {
    final order = store.orderById(j.orderId);
    final ok = await showNvConfirm(
      context,
      title: 'ยืนยันส่งสำเร็จ',
      message: 'งาน ${j.id} เก็บเงินปลายทาง${order == null ? '' : ' ${baht(order.netTotal)}'} — ได้รับเงินจากผู้ส่งของแล้วใช่ไหม',
      confirmLabel: 'ได้รับเงินแล้ว · ส่งสำเร็จ',
      danger: false,
      icon: NvIcons.handDollar,
    );
    if (!ok || !context.mounted) return;
  }
  if (j.status == DeliveryStatus.delivered || j.status == DeliveryStatus.cancelled) return;
  store.advanceDelivery(j);
  nvToast(context, '${j.id} → ${j.status.label}', kind: NvToastKind.success);
}

Future<void> _cancelJob(BuildContext context, DeliveryJob j) async {
  final ok = await showNvConfirm(
    context,
    title: 'ยกเลิกงาน ${j.id}?',
    message: 'งานจะย้ายไปอยู่ในรายการที่ยกเลิก บิล ${j.orderId} จะสร้างงานจัดส่งใหม่ได้',
    confirmLabel: 'ยกเลิกงาน',
    cancelLabel: 'ไม่ยกเลิก',
  );
  if (!ok || !context.mounted) return;
  AppScope.read(context).cancelDelivery(j);
  nvToast(context, 'ยกเลิกงาน ${j.id} แล้ว', kind: NvToastKind.success);
}

Future<void> _editJob(BuildContext context, DeliveryJob j) async {
  final store = AppScope.read(context);
  final input = await _openJobForm(context, edit: j, order: store.orderById(j.orderId));
  if (input == null || !context.mounted) return;
  store.updateDelivery(
    j,
    customerName: input.name,
    phone: input.phone,
    address: input.address,
    providerId: input.providerId,
    trackingNo: input.tracking,
    riderName: input.rider,
    fee: input.fee,
    cod: input.cod,
    weightGrams: input.weight,
    note: input.note,
  );
  nvToast(context, 'บันทึกงาน ${j.id} แล้ว', kind: NvToastKind.success);
}

Future<void> _createJob(BuildContext context) async {
  final store = AppScope.read(context);
  final order = await showNvDialog<Order>(
    context,
    title: 'เลือกบิลที่จะจัดส่ง',
    subtitle: 'บิลที่ชำระแล้วและยังไม่มีงานจัดส่ง',
    art: 'delivery',
    maxWidth: 560,
    body: const _OrderPicker(),
    actions: (ctx) => [NvButton.soft('ยกเลิก', onPressed: () => _close(ctx))],
  );
  if (order == null || !context.mounted) return;
  if (store.deliveryForOrder(order.id) != null) {
    nvToast(context, 'บิล ${order.id} มีงานจัดส่งอยู่แล้ว', kind: NvToastKind.error);
    return;
  }
  final input = await _openJobForm(context, order: order);
  if (input == null || !context.mounted) return;
  if (store.deliveryForOrder(order.id) != null) {
    nvToast(context, 'บิล ${order.id} มีงานจัดส่งอยู่แล้ว', kind: NvToastKind.error);
    return;
  }
  final job = store.createDelivery(
    order,
    customerName: input.name,
    phone: input.phone,
    address: input.address,
    providerId: input.providerId,
    fee: input.fee,
    cod: input.cod,
    weightGrams: input.weight,
    note: input.note,
  );
  // createDelivery ใส่ค่าส่งเริ่มต้นเมื่อ fee = 0 และไม่รับเลขพัสดุ/ผู้ส่ง — เติมค่าที่กรอกให้ตรง
  if (input.tracking.isNotEmpty || input.rider.isNotEmpty || job.fee != input.fee) {
    store.updateDelivery(job, trackingNo: input.tracking, riderName: input.rider, fee: input.fee);
  }
  final router = GoRouter.of(context);
  nvToast(context, 'สร้างงาน ${job.id} จากบิล ${order.id} แล้ว',
      kind: NvToastKind.success, actionLabel: 'พิมพ์ใบปะหน้า', onAction: () => router.go('/shipping/labels?id=${job.id}'));
}

// ───────────────────────────── order picker ─────────────────────────────

class _OrderPicker extends StatefulWidget {
  const _OrderPicker();

  @override
  State<_OrderPicker> createState() => _OrderPickerState();
}

class _OrderPickerState extends State<_OrderPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final q = _q.trim().toLowerCase();
    final all = store.paidOrders.where((o) => store.deliveryForOrder(o.id) == null).toList()
      ..sort((a, b) {
        final da = a.type == OrderType.delivery ? 0 : 1;
        final db = b.type == OrderType.delivery ? 0 : 1;
        return da != db ? da.compareTo(db) : b.createdAt.compareTo(a.createdAt);
      });
    final list = all
        .where((o) => q.isEmpty || o.id.toLowerCase().contains(q) || (o.customerName ?? '').toLowerCase().contains(q))
        .take(60)
        .toList();
    if (all.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NvArt.mascot('empty', height: 110),
          const SizedBox(height: 8),
          Text('ไม่มีบิลที่ชำระแล้วซึ่งยังไม่มีงานจัดส่ง', textAlign: TextAlign.center, style: Nv.ui(14, color: Nv.ink2)),
          const SizedBox(height: 4),
          Text('ขายและชำระเงินที่หน้าขายก่อน แล้วกลับมาสร้างงานจัดส่ง', textAlign: TextAlign.center, style: Nv.ui(12.5, color: Nv.ink3)),
          const SizedBox(height: 12),
          NvButton.gold('ไปหน้าขาย', icon: NvIcons.cashier, onPressed: () {
            final router = GoRouter.of(context);
            _close(context);
            router.go('/cashier');
          }),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSearchField(hint: 'ค้นหาเลขบิลหรือชื่อลูกค้า', autofocus: true, onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 10),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('ไม่พบบิลที่ค้นหา', textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.ink3)),
          ),
        for (final o in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NvSheet(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              radius: Nv.rMd,
              onTap: () => _close(context, o),
              child: Row(
                children: [
                  const Icon(NvIcons.receipt, size: 15, color: Nv.goldInk),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(o.id, style: Nv.money(14)),
                          const SizedBox(width: 8),
                          if (o.type == OrderType.delivery) const NvBadge('เดลิเวอรี่', tint: NvTint.gold),
                        ]),
                        Text(
                          '${thaiDateTime(o.createdAt)} · ${o.itemCount} ชิ้น${o.customerName == null ? '' : ' · ${o.customerName}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Nv.ui(12, color: Nv.ink3),
                        ),
                      ],
                    ),
                  ),
                  NvMoney(o.netTotal, size: 14.5),
                  const SizedBox(width: 6),
                  const Icon(NvIcons.angleRight, size: 12, color: Nv.ink4),
                ],
              ),
            ),
          ),
        if (all.length > list.length && q.isEmpty)
          Text('แสดง 60 บิลล่าสุด — พิมพ์เลขบิลเพื่อค้นหาบิลที่เก่ากว่า', textAlign: TextAlign.center, style: Nv.ui(12, color: Nv.ink3)),
      ],
    );
  }
}

// ───────────────────────────── job form ─────────────────────────────

class _JobInput {
  final String name, phone, address, providerId, tracking, rider, note;
  final int fee, weight;
  final bool cod;
  const _JobInput({
    required this.name,
    required this.phone,
    required this.address,
    required this.providerId,
    required this.tracking,
    required this.rider,
    required this.note,
    required this.fee,
    required this.weight,
    required this.cod,
  });
}

Future<_JobInput?> _openJobForm(BuildContext context, {DeliveryJob? edit, Order? order}) {
  final key = GlobalKey<_JobFormState>();
  return showNvDialog<_JobInput>(
    context,
    title: edit == null ? 'งานจัดส่งใหม่' : 'แก้ไขงาน ${edit.id}',
    subtitle: order == null ? null : 'บิล ${order.id} · ${baht(order.netTotal)} · ${order.itemCount} ชิ้น',
    art: 'shipping',
    maxWidth: 600,
    body: _JobForm(key: key, edit: edit, order: order),
    actions: (ctx) => [
      NvButton.soft('ยกเลิก', onPressed: () => _close(ctx)),
      NvButton.gold(edit == null ? 'สร้างงาน' : 'บันทึก', icon: NvIcons.floppy, onPressed: () => key.currentState?._save()),
    ],
  );
}

class _JobForm extends StatefulWidget {
  final DeliveryJob? edit;
  final Order? order;
  const _JobForm({super.key, this.edit, this.order});

  @override
  State<_JobForm> createState() => _JobFormState();
}

class _JobFormState extends State<_JobForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _tracking;
  late final TextEditingController _rider;
  late final TextEditingController _fee;
  late final TextEditingController _weight;
  late final TextEditingController _note;
  late String _providerId;
  late bool _cod;
  bool _feeTouched = false;

  @override
  void initState() {
    super.initState();
    final store = AppScope.read(context);
    final e = widget.edit;
    final o = widget.order;
    final member = o?.customerId == null ? null : store.customerById(o!.customerId!);
    final providers = store.enabledProviders.isEmpty ? store.shippingProviders : store.enabledProviders;
    _providerId = e?.providerId ?? (providers.isNotEmpty ? providers.first.id : 'self');
    final baseFee = store.providerById(_providerId)?.baseFee ?? 0;
    _name = TextEditingController(text: e?.customerName ?? o?.customerName ?? member?.name ?? '');
    _phone = TextEditingController(text: (e?.phone ?? member?.phone ?? '').replaceAll(RegExp(r'\D'), ''));
    _address = TextEditingController(text: e?.address ?? '');
    _tracking = TextEditingController(text: e?.trackingNo ?? '');
    _rider = TextEditingController(text: e?.riderName ?? '');
    _fee = TextEditingController(text: '${e?.fee ?? baseFee}');
    _weight = TextEditingController(text: '${e?.weightGrams ?? 500}');
    _note = TextEditingController(text: e?.note ?? '');
    _cod = e?.cod ?? false;
    _feeTouched = e != null;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _tracking, _rider, _fee, _weight, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    _close(context, _JobInput(
      name: _name.text.trim(),
      phone: _phone.text.replaceAll(RegExp(r'\D'), ''),
      address: _address.text.trim(),
      providerId: _providerId,
      tracking: _tracking.text.trim(),
      rider: _rider.text.trim(),
      note: _note.text.trim(),
      fee: int.tryParse(_fee.text) ?? 0,
      weight: int.tryParse(_weight.text) ?? 0,
      cod: _cod,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final enabled = store.enabledProviders;
    final providers = <ShippingProvider>[
      ...(enabled.isEmpty ? store.shippingProviders : enabled),
    ];
    final cur = store.providerById(_providerId);
    if (cur != null && !providers.any((p) => p.id == cur.id)) providers.add(cur);
    final codAmount = widget.order?.netTotal;

    Widget two(Widget a, Widget b) => LayoutBuilder(
          builder: (context, c) => c.maxWidth < 420
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 12), b])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]),
        );

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          two(
            NvField(label: 'ชื่อผู้รับ', controller: _name, icon: NvIcons.user, formatters: [LengthLimitingTextInputFormatter(60)]),
            NvField(
              label: 'เบอร์โทรผู้รับ',
              controller: _phone,
              icon: NvIcons.phone,
              keyboard: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              validator: (v) {
                final d = (v ?? '').trim();
                if (d.isEmpty) return null;
                return RegExp(r'^0\d{8,9}$').hasMatch(d) ? null : 'ตัวเลข 9–10 หลัก ขึ้นต้นด้วย 0';
              },
            ),
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'ที่อยู่จัดส่ง',
            controller: _address,
            icon: NvIcons.location,
            maxLines: 3,
            hint: 'บ้านเลขที่ ถนน แขวง/ตำบล เขต/อำเภอ จังหวัด รหัสไปรษณีย์',
            onChanged: (_) => setState(() {}),
          ),
          if (_address.text.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('ต้องมีที่อยู่เพื่อพิมพ์ใบปะหน้า', style: Nv.ui(11.5, color: Nv.amber)),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('ผู้ให้บริการ', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
          ),
          InputDecorator(
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: providers.any((p) => p.id == _providerId) ? _providerId : null,
                isExpanded: true,
                style: Nv.ui(14.5),
                icon: const Icon(NvIcons.chevronDown, size: 12, color: Nv.ink3),
                borderRadius: BorderRadius.circular(Nv.rSm),
                dropdownColor: Nv.paper,
                items: [
                  for (final p in providers)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.name}${p.enabled ? '' : ' (ปิดใช้งาน)'} · ค่าส่งเริ่มต้น ${baht(p.baseFee)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _providerId = v;
                    if (!_feeTouched) _fee.text = '${store.providerById(v)?.baseFee ?? 0}';
                  });
                },
              ),
            ),
          ),
          if (enabled.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('ยังไม่ได้เปิดใช้ผู้ให้บริการ — แสดงทั้งหมด (เปิดใช้ได้ที่ "ผู้ให้บริการขนส่ง")', style: Nv.ui(11.5, color: Nv.amber)),
            ),
          const SizedBox(height: 12),
          two(
            NvField(label: 'เลขพัสดุ / เลขออเดอร์ผู้ให้บริการ', controller: _tracking, icon: NvIcons.barcode, formatters: [LengthLimitingTextInputFormatter(40)]),
            NvField(label: 'ชื่อผู้ส่งของ / ไรเดอร์', controller: _rider, icon: NvIcons.personWalking, formatters: [LengthLimitingTextInputFormatter(40)]),
          ),
          const SizedBox(height: 12),
          two(
            NvField(
              label: 'ค่าส่ง (บาท)',
              controller: _fee,
              icon: NvIcons.moneyBill,
              keyboard: TextInputType.number,
              suffixText: '฿',
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              onChanged: (_) => _feeTouched = true,
            ),
            NvField(
              label: 'น้ำหนัก (กรัม)',
              controller: _weight,
              icon: NvIcons.scale,
              keyboard: TextInputType.number,
              suffixText: 'g',
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'ต้องมากกว่า 0' : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Switch(value: _cod, onChanged: (v) => setState(() => _cod = v)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _cod ? 'เก็บเงินปลายทาง (COD)${codAmount == null ? '' : ' ${baht(codAmount)}'}' : 'ไม่เก็บเงินปลายทาง',
                  style: Nv.ui(13.5, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          NvField(label: 'หมายเหตุ', controller: _note, icon: NvIcons.note, hint: 'เช่น ฝากป้อมยาม · โทรก่อนส่ง', formatters: [LengthLimitingTextInputFormatter(120)]),
        ],
      ),
    );
  }
}

/// Pop [ctx]'s route only while it is still the top route — a double tap
/// during the exit animation must never pop the page underneath.
void _close(BuildContext ctx, [Object? result]) {
  if (ModalRoute.of(ctx)?.isCurrent ?? false) Navigator.of(ctx).pop(result);
}
