// Thaiprompt POS — บิลย้อนหลัง (sales history) · Nova.
//
// Two tabs:
//  • บิลที่ชำระแล้ว — every paid / refunded bill, filtered by period, payment
//    method, status and a search over bill id / customer / reference, with a
//    master–detail panel (side panel on wide screens, dialog on narrow ones):
//    lines + options, totals, payment & reference, cashier, table, refund
//    info, tax invoice number, print count, delivery job. Actions print /
//    reprint, share PDF, open the refund and tax-invoice screens, and create
//    or open a delivery job.
//  • ออเดอร์ค้างชำระ — open kitchen tickets (tables / self-order) that can be
//    pulled into the cart for payment, or cancelled with a reason + manager PIN.
//
// /orders?id=A1042 preselects a bill (used by the shift screen).
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../print/print_actions.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

enum _Tab { settled, open }

enum _Period { today, week, month, all }

enum _StatusF { all, paid, partial, refunded }

extension on _Period {
  String get label => switch (this) {
        _Period.today => 'วันนี้',
        _Period.week => '7 วัน',
        _Period.month => '30 วัน',
        _Period.all => 'ทั้งหมด',
      };

  DateTime? from(DateTime now) {
    final d0 = DateTime(now.year, now.month, now.day);
    return switch (this) {
      _Period.today => d0,
      _Period.week => d0.subtract(const Duration(days: 6)),
      _Period.month => d0.subtract(const Duration(days: 29)),
      _Period.all => null,
    };
  }
}

extension on _StatusF {
  String get label => switch (this) {
        _StatusF.all => 'ทุกสถานะ',
        _StatusF.paid => 'ชำระแล้ว',
        _StatusF.partial => 'คืนบางส่วน',
        _StatusF.refunded => 'คืนเงินแล้ว',
      };

  bool matches(Order o) => switch (this) {
        _StatusF.all => true,
        _StatusF.paid => o.status == OrderStatus.paid && o.refundAmount == 0,
        _StatusF.partial => o.isPartiallyRefunded,
        _StatusF.refunded => o.status == OrderStatus.refunded,
      };
}

IconData _methodIcon(PaymentMethod m) => switch (m) {
      PaymentMethod.cash => NvIcons.moneyBill,
      PaymentMethod.card => NvIcons.creditCard,
      PaymentMethod.promptpay => NvIcons.qrcode,
      PaymentMethod.wallet => NvIcons.wallet,
    };

Widget _statusBadge(Order o) {
  if (o.status == OrderStatus.refunded) return const NvBadge('คืนเงินแล้ว', tint: NvTint.lacquer);
  if (o.refundAmount > 0) return const NvBadge('คืนบางส่วน', tint: NvTint.amber);
  return const NvBadge('ชำระแล้ว', tint: NvTint.jade);
}

String _when(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'วันนี้ ${hm(d)}';
  if (day == today.subtract(const Duration(days: 1))) return 'เมื่อวาน ${hm(d)}';
  return thaiDateTime(d);
}

String _summary(List<OrderLine> lines) {
  if (lines.isEmpty) return '—';
  final head = lines.take(2).map((l) => '${l.name} ×${l.qty}').join(', ');
  return lines.length > 2 ? '$head +${lines.length - 2}' : head;
}

String _waitText(DateTime d) {
  final m = DateTime.now().difference(d).inMinutes;
  if (m < 1) return 'เพิ่งสั่ง';
  if (m < 60) return 'รอ $m นาที';
  return 'รอ ${m ~/ 60} ชม. ${m % 60} นาที';
}

/// A table whose tickets were loaded into the cart is marked "billing"; when
/// those tickets leave the cart unpaid, put it back to "seated".
void _releaseTable(PosStore store, int? table) {
  if (table == null) return;
  final tb = store.tableByNumber(table);
  if (tb != null && tb.status == TableStatus.billing && store.openTicketsForTable(table).isNotEmpty) {
    store.setTableStatus(tb, TableStatus.seated);
  }
}

NvTint _prepTint(PrepStatus p) => switch (p) {
      PrepStatus.queued => NvTint.amber,
      PrepStatus.preparing => NvTint.sapphire,
      PrepStatus.ready => NvTint.jade,
      PrepStatus.served => NvTint.neutral,
    };

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  _Tab _tab = _Tab.settled;
  _Period _period = _Period.today;
  _StatusF _status = _StatusF.all;
  PaymentMethod? _method;
  String _query = '';
  String _ticketQuery = '';
  String? _selectedId;
  String? _lastParam;
  bool _pendingOpen = false;
  Timer? _tick;
  final _searchCtrl = TextEditingController();
  final _ticketSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ticket ages ("รอ 12 นาที") refresh while the open-orders tab is visible
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _tab == _Tab.open) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = GoRouterState.of(context).uri.queryParameters['id'];
    if (id != null && id != _lastParam) {
      _lastParam = id;
      _tab = _Tab.settled;
      _period = _Period.all;
      _status = _StatusF.all;
      _method = null;
      if (_query.isNotEmpty) {
        _query = '';
        _searchCtrl.clear();
      }
      _selectedId = id;
      _pendingOpen = true;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _searchCtrl.dispose();
    _ticketSearchCtrl.dispose();
    super.dispose();
  }

  bool get _filtersActive => _query.isNotEmpty || _method != null || _status != _StatusF.all || _period != _Period.all;

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchCtrl.clear();
      _method = null;
      _status = _StatusF.all;
      _period = _Period.all;
    });
  }

  /// Settled bills after period / status / search (payment method applied separately
  /// so the method chips can show counts).
  List<Order> _base(PosStore store) {
    final from = _period.from(DateTime.now());
    final q = _query.trim().toLowerCase();
    return store.settledOrders.where((o) {
      if (from != null && o.createdAt.isBefore(from)) return false;
      if (!_status.matches(o)) return false;
      if (q.isNotEmpty) {
        final hay = '${o.id} ${o.reference} ${o.customerName ?? ''} ${o.paymentRef ?? ''} ${o.taxInvoiceNo ?? ''} ${o.cashier}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  void _select(Order o, bool wide) {
    setState(() => _selectedId = o.id);
    if (!wide) _openDetail(o.id);
  }

  Future<void> _openDetail(String id) async {
    final route = await showNvDialog<String>(
      context,
      title: 'รายละเอียดบิล',
      maxWidth: 560,
      body: Builder(builder: (ctx) => _OrderDetail(orderId: id, onGo: (r) => Navigator.of(ctx).pop(r))),
    );
    if (!mounted || route == null) return;
    context.go(route);
  }

  // ─────────────────────────── open tickets ───────────────────────────

  Future<void> _charge(Ticket t) async {
    final store = AppScope.read(context);
    if (store.cart.isNotEmpty && store.activeTicketIds.isEmpty) {
      final ok = await showNvConfirm(
        context,
        title: 'มีบิลค้างอยู่ในตะกร้า',
        message: 'ตะกร้าปัจจุบันมี ${store.cartItemCount} ชิ้น (${baht(store.cartTotal)})\n'
            'ระบบจะพักบิลนี้ไว้ก่อน (เรียกคืนได้ที่ "พักบิล/แยกบิล") แล้วโหลดออเดอร์ ${t.id} มาเรียกเก็บเงิน',
        confirmLabel: 'พักบิลแล้วเรียกเก็บ',
        danger: false,
        art: 'payment',
      );
      if (!ok || !mounted) return;
      store.holdCart();
    }
    if (!mounted) return;
    if (!t.isOpen) {
      nvToast(context, 'ออเดอร์ ${t.id} ถูกปิดไปแล้ว', kind: NvToastKind.warning);
      return;
    }
    // the cart already held another table's tickets → that table is no longer being billed
    if (store.activeTicketIds.isNotEmpty && store.tableNumber != t.tableNumber) _releaseTable(store, store.tableNumber);
    store.loadTicketToCart(t);
    nvToast(
      context,
      t.tableNumber != null ? 'โหลดบิลโต๊ะ ${t.tableNumber} ไปที่หน้าขายแล้ว' : 'โหลดออเดอร์ ${t.id} ไปที่หน้าขายแล้ว',
      kind: NvToastKind.success,
    );
    context.go('/cashier');
  }

  Future<void> _cancel(Ticket t) async {
    final label = t.tableNumber != null ? 'โต๊ะ ${t.tableNumber}' : (t.customerName ?? t.source.label);
    final reason = await showNvDialog<String>(
      context,
      title: 'ยกเลิกออเดอร์ ${t.id}',
      subtitle: '$label · ${t.itemCount} ชิ้น · ${baht(t.total)}',
      maxWidth: 460,
      body: const _ReasonForm(
        options: ['ลูกค้ายกเลิก', 'สั่งผิด', 'สินค้าหมด', 'รอนานเกินไป', 'อื่น ๆ'],
        confirmLabel: 'ยกเลิกออเดอร์',
      ),
    );
    if (reason == null || !mounted) return;
    final mgr = await showManagerPin(context, reason: 'ยกเลิกออเดอร์ ${t.id} · $reason');
    if (mgr == null || !mounted) return;
    final store = AppScope.read(context);
    if (!t.isOpen) {
      nvToast(context, 'ออเดอร์ ${t.id} ถูกปิดไปแล้ว', kind: NvToastKind.warning);
      return;
    }
    final wasInCart = store.activeTicketIds.contains(t.id);
    final cartTable = store.tableNumber;
    store.cancelTicket(t, reason: reason, approvedBy: mgr);
    // the cart still held this ticket's lines — clear it so they can't be charged
    if (wasInCart) {
      store.clearCart();
      _releaseTable(store, cartTable);
    }
    nvToast(
      context,
      wasInCart ? 'ยกเลิกออเดอร์ ${t.id} แล้ว · ล้างตะกร้าที่โหลดออเดอร์นี้ไว้' : 'ยกเลิกออเดอร์ ${t.id} แล้ว',
      kind: NvToastKind.success,
    );
  }

  // ─────────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final openCount = store.openTickets.length;
    return NvScaffold(
      title: 'บิลย้อนหลัง',
      eyebrow: 'ประวัติการขาย',
      subtitle: 'พิมพ์ซ้ำ · คืนเงิน · ใบกำกับภาษี · จัดส่ง · ออเดอร์ค้างชำระ',
      art: 'receipt',
      actions: [
        NvButton.soft('หน้าขาย', icon: NvIcons.cashier, size: NvButtonSize.sm, onPressed: () => context.go('/cashier')),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: NvSegmented<_Tab>(
                options: [
                  (_Tab.settled, 'บิลที่ชำระแล้ว'),
                  (_Tab.open, openCount > 0 ? 'ออเดอร์ค้างชำระ · $openCount' : 'ออเดอร์ค้างชำระ'),
                ],
                value: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _tab == _Tab.settled ? _settled(store) : _open(store)),
        ],
      ),
    );
  }

  Widget _settled(PosStore store) {
    final base = _base(store);
    final list = _method == null ? base : base.where((o) => o.method == _method).toList();
    final net = list.fold<int>(0, (s, o) => s + o.netTotal);
    final refunds = list.fold<int>(0, (s, o) => s + o.refundAmount);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 860;
      final detailW = wide ? (c.maxWidth * 0.4).clamp(360.0, 480.0) : 0.0;
      final masterW = wide ? c.maxWidth - detailW - 16 : c.maxWidth;

      Order? selected = _selectedId == null ? null : store.orderById(_selectedId!);
      if (wide && selected == null && list.isNotEmpty) selected = list.first;

      if (!wide && _pendingOpen && _selectedId != null) {
        final id = _selectedId!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pendingOpen) return;
          _pendingOpen = false;
          _openDetail(id);
        });
      } else if (wide) {
        _pendingOpen = false;
      }

      final master = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _filters(base, oneRow: masterW >= 640),
          const SizedBox(height: 10),
          _SummaryStrip(count: list.length, net: net, refunds: refunds),
          const SizedBox(height: 10),
          Expanded(
            child: list.isEmpty
                ? _emptySettled(store)
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 8, top: 2),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final o = list[i];
                      return _OrderRow(order: o, selected: wide && selected?.id == o.id, onTap: () => _select(o, wide));
                    },
                  ),
          ),
        ],
      );
      if (!wide) return master;

      final sel = selected;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: master),
          const SizedBox(width: 16),
          SizedBox(
            width: detailW,
            child: NvSheet(
              padding: EdgeInsets.zero,
              child: sel == null
                  ? const NvEmptyState(mascot: 'present', title: 'เลือกบิลเพื่อดูรายละเอียด', size: 120)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: _OrderDetail(key: ValueKey(sel.id), orderId: sel.id, onGo: (r) => context.go(r)),
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _filters(List<Order> base, {required bool oneRow}) {
    final search = NvSearchField(
      controller: _searchCtrl,
      hint: 'ค้นหาเลขบิล / ลูกค้า / เลขอ้างอิง',
      onChanged: (v) => setState(() => _query = v),
    );
    final period = NvSegmented<_Period>(
      options: [for (final p in _Period.values) (p, p.label)],
      value: _period,
      onChanged: (p) => setState(() => _period = p),
    );
    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          NvChip('ทุกช่องทาง', selected: _method == null, onTap: () => setState(() => _method = null)),
          for (final m in PaymentMethod.values) ...[
            const SizedBox(width: 8),
            NvChip(
              m.receiptLabel,
              icon: _methodIcon(m),
              count: base.where((o) => o.method == m).length,
              selected: _method == m,
              onTap: () => setState(() => _method = _method == m ? null : m),
            ),
          ],
          Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 12), color: Nv.line),
          for (final s in _StatusF.values) ...[
            NvChip(s.label, selected: _status == s, onTap: () => setState(() => _status = s)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (oneRow)
          Row(children: [Expanded(child: search), const SizedBox(width: 12), period])
        else ...[
          search,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: period)),
        ],
        const SizedBox(height: 10),
        chips,
      ],
    );
  }

  Widget _emptySettled(PosStore store) {
    if (store.settledOrders.isEmpty) {
      return NvEmptyState(
        mascot: 'search',
        title: 'ยังไม่มีบิล',
        message: 'เมื่อขายและรับชำระเงินแล้ว บิลจะแสดงที่นี่ พร้อมพิมพ์ซ้ำ คืนเงิน และออกใบกำกับภาษี',
        actionLabel: 'เริ่มขาย',
        actionIcon: NvIcons.cashier,
        onAction: () => context.go('/cashier'),
      );
    }
    return NvEmptyState(
      mascot: 'search',
      title: 'ไม่พบบิลตามตัวกรอง',
      message: _period == _Period.today ? 'วันนี้ยังไม่มีบิลที่ตรงเงื่อนไข ลองเลือก "ทั้งหมด"' : 'ลองเปลี่ยนช่วงเวลา ช่องทาง หรือคำค้นหา',
      actionLabel: _filtersActive ? 'ล้างตัวกรอง' : null,
      actionIcon: NvIcons.filter,
      onAction: _filtersActive ? _clearFilters : null,
    );
  }

  Widget _open(PosStore store) {
    final q = _ticketQuery.trim().toLowerCase();
    final all = store.openTickets..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final list = q.isEmpty
        ? all
        : all.where((t) {
            final hay = '${t.id} ${t.tableNumber != null ? 'โต๊ะ ${t.tableNumber} ${t.tableNumber}' : ''} ${t.customerName ?? ''} ${t.staffName} ${t.source.label}'.toLowerCase();
            return hay.contains(q);
          }).toList();
    final total = list.fold<int>(0, (s, t) => s + t.total);

    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / 300).floor().clamp(1, 5);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: NvSearchField(
                  controller: _ticketSearchCtrl,
                  hint: 'ค้นหาโต๊ะ / เลขออเดอร์ / ชื่อลูกค้า',
                  onChanged: (v) => setState(() => _ticketQuery = v),
                ),
              ),
              if (c.maxWidth >= 600) ...[
                const SizedBox(width: 14),
                Text('ค้าง ${list.length} ออเดอร์ · ', style: Nv.ui(13.5, color: Nv.ink3)),
                Text(baht(total), style: Nv.money(17)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: list.isEmpty
                ? NvEmptyState(
                    mascot: 'search',
                    title: all.isEmpty ? 'ไม่มีออเดอร์ค้างชำระ' : 'ไม่พบออเดอร์ที่ค้นหา',
                    message: all.isEmpty ? 'ออเดอร์จากโต๊ะและจากลูกค้าสั่งเองที่ยังไม่ชำระเงินจะแสดงที่นี่' : 'ลองค้นด้วยเลขโต๊ะ หรือเลขออเดอร์ เช่น T-0007',
                    actionLabel: all.isEmpty ? 'ไปผังโต๊ะ' : null,
                    actionIcon: NvIcons.chair,
                    onAction: all.isEmpty ? () => context.go('/tablet/floor') : null,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 8, top: 2),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 282,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final t = list[i];
                      return _TicketCard(
                        ticket: t,
                        tableTickets: t.tableNumber == null ? 1 : store.openTicketsForTable(t.tableNumber!).length,
                        onCharge: () => _charge(t),
                        onCancel: () => _cancel(t),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────── list pieces ───────────────────────────

class _SummaryStrip extends StatelessWidget {
  final int count;
  final int net;
  final int refunds;
  const _SummaryStrip({required this.count, required this.net, required this.refunds});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) => _strip(showArt: c.maxWidth >= 520));

  Widget _strip({required bool showArt}) {
    Widget stat(String art, String label, String value, {Color? color}) => Expanded(
          child: Row(
            children: [
              if (showArt) ...[NvArt.icon(art, size: 38), const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w500)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: Nv.money(19, color: color ?? Nv.ink)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    Widget sep() => Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 12), color: Nv.line);
    return NvSheet(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          stat('receipt', 'จำนวนบิล', groupDigits(count)),
          sep(),
          stat('cash', 'ยอดสุทธิ', baht(net)),
          sep(),
          stat('refund', 'คืนเงิน', refunds == 0 ? baht(0) : '-${baht(refunds)}', color: refunds > 0 ? Nv.lacquer : null),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final Order order;
  final bool selected;
  final VoidCallback onTap;
  const _OrderRow({required this.order, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final o = order;
    final refunded = o.status == OrderStatus.refunded;
    final who = [
      if (o.type == OrderType.dineIn && o.tableNumber != null) 'โต๊ะ ${o.tableNumber}' else o.type.label,
      if (o.customerName != null && o.customerName!.isNotEmpty) o.customerName!,
      o.cashier,
    ].join(' · ');
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          NvArt.icon(o.method.art, size: 40, fallbackIcon: _methodIcon(o.method)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(o.id, style: Nv.money(15)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(_when(o.createdAt), maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
                    ),
                    if (o.taxInvoiceNo != null) ...[
                      const SizedBox(width: 6),
                      const Icon(NvIcons.fileInvoice, size: 11, color: Nv.goldInk),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(_summary(o.lines), maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(13, color: Nv.ink2)),
                Text(who, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11.5, color: Nv.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(baht(o.netTotal), style: Nv.money(16, color: refunded ? Nv.ink4 : Nv.ink)),
              if (o.refundAmount > 0)
                Text(baht(o.total),
                    style: Nv.money(11.5, color: Nv.ink4, weight: FontWeight.w500).copyWith(decoration: TextDecoration.lineThrough)),
              const SizedBox(height: 4),
              _statusBadge(o),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final int tableTickets;
  final VoidCallback onCharge;
  final VoidCallback onCancel;
  const _TicketCard({required this.ticket, required this.tableTickets, required this.onCharge, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final title = t.tableNumber != null
        ? 'โต๊ะ ${t.tableNumber}'
        : ((t.customerName != null && t.customerName!.isNotEmpty) ? t.customerName! : t.source.label);
    final late = DateTime.now().difference(t.createdAt).inMinutes >= 20;
    final shown = t.lines.take(3).toList();
    return NvSheet(
      padding: const EdgeInsets.all(14),
      goldEdge: t.callWaiter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.display(19))),
              if (t.callWaiter) ...[
                const NvBadge('เรียกพนักงาน', tint: NvTint.lacquer, icon: NvIcons.bell),
                const SizedBox(width: 6),
              ],
              NvBadge(t.prep.label, tint: _prepTint(t.prep)),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(t.id, style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(child: Text(t.source.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3))),
              Icon(NvIcons.hourglass, size: 11, color: late ? Nv.amber : Nv.ink3),
              const SizedBox(width: 4),
              Text(_waitText(t.createdAt),
                  style: Nv.ui(12, color: late ? Nv.amber : Nv.ink3, weight: late ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final l in shown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Text('${l.qty}×', style: Nv.money(13, color: Nv.goldInk))),
                          Expanded(
                            child: Text(l.detail.isEmpty ? l.name : '${l.name} · ${l.detail}',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(13.5)),
                          ),
                        ],
                      ),
                    ),
                  if (t.lines.length > shown.length)
                    Text('+ อีก ${t.lines.length - shown.length} รายการ', style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w600)),
                  if (t.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(NvIcons.note, size: 11, color: Nv.goldInk),
                          const SizedBox(width: 5),
                          Expanded(child: Text(t.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink2))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('${t.itemCount} ชิ้น · ${t.staffName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
              ),
              Text(baht(t.total), style: Nv.money(19)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: NvButton.gold(
                  tableTickets > 1 ? 'เก็บเงินทั้งโต๊ะ ($tableTickets)' : 'เรียกเก็บเงิน',
                  icon: NvIcons.cashier,
                  size: NvButtonSize.sm,
                  expand: true,
                  onPressed: onCharge,
                ),
              ),
              const SizedBox(width: 8),
              NvIconButton(NvIcons.xmark, tooltip: 'ยกเลิกออเดอร์ (ต้องอนุมัติโดยผู้จัดการ)', size: 36, color: Nv.lacquer, onPressed: onCancel),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── detail ───────────────────────────

class _OrderDetail extends StatefulWidget {
  final String orderId;
  final ValueChanged<String> onGo;
  const _OrderDetail({super.key, required this.orderId, required this.onGo});

  @override
  State<_OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<_OrderDetail> {
  bool _printing = false;
  bool _sharing = false;

  Future<void> _print(Order o) async {
    setState(() => _printing = true);
    await printReceipt(context, o);
    if (!mounted) return;
    setState(() => _printing = false); // also refreshes the print count
  }

  Future<void> _share(Order o) async {
    setState(() => _sharing = true);
    await shareReceipt(context, o);
    if (!mounted) return;
    setState(() => _sharing = false);
  }

  Future<void> _createDelivery(Order o) async {
    final store = AppScope.read(context);
    final customer = o.customerId == null ? null : store.customerById(o.customerId!);
    var providers = store.enabledProviders;
    if (providers.isEmpty) {
      final self = store.providerById('self');
      providers = [?self];
    }
    final draft = await showNvDialog<_DeliveryDraft>(
      context,
      title: 'สร้างงานจัดส่ง',
      subtitle: 'บิล ${o.id} · ${baht(o.total)}',
      art: 'delivery',
      maxWidth: 520,
      body: _DeliveryForm(order: o, customer: customer, providers: providers),
    );
    if (draft == null || !mounted) return;
    final job = store.createDelivery(
      o,
      customerName: draft.name,
      phone: draft.phone,
      address: draft.address,
      providerId: draft.providerId,
      fee: draft.fee,
      cod: draft.cod,
      note: draft.note,
    );
    // createDelivery falls back to the provider's base fee when 0 is passed
    if (draft.fee == 0 && job.fee != 0) store.updateDelivery(job, fee: 0);
    nvToast(
      context,
      'สร้างงานจัดส่ง ${job.id} แล้ว',
      kind: NvToastKind.success,
      actionLabel: 'พิมพ์ใบปะหน้า',
      onAction: () {
        if (mounted) widget.onGo('/shipping/labels?id=${job.id}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final o = store.orderById(widget.orderId);
    if (o == null) {
      return const NvEmptyState(mascot: 'search', title: 'ไม่พบบิลนี้', message: 'บิลอาจถูกลบหรือยังไม่ได้ซิงก์มาที่เครื่องนี้', size: 110);
    }
    final delivery = store.deliveryForOrder(o.id);
    final provider = delivery == null ? null : store.providerById(delivery.providerId);
    final inclusive = o.tax > 0 && o.total == o.subtotal - o.discount;
    final typeLabel = o.type == OrderType.dineIn && o.tableNumber != null ? 'โต๊ะ ${o.tableNumber} · ${o.guests} ท่าน' : o.type.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NvArt.icon(o.method.art, size: 46, fallbackIcon: _methodIcon(o.method)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('บิล ${o.id}', style: Nv.display(21)),
                  Text(thaiDateTime(o.createdAt), style: Nv.ui(12.5, color: Nv.ink3)),
                ],
              ),
            ),
            _statusBadge(o),
          ],
        ),
        const SizedBox(height: 6),
        SelectableText('อ้างอิง ${o.reference}', style: Nv.money(11.5, color: Nv.ink3, weight: FontWeight.w500)),
        const SizedBox(height: 10),
        NvKeyValue('ประเภท', typeLabel, mono: false),
        if (o.customerName != null && o.customerName!.isNotEmpty) NvKeyValue('ลูกค้า', o.customerName!, mono: false),
        NvKeyValue('แคชเชียร์', o.cashier, mono: false),
        NvKeyValue('ช่องทางสั่ง', o.source.label, mono: false),
        NvKeyValue('ชำระโดย', o.method.label, mono: false),
        if (o.paymentRef != null) NvKeyValue('เลขอ้างอิงการชำระ', o.paymentRef!),
        if (o.method == PaymentMethod.cash && o.cashReceived > 0) ...[
          NvKeyValue('รับเงิน', baht(o.cashReceived)),
          NvKeyValue('เงินทอน', baht(o.change)),
        ],
        NvKeyValue('ใบกำกับภาษี', o.taxInvoiceNo ?? '—', valueColor: o.taxInvoiceNo != null ? Nv.goldInk : Nv.ink4),
        NvKeyValue('พิมพ์ใบเสร็จ', o.printCount == 0 ? 'ยังไม่พิมพ์' : '${o.printCount} ครั้ง', mono: false),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
        NvSectionTitle('รายการสินค้า', trailing: '${o.itemCount} ชิ้น', icon: NvIcons.list),
        for (final l in o.lines) _LineRow(l),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
        NvKeyValue('รวม', baht(o.subtotal)),
        if (o.discount > 0)
          NvKeyValue('ส่วนลด${o.discountNote.isNotEmpty ? ' (${o.discountNote})' : ''}', '-${baht(o.discount)}', valueColor: Nv.lacquer),
        if (o.tax > 0) NvKeyValue(inclusive ? 'VAT (รวมในราคาแล้ว)' : 'VAT', baht(o.tax)),
        const SizedBox(height: 6),
        NvNightCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          radius: Nv.rMd,
          child: Row(
            children: [
              Expanded(child: Text('ยอดสุทธิ', style: Nv.ui(15, color: Nv.onNight, weight: FontWeight.w700))),
              NvFoilText(baht(o.total), style: Nv.money(24)),
            ],
          ),
        ),
        if (o.refundAmount > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Nv.lacquerTint, borderRadius: BorderRadius.circular(Nv.rSm)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(NvIcons.refund, size: 14, color: Nv.lacquerDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(o.status == OrderStatus.refunded ? 'คืนเงินครบทั้งบิล' : 'คืนเงินบางส่วน',
                          style: Nv.ui(14, color: Nv.lacquerDeep, weight: FontWeight.w700)),
                    ),
                    Text('-${baht(o.refundAmount)}', style: Nv.money(16, color: Nv.lacquerDeep)),
                  ],
                ),
                const SizedBox(height: 4),
                if (o.refundReason != null) Text('เหตุผล: ${o.refundReason}', style: Nv.ui(12.5, color: Nv.ink2)),
                Text(
                  [
                    if (o.refundedAt != null) thaiDateTime(o.refundedAt!),
                    if (o.refundedBy != null) 'อนุมัติโดย ${o.refundedBy}',
                  ].join(' · '),
                  style: Nv.ui(12, color: Nv.ink3),
                ),
                if (o.status != OrderStatus.refunded) Text('คงเหลือสุทธิ ${baht(o.netTotal)}', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        const NvSectionTitle('จัดส่ง', icon: NvIcons.truck),
        if (delivery != null)
          NvSheet(
            padding: const EdgeInsets.all(12),
            color: Nv.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    NvArt.icon('delivery', size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${delivery.id} · ${provider?.name ?? delivery.providerId}', style: Nv.ui(13.5, weight: FontWeight.w700)),
                          Text(
                            [
                              if (delivery.customerName.isNotEmpty) delivery.customerName,
                              if (delivery.trackingNo.isNotEmpty) 'เลขพัสดุ ${delivery.trackingNo}',
                              if (delivery.cod) 'COD',
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Nv.ui(12, color: Nv.ink3),
                          ),
                        ],
                      ),
                    ),
                    NvBadge(delivery.status.label,
                        tint: delivery.status == DeliveryStatus.delivered ? NvTint.jade : NvTint.sapphire),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    NvButton.soft('ใบปะหน้า', icon: NvIcons.print, size: NvButtonSize.sm, onPressed: () => widget.onGo('/shipping/labels?id=${delivery.id}')),
                    NvButton.soft('งานจัดส่ง', icon: NvIcons.route, size: NvButtonSize.sm, onPressed: () => widget.onGo('/delivery')),
                  ],
                ),
              ],
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: NvButton.soft(
              'สร้างงานจัดส่ง',
              icon: NvIcons.truck,
              size: NvButtonSize.sm,
              onPressed: o.status == OrderStatus.refunded ? null : () => _createDelivery(o),
            ),
          ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            NvButton.gold(o.printCount > 0 ? 'พิมพ์ซ้ำ' : 'พิมพ์ใบเสร็จ',
                icon: NvIcons.print, loading: _printing, onPressed: _printing ? null : () => _print(o)),
            NvButton.soft('แชร์ PDF', icon: NvIcons.share, loading: _sharing, onPressed: _sharing ? null : () => _share(o)),
            NvButton.ghost('คืนเงิน',
                icon: NvIcons.refund, onPressed: o.status == OrderStatus.paid ? () => widget.onGo('/refund?id=${o.id}') : null),
            NvButton.navy('ใบกำกับภาษี', icon: NvIcons.tax, onPressed: () => widget.onGo('/tax-invoice?id=${o.id}')),
          ],
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final OrderLine line;
  const _LineRow(this.line);

  @override
  Widget build(BuildContext context) {
    final l = line;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 36, child: Text('${l.qty}×', style: Nv.money(13.5, color: Nv.goldInk))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.name, style: Nv.ui(14, weight: FontWeight.w600)),
                if (l.detail.isNotEmpty) Text(l.detail, style: Nv.ui(12, color: Nv.ink3)),
                if (l.qty > 1) Text('@ ${baht(l.price)}', style: Nv.money(11.5, color: Nv.ink3, weight: FontWeight.w500)),
                if (l.refundedQty > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: NvBadge('คืนแล้ว ${l.refundedQty} ชิ้น', tint: NvTint.lacquer),
                  ),
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

// ─────────────────────────── dialogs ───────────────────────────

/// Reason picker (chips + note) with its own action buttons; pops the reason text.
class _ReasonForm extends StatefulWidget {
  final List<String> options;
  final String confirmLabel;
  const _ReasonForm({required this.options, required this.confirmLabel});

  @override
  State<_ReasonForm> createState() => _ReasonFormState();
}

class _ReasonFormState extends State<_ReasonForm> {
  String? _picked;
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final note = _note.text.trim();
    if (_picked == null) {
      setState(() => _error = 'เลือกเหตุผลก่อน');
      return;
    }
    final other = _picked == widget.options.last;
    if (other && note.isEmpty) {
      setState(() => _error = 'ระบุเหตุผล');
      return;
    }
    Navigator.of(context).pop(other ? note : (note.isEmpty ? _picked! : '${_picked!} · $note'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('เหตุผล', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in widget.options)
              NvChip(r, selected: _picked == r, onTap: () => setState(() {
                    _picked = r;
                    _error = null;
                  })),
          ],
        ),
        const SizedBox(height: 12),
        NvField(
          label: _picked == widget.options.last ? 'ระบุเหตุผล (จำเป็น)' : 'หมายเหตุเพิ่มเติม (ถ้ามี)',
          controller: _note,
          maxLines: 2,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        SizedBox(
          height: 26,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error ?? '', style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ไม่ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            NvButton.danger(widget.confirmLabel, icon: NvIcons.xmark, onPressed: _submit),
          ],
        ),
      ],
    );
  }
}

class _DeliveryDraft {
  final String name;
  final String phone;
  final String address;
  final String providerId;
  final int fee;
  final bool cod;
  final String note;
  const _DeliveryDraft({
    required this.name,
    required this.phone,
    required this.address,
    required this.providerId,
    required this.fee,
    required this.cod,
    required this.note,
  });
}

class _DeliveryForm extends StatefulWidget {
  final Order order;
  final Customer? customer;
  final List<ShippingProvider> providers;
  const _DeliveryForm({required this.order, required this.customer, required this.providers});

  @override
  State<_DeliveryForm> createState() => _DeliveryFormState();
}

class _DeliveryFormState extends State<_DeliveryForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.order.customerName ?? widget.customer?.name ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.customer?.phone ?? '');
  final TextEditingController _address = TextEditingController();
  late final TextEditingController _fee;
  final TextEditingController _note = TextEditingController();
  late String _providerId;
  bool _cod = false;

  @override
  void initState() {
    super.initState();
    final first = widget.providers.isEmpty ? null : widget.providers.first;
    _providerId = first?.id ?? 'self';
    _fee = TextEditingController(text: '${first?.baseFee ?? 0}');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _fee.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_DeliveryDraft(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      providerId: _providerId,
      fee: int.tryParse(_fee.text.trim()) ?? 0,
      cod: _cod,
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NvField(
            label: 'ชื่อผู้รับ',
            controller: _name,
            icon: NvIcons.user,
            validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อผู้รับ' : null,
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'เบอร์โทรผู้รับ',
            controller: _phone,
            icon: NvIcons.phone,
            keyboard: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            validator: (v) {
              final d = (v ?? '').trim();
              if (d.isEmpty) return null;
              return d.length < 9 ? 'เบอร์โทรไม่ครบ' : null;
            },
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'ที่อยู่จัดส่ง',
            controller: _address,
            icon: NvIcons.location,
            maxLines: 3,
            validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกที่อยู่จัดส่ง' : null,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('ผู้ให้บริการขนส่ง', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
          ),
          if (widget.providers.isEmpty)
            Text('ยังไม่ได้เปิดผู้ให้บริการขนส่ง — จะบันทึกเป็น "ส่งเองโดยร้าน"', style: Nv.ui(12.5, color: Nv.amber))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in widget.providers)
                  NvChip(
                    p.name,
                    selected: p.id == _providerId,
                    onTap: () => setState(() {
                      _providerId = p.id;
                      _fee.text = '${p.baseFee}';
                    }),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          NvField(label: 'ค่าส่ง (บาท)', controller: _fee, icon: NvIcons.coins, keyboard: TextInputType.number, formatters: NvField.digits),
          const SizedBox(height: 6),
          Row(
            children: [
              Switch(value: _cod, onChanged: (v) => setState(() => _cod = v)),
              const SizedBox(width: 6),
              Expanded(child: Text('เก็บเงินปลายทาง (COD)', style: Nv.ui(14, color: Nv.ink2))),
            ],
          ),
          const SizedBox(height: 6),
          NvField(label: 'หมายเหตุ (ถ้ามี)', controller: _note, icon: NvIcons.note),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
              NvButton.gold('สร้างงานจัดส่ง', icon: NvIcons.truck, onPressed: _submit),
            ],
          ),
        ],
      ),
    );
  }
}
