// Thaiprompt POS — Manager summary, phone layout (Nova).
//
// Everything a manager checks on the floor, from the live store: today's
// sales, the kitchen queue and its oldest ticket, open tables and waiter
// calls, the cash shift, low stock, who is clocked in and the last ten bills.
// Centered at 520 px so it reads like a phone even on a desktop terminal; a
// 30-second tick keeps ticket ages and lock timers fresh.
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';

class MobileManagerScreen extends StatefulWidget {
  const MobileManagerScreen({super.key});

  @override
  State<MobileManagerScreen> createState() => _MobileManagerScreenState();
}

class _MobileManagerScreenState extends State<MobileManagerScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _ackCall(int table) async {
    final ok = await showNvConfirm(
      context,
      title: 'รับทราบการเรียกโต๊ะ $table?',
      message: 'ปิดสัญญาณเรียกพนักงานของโต๊ะ $table (ให้พนักงานไปที่โต๊ะแล้ว)',
      confirmLabel: 'รับทราบ',
      danger: false,
      icon: NvIcons.bellConcierge,
    );
    if (!ok || !mounted) return;
    AppScope.read(context).setCallWaiter(table, false);
    nvToast(context, 'ปิดการเรียกโต๊ะ $table แล้ว', kind: NvToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final now = DateTime.now();
    final sales = store.todaySales;
    final bills = store.todayOrderCount;
    final avg = bills == 0 ? 0 : (sales / bills).round(); // today only — no all-time fallback
    final refunds = store.todayRefunds;
    final queue = store.kitchenQueue;
    final oldest = queue.isEmpty ? null : queue.first;
    final oldestAge = oldest == null ? null : now.difference(oldest.createdAt);
    final openTables = store.tables.where((t) => t.status != TableStatus.free).length;
    final calls = store.tablesCallingWaiter;
    final low = List.of(store.lowStockProducts)..sort((a, b) => a.stock.compareTo(b.stock));
    final onDuty = store.staff.where((s) => s.active && s.online).toList()
      ..sort((a, b) => (a.clockedInAt ?? now).compareTo(b.clockedInAt ?? now));
    final recent = store.settledOrders.take(10).toList();
    final shift = store.currentShift;

    return NvScaffold(
      title: 'สรุปผู้จัดการ',
      eyebrow: 'มุมมองมือถือ',
      subtitle: '${store.shopName} · ${store.branch}',
      art: 'dashboard',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // ── today hero ──
              Stack(
                children: [
                  NvNightCard(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    onTap: () => context.go('/dashboard'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ยอดขายสุทธิวันนี้', style: Nv.eyebrow(color: Nv.gold300)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: NvFoilText(baht(sales), style: Nv.money(36)),
                        ),
                        Text(thaiDateFull(now), style: Nv.ui(12.5, color: Nv.onNight3)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _heroMini('บิล', groupDigits(bills))),
                            Expanded(child: _heroMini('เฉลี่ย/บิล', baht(avg))),
                            Expanded(child: _heroMini('คืนเงิน', baht(refunds), warn: refunds > 0)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const NvKanokCorners(size: 46, opacity: 0.5, inset: EdgeInsets.all(3), bottom: false),
                ],
              ),
              const SizedBox(height: 12),

              // ── kitchen + tables ──
              LayoutBuilder(
                builder: (context, c) {
                  final kitchenTile = NvStatTile(
                    label: 'คิวครัว',
                    value: '${queue.length} คิว',
                    art: 'kitchen',
                    caption: oldestAge == null ? 'ไม่มีคิวค้าง' : 'นานสุด ${elapsed(oldestAge)}',
                    tint: oldestAge == null
                        ? NvTint.jade
                        : (oldestAge.inMinutes >= 20 ? NvTint.lacquer : (oldestAge.inMinutes >= 10 ? NvTint.amber : NvTint.jade)),
                    onTap: () => context.go('/display/kitchen'),
                  );
                  final tablesTile = NvStatTile(
                    label: 'โต๊ะที่เปิด',
                    value: '$openTables โต๊ะ',
                    art: 'table',
                    caption: calls.isEmpty ? 'ไม่มีการเรียก' : 'เรียกพนักงาน ${calls.length}',
                    tint: calls.isEmpty ? NvTint.neutral : NvTint.lacquer,
                    onTap: () => context.go('/tablet/floor'),
                  );
                  // side by side from ~440 px; stacked on small phones so captions stay readable
                  if (c.maxWidth < 440) return Column(children: [kitchenTile, const SizedBox(height: 10), tablesTile]);
                  return Row(
                    children: [
                      Expanded(child: kitchenTile),
                      const SizedBox(width: 10),
                      Expanded(child: tablesTile),
                    ],
                  );
                },
              ),
              if (calls.isNotEmpty) ...[
                const SizedBox(height: 10),
                NvSheet(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  color: Nv.lacquerTint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(NvIcons.bellConcierge, size: 14, color: Nv.lacquer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ลูกค้าเรียกพนักงาน · แตะเพื่อรับทราบ',
                              style: Nv.ui(13, color: Nv.lacquerDeep, weight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final t in calls) NvChip('โต๊ะ $t', icon: NvIcons.bell, onTap: () => _ackCall(t))],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // ── shift ──
              _Section(
                art: 'shift',
                title: 'กะการขาย',
                action: NvButton.soft(shift == null ? 'เปิดกะ' : 'จัดการกะ', size: NvButtonSize.sm, onPressed: () => context.go('/shift')),
                child: shift == null
                    ? Row(
                        children: [
                          const NvBadge('ยังไม่เปิดกะ', tint: NvTint.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              store.requireShift ? 'ต้องเปิดกะก่อนจึงรับชำระเงินได้' : 'ตั้งค่าให้ขายได้โดยไม่ต้องเปิดกะ',
                              style: Nv.ui(12.5, color: Nv.ink3),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          NvKeyValue('เปิดกะเมื่อ', '${hm(shift.openedAt)} · ${shift.cashier}', mono: false),
                          NvKeyValue('ยอดขายในกะ', baht(store.shiftSales(shift))),
                          NvKeyValue('บิลในกะ', groupDigits(store.ordersInShift(shift).length)),
                          NvKeyValue('เงินสดที่ควรมีในลิ้นชัก', baht(store.expectedCash(shift)), strong: true),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              // ── low stock ──
              _Section(
                art: 'inventory',
                title: 'สต็อกใกล้หมด',
                trailing: low.isEmpty ? null : '${low.length} รายการ',
                action: NvButton.soft('ดูทั้งหมด', size: NvButtonSize.sm, onPressed: () => context.go('/inventory')),
                child: low.isEmpty
                    ? _okLine('สต็อกปกติทุกรายการ')
                    : Column(
                        children: [
                          for (final p in low.take(5))
                            InkWell(
                              onTap: () => context.go('/inventory'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Nv.ui(13.5, weight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(
                                      p.code,
                                      style: Nv.money(11, color: Nv.ink4, weight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 10),
                                    NvBadge(p.stock <= 0 ? 'หมด' : 'เหลือ ${p.stock}', tint: p.stock <= 0 ? NvTint.lacquer : NvTint.amber),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              // ── staff on duty ──
              _Section(
                art: 'staff',
                title: 'พนักงานที่ลงเวลาเข้างาน',
                trailing: '${onDuty.length} คน',
                action: NvButton.soft('พนักงาน', size: NvButtonSize.sm, onPressed: () => context.go('/staff')),
                child: onDuty.isEmpty
                    ? Text('ยังไม่มีพนักงานลงเวลาเข้างาน (เข้าระบบด้วย PIN = ลงเวลาเข้า)', style: Nv.ui(12.5, color: Nv.ink3))
                    : Column(
                        children: [
                          for (final s in onDuty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  NvAvatar(s.initials, hue: s.hue, size: 36, ring: store.currentStaff?.id == s.id),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Nv.ui(13.5, weight: FontWeight.w700),
                                        ),
                                        Text(
                                          '${s.role.label}${s.clockedInAt != null ? ' · เข้างาน ${hm(s.clockedInAt!)}' : ''}',
                                          style: Nv.ui(11.5, color: Nv.ink3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(baht(store.salesTodayFor(s)), style: Nv.money(13.5)),
                                      Text('${store.ordersTodayFor(s)} บิล', style: Nv.ui(11, color: Nv.ink3)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              // ── recent bills ──
              _Section(
                art: 'receipt',
                title: 'บิลล่าสุด',
                action: NvButton.soft('ทั้งหมด', size: NvButtonSize.sm, onPressed: () => context.go('/orders')),
                child: recent.isEmpty
                    ? Text('ยังไม่มีบิล', style: Nv.ui(12.5, color: Nv.ink3))
                    : Column(
                        children: [
                          for (final o in recent)
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => context.go('/receipt?id=${Uri.encodeQueryComponent(o.id)}'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                                child: Row(
                                  children: [
                                    NvArt.icon(o.method.art, size: 30),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(o.id, style: Nv.money(13)),
                                          Text(
                                            '${thaiDayMonth(o.createdAt)} ${hm(o.createdAt)} · ${o.cashier}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Nv.ui(11.5, color: Nv.ink3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (o.status == OrderStatus.refunded)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: NvBadge('คืนเงิน', tint: NvTint.lacquer),
                                      )
                                    else if (o.refundAmount > 0)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: NvBadge('คืนบางส่วน', tint: NvTint.amber),
                                      ),
                                    Text(baht(o.netTotal), style: Nv.money(14)),
                                    const SizedBox(width: 6),
                                    const Icon(NvIcons.angleRight, size: 12, color: Nv.ink4),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroMini(String k, String v, {bool warn = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(v, style: Nv.money(17, color: warn ? Nv.lacquerLight : Nv.onNight)),
      ),
      Text(k, style: Nv.ui(11.5, color: Nv.onNight3)),
    ],
  );

  Widget _okLine(String text) => Row(
    children: [
      const Icon(NvIcons.checkCircle, size: 15, color: Nv.jade),
      const SizedBox(width: 8),
      Text(text, style: Nv.ui(13, color: Nv.ink2)),
    ],
  );
}

class _Section extends StatelessWidget {
  final String art;
  final String title;
  final String? trailing;
  final Widget? action;
  final Widget child;
  const _Section({required this.art, required this.title, required this.child, this.trailing, this.action});

  @override
  Widget build(BuildContext context) => NvSheet(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            NvArt.icon(art, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Nv.ui(15, weight: FontWeight.w700),
                  ),
                  if (trailing != null) Text(trailing!, style: Nv.ui(11.5, color: Nv.ink3)),
                ],
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}
