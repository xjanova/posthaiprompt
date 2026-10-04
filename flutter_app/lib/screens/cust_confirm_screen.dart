// Thaiprompt POS — Customer order sent (/cust/confirm?ticket=T-0001) · kiosk.
//
// Pure read-only confirmation of the kitchen ticket the customer just sent:
// ticket id, table, items, total and how to pay (at the counter / call a
// waiter). It NEVER checks out or records a payment — the old version
// auto-recorded a paid PromptPay sale just by opening the route.
//
// by xman studio

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';
import 'cust_menu_screen.dart';

class CustConfirmScreen extends StatelessWidget {
  const CustConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final id = GoRouterState.of(context).uri.queryParameters['ticket'] ?? '';
    final t = (id.isEmpty ? null : store.ticketById(id)) ?? store.lastSelfTicket;

    final header = CustTopBar(
      eyebrow: 'สั่งอาหารด้วยตนเอง',
      title: store.shopName,
      subtitle: t?.tableNumber != null ? 'โต๊ะ ${t!.tableNumber}' : null,
      onBack: () => context.go('/cust/menu'),
    );

    if (t == null) {
      return NvKiosk(
        child: Column(
          children: [
            header,
            Expanded(
              child: NvEmptyState(
                onNight: true,
                mascot: 'search',
                title: 'ไม่พบออเดอร์',
                message: 'ยังไม่มีออเดอร์ที่ส่งจากเครื่องนี้ หรือออเดอร์ถูกปิดไปแล้ว',
                actionLabel: 'กลับไปหน้าเมนู',
                actionIcon: NvIcons.utensils,
                onAction: () => context.go('/cust/menu'),
              ),
            ),
          ],
        ),
      );
    }

    final cancelled = t.status == TicketStatus.cancelled;
    final settled = t.status == TicketStatus.settled;
    final mascot = cancelled ? 'empty' : (settled ? 'wai' : 'cheer');
    final heading = cancelled ? 'ออเดอร์นี้ถูกยกเลิก' : (settled ? 'ชำระเงินเรียบร้อยแล้ว' : 'ส่งออเดอร์เข้าครัวแล้ว');
    final sub = cancelled
        ? 'กรุณาติดต่อพนักงานหากต้องการสั่งใหม่'
        : (settled ? 'ขอบคุณที่อุดหนุน ขอให้อร่อยกับมื้อนี้นะคะ' : 'ครัวได้รับออเดอร์แล้ว อาหารจะทยอยเสิร์ฟที่โต๊ะ');
    final table = t.tableNumber;
    final statusRoute = '/order-status?ticket=${Uri.encodeQueryComponent(t.id)}${table != null ? '&table=$table' : ''}';

    return NvKiosk(
      child: Column(
        children: [
          header,
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final hero = _Hero(ticket: t, mascot: mascot, heading: heading, sub: sub, wide: wide, maxH: c.maxHeight);
              final items = _ItemsCard(store: store, ticket: t);
              final actions = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!cancelled && !settled) ...[
                    _PayHint(store: store, table: table),
                    const SizedBox(height: 14),
                  ],
                  NvButton.gold('ดูสถานะออเดอร์',
                      icon: NvIcons.listCheck, size: NvButtonSize.xl, expand: true, onPressed: () => context.go(statusRoute)),
                  const SizedBox(height: 10),
                  NvButton.ghost('สั่งเพิ่ม',
                      onNight: true, icon: NvIcons.plus, size: NvButtonSize.xl, expand: true, onPressed: () => context.go('/cust/menu')),
                  if (table != null && !settled) ...[
                    const SizedBox(height: 10),
                    CustCallWaiterButton(table: table, expand: true),
                  ],
                ],
              );
              if (wide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [hero, const SizedBox(height: 18), actions],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: items),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                children: [
                  hero,
                  const SizedBox(height: 16),
                  SizedBox(height: math.max(260, math.min(420, 120 + t.lines.length * 72.0)), child: items),
                  const SizedBox(height: 16),
                  actions,
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Ticket ticket;
  final String mascot;
  final String heading;
  final String sub;
  final bool wide;
  final double maxH;

  const _Hero({required this.ticket, required this.mascot, required this.heading, required this.sub, required this.wide, required this.maxH});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NvArt.mascot(mascot, height: math.min(wide ? 230 : 180, maxH * 0.32)),
        const SizedBox(height: 8),
        NvFoilText(heading, style: Nv.display(wide ? 38 : 28, weight: FontWeight.w700), align: TextAlign.center),
        const SizedBox(height: 6),
        Text(sub, textAlign: TextAlign.center, style: Nv.ui(16, color: Nv.onNight2, height: 1.45)),
        const SizedBox(height: 14),
        Stack(
          children: [
            NvNightCard(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              glow: true,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('เลขที่ออเดอร์', style: Nv.eyebrow(color: Nv.gold300)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: NvFoilText(t.id, style: Nv.money(wide ? 40 : 32)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.tableNumber != null ? 'โต๊ะ ${t.tableNumber}' : 'รับที่เคาน์เตอร์'} · ส่งเมื่อ ${hm(t.createdAt)} น. · ${t.guests} ท่าน',
                          style: Nv.ui(14, color: Nv.onNight2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CustPrepBadge(t),
                ],
              ),
            ),
            const NvKanokCorners(size: 46, opacity: 0.7, inset: EdgeInsets.all(2)),
          ],
        ),
      ],
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final PosStore store;
  final Ticket ticket;
  const _ItemsCard({required this.store, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    return NvNightCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvSectionTitle('รายการที่สั่ง', trailing: '${t.itemCount} รายการ', onNight: true, icon: NvIcons.receipt),
          Expanded(
            child: ListView.separated(
              itemCount: t.lines.length,
              separatorBuilder: (_, _) => Divider(height: 18, color: Nv.lineNight.withValues(alpha: 0.6)),
              itemBuilder: (context, i) {
                final l = t.lines[i];
                return Row(
                  children: [
                    custLinePicture(store, l, size: 54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(16, color: Nv.onNight, weight: FontWeight.w600)),
                          if (l.detail.isNotEmpty)
                            Text(l.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(13, color: Nv.gold300)),
                          Text('${l.qty} × ${baht(l.price)}', style: Nv.money(13, color: Nv.onNight3, weight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(baht(l.lineTotal), style: Nv.money(17, color: Nv.gold200)),
                  ],
                );
              },
            ),
          ),
          if (t.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(Nv.rSm),
                border: Border.all(color: Nv.lineNight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(NvIcons.comment, size: 14, color: Nv.gold300),
                  const SizedBox(width: 8),
                  Expanded(child: Text('ถึงครัว: ${t.note}', style: Nv.ui(14, color: Nv.onNight2))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const NvKanokDivider(width: 200, thin: true, opacity: 0.8),
          Row(
            children: [
              Expanded(child: Text('ยอดรวมออเดอร์นี้', style: Nv.ui(16, color: Nv.onNight, weight: FontWeight.w700))),
              FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(t.total), style: Nv.money(30))),
            ],
          ),
        ],
      ),
    );
  }
}

/// "How do I pay?" — counter or call a waiter; shows the table's open bill.
class _PayHint extends StatelessWidget {
  final PosStore store;
  final int? table;
  const _PayHint({required this.store, required this.table});

  @override
  Widget build(BuildContext context) {
    final tb = table;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Nv.gold400.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Nv.rMd),
        border: Border.all(color: Nv.lineNightStrong),
      ),
      child: Row(
        children: [
          NvArt.icon('cash', size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ชำระเงินที่เคาน์เตอร์หรือเรียกพนักงานเมื่อพร้อมชำระ',
                    style: Nv.ui(15, color: Nv.onNight, weight: FontWeight.w600, height: 1.4)),
                if (tb != null && store.tableBillTotal(tb) > 0)
                  Text('ยอดค้างชำระของโต๊ะ $tb ตอนนี้ ${baht(store.tableBillTotal(tb))}',
                      style: Nv.ui(13.5, color: Nv.gold300)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
