// Thaiprompt POS — ผังโต๊ะ (/tablet/floor): the live floor for waiters.
//
// Zone chips over a 4:3 ivory floor. Every table sits exactly where the
// manager placed it in the floor designer (shared [FloorGeometry]), sized by
// seats and coloured by status — ว่าง ivory · นั่งอยู่ gold · รอเช็คบิล lacquer ·
// จอง sapphire — with guests, the open bill and time seated (refreshed every
// 30 s). Tap a table → side panel (wide) or bottom sheet (narrow) with the
// real actions for its status: open / reserve / order more (→ /cashier) /
// check bill (→ /payment) / acknowledge a waiter call / release. A banner
// lists every table calling for staff.
//
// by xman studio

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

// ───────────────────────── shared floor geometry ─────────────────────────

/// Floor-plan maths shared by the waiter floor and the floor designer so a
/// table sits in exactly the same spot on both. The canvas keeps a fixed 4:3
/// ratio; a table's stored x / y (0..1) is its top-left as a fraction of the
/// free travel area (canvas − table size), so a table can never hang off the
/// edge on any screen size.
class FloorGeometry {
  FloorGeometry._();

  static const double aspect = 4 / 3;
  static const double unitsAcross = 14;

  /// Largest 4:3 canvas that fits [max].
  static Size fit(Size max) {
    var w = max.width.isFinite ? max.width : max.height * aspect;
    var h = w / aspect;
    if (max.height.isFinite && h > max.height) {
      h = max.height;
      w = h * aspect;
    }
    return Size(math.max(0, w), math.max(0, h));
  }

  /// One layout unit (a 2-seat table is ~1.7 units wide).
  static double unit(Size canvas) => canvas.width / unitsAcross;

  static Size tableSize(TableInfo t, double u) {
    final s = t.seats;
    switch (t.shape) {
      case TableShape.round:
        final d = (s <= 2 ? 1.7 : (s <= 4 ? 2.1 : (s <= 6 ? 2.5 : 2.9))) * u;
        return Size(d, d);
      case TableShape.square:
        final d = (s <= 2 ? 1.7 : (s <= 4 ? 2.1 : (s <= 8 ? 2.5 : 2.9))) * u;
        return Size(d, d);
      case TableShape.rect:
        final w = (1.4 + 0.5 * ((s + 1) ~/ 2)).clamp(2.4, 5.0).toDouble() * u;
        return Size(w, 1.8 * u);
    }
  }

  static Size travel(Size table, Size canvas) =>
      Size(math.max(0, canvas.width - table.width), math.max(0, canvas.height - table.height));

  /// Where [t] is drawn on [canvas] (optionally at an overridden x / y).
  static Rect rectOf(TableInfo t, Size canvas, {double? x, double? y}) {
    final sz = tableSize(t, unit(canvas));
    final tr = travel(sz, canvas);
    final nx = (x ?? t.x).clamp(0.0, 1.0);
    final ny = (y ?? t.y).clamp(0.0, 1.0);
    return Rect.fromLTWH(nx * tr.width, ny * tr.height, sz.width, sz.height);
  }

  /// Pixel top-left → stored 0..1 position.
  static Offset normalize(Offset topLeft, Size table, Size canvas) {
    final tr = travel(table, canvas);
    return Offset(
      tr.width <= 0 ? 0.0 : (topLeft.dx / tr.width).clamp(0.0, 1.0),
      tr.height <= 0 ? 0.0 : (topLeft.dy / tr.height).clamp(0.0, 1.0),
    );
  }

  static Offset clampTopLeft(Offset tl, Size table, Size canvas) {
    final tr = travel(table, canvas);
    return Offset(tl.dx.clamp(0.0, tr.width), tl.dy.clamp(0.0, tr.height));
  }
}

/// Faint floor grid (every half unit, stronger every two units).
class FloorGridPainter extends CustomPainter {
  final double step;
  final Color color;
  const FloorGridPainter({required this.step, this.color = Nv.line});

  @override
  void paint(Canvas canvas, Size size) {
    if (step < 4) return;
    final thin = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final bold = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..strokeWidth = 1;
    var i = 0;
    for (var x = 0.0; x <= size.width + 0.5; x += step, i++) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 4 == 0 ? bold : thin);
    }
    i = 0;
    for (var y = 0.0; y <= size.height + 0.5; y += step, i++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 4 == 0 ? bold : thin);
    }
  }

  @override
  bool shouldRepaint(FloorGridPainter oldDelegate) => oldDelegate.step != step || oldDelegate.color != color;
}

/// The ivory floor sheet with its grid (fills its parent).
class FloorSurface extends StatelessWidget {
  final double step;
  const FloorSurface({super.key, required this.step});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Nv.paper,
          borderRadius: BorderRadius.circular(Nv.rLg),
          border: Border.all(color: Nv.line),
          boxShadow: Nv.shadowSheet,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Nv.rLg),
          child: CustomPaint(painter: FloorGridPainter(step: step), child: const SizedBox.expand()),
        ),
      );
}

String floorShapeLabel(TableShape s) => switch (s) {
      TableShape.round => 'โต๊ะกลม',
      TableShape.square => 'โต๊ะสี่เหลี่ยม',
      TableShape.rect => 'โต๊ะยาว',
    };

// ───────────────────────── status look ─────────────────────────

const _ink = Color(0xFF1A1405);
const _sapphireGrad = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF4F7FCC), Color(0xFF234A8C)],
);
const _statusOrder = [TableStatus.free, TableStatus.seated, TableStatus.billing, TableStatus.reserved];

class _TableLook {
  final Gradient? gradient;
  final Color? fill;
  final Color fg;
  final Color sub;
  final Color border;
  final List<BoxShadow> glow;
  final NvTint tint;
  const _TableLook({this.gradient, this.fill, required this.fg, required this.sub, required this.border, required this.glow, required this.tint});
}

_TableLook _lookFor(TableStatus s) => switch (s) {
      TableStatus.free => const _TableLook(fill: Nv.ivory2, fg: Nv.ink, sub: Nv.ink3, border: Nv.line, glow: [], tint: NvTint.neutral),
      TableStatus.seated => _TableLook(
          gradient: Nv.btnGold,
          fg: _ink,
          sub: _ink.withValues(alpha: 0.72),
          border: Nv.gold600,
          glow: Nv.goldGlow(0.7),
          tint: NvTint.gold,
        ),
      TableStatus.billing => _TableLook(
          gradient: Nv.btnLacquer,
          fg: Colors.white,
          sub: Colors.white.withValues(alpha: 0.82),
          border: Nv.lacquerDeep,
          glow: Nv.tintGlow(Nv.lacquer),
          tint: NvTint.lacquer,
        ),
      TableStatus.reserved => _TableLook(
          gradient: _sapphireGrad,
          fg: Colors.white,
          sub: Colors.white.withValues(alpha: 0.82),
          border: const Color(0xFF1F4A8F),
          glow: Nv.tintGlow(Nv.sapphire),
          tint: NvTint.sapphire,
        ),
    };

NvTint _prepTint(PrepStatus p) => switch (p) {
      PrepStatus.queued => NvTint.amber,
      PrepStatus.preparing => NvTint.sapphire,
      PrepStatus.ready => NvTint.jade,
      PrepStatus.served => NvTint.neutral,
    };

bool _occupied(TableInfo t) => t.status == TableStatus.seated || t.status == TableStatus.billing;

String _sinceShort(DateTime from, DateTime now) {
  final m = now.difference(from).inMinutes;
  if (m < 1) return 'เพิ่งนั่ง';
  if (m < 60) return '$m นาที';
  return '${m ~/ 60} ชม. ${m % 60} น.';
}

bool _sameIds(Iterable<String> a, Iterable<String> b) {
  final sa = a.toSet();
  final sb = b.toSet();
  return sa.length == sb.length && sa.containsAll(sb);
}

// ───────────────────────── screen ─────────────────────────

class TabletWaiterScreen extends StatefulWidget {
  const TabletWaiterScreen({super.key});

  @override
  State<TabletWaiterScreen> createState() => _TabletWaiterScreenState();
}

class _TabletWaiterScreenState extends State<TabletWaiterScreen> {
  Timer? _tick;
  String? _zone;
  int? _selected;

  @override
  void initState() {
    super.initState();
    // elapsed "seated for" labels
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  static List<String> _zonesOf(PosStore s) {
    final out = <String>[];
    for (final t in s.tables) {
      if (!out.contains(t.zone)) out.add(t.zone);
    }
    return out;
  }

  // ── selection ──

  void _select(TableInfo t, {required bool wide}) {
    setState(() {
      _selected = t.number;
      _zone = t.zone;
    });
    if (!wide) _openSheet(t.number);
  }

  void _selectNumber(int n, {required bool wide}) {
    final t = AppScope.read(context).tableByNumber(n);
    if (t != null) _select(t, wide: wide);
  }

  Future<void> _openSheet(int number) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
        child: _TablePanel(number: number, host: this, sheet: true),
      ),
    );
    if (!mounted) return;
    setState(() => _selected = null);
  }

  // ── actions (called by the panel; all use this screen's context) ──

  String _payBlock(PosStore s) {
    final me = s.currentStaff;
    if (me == null) return 'กรุณาเข้าสู่ระบบก่อนขาย';
    if (!me.role.canSell) return 'บทบาทนี้ไม่มีสิทธิ์รับชำระเงิน';
    if (s.requireShift && !s.hasOpenShift) return 'กรุณาเปิดกะก่อนรับชำระเงิน';
    return '';
  }

  void _toastBlock(String why) {
    final router = GoRouter.of(context);
    final shift = why.contains('เปิดกะ');
    nvToast(context, why,
        kind: NvToastKind.warning, actionLabel: shift ? 'เปิดกะ' : null, onAction: shift ? () => router.go('/shift') : null);
  }

  /// Make the counter cart safe to point at [table] (never silently re-target
  /// or overwrite another bill). False = cancelled.
  Future<bool> _freeCartFor(int table, {bool forBill = false}) async {
    final store = AppScope.read(context);
    if (store.cart.isEmpty) return true;
    final loadedBill = store.activeTicketIds.isNotEmpty;
    if (!forBill && !loadedBill && store.tableNumber == table) return true; // already this table's draft
    final where = store.tableNumber != null ? 'ของโต๊ะ ${store.tableNumber}' : 'ที่ยังไม่ระบุโต๊ะ';
    final canMove = !loadedBill && !forBill;
    final choice = await showNvDialog<String>(
      context,
      title: 'ตะกร้ายังมีรายการค้าง',
      subtitle: '${store.cartItemCount} รายการ $where · ${baht(store.cartTotal)}',
      art: 'payment',
      body: Text(
        loadedBill
            ? 'ตะกร้านี้เป็นบิลที่ส่งครัวแล้ว ล้างตะกร้าได้เลย ออเดอร์ของโต๊ะเดิมยังค้างอยู่ครบ'
            : 'พักบิลเดิมไว้ก่อนเพื่อเริ่มบิลของโต๊ะ $table${canMove ? ' หรือย้ายรายการทั้งหมดมาเป็นของโต๊ะนี้' : ''}',
        textAlign: TextAlign.center,
        style: Nv.ui(14, color: Nv.ink2, height: 1.5),
      ),
      actions: (ctx) => [
        NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(ctx).pop()),
        if (canMove) NvButton.ghost('ย้ายมาโต๊ะนี้', onPressed: () => Navigator.of(ctx).pop('move')),
        NvButton.gold(loadedBill ? 'ล้างตะกร้า' : 'พักบิลเดิม', onPressed: () => Navigator.of(ctx).pop(loadedBill ? 'clear' : 'hold')),
      ],
    );
    if (choice == null || !mounted) return false;
    if (choice == 'hold') {
      final h = store.holdCart();
      if (h != null) nvToast(context, 'พักบิล "${h.label}" ไว้แล้ว');
    } else if (choice == 'clear') {
      store.clearCart();
    }
    return true;
  }

  void seat(TableInfo t, int guests) {
    final store = AppScope.read(context);
    // seatTable also points the counter cart at the table — only do that when
    // the cart is free, otherwise just mark the table.
    if (store.cart.isEmpty || store.tableNumber == t.number) {
      store.seatTable(t, guests);
    } else {
      store.setTableStatus(t, TableStatus.seated, guests: guests);
    }
    nvToast(context, 'เปิดโต๊ะ ${t.number} แล้ว · $guests ท่าน', kind: NvToastKind.success);
  }

  void setGuests(TableInfo t, int guests) {
    final store = AppScope.read(context);
    store.setTableStatus(t, TableStatus.seated, guests: guests);
    if (store.tableNumber == t.number) store.setGuests(guests);
  }

  Future<void> reserve(TableInfo t) async {
    final name = await showNvTextDialog(
      context,
      title: 'จองโต๊ะ ${t.number}',
      subtitle: 'ใส่ชื่อลูกค้าและเวลาที่จอง',
      hint: 'เช่น คุณสมชาย · 19:00',
      confirmLabel: 'จองโต๊ะ',
      art: 'table',
    );
    if (name == null || !mounted) return;
    if (name.isEmpty) {
      nvToast(context, 'กรุณาใส่ชื่อผู้จอง', kind: NvToastKind.warning);
      return;
    }
    if (t.status != TableStatus.free) {
      nvToast(context, 'โต๊ะ ${t.number} ไม่ว่างแล้ว', kind: NvToastKind.warning);
      return;
    }
    AppScope.read(context).setTableStatus(t, TableStatus.reserved, reservedFor: name);
    nvToast(context, 'จองโต๊ะ ${t.number} ให้ $name แล้ว', kind: NvToastKind.success);
  }

  Future<void> cancelReservation(TableInfo t) async {
    final ok = await showNvConfirm(
      context,
      title: 'ยกเลิกการจองโต๊ะ ${t.number}?',
      message: 'การจองของ ${(t.reservedFor ?? '').isEmpty ? 'ลูกค้า' : t.reservedFor} จะถูกยกเลิก และโต๊ะกลับเป็นว่าง',
      confirmLabel: 'ยกเลิกการจอง',
    );
    if (!ok || !mounted) return;
    AppScope.read(context).setTableStatus(t, TableStatus.free);
    nvToast(context, 'ยกเลิกการจองโต๊ะ ${t.number} แล้ว', kind: NvToastKind.success);
  }

  Future<void> release(TableInfo t) async {
    final ok = await showNvConfirm(
      context,
      title: 'ย้ายโต๊ะ ${t.number} เป็นว่าง?',
      message: 'จำนวนลูกค้าและเวลาเปิดโต๊ะจะถูกล้าง',
      confirmLabel: 'ย้ายเป็นว่าง',
      danger: false,
    );
    if (!ok || !mounted) return;
    final store = AppScope.read(context);
    if (store.openTicketsForTable(t.number).isNotEmpty) {
      nvToast(context, 'โต๊ะ ${t.number} ยังมีออเดอร์ค้าง — เช็คบิลก่อน', kind: NvToastKind.error);
      return;
    }
    store.setTableStatus(t, TableStatus.free);
    nvToast(context, 'โต๊ะ ${t.number} ว่างแล้ว', kind: NvToastKind.success);
  }

  void backToSeated(TableInfo t) {
    AppScope.read(context).setTableStatus(t, TableStatus.seated);
    nvToast(context, 'โต๊ะ ${t.number} กลับเป็นกำลังนั่ง');
  }

  void ackCall(int table) {
    AppScope.read(context).setCallWaiter(table, false);
    nvToast(context, 'รับทราบการเรียกจากโต๊ะ $table แล้ว', kind: NvToastKind.success);
  }

  void _ackAll(List<int> tables) {
    final store = AppScope.read(context);
    for (final n in List.of(tables)) {
      store.setCallWaiter(n, false);
    }
    nvToast(context, 'รับทราบการเรียกทั้งหมดแล้ว', kind: NvToastKind.success);
  }

  Future<void> orderFor(TableInfo t) async {
    final ok = await _freeCartFor(t.number);
    if (!ok || !mounted) return;
    final store = AppScope.read(context);
    store.setTable(t.number);
    store.setGuests(t.guests > 0 ? t.guests : 1);
    context.go('/cashier');
  }

  Future<void> checkBill(TableInfo t) async {
    final store = AppScope.read(context);
    final open = store.openTicketsForTable(t.number);
    if (open.isEmpty) {
      nvToast(context, 'โต๊ะ ${t.number} ยังไม่มีรายการสั่ง', kind: NvToastKind.warning);
      return;
    }
    final block = _payBlock(store);
    if (block.isNotEmpty) {
      _toastBlock(block);
      return;
    }
    final loaded = store.tableNumber == t.number && _sameIds(store.activeTicketIds, open.map((x) => x.id));
    if (!loaded) {
      final ok = await _freeCartFor(t.number, forBill: true);
      if (!ok || !mounted) return;
      store.loadTableToCart(t.number);
    }
    context.go('/payment');
  }

  Future<void> cancelTicket(Ticket tk) async {
    final store = AppScope.read(context);
    final approver = await showManagerPin(context,
        reason: 'ยกเลิกออเดอร์ ${tk.id}${tk.tableNumber != null ? ' (โต๊ะ ${tk.tableNumber})' : ''}');
    if (approver == null || !mounted) return;
    final reason = await showNvTextDialog(
      context,
      title: 'เหตุผลที่ยกเลิก ${tk.id}',
      hint: 'เช่น ลูกค้าเปลี่ยนใจ · สั่งผิด',
      confirmLabel: 'ยกเลิกออเดอร์',
    );
    if (reason == null || !mounted) return;
    if (!tk.isOpen) return;
    final wasLoaded = store.activeTicketIds.contains(tk.id);
    store.cancelTicket(tk, reason: reason, approvedBy: approver);
    // keep a loaded bill in step so cancelled dishes are never charged
    final table = tk.tableNumber;
    if (wasLoaded) {
      if (table != null && store.openTicketsForTable(table).isNotEmpty) {
        store.loadTableToCart(table);
      } else {
        store.clearCart();
      }
    }
    nvToast(context, 'ยกเลิกออเดอร์ ${tk.id} แล้ว', kind: NvToastKind.success);
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final tables = store.tables;
    final manager = store.isManager;
    final actions = <Widget>[
      if (manager)
        NvButton.soft('ออกแบบผัง', icon: NvIcons.penRuler, size: NvButtonSize.sm, onPressed: () => context.go('/floor-designer')),
    ];

    if (tables.isEmpty) {
      return NvScaffold(
        title: 'ผังโต๊ะ',
        art: 'table',
        actions: actions,
        body: NvEmptyState(
          mascot: 'present',
          title: 'ยังไม่มีผังโต๊ะ',
          message: manager
              ? 'เริ่มวางโต๊ะของร้านในหน้าออกแบบผังร้าน แล้วกลับมาเปิดโต๊ะรับลูกค้าได้ทันที'
              : 'ให้ผู้จัดการเพิ่มโต๊ะในหน้า "ออกแบบผังร้าน" ก่อนเริ่มใช้งาน',
          actionLabel: manager ? 'ออกแบบผังร้าน' : null,
          actionIcon: NvIcons.penRuler,
          onAction: manager ? () => context.go('/floor-designer') : null,
        ),
      );
    }

    final now = DateTime.now();
    final zones = _zonesOf(store);
    final zone = (_zone != null && zones.contains(_zone)) ? _zone! : zones.first;
    final inZone = tables.where((t) => t.zone == zone).toList();
    final calling = store.tablesCallingWaiter;
    final callingSet = calling.toSet();
    final sel = _selected == null ? null : store.tableByNumber(_selected!);
    final bills = {for (final t in inZone) t.number: store.tableBillTotal(t.number)};

    return NvScaffold(
      title: 'ผังโต๊ะ',
      art: 'table',
      subtitle: 'แตะโต๊ะเพื่อเปิดโต๊ะ สั่งอาหาร หรือเช็คบิล',
      actions: actions,
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 860;
        final canvas = _FloorCanvas(
          tables: inZone,
          selected: sel?.number,
          calling: callingSet,
          bills: bills,
          now: now,
          onTap: (t) => _select(t, wide: wide),
          onBackground: wide && _selected != null ? () => setState(() => _selected = null) : null,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (calling.isNotEmpty) ...[
              _CallBanner(tables: calling, onTable: (n) => _selectNumber(n, wide: wide), onAckAll: () => _ackAll(calling)),
              const SizedBox(height: 10),
            ],
            _ZoneBar(
              zones: zones,
              current: zone,
              store: store,
              calling: callingSet,
              showLegend: wide,
              onZone: (z) => setState(() {
                _zone = z;
                if (sel != null && sel.zone != z) _selected = null;
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: canvas),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: c.maxWidth >= 1300 ? 360 : 310,
                          child: sel == null
                              ? _FloorSummary(store: store, calling: calling, onTable: (n) => _selectNumber(n, wide: true))
                              : _TablePanel(
                                  key: ValueKey('panel-${sel.number}'),
                                  number: sel.number,
                                  host: this,
                                  onClose: () => setState(() => _selected = null),
                                ),
                        ),
                      ],
                    )
                  : canvas,
            ),
            if (!wide) ...[const SizedBox(height: 10), _Legend(store: store)],
          ],
        );
      }),
    );
  }
}

// ───────────────────────── floor canvas ─────────────────────────

class _FloorCanvas extends StatelessWidget {
  final List<TableInfo> tables;
  final int? selected;
  final Set<int> calling;
  final Map<int, int> bills;
  final DateTime now;
  final ValueChanged<TableInfo> onTap;
  final VoidCallback? onBackground;

  const _FloorCanvas({
    required this.tables,
    required this.selected,
    required this.calling,
    required this.bills,
    required this.now,
    required this.onTap,
    this.onBackground,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = FloorGeometry.fit(c.biggest);
      final u = FloorGeometry.unit(size);
      return Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onBackground, child: FloorSurface(step: u / 2)),
              ),
              if (tables.isEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(child: Text('โซนนี้ยังไม่มีโต๊ะ', style: Nv.ui(14, color: Nv.ink3))),
                  ),
                ),
              for (final t in tables)
                Positioned.fromRect(
                  rect: FloorGeometry.rectOf(t, size),
                  child: _FloorTile(
                    table: t,
                    selected: t.number == selected,
                    calling: calling.contains(t.number),
                    bill: bills[t.number] ?? 0,
                    now: now,
                    onTap: () => onTap(t),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _FloorTile extends StatelessWidget {
  final TableInfo table;
  final bool selected;
  final bool calling;
  final int bill;
  final DateTime now;
  final VoidCallback onTap;

  const _FloorTile({
    required this.table,
    required this.selected,
    required this.calling,
    required this.bill,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = table;
    final look = _lookFor(t.status);
    final occupied = _occupied(t);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final short = math.min(w, h);
      final round = t.shape == TableShape.round;
      final lines = <Widget>[
        Text('${t.number}', style: Nv.display(20, color: look.fg, weight: FontWeight.w700)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(NvIcons.users, size: 10, color: look.sub),
            const SizedBox(width: 4),
            Text(occupied ? '${t.guests}/${t.seats}' : '${t.seats} ที่',
                style: Nv.money(11.5, color: look.sub, weight: FontWeight.w600)),
          ],
        ),
        if (occupied && bill > 0) Text(baht(bill), style: Nv.money(12, color: look.fg)),
        if (occupied && t.seatedAt != null)
          Text(_sinceShort(t.seatedAt!, now), style: Nv.ui(10.5, color: look.sub, weight: FontWeight.w600)),
        if (t.status == TableStatus.reserved && (t.reservedFor ?? '').isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(t.reservedFor!,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(10.5, color: look.sub, weight: FontWeight.w600)),
          ),
      ];
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: selected ? 1.06 : 1,
            duration: Nv.fast,
            curve: Nv.ease,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: Nv.med,
                  curve: Nv.ease,
                  width: w,
                  height: h,
                  padding: EdgeInsets.all(short * (round ? 0.16 : 0.08)),
                  decoration: BoxDecoration(
                    gradient: look.gradient,
                    color: look.fill,
                    borderRadius: BorderRadius.circular(round ? short / 2 : short * 0.18),
                    border: Border.all(color: selected ? Nv.navy800 : look.border, width: selected ? 2.6 : 1.2),
                    boxShadow: [...Nv.shadowSheet, ...look.glow],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(mainAxisSize: MainAxisSize.min, children: lines),
                  ),
                ),
                if (calling) const Positioned(top: -7, right: -7, child: _PulsingBell()),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Lacquer bell badge that breathes while a table is calling.
class _PulsingBell extends StatefulWidget {
  const _PulsingBell();

  @override
  State<_PulsingBell> createState() => _PulsingBellState();
}

class _PulsingBellState extends State<_PulsingBell> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))
    ..repeat(reverse: true);
  late final CurvedAnimation _curve = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.86, end: 1.12).animate(_curve);

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Nv.lacquer,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: Nv.tintGlow(Nv.lacquer),
          ),
          child: const Icon(NvIcons.bellConcierge, size: 10, color: Colors.white),
        ),
      );
}

// ───────────────────────── bars & legend ─────────────────────────

class _CallBanner extends StatelessWidget {
  final List<int> tables;
  final ValueChanged<int> onTable;
  final VoidCallback onAckAll;
  const _CallBanner({required this.tables, required this.onTable, required this.onAckAll});

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF8A5A00);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: Nv.amberTint,
        borderRadius: BorderRadius.circular(Nv.rMd),
        border: Border.all(color: Nv.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const _PulsingBell(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ลูกค้าเรียกพนักงาน ${tables.length} โต๊ะ', style: Nv.ui(14, color: brown, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final n in tables)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Nv.rPill),
                          onTap: () => onTable(n),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Nv.paper,
                              borderRadius: BorderRadius.circular(Nv.rPill),
                              border: Border.all(color: Nv.amber.withValues(alpha: 0.6)),
                            ),
                            child: Text('โต๊ะ $n', style: Nv.ui(13, color: brown, weight: FontWeight.w700)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NvButton.soft('รับทราบทั้งหมด', icon: NvIcons.check, size: NvButtonSize.sm, onPressed: onAckAll),
        ],
      ),
    );
  }
}

class _ZoneBar extends StatelessWidget {
  final List<String> zones;
  final String current;
  final PosStore store;
  final Set<int> calling;
  final bool showLegend;
  final ValueChanged<String> onZone;

  const _ZoneBar({
    required this.zones,
    required this.current,
    required this.store,
    required this.calling,
    required this.showLegend,
    required this.onZone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: zones.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final z = zones[i];
                final list = store.tables.where((t) => t.zone == z).toList();
                final ringing = list.any((t) => calling.contains(t.number));
                return NvChip(
                  z,
                  selected: z == current,
                  icon: ringing ? NvIcons.bellConcierge : NvIcons.mapPin,
                  count: list.length,
                  onTap: () => onZone(z),
                );
              },
            ),
          ),
        ),
        if (showLegend) ...[const SizedBox(width: 12), _Legend(store: store)],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final PosStore store;
  const _Legend({required this.store});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final s in _statusOrder)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Swatch(status: s),
              const SizedBox(width: 6),
              Text(s.label, style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
              const SizedBox(width: 5),
              Text('${store.tables.where((t) => t.status == s).length}', style: Nv.money(12.5)),
            ],
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final TableStatus status;
  final double size;
  const _Swatch({required this.status, this.size = 13});

  @override
  Widget build(BuildContext context) {
    final look = _lookFor(status);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: look.gradient,
        color: look.fill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: look.border),
      ),
    );
  }
}

class _FloorSummary extends StatelessWidget {
  final PosStore store;
  final List<int> calling;
  final ValueChanged<int> onTable;
  const _FloorSummary({required this.store, required this.calling, required this.onTable});

  @override
  Widget build(BuildContext context) {
    final tables = store.tables;
    final openBills = tables.fold<int>(0, (s, t) => s + store.tableBillTotal(t.number));
    final guests = tables.where(_occupied).fold<int>(0, (s, t) => s + t.guests);
    return NvSheet(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NvSectionTitle('ภาพรวมร้าน', icon: NvIcons.chair),
          Expanded(
            child: ListView(
              children: [
                for (final s in _statusOrder)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        _Swatch(status: s, size: 16),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s.label, style: Nv.ui(14, color: Nv.ink2, weight: FontWeight.w600))),
                        Text('${tables.where((t) => t.status == s).length}', style: Nv.money(17)),
                        Text(' โต๊ะ', style: Nv.ui(12.5, color: Nv.ink3)),
                      ],
                    ),
                  ),
                const Divider(height: 22),
                NvKeyValue('ลูกค้าในร้าน', '$guests ท่าน'),
                NvKeyValue('ยอดค้างชำระทุกโต๊ะ', baht(openBills), strong: true),
                if (calling.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const NvSectionTitle('กำลังเรียกพนักงาน', icon: NvIcons.bellConcierge),
                  for (final n in calling)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: NvSheet(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        radius: Nv.rMd,
                        color: Nv.amberTint,
                        onTap: () => onTable(n),
                        child: Row(
                          children: [
                            const Icon(NvIcons.bellConcierge, size: 14, color: Nv.amber),
                            const SizedBox(width: 10),
                            Expanded(child: Text('โต๊ะ $n', style: Nv.ui(14, weight: FontWeight.w700))),
                            const Icon(NvIcons.angleRight, size: 14, color: Nv.ink3),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 18),
                Center(child: NvArt.mascot('present_tab', height: 130)),
                const SizedBox(height: 8),
                Text(
                  'แตะโต๊ะบนผังเพื่อเปิดโต๊ะ สั่งอาหาร หรือเช็คบิล',
                  textAlign: TextAlign.center,
                  style: Nv.ui(13, color: Nv.ink3, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── table panel ─────────────────────────

class _TablePanel extends StatefulWidget {
  final int number;
  final _TabletWaiterScreenState host;
  final bool sheet;
  final VoidCallback? onClose;

  const _TablePanel({super.key, required this.number, required this.host, this.sheet = false, this.onClose});

  @override
  State<_TablePanel> createState() => _TablePanelState();
}

class _TablePanelState extends State<_TablePanel> {
  int _guests = 2;

  @override
  void initState() {
    super.initState();
    final t = AppScope.read(context).tableByNumber(widget.number);
    if (t != null) _guests = t.guests > 0 ? t.guests : (t.seats >= 2 ? 2 : 1);
  }

  /// Run a host action that leaves this screen (closes the sheet first).
  void _leave(Future<void> Function() action) {
    if (widget.sheet) Navigator.of(context).pop();
    action();
  }

  Widget _frame(List<Widget> top, Widget scroll, Widget actions) {
    if (widget.sheet) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Nv.line, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 14),
            ...top,
            Flexible(child: scroll),
            const SizedBox(height: 14),
            actions,
          ],
        ),
      );
    }
    return NvSheet(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...top, Expanded(child: scroll), const SizedBox(height: 14), actions],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final t = store.tableByNumber(widget.number);
    if (t == null) {
      return _frame(
        const [],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('ไม่พบโต๊ะนี้ (อาจถูกลบหรือเปลี่ยนหมายเลขแล้ว)',
              textAlign: TextAlign.center, style: Nv.ui(14, color: Nv.ink3)),
        ),
        widget.onClose == null ? const SizedBox.shrink() : NvButton.soft('ปิด', expand: true, onPressed: widget.onClose),
      );
    }

    final h = widget.host;
    final tickets = store.openTicketsForTable(t.number);
    final bill = store.tableBillTotal(t.number);
    final calling = store.tablesCallingWaiter.contains(t.number);
    final look = _lookFor(t.status);
    final occupied = _occupied(t);
    final round = t.shape == TableShape.round;
    final now = DateTime.now();

    final header = Row(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: look.gradient,
            color: look.fill,
            shape: round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: round ? null : BorderRadius.circular(14),
            border: Border.all(color: look.border),
            boxShadow: look.glow,
          ),
          child: Text('${t.number}', style: Nv.display(22, color: look.fg, weight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('โต๊ะ ${t.number}', style: Nv.display(20)),
              const SizedBox(height: 2),
              Text('${t.zone} · ${floorShapeLabel(t.shape)} · ${t.seats} ที่นั่ง',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink3)),
              const SizedBox(height: 6),
              NvBadge(t.status.label, tint: look.tint),
            ],
          ),
        ),
        if (widget.onClose != null) NvIconButton(NvIcons.xmark, size: 36, tooltip: 'ปิด', onPressed: widget.onClose),
      ],
    );

    final info = <Widget>[
      if (calling) _CallAlert(onAck: () => h.ackCall(t.number)),
      if (t.status == TableStatus.billing) NvKeyValue('ลูกค้า', '${t.guests} ท่าน', mono: false),
      if (occupied)
        NvKeyValue('เปิดโต๊ะ', t.seatedAt == null ? '—' : '${hm(t.seatedAt!)} น. · ${_sinceShort(t.seatedAt!, now)}', mono: false),
      if (occupied) NvKeyValue('ยอดค้างชำระ', baht(bill), strong: true),
      if (t.status == TableStatus.reserved)
        NvKeyValue('ผู้จอง', (t.reservedFor ?? '').isEmpty ? '—' : t.reservedFor!, mono: false),
      if (t.status != TableStatus.billing)
        _GuestsRow(
          label: t.status == TableStatus.seated ? 'จำนวนลูกค้า' : 'ลูกค้าที่จะนั่ง',
          value: t.status == TableStatus.seated ? math.max(1, t.guests) : _guests,
          onChanged: (g) {
            if (t.status == TableStatus.seated) {
              h.setGuests(t, g);
            } else {
              setState(() => _guests = g);
            }
          },
        ),
      if (occupied) ...[
        const SizedBox(height: 14),
        NvSectionTitle('ออเดอร์ที่ส่งครัว', trailing: '${tickets.length} บิล', icon: NvIcons.receipt),
        if (tickets.isEmpty)
          Text('ยังไม่มีออเดอร์ — แตะ "สั่งอาหาร" เพื่อเริ่มรับออเดอร์', style: Nv.ui(13, color: Nv.ink3, height: 1.4))
        else
          for (final tk in tickets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TicketTile(ticket: tk, onCancel: () => h.cancelTicket(tk)),
            ),
      ],
    ];

    final buttons = <Widget>[];
    switch (t.status) {
      case TableStatus.free:
        buttons.addAll([
          NvButton.gold('เปิดโต๊ะ · $_guests ท่าน',
              icon: NvIcons.chair, size: NvButtonSize.lg, expand: true, onPressed: () => h.seat(t, _guests)),
          NvButton.ghost('จองโต๊ะ', icon: NvIcons.calendarCheck, expand: true, onPressed: () => h.reserve(t)),
        ]);
      case TableStatus.reserved:
        buttons.addAll([
          NvButton.gold('ลูกค้ามาแล้ว · $_guests ท่าน',
              icon: NvIcons.userCheck, size: NvButtonSize.lg, expand: true, onPressed: () => h.seat(t, _guests)),
          NvButton.soft('ยกเลิกการจอง', icon: NvIcons.xmark, expand: true, onPressed: () => h.cancelReservation(t)),
        ]);
      case TableStatus.seated:
        buttons.add(NvButton.gold(tickets.isEmpty ? 'สั่งอาหาร' : 'สั่งเพิ่ม',
            icon: NvIcons.utensils, size: NvButtonSize.lg, expand: true, onPressed: () => _leave(() => h.orderFor(t))));
        if (tickets.isNotEmpty) {
          buttons.add(NvButton.navy('เช็คบิล · ${baht(bill)}',
              icon: NvIcons.receipt, expand: true, onPressed: () => _leave(() => h.checkBill(t))));
        } else {
          buttons.add(NvButton.soft('ย้ายเป็นว่าง', icon: NvIcons.doorOpen, expand: true, onPressed: () => h.release(t)));
        }
      case TableStatus.billing:
        if (tickets.isNotEmpty) {
          buttons.add(NvButton.gold('ชำระเงิน · ${baht(bill)}',
              icon: NvIcons.moneyBill, size: NvButtonSize.lg, expand: true, onPressed: () => _leave(() => h.checkBill(t))));
        }
        buttons.add(NvButton.soft('สั่งเพิ่ม', icon: NvIcons.utensils, expand: true, onPressed: () => _leave(() => h.orderFor(t))));
        buttons.add(NvButton.soft('กลับเป็นกำลังนั่ง', icon: NvIcons.rotate, expand: true, onPressed: () => h.backToSeated(t)));
        if (tickets.isEmpty) {
          buttons.add(NvButton.soft('ย้ายเป็นว่าง', icon: NvIcons.doorOpen, expand: true, onPressed: () => h.release(t)));
        }
    }

    final actions = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(height: 8), buttons[i]],
      ],
    );

    return _frame(
      [header, const SizedBox(height: 10), const NvKanokDivider(width: 200, thin: true, opacity: 0.8), const SizedBox(height: 6)],
      SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: info)),
      actions,
    );
  }
}

class _GuestsRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _GuestsRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(NvIcons.users, size: 14, color: Nv.goldInk),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: Nv.ui(13.5, color: Nv.ink2, weight: FontWeight.w600))),
            NvStepper(
              value: value,
              onMinus: value > 1 ? () => onChanged(value - 1) : null,
              onPlus: value < 99 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      );
}

class _CallAlert extends StatelessWidget {
  final VoidCallback onAck;
  const _CallAlert({required this.onAck});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: Nv.amberTint,
          borderRadius: BorderRadius.circular(Nv.rMd),
          border: Border.all(color: Nv.amber.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const _PulsingBell(),
            const SizedBox(width: 10),
            Expanded(
              child: Text('ลูกค้ากำลังเรียกพนักงาน', style: Nv.ui(13.5, color: const Color(0xFF8A5A00), weight: FontWeight.w700)),
            ),
            NvButton.gold('รับทราบ', icon: NvIcons.check, size: NvButtonSize.sm, onPressed: onAck),
          ],
        ),
      );
}

class _TicketTile extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onCancel;
  const _TicketTile({required this.ticket, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final tk = ticket;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 10),
      decoration: BoxDecoration(
        color: Nv.paper,
        borderRadius: BorderRadius.circular(Nv.rMd),
        border: Border.all(color: Nv.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tk.id, style: Nv.money(13, color: Nv.goldInk)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${hm(tk.createdAt)} · ${tk.source.label}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
              ),
              NvBadge(tk.prep.label, tint: _prepTint(tk.prep)),
              NvIconButton(NvIcons.trash, size: 32, color: Nv.lacquer, tooltip: 'ยกเลิกออเดอร์ (ผู้จัดการอนุมัติ)', onPressed: onCancel),
            ],
          ),
          const SizedBox(height: 4),
          for (final l in tk.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 30, child: Text('${l.qty}×', style: Nv.money(13, color: Nv.ink2))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.name, style: Nv.ui(13.5, weight: FontWeight.w600)),
                        if (l.detail.isNotEmpty) Text(l.detail, style: Nv.ui(12, color: Nv.goldInk, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text(baht(l.lineTotal), style: Nv.money(12.5, color: Nv.ink2, weight: FontWeight.w600)),
                ],
              ),
            ),
          if (tk.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Text('หมายเหตุ: ${tk.note}', style: Nv.ui(12, color: Nv.ink3)),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('${tk.itemCount} รายการ${tk.staffName.isEmpty ? '' : ' · ${tk.staffName}'}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
                ),
                Text(baht(tk.total), style: Nv.money(14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
