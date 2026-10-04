// Thaiprompt POS — กะการขาย (cash shift) · Nova.
//
// No open shift → a night hero with น้องพร้อม, the last Z summary and
// "เปิดกะ" (opening float → PosStore.openShift).
// Open shift → live KPIs computed from the orders recorded in THIS shift
// (shiftSales / ordersInShift / shiftRefunds / expectedCash), the by-method
// breakdown, the drawer ledger with pay-in / pay-out (manager PIN) / safe
// drop, and the shift's bills. "ปิดกะ" counts the drawer by denomination (or
// a typed total), shows the variance against the expected cash live, takes a
// note, confirms, closes the shift (Z snapshot) and opens the Z-Report
// preview for printing. Past shifts can reprint their Z-Report.
// "เปิดลิ้นชัก" kicks the cash drawer through the ESC/POS receipt printer
// (manager PIN, audit log "drawer.open").
//
// by xman studio

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/hardware/printer_hub.dart';
import '../core/print/print_service.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../print/print_actions.dart' show rollMedium;
import '../print/receipt_doc.dart' show ShopInfo;
import '../print/z_report_doc.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

const _denoms = [1000, 500, 100, 50, 20, 10, 5, 2, 1];

String _dur(DateTime from, [DateTime? to]) {
  final d = (to ?? DateTime.now()).difference(from);
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h > 0 ? '$h ชม. $m นาที' : '$m นาที';
}

String _varianceText(int v) => v == 0 ? 'ตรง' : (v > 0 ? 'เกิน ${baht(v)}' : 'ขาด ${baht(-v)}');

Widget _varianceBadge(int v) {
  if (v == 0) return const NvBadge('เงินสดตรง', tint: NvTint.jade);
  if (v > 0) return NvBadge('เกิน ${baht(v)}', tint: NvTint.sapphire);
  return NvBadge('ขาด ${baht(-v)}', tint: NvTint.lacquer);
}

String _summary(List<OrderLine> lines) {
  if (lines.isEmpty) return '—';
  final head = lines.take(2).map((l) => '${l.name} ×${l.qty}').join(', ');
  return lines.length > 2 ? '$head +${lines.length - 2}' : head;
}

/// Equal-width grid built from Rows (works inside ListViews).
Widget _grid(List<Widget> items, int cols, {double gap = 12}) {
  final rows = <Widget>[];
  for (var i = 0; i < items.length; i += cols) {
    final chunk = items.sublist(i, math.min(i + cols, items.length));
    rows.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var j = 0; j < cols; j++) ...[
          if (j > 0) SizedBox(width: gap),
          Expanded(child: j < chunk.length ? chunk[j] : const SizedBox.shrink()),
        ],
      ],
    ));
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        rows[i],
      ],
    ],
  );
}

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  bool _openingDrawer = false;

  // ─────────────────────────── actions ───────────────────────────

  /// "No sale" drawer open — manager PIN, audit-logged.
  Future<void> _openDrawer() async {
    if (_openingDrawer) return;
    final hub = PrinterHub.instance;
    if (!hub.usesEscPos) {
      nvToast(context, 'ยังไม่ได้ตั้งเครื่องพิมพ์ใบเสร็จแบบ USB / LAN / บลูทูธ ที่ต่อลิ้นชักเงินสด', kind: NvToastKind.warning);
      return;
    }
    final mgr = await showManagerPin(context, reason: 'เปิดลิ้นชักเงินสด (ไม่มีการขาย)');
    if (mgr == null || !mounted) return;
    setState(() => _openingDrawer = true);
    try {
      await hub.openDrawer();
      if (!mounted) return;
      final store = AppScope.read(context);
      store.log('drawer.open', 'เปิดลิ้นชัก (ไม่มีการขาย) · อนุมัติโดย ${mgr.name}');
      store.flush().ignore();
      nvToast(context, 'เปิดลิ้นชักแล้ว', kind: NvToastKind.success);
    } on PrinterException catch (e) {
      if (mounted) nvToast(context, 'เปิดลิ้นชักไม่สำเร็จ: ${e.message}', kind: NvToastKind.error);
    } catch (e) {
      if (mounted) nvToast(context, 'เปิดลิ้นชักไม่สำเร็จ: $e', kind: NvToastKind.error);
    } finally {
      if (mounted) setState(() => _openingDrawer = false);
    }
  }

  Widget _drawerButton() {
    final ready = PrinterHub.instance.usesEscPos;
    final btn = NvButton.soft('เปิดลิ้นชัก',
        icon: NvIcons.drawer, size: NvButtonSize.sm, loading: _openingDrawer, onPressed: ready && !_openingDrawer ? _openDrawer : null);
    return Tooltip(
      message: ready
          ? 'เปิดลิ้นชักเงินสดโดยไม่มีการขาย (ต้องใช้ PIN ผู้จัดการ)'
          : 'ต้องตั้งเครื่องพิมพ์ใบเสร็จแบบ USB / LAN / บลูทูธ ที่ต่อลิ้นชักก่อน (ตั้งค่า › ใบเสร็จและเครื่องพิมพ์)',
      child: btn,
    );
  }

  Future<void> _openShift() async {
    final store = AppScope.read(context);
    final amount = await showNvAmountDialog(
      context,
      title: 'เปิดกะการขาย',
      subtitle: 'นับเงินทอนในลิ้นชักก่อนเริ่มขาย แล้วใส่ยอดตั้งต้น (ใส่ 0 ได้)',
      art: 'drawer',
      confirmLabel: 'เปิดกะ',
      initial: store.shiftHistory.isNotEmpty ? store.shiftHistory.first.openingCash : null,
    );
    if (amount == null || !mounted) return;
    final s = AppScope.read(context);
    if (s.hasOpenShift) {
      nvToast(context, 'มีกะที่เปิดอยู่แล้ว', kind: NvToastKind.warning);
      return;
    }
    s.openShift(openingCash: amount);
    nvToast(context, 'เปิดกะแล้ว · เงินทอนตั้งต้น ${baht(amount)}', kind: NvToastKind.success);
  }

  Future<void> _move(CashMoveType type) async {
    final store = AppScope.read(context);
    final s = store.currentShift;
    if (s == null || !s.isOpen) return;
    final res = await showNvDialog<(int, String)>(
      context,
      title: type.label,
      subtitle: switch (type) {
        CashMoveType.payIn => 'เพิ่มเงินเข้าลิ้นชัก เช่น เติมเงินทอน',
        CashMoveType.payOut => 'นำเงินสดออกไปใช้จ่าย — ต้องอนุมัติโดยผู้จัดการ',
        CashMoveType.drop => 'ย้ายเงินส่วนเกินออกจากลิ้นชักไปเก็บในตู้เซฟ',
      },
      art: type == CashMoveType.drop ? 'drawer' : 'cash',
      maxWidth: 440,
      body: _CashMoveForm(type: type, available: store.expectedCash(s)),
    );
    if (res == null || !mounted) return;
    var reason = res.$2;
    if (type == CashMoveType.payOut) {
      final mgr = await showManagerPin(context, reason: 'นำเงินออกจากลิ้นชัก ${baht(res.$1)}${reason.isEmpty ? '' : ' · $reason'}');
      if (mgr == null || !mounted) return;
      if (mgr.id != AppScope.read(context).currentStaff?.id) {
        reason = [reason, 'อนุมัติโดย ${mgr.name}'].where((e) => e.isNotEmpty).join(' · ');
      }
    }
    final st = AppScope.read(context);
    if (!st.hasOpenShift) {
      nvToast(context, 'กะถูกปิดไปแล้ว', kind: NvToastKind.warning);
      return;
    }
    st.addCashMovement(type, res.$1, reason: reason);
    nvToast(context, '${type.label} ${baht(res.$1)} แล้ว', kind: NvToastKind.success);
  }

  Future<void> _close() async {
    final store = AppScope.read(context);
    final s = store.currentShift;
    if (s == null || !s.isOpen) return;
    final res = await showNvDialog<(int, String)>(
      context,
      title: 'ปิดกะ · นับเงินสด',
      subtitle: 'นับเงินในลิ้นชักจริง ระบบจะเทียบกับยอดที่ควรมีให้ทันที',
      art: 'drawer',
      maxWidth: 560,
      barrierDismissible: false,
      body: const _CloseShiftForm(),
    );
    if (res == null || !mounted) return;
    final st = AppScope.read(context);
    final cur = st.currentShift;
    if (cur == null || !cur.isOpen) return;
    final expected = st.expectedCash(cur);
    final variance = res.$1 - expected;
    final ok = await showNvConfirm(
      context,
      title: 'ยืนยันปิดกะ?',
      message: 'นับได้ ${baht(res.$1)} · ควรมี ${baht(expected)}\n'
          'ส่วนต่าง: ${variance == 0 ? 'ตรงพอดี' : _varianceText(variance)}\n\n'
          'ปิดกะแล้วจะแก้ไขยอดไม่ได้ และระบบจะออก Z-Report',
      confirmLabel: 'ปิดกะ',
      danger: variance != 0,
      art: 'shift',
    );
    if (!ok || !mounted) return;
    final z = AppScope.read(context).closeShift(countedCash: res.$1, note: res.$2);
    if (z == null) {
      nvToast(context, 'ไม่มีกะที่เปิดอยู่', kind: NvToastKind.warning);
      return;
    }
    nvToast(context, 'ปิดกะ ${ZReportDoc.zLabel(z)} แล้ว', kind: NvToastKind.success);
    await _showZ(z, reprint: false);
  }

  Future<void> _showZ(Shift z, {required bool reprint}) => showNvDialog<void>(
        context,
        title: 'Z-Report ${ZReportDoc.zLabel(z)}',
        subtitle: reprint ? 'พิมพ์ซ้ำ (สำเนา)' : 'ปิดกะเรียบร้อย · พิมพ์เก็บไว้เป็นหลักฐาน',
        art: 'receipt',
        maxWidth: 520,
        body: _ZPreview(shift: z, reprint: reprint),
      );

  // ─────────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.currentShift;
    return NvScaffold(
      title: 'กะการขาย',
      eyebrow: (s != null && s.isOpen) ? 'กะเปิดอยู่' : 'ยังไม่เปิดกะ',
      subtitle: 'เปิด–ปิดกะ · นับเงินสด · เงินเข้า–ออกลิ้นชัก · Z-Report',
      art: 'shift',
      actions: [
        _drawerButton(),
        if (s != null && s.isOpen) NvButton.danger('ปิดกะ', icon: NvIcons.lock, size: NvButtonSize.sm, onPressed: _close),
      ],
      body: (s != null && s.isOpen) ? _openView(store, s) : _closedView(store),
    );
  }

  Widget _mini(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(v, style: Nv.money(18, color: Nv.onNight)),
          Text(k, style: Nv.ui(11.5, color: Nv.onNight3)),
        ],
      );

  Widget _closedView(PosStore store) {
    final last = store.shiftHistory.isEmpty ? null : store.shiftHistory.first;
    final canSell = store.currentStaff?.role.canSell ?? false;
    return LayoutBuilder(builder: (context, c) {
      final compact = c.maxWidth < 760;
      final hero = ClipRRect(
        borderRadius: BorderRadius.circular(Nv.rXl),
        child: Container(
          constraints: const BoxConstraints(minHeight: 230),
          decoration: BoxDecoration(
            gradient: Nv.night,
            borderRadius: BorderRadius.circular(Nv.rXl),
            border: Border.all(color: Nv.lineNightStrong),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(26, 24, compact ? 22 : 240, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ยังไม่เปิดกะ', style: Nv.eyebrow(color: Nv.gold300)),
                    const SizedBox(height: 4),
                    NvFoilText('เปิดกะเพื่อเริ่มรับชำระเงิน', style: Nv.display(compact ? 22 : 28, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      store.requireShift
                          ? 'ร้านตั้งค่าให้ต้องเปิดกะก่อนรับชำระเงิน — ระบบจะบันทึกเงินทอนตั้งต้น และสรุปยอดตอนปิดกะ (Z-Report)'
                          : 'เปิดกะเพื่อนับเงินในลิ้นชักและสรุปยอดตอนปิดกะ (Z-Report)',
                      style: Nv.ui(13.5, color: Nv.onNight2, height: 1.45),
                    ),
                    if (last != null) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 22,
                        runSpacing: 10,
                        children: [
                          _mini('กะล่าสุด', ZReportDoc.zLabel(last)),
                          _mini('ปิดเมื่อ', last.closedAt == null ? '—' : timeAgo(last.closedAt!)),
                          _mini('ยอดขาย', baht(last.salesTotal)),
                          _mini('เงินสด', _varianceText(last.cashVariance)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        NvButton.gold('เปิดกะ', icon: NvIcons.unlock, size: NvButtonSize.lg, onPressed: canSell ? _openShift : null),
                        if (last != null)
                          NvButton.ghost('ดู/พิมพ์ Z ล่าสุด', icon: NvIcons.print, onNight: true, onPressed: () => _showZ(last, reprint: true)),
                      ],
                    ),
                    if (!canSell)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('บทบาทนี้ไม่มีสิทธิ์รับชำระเงินจึงเปิดกะไม่ได้', style: Nv.ui(12.5, color: Nv.onNight3)),
                      ),
                  ],
                ),
              ),
              if (!compact) Positioned(right: 24, bottom: 0, child: NvArt.mascot('clock', height: 200)),
              const NvKanokCorners(size: 64, opacity: 0.6, inset: EdgeInsets.all(4), bottom: false),
            ],
          ),
        ),
      );
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [hero, const SizedBox(height: 18), _history(store)],
      );
    });
  }

  Widget _openView(PosStore store, Shift s) {
    final orders = store.ordersInShift(s);
    final sales = store.shiftSales(s);
    final refunds = store.shiftRefunds(s);
    final byMethod = store.shiftByMethod(s);
    final expected = store.expectedCash(s);
    final refundBills = orders.where((o) => o.refundAmount > 0).length;

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w >= 860 ? 4 : (w >= 520 ? 2 : 1);
      final two = w >= 860;
      final tiles = <Widget>[
        NvStatTile(label: 'ยอดขายในกะ', value: baht(sales), art: 'cash', caption: 'สุทธิหลังคืนเงิน ${baht(sales - refunds)}', tint: NvTint.jade),
        NvStatTile(
          label: 'จำนวนบิล',
          value: groupDigits(orders.length),
          art: 'receipt',
          caption: orders.isEmpty ? 'ยังไม่มีบิลในกะนี้' : 'เฉลี่ย ${baht((sales / orders.length).round())}/บิล',
        ),
        NvStatTile(
          label: 'คืนเงิน',
          value: refunds == 0 ? baht(0) : '-${baht(refunds)}',
          art: 'refund',
          caption: '$refundBills บิล',
          tint: refunds > 0 ? NvTint.lacquer : NvTint.neutral,
        ),
        NvStatTile(label: 'เงินที่ควรมีในลิ้นชัก', value: baht(expected), art: 'drawer', caption: 'รวมเงินทอน ${baht(s.openingCash)}', night: true),
      ];
      final left = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_methodCard(byMethod), const SizedBox(height: 16), _drawerCard(s, byMethod, expected)],
      );
      final right = _ordersCard(orders);
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          NvSheet(
            goldEdge: true,
            child: Row(
              children: [
                NvArt.icon('shift', size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('กะเปิดตั้งแต่ ${hm(s.openedAt)} น. · ${thaiDate(s.openedAt)}', style: Nv.ui(15, weight: FontWeight.w700)),
                      Text('${s.cashier} · เปิดมาแล้ว ${_dur(s.openedAt)} · เงินทอนตั้งต้น ${baht(s.openingCash)}',
                          style: Nv.ui(12.5, color: Nv.ink3)),
                    ],
                  ),
                ),
                if (w >= 700) ...[
                  const SizedBox(width: 12),
                  NvButton.danger('ปิดกะ · นับเงิน', icon: NvIcons.lock, onPressed: _close),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _grid(tiles, cols),
          const SizedBox(height: 16),
          if (two)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)],
            )
          else ...[
            left,
            const SizedBox(height: 16),
            right,
          ],
          const SizedBox(height: 16),
          _history(store),
        ],
      );
    });
  }

  Widget _methodCard(Map<PaymentMethod, int> byMethod) {
    final total = byMethod.values.fold<int>(0, (a, b) => a + b);
    return NvSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvSectionTitle('ยอดตามช่องทางชำระ (สุทธิ)', icon: NvIcons.chartPie, trailing: baht(total)),
          for (final m in PaymentMethod.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  NvArt.icon(m.art, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(m.label, style: Nv.ui(13.5, weight: FontWeight.w600))),
                            Text(baht(byMethod[m] ?? 0), style: Nv.money(14)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total <= 0 ? 0.0 : ((byMethod[m] ?? 0) / total).clamp(0.0, 1.0).toDouble(),
                            minHeight: 6,
                            backgroundColor: Nv.ivoryDeep,
                            color: Nv.gold500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _drawerCard(Shift s, Map<PaymentMethod, int> byMethod, int expected) {
    return NvSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvSectionTitle('เงินสดในลิ้นชัก', icon: NvIcons.drawer, trailing: 'ควรมี ${baht(expected)}'),
          NvKeyValue('เงินทอนตั้งต้น', baht(s.openingCash)),
          NvKeyValue('ขายเงินสด (สุทธิ)', baht(byMethod[PaymentMethod.cash] ?? 0)),
          NvKeyValue('เงินเข้า–ออก', baht(s.movementNet, sign: true), valueColor: s.movementNet < 0 ? Nv.lacquer : null),
          NvKeyValue('ควรมีในลิ้นชัก', baht(expected), strong: true),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              NvButton.soft('นำเงินเข้า', icon: NvIcons.plusCircle, size: NvButtonSize.sm, onPressed: () => _move(CashMoveType.payIn)),
              NvButton.soft('นำเงินออก', icon: NvIcons.minusCircle, size: NvButtonSize.sm, onPressed: () => _move(CashMoveType.payOut)),
              NvButton.soft('ส่งเข้าตู้เซฟ', icon: NvIcons.piggy, size: NvButtonSize.sm, onPressed: () => _move(CashMoveType.drop)),
            ],
          ),
          const SizedBox(height: 10),
          if (s.movements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('ยังไม่มีรายการเงินเข้า–ออกในกะนี้', style: Nv.ui(12.5, color: Nv.ink3)),
            )
          else
            for (final mv in s.movements.reversed) _MoveRow(move: mv),
        ],
      ),
    );
  }

  Widget _ordersCard(List<Order> orders) {
    final shown = orders.take(40).toList();
    return NvSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvSectionTitle('บิลในกะนี้', icon: NvIcons.receipt, trailing: '${orders.length} บิล'),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  NvArt.mascot('sleepy', height: 100),
                  const SizedBox(height: 6),
                  Text('ยังไม่มีบิลในกะนี้', style: Nv.ui(13.5, color: Nv.ink3)),
                  const SizedBox(height: 10),
                  NvButton.gold('เริ่มขาย', icon: NvIcons.cashier, size: NvButtonSize.sm, onPressed: () => context.go('/cashier')),
                ],
              ),
            )
          else
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _ShiftOrderRow(order: shown[i], onTap: () => context.go('/orders?id=${shown[i].id}')),
            ],
          if (orders.length > shown.length)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: NvButton.soft('ดูทั้งหมด ${orders.length} บิลในบิลย้อนหลัง', icon: NvIcons.receipt, size: NvButtonSize.sm, onPressed: () => context.go('/orders')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _history(PosStore store) {
    final list = store.shiftHistory.take(30).toList();
    return NvSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvSectionTitle('ประวัติการปิดกะ', icon: NvIcons.history, trailing: '${store.shiftHistory.length} กะ'),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('ยังไม่มีประวัติ — เมื่อปิดกะ Z-Report จะเก็บไว้ที่นี่ให้พิมพ์ซ้ำได้', style: Nv.ui(13, color: Nv.ink3)),
            )
          else
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _ZRow(shift: list[i], onReprint: () => _showZ(list[i], reprint: true)),
            ],
        ],
      ),
    );
  }
}

// ─────────────────────────── rows ───────────────────────────

class _MoveRow extends StatelessWidget {
  final CashMovement move;
  const _MoveRow({required this.move});

  @override
  Widget build(BuildContext context) {
    final m = move;
    final (icon, tint) = switch (m.type) {
      CashMoveType.payIn => (NvIcons.plusCircle, NvTint.jade),
      CashMoveType.payOut => (NvIcons.minusCircle, NvTint.lacquer),
      CashMoveType.drop => (NvIcons.piggy, NvTint.sapphire),
    };
    final c = nvTint(tint);
    final sub = [if (m.reason.isNotEmpty) m.reason, hm(m.at), if (m.by.isNotEmpty) m.by].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: c.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.type.label, style: Nv.ui(13.5, weight: FontWeight.w600)),
                Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${m.type.sign > 0 ? '+' : '-'}${baht(m.amount)}', style: Nv.money(14, color: c.fg)),
        ],
      ),
    );
  }
}

class _ShiftOrderRow extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const _ShiftOrderRow({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(Nv.rSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              NvArt.icon(o.method.art, size: 30),
              const SizedBox(width: 10),
              Text(o.id, style: Nv.money(13.5)),
              const SizedBox(width: 8),
              Text(hm(o.createdAt), style: Nv.ui(12, color: Nv.ink3)),
              const SizedBox(width: 10),
              Expanded(child: Text(_summary(o.lines), maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink2))),
              if (o.refundAmount > 0) ...[
                NvBadge(o.status == OrderStatus.refunded ? 'คืนแล้ว' : 'คืนบางส่วน', tint: o.status == OrderStatus.refunded ? NvTint.lacquer : NvTint.amber),
                const SizedBox(width: 8),
              ],
              Text(baht(o.netTotal), style: Nv.money(14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZRow extends StatelessWidget {
  final Shift shift;
  final VoidCallback onReprint;
  const _ZRow({required this.shift, required this.onReprint});

  @override
  Widget build(BuildContext context) {
    final z = shift;
    final closed = z.closedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Nv.gold100, borderRadius: BorderRadius.circular(12)),
            child: Text('Z', style: Nv.display(18, color: Nv.goldInk, weight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [Text(ZReportDoc.zLabel(z), style: Nv.money(14)), _varianceBadge(z.cashVariance)],
                ),
                Text(
                  '${thaiDate(z.openedAt)} · ${hm(z.openedAt)}–${closed == null ? '—' : hm(closed)} · ${z.cashier}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Nv.ui(12, color: Nv.ink3),
                ),
                Text(
                  'ยอดขาย ${baht(z.salesTotal)} · ${z.orderCount} บิล${z.refundTotal > 0 ? ' · คืน ${baht(z.refundTotal)}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Nv.ui(12, color: Nv.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NvIconButton(NvIcons.print, tooltip: 'ดู/พิมพ์ Z-Report ซ้ำ', size: 38, onPressed: onReprint),
        ],
      ),
    );
  }
}

// ─────────────────────────── dialogs ───────────────────────────

class _CashMoveForm extends StatefulWidget {
  final CashMoveType type;
  final int available;
  const _CashMoveForm({required this.type, required this.available});

  @override
  State<_CashMoveForm> createState() => _CashMoveFormState();
}

class _CashMoveFormState extends State<_CashMoveForm> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  String? _error;

  List<String> get _presets => switch (widget.type) {
        CashMoveType.payIn => const ['เพิ่มเงินทอน', 'แลกแบงก์ย่อย/เหรียญ', 'คืนเงินยืม'],
        CashMoveType.payOut => const ['ซื้อของใช้ในร้าน', 'จ่ายค่าส่งของ', 'เบิกเงินสดย่อย', 'จ่ายซัพพลายเออร์'],
        CashMoveType.drop => const ['ส่งเข้าตู้เซฟ', 'นำฝากธนาคาร'],
      };

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = parseBaht(_amount.text) ?? 0;
    final reason = _reason.text.trim();
    if (amount <= 0) {
      setState(() => _error = 'กรอกจำนวนเงิน');
      return;
    }
    if (widget.type != CashMoveType.payIn && amount > widget.available) {
      setState(() => _error = 'เกินเงินที่ควรมีในลิ้นชัก (${baht(widget.available)})');
      return;
    }
    if (widget.type == CashMoveType.payOut && reason.isEmpty) {
      setState(() => _error = 'ระบุเหตุผลการนำเงินออก');
      return;
    }
    Navigator.of(context).pop((amount, reason));
  }

  @override
  Widget build(BuildContext context) {
    final payOut = widget.type == CashMoveType.payOut;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _amount,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
          textAlign: TextAlign.center,
          style: Nv.money(30),
          decoration: const InputDecoration(prefixText: '฿ ', hintText: '0'),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        if (widget.type != CashMoveType.payIn)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('เงินที่ควรมีในลิ้นชักตอนนี้ ${baht(widget.available)}', textAlign: TextAlign.center, style: Nv.ui(12, color: Nv.ink3)),
          ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _presets)
              NvChip(p, selected: _reason.text.trim() == p, onTap: () => setState(() {
                    _reason.text = p;
                    _error = null;
                  })),
          ],
        ),
        const SizedBox(height: 12),
        NvField(
          label: payOut ? 'เหตุผล (จำเป็น)' : 'เหตุผล / หมายเหตุ (ถ้ามี)',
          controller: _reason,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (payOut)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(NvIcons.shield, size: 12, color: Nv.goldInk),
                const SizedBox(width: 6),
                Expanded(child: Text('กดบันทึกแล้วต้องใส่ PIN ผู้จัดการ', style: Nv.ui(12, color: Nv.ink3))),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
          ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            NvButton.gold('บันทึก', icon: NvIcons.check, onPressed: _submit),
          ],
        ),
      ],
    );
  }
}

class _CloseShiftForm extends StatefulWidget {
  const _CloseShiftForm();

  @override
  State<_CloseShiftForm> createState() => _CloseShiftFormState();
}

class _CloseShiftFormState extends State<_CloseShiftForm> {
  bool _byDenom = true;
  final Map<int, TextEditingController> _counts = {for (final d in _denoms) d: TextEditingController()};
  final _total = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in _counts.values) {
      c.dispose();
    }
    _total.dispose();
    _note.dispose();
    super.dispose();
  }

  int _countOf(int d) => int.tryParse(_counts[d]!.text.trim()) ?? 0;
  int get _denomSum => _denoms.fold(0, (s, d) => s + d * _countOf(d));
  bool get _anyDenom => _counts.values.any((c) => c.text.trim().isNotEmpty);
  int? get _counted => _byDenom ? (_anyDenom ? _denomSum : null) : parseBaht(_total.text);

  void _bump(int d, int delta) {
    final v = (_countOf(d) + delta).clamp(0, 99999);
    setState(() {
      _counts[d]!.text = '$v';
      _error = null;
    });
  }

  void _submit(int expected) {
    final counted = _counted ?? (expected == 0 ? 0 : null);
    if (counted == null) {
      setState(() => _error = _byDenom ? 'กรอกจำนวนธนบัตร/เหรียญที่นับได้' : 'กรอกยอดเงินสดที่นับได้');
      return;
    }
    if (counted != expected && _note.text.trim().isEmpty) {
      setState(() => _error = 'ยอดไม่ตรง — กรุณาระบุหมายเหตุ (เช่น สาเหตุที่ขาด/เกิน)');
      return;
    }
    Navigator.of(context).pop((counted, _note.text.trim()));
  }

  Widget _denomRow(int d) {
    final count = _countOf(d);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(baht(d), style: Nv.money(15))),
          Expanded(child: Text(d >= 20 ? 'ธนบัตร' : 'เหรียญ', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11.5, color: Nv.ink3))),
          NvIconButton(NvIcons.minus, size: 32, onPressed: count > 0 ? () => _bump(d, -1) : null),
          const SizedBox(width: 6),
          SizedBox(
            width: 54,
            child: TextField(
              controller: _counts[d],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
              textAlign: TextAlign.center,
              style: Nv.money(15),
              decoration: const InputDecoration(hintText: '0', contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 9)),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          const SizedBox(width: 6),
          NvIconButton(NvIcons.plus, size: 32, onPressed: () => _bump(d, 1)),
          SizedBox(
            width: 76,
            child: Text(baht(d * count), textAlign: TextAlign.right, style: Nv.money(13.5, color: count == 0 ? Nv.ink4 : Nv.ink)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.currentShift;
    final expected = s == null ? 0 : store.expectedCash(s);
    final counted = _counted;
    final variance = (counted ?? 0) - expected;
    final varColor = counted == null ? Nv.onNight3 : (variance == 0 ? Nv.jadeLight : (variance > 0 ? Nv.sapphireTint : Nv.lacquerLight));

    Widget sum(String label, String value, Color color) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Nv.ui(11.5, color: Nv.onNight3)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: Nv.money(19, color: color))),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: NvSegmented<bool>(
              options: const [(true, 'นับตามธนบัตร/เหรียญ'), (false, 'กรอกยอดรวม')],
              value: _byDenom,
              onChanged: (v) => setState(() {
                if (!v && _total.text.trim().isEmpty && _anyDenom) _total.text = '$_denomSum';
                _byDenom = v;
                _error = null;
              }),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_byDenom)
          for (final d in _denoms) _denomRow(d)
        else
          TextField(
            controller: _total,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]')), LengthLimitingTextInputFormatter(10)],
            textAlign: TextAlign.center,
            style: Nv.money(30),
            decoration: const InputDecoration(prefixText: '฿ ', hintText: '0'),
            onChanged: (_) => setState(() => _error = null),
          ),
        const SizedBox(height: 14),
        NvNightCard(
          padding: const EdgeInsets.all(16),
          radius: Nv.rMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: sum('นับได้', counted == null ? '—' : baht(counted), Nv.gold200)),
                  Expanded(child: sum('ควรมีในลิ้นชัก', baht(expected), Nv.onNight)),
                  Expanded(
                    child: sum(
                      'ส่วนต่าง',
                      counted == null ? '—' : (variance == 0 ? 'ตรง' : (variance > 0 ? '+${baht(variance)}' : '-${baht(-variance)}')),
                      varColor,
                    ),
                  ),
                ],
              ),
              if (counted != null && variance != 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(variance > 0 ? 'เงินในลิ้นชักเกิน ${baht(variance)}' : 'เงินในลิ้นชักขาด ${baht(-variance)}',
                      style: Nv.ui(12.5, color: varColor, weight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NvField(
          label: counted != null && variance != 0 ? 'หมายเหตุ (จำเป็นเมื่อยอดไม่ตรง)' : 'หมายเหตุ (ถ้ามี)',
          controller: _note,
          maxLines: 2,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
          ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            NvButton.gold('ถัดไป: ยืนยันปิดกะ', icon: NvIcons.lock, onPressed: () => _submit(expected)),
          ],
        ),
      ],
    );
  }
}

class _ZPreview extends StatefulWidget {
  final Shift shift;
  final bool reprint;
  const _ZPreview({required this.shift, required this.reprint});

  @override
  State<_ZPreview> createState() => _ZPreviewState();
}

class _ZPreviewState extends State<_ZPreview> {
  bool _printing = false;
  bool _sharing = false;

  ZReportDoc _doc(PosStore store) => ZReportDoc(
        shift: widget.shift,
        shop: ShopInfo.of(store),
        narrow: store.paperWidthMm == 58,
        reprint: widget.reprint,
        printedAt: DateTime.now(),
      );

  Future<void> _print() async {
    final store = AppScope.read(context);
    setState(() => _printing = true);
    final res = await PrintService.printDoc(
      context,
      _doc(store),
      jobName: 'Z-Report ${ZReportDoc.zLabel(widget.shift)}',
      medium: rollMedium(store.paperWidthMm),
      printerName: store.printerName,
      precache: ZReportDoc.precache,
    );
    if (!mounted) return;
    setState(() => _printing = false);
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  Future<void> _share() async {
    final store = AppScope.read(context);
    setState(() => _sharing = true);
    final res = await PrintService.shareDoc(
      context,
      _doc(store),
      fileName: 'z-report-${widget.shift.zNumber.toString().padLeft(4, '0')}',
      medium: rollMedium(store.paperWidthMm),
      precache: ZReportDoc.precache,
    );
    if (!mounted) return;
    setState(() => _sharing = false);
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final medium = rollMedium(store.paperWidthMm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Nv.line),
                boxShadow: Nv.shadowLift,
              ),
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                child: SizedBox(width: medium.renderWidth, child: _doc(store)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ปิด', onPressed: () => Navigator.of(context).pop()),
            NvButton.soft('แชร์ PDF', icon: NvIcons.share, loading: _sharing, onPressed: _sharing ? null : _share),
            NvButton.gold('พิมพ์ Z-Report', icon: NvIcons.print, loading: _printing, onPressed: _printing ? null : _print),
          ],
        ),
      ],
    );
  }
}
