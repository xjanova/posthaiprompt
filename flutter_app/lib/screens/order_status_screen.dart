// Thaiprompt POS — Order status (/order-status?ticket=T-0001[&table=7]) · kiosk.
//
// Follows a real kitchen ticket: the one in the query, else this kiosk's last
// self-order, else the newest open ticket of the table. A 4-step timeline
// from ticket.prep (รับออเดอร์ → กำลังทำ → พร้อมเสิร์ฟ → เสิร์ฟแล้ว) with the
// active step in gold, a mascot pose per step, elapsed time and the items.
// When the ticket belongs to a table, the table's other open tickets (this
// seating only) and its unpaid bill are listed too. Updates live through
// AppScope as the kitchen advances tickets. Never shows other tables' orders.
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';
import 'cust_menu_screen.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // refresh the "ผ่านไป N นาที" labels
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _statusRoute(Ticket t, int? table) =>
      '/order-status?ticket=${Uri.encodeQueryComponent(t.id)}${table != null ? '&table=$table' : ''}';

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final qp = GoRouterState.of(context).uri.queryParameters;
    final tid = qp['ticket'] ?? '';
    final paramTable = int.tryParse(qp['table'] ?? '');

    Ticket? primary = tid.isEmpty ? null : store.ticketById(tid);
    if (primary == null) {
      final last = store.lastSelfTicket;
      if (last != null && (paramTable == null || last.tableNumber == paramTable)) primary = last;
    }
    final table = paramTable ?? primary?.tableNumber ?? store.selfTable;

    // This seating's tickets only (open ones + anything since the party sat down).
    var tableTickets = <Ticket>[];
    if (table != null) {
      final since = store.tableByNumber(table)?.seatedAt;
      tableTickets = store.tickets
          .where((t) =>
              t.tableNumber == table &&
              t.status != TicketStatus.cancelled &&
              (t.isOpen || (since != null && !t.createdAt.isBefore(since))))
          .toList();
    }
    if (primary == null && tableTickets.isNotEmpty) {
      primary = tableTickets.firstWhere((t) => t.prep != PrepStatus.served, orElse: () => tableTickets.first);
    }

    final header = CustTopBar(
      eyebrow: 'ติดตามออเดอร์',
      title: 'สถานะออเดอร์',
      subtitle: table != null ? '${store.shopName} · โต๊ะ $table' : store.shopName,
      onBack: () => context.go(table != null ? '/self-order?table=$table' : custHomeRoute(store)),
      actions: [if (table != null) CustCallWaiterButton(table: table, compact: true)],
    );

    if (primary == null) {
      return NvKiosk(
        child: Column(
          children: [
            header,
            Expanded(
              child: NvEmptyState(
                onNight: true,
                mascot: 'search',
                title: 'ยังไม่มีออเดอร์ให้ติดตาม',
                message: table != null ? 'โต๊ะ $table ยังไม่มีออเดอร์ที่ส่งเข้าครัว' : 'สั่งอาหารแล้วกลับมาติดตามสถานะได้ที่หน้านี้',
                actionLabel: 'เริ่มสั่งอาหาร',
                actionIcon: NvIcons.utensils,
                onAction: () => context.go('/cust/menu'),
              ),
            ),
          ],
        ),
      );
    }

    final main = primary;
    final others = tableTickets.where((t) => t.id != main.id).toList();
    final now = DateTime.now();

    return NvKiosk(
      child: Column(
        children: [
          header,
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final mainCard = _MainTicket(store: store, ticket: main, now: now, wide: wide);
              final side = <Widget>[
                _TableSummary(store: store, table: table),
                if (others.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  NvSectionTitle('ออเดอร์อื่นของโต๊ะนี้', trailing: '${others.length} ออเดอร์', onNight: true, icon: NvIcons.layers),
                  for (final t in others)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OtherTicket(ticket: t, now: now, onTap: () => context.go(_statusRoute(t, table))),
                    ),
                ],
              ];
              if (wide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: SingleChildScrollView(child: mainCard)),
                      const SizedBox(width: 20),
                      SizedBox(width: 390, child: ListView(children: side)),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                children: [mainCard, const SizedBox(height: 16), ...side],
              );
            }),
          ),
        ],
      ),
    );
  }
}

String _waited(DateTime from, DateTime now) {
  final m = now.difference(from).inMinutes;
  if (m < 1) return 'เพิ่งสั่ง';
  if (m < 60) return 'ผ่านไป $m นาที';
  return 'ผ่านไป ${m ~/ 60} ชม. ${m % 60} นาที';
}

class _MainTicket extends StatelessWidget {
  final PosStore store;
  final Ticket ticket;
  final DateTime now;
  final bool wide;

  const _MainTicket({required this.store, required this.ticket, required this.now, required this.wide});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final cancelled = t.status == TicketStatus.cancelled;
    final step = t.prep.step;
    final (mascot, message) = cancelled
        ? ('empty', 'ออเดอร์นี้ถูกยกเลิก · กรุณาติดต่อพนักงาน')
        : switch (t.prep) {
            PrepStatus.queued => ('clock', 'ครัวได้รับออเดอร์แล้ว รอคิวสักครู่นะคะ'),
            PrepStatus.preparing => ('chef', 'เชฟกำลังปรุงอาหารของคุณอยู่'),
            PrepStatus.ready => ('cheer', 'อาหารพร้อมเสิร์ฟแล้ว! พนักงานกำลังนำไปที่โต๊ะ'),
            PrepStatus.served => ('wai', 'เสิร์ฟครบแล้ว ขอให้อร่อยกับมื้อนี้นะคะ'),
          };

    return Stack(
      children: [
        NvNightCard(
          padding: EdgeInsets.all(wide ? 24 : 16),
          glow: !cancelled && t.prep == PrepStatus.ready,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ออเดอร์', style: Nv.eyebrow(color: Nv.gold300)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: NvFoilText(t.id, style: Nv.money(wide ? 38 : 30)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.tableNumber != null ? 'โต๊ะ ${t.tableNumber}' : 'รับที่เคาน์เตอร์'} · สั่งเมื่อ ${hm(t.createdAt)} น. · ${_waited(t.createdAt, now)}',
                          style: Nv.ui(14, color: Nv.onNight2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustPrepBadge(t),
                      if (t.status == TicketStatus.settled) ...[
                        const SizedBox(height: 6),
                        const NvBadge('ชำระแล้ว', tint: NvTint.jade, icon: NvIcons.checkCircle),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  NvArt.mascot(mascot, height: wide ? 150 : 110),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(message, style: Nv.display(wide ? 24 : 19, color: cancelled ? Nv.lacquerLight : Nv.onNight)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Opacity(opacity: cancelled ? 0.35 : 1, child: _Timeline(step: step)),
              const SizedBox(height: 14),
              const NvKanokDivider(width: 240, thin: true, opacity: 0.85),
              const SizedBox(height: 6),
              NvSectionTitle('รายการ', trailing: '${t.itemCount} รายการ', onNight: true, icon: NvIcons.receipt),
              for (var i = 0; i < t.lines.length; i++) ...[
                if (i > 0) Divider(height: 16, color: Nv.lineNight.withValues(alpha: 0.6)),
                _LineRow(store: store, line: t.lines[i]),
              ],
              if (t.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('ถึงครัว: ${t.note}', style: Nv.ui(14, color: Nv.gold300)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('ยอดรวมออเดอร์นี้', style: Nv.ui(16, color: Nv.onNight, weight: FontWeight.w700))),
                  FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(t.total), style: Nv.money(28))),
                ],
              ),
            ],
          ),
        ),
        const NvKanokCorners(size: 56, opacity: 0.6, inset: EdgeInsets.all(2)),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final PosStore store;
  final OrderLine line;
  const _LineRow({required this.store, required this.line});

  @override
  Widget build(BuildContext context) {
    final l = line;
    return Row(
      children: [
        custLinePicture(store, l, size: 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(16, color: Nv.onNight, weight: FontWeight.w600)),
              if (l.detail.isNotEmpty)
                Text(l.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(13, color: Nv.gold300)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text('× ${l.qty}', style: Nv.money(18, color: Nv.gold200)),
      ],
    );
  }
}

/// 4-step customer timeline; the active step glows gold.
class _Timeline extends StatelessWidget {
  final int step;
  const _Timeline({required this.step});

  static const _labels = ['รับออเดอร์', 'กำลังทำ', 'พร้อมเสิร์ฟ', 'เสิร์ฟแล้ว'];
  static const _icons = [NvIcons.receipt, NvIcons.fire, NvIcons.bellConcierge, NvIcons.utensils];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = c.maxWidth < 420 ? 46.0 : 60.0;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: s,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(child: i == 0 ? const SizedBox() : _bar(i <= step)),
                            SizedBox(width: s * 0.8),
                            Expanded(child: i == 3 ? const SizedBox() : _bar(i < step)),
                          ],
                        ),
                        _dot(i, s),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: i == step
                        ? Nv.ui(s > 50 ? 15 : 13, color: Nv.gold200, weight: FontWeight.w700)
                        : Nv.ui(s > 50 ? 14 : 12.5, color: i < step ? Nv.onNight2 : Nv.onNight3),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _bar(bool done) => Container(
        height: 3,
        decoration: BoxDecoration(
          gradient: done ? const LinearGradient(colors: [Nv.gold500, Nv.gold300]) : null,
          color: done ? null : Nv.lineNight,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _dot(int i, double s) {
    if (i == step) {
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: Nv.btnGold, boxShadow: Nv.goldGlow(1.2)),
        child: Icon(_icons[i], size: s * 0.38, color: const Color(0xFF1A1405)),
      );
    }
    final d = s * 0.74;
    final done = i < step;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? Nv.gold400.withValues(alpha: 0.16) : Nv.navy850,
        border: Border.all(color: done ? Nv.gold400 : Nv.lineNight, width: done ? 2 : 1.2),
      ),
      child: Icon(done ? NvIcons.check : _icons[i], size: d * 0.36, color: done ? Nv.gold300 : Nv.onNight3),
    );
  }
}

/// The table's unpaid bill + call waiter + order more.
class _TableSummary extends StatelessWidget {
  final PosStore store;
  final int? table;
  const _TableSummary({required this.store, required this.table});

  @override
  Widget build(BuildContext context) {
    final tb = table;
    final open = tb == null ? 0 : store.openTicketsForTable(tb).length;
    final bill = tb == null ? 0 : store.tableBillTotal(tb);
    return NvNightCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NvArt.icon(tb != null ? 'table' : 'cash', size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tb != null ? 'โต๊ะ $tb' : 'รับที่เคาน์เตอร์', style: Nv.display(22, color: Nv.onNight)),
                    Text(tb != null ? 'ออเดอร์ที่ยังไม่ชำระ $open ออเดอร์' : 'ชำระเงินที่เคาน์เตอร์เมื่อรับอาหาร',
                        style: Nv.ui(13.5, color: Nv.onNight3)),
                  ],
                ),
              ),
            ],
          ),
          if (tb != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text('ยอดค้างชำระ', style: Nv.ui(16, color: Nv.onNight2, weight: FontWeight.w600))),
                FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(bill), style: Nv.money(28))),
              ],
            ),
            const SizedBox(height: 4),
            Text('ชำระเงินที่เคาน์เตอร์หรือเรียกพนักงานเมื่อพร้อมชำระ', style: Nv.ui(13, color: Nv.onNight3, height: 1.4)),
            const SizedBox(height: 14),
            CustCallWaiterButton(table: tb, expand: true),
          ],
          const SizedBox(height: 10),
          NvButton.gold('สั่งเพิ่ม', icon: NvIcons.plus, size: NvButtonSize.xl, expand: true, onPressed: () => context.go('/cust/menu')),
        ],
      ),
    );
  }
}

class _OtherTicket extends StatelessWidget {
  final Ticket ticket;
  final DateTime now;
  final VoidCallback onTap;
  const _OtherTicket({required this.ticket, required this.now, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final step = t.prep.step;
    return NvNightCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.id, style: Nv.money(18, color: Nv.gold200)),
                const SizedBox(height: 2),
                Text('${hm(t.createdAt)} น. · ${t.itemCount} รายการ · ${_waited(t.createdAt, now)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.onNight3)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 5),
                      Container(
                        width: i == step ? 22 : 9,
                        height: 9,
                        decoration: BoxDecoration(
                          gradient: i <= step ? Nv.btnGold : null,
                          color: i <= step ? null : Nv.lineNight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CustPrepBadge(t),
          const SizedBox(width: 6),
          const Icon(NvIcons.chevronRight, size: 16, color: Nv.onNight3),
        ],
      ),
    );
  }
}
