// Thaiprompt POS — สมาชิก (CRM) · /crm
//
// Live member book: KPI tiles, search (name / phone / email), tier filter
// chips, sortable rows. Tap a row → detail panel (wide) or bottom sheet
// (narrow) with contact info, next-tier progress, purchase history (→ receipt),
// edit, manager-approved points adjustment, "use with current bill" and
// delete. Everything reads/writes the PosStore — no sample data.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/catalog_models.dart' show stableHue;
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

enum _Sort { recent, spent, points }

/// Tier → badge tint by rank (lowest = neutral … top = amethyst).
NvTint _tierTint(List<MembershipTier> sorted, MembershipTier t) {
  final i = sorted.indexWhere((x) => x.id == t.id);
  if (i <= 0) return NvTint.neutral;
  if (i == 1) return NvTint.sapphire;
  if (i == 2) return NvTint.gold;
  return NvTint.amethyst;
}

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _tierId;
  String? _selectedId;
  _Sort _sort = _Sort.recent;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Camera scan (member phone / member QR) → the text goes into the search
  /// box; a single match is selected for the detail panel.
  void _onCameraScan(String raw) {
    if (!mounted) return;
    final code = raw.trim();
    if (code.isEmpty) return;
    _search.text = code;
    final hits = AppScope.read(context).searchCustomers(code);
    setState(() {
      _query = code;
      _tierId = null;
      if (hits.length == 1) _selectedId = hits.first.id;
    });
  }

  Future<void> _add() async {
    final input = await _openCustomerForm(context);
    if (input == null || !mounted) return;
    final store = AppScope.read(context);
    // ตรวจซ้ำอีกครั้งตอนบันทึก (กันกรณีมีคนเพิ่มเบอร์เดียวกันระหว่างเปิดฟอร์ม)
    if (input.phone.isNotEmpty && store.customerByPhone(input.phone) != null) {
      nvToast(context, 'เบอร์ ${phoneFmt(input.phone)} มีสมาชิกใช้อยู่แล้ว', kind: NvToastKind.error);
      return;
    }
    final c = store.addCustomer(input.name, phone: input.phone, email: input.email, note: input.note, birthday: input.birthday);
    setState(() => _selectedId = c.id);
    nvToast(context, 'เพิ่มสมาชิก ${c.name} แล้ว', kind: NvToastKind.success);
  }

  void _openSheet(Customer c) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Nv.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Nv.rXl))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => _CustomerDetail(customerId: c.id, inSheet: true, scrollController: scroll),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final tiers = store.sortedTiers;
    if (_tierId != null && !tiers.any((t) => t.id == _tierId)) _tierId = null;

    var list = store.searchCustomers(_query);
    if (_tierId != null) list = list.where((c) => store.tierFor(c).id == _tierId).toList();
    switch (_sort) {
      case _Sort.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Sort.spent:
        list.sort((a, b) => b.spent.compareTo(a.spent));
      case _Sort.points:
        list.sort((a, b) => b.points.compareTo(a.points));
    }
    final selected = _selectedId == null ? null : store.customerById(_selectedId!);
    final compactActions = MediaQuery.sizeOf(context).width < 760;

    return NvScaffold(
      title: 'สมาชิก',
      eyebrow: 'CRM · LOYALTY',
      subtitle: 'ค้นหาสมาชิก ดูแต้ม ประวัติการซื้อ และผูกสมาชิกกับบิล',
      art: 'member',
      actions: [
        if (store.isManager && !compactActions)
          NvButton.ghost('ระดับสมาชิก', icon: NvIcons.crown, onPressed: () => context.go('/tiers')),
        NvButton.gold(compactActions ? '' : 'เพิ่มสมาชิก', icon: NvIcons.userPlus, tooltip: 'เพิ่มสมาชิก', onPressed: _add),
      ],
      body: store.customers.isEmpty
          ? NvEmptyState(
              mascot: 'gift',
              title: 'ยังไม่มีสมาชิก',
              message: 'เพิ่มสมาชิกเพื่อสะสมแต้ม รับส่วนลดตามระดับ และดูประวัติการซื้อของลูกค้าประจำ',
              actionLabel: 'เพิ่มสมาชิกคนแรก',
              actionIcon: NvIcons.userPlus,
              onAction: _add,
            )
          : LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 840;
              final panelW = c.maxWidth >= 1200 ? 410.0 : 350.0;
              final listCol = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _toolbar(c.maxWidth - (wide ? panelW + 16 : 0)),
                  const SizedBox(height: 10),
                  _tierChips(store, tiers),
                  const SizedBox(height: 10),
                  Expanded(
                    child: list.isEmpty
                        ? const NvEmptyState(
                            mascot: 'search',
                            size: 130,
                            title: 'ไม่พบสมาชิก',
                            message: 'ลองค้นหาด้วยชื่อ เบอร์โทร หรืออีเมลอื่น หรือเลือกระดับ "ทั้งหมด"',
                          )
                        : LayoutBuilder(builder: (context, lc) {
                            final roomy = lc.maxWidth > 560;
                            return ListView.separated(
                              padding: const EdgeInsets.only(bottom: 12),
                              itemCount: list.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final m = list[i];
                                final tier = store.tierFor(m);
                                return _MemberRow(
                                  customer: m,
                                  tier: tier,
                                  tint: _tierTint(tiers, tier),
                                  roomy: roomy,
                                  selected: wide && m.id == selected?.id,
                                  linked: store.customerId == m.id,
                                  onTap: () {
                                    if (wide) {
                                      setState(() => _selectedId = m.id);
                                    } else {
                                      _openSheet(m);
                                    }
                                  },
                                );
                              },
                            );
                          }),
                  ),
                ],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Kpis(store: store),
                  const SizedBox(height: 14),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: listCol),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: panelW,
                                child: selected == null
                                    ? const NvSheet(
                                        child: NvEmptyState(
                                          mascot: 'face',
                                          size: 120,
                                          title: 'เลือกสมาชิก',
                                          message: 'แตะรายชื่อทางซ้ายเพื่อดูรายละเอียด แต้ม และประวัติการซื้อ',
                                        ),
                                      )
                                    : NvSheet(
                                        padding: EdgeInsets.zero,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(Nv.rLg),
                                          child: _CustomerDetail(customerId: selected.id, inSheet: false),
                                        ),
                                      ),
                              ),
                            ],
                          )
                        : listCol,
                  ),
                ],
              );
            }),
    );
  }

  Widget _toolbar(double w) {
    final field = NvSearchField(
      hint: 'ค้นหาชื่อ เบอร์โทร หรืออีเมล',
      controller: _search,
      onChanged: (v) => setState(() => _query = v),
    );
    final search = nvCameraScanSupported
        ? Row(
            children: [
              Expanded(child: field),
              const SizedBox(width: 8),
              NvScanButton(
                icon: NvIcons.qrcode,
                title: 'สแกนบัตร / QR สมาชิก',
                hint: 'สแกน QR หรือบาร์โค้ดบัตรสมาชิก · ระบบจะนำข้อความไปค้นหาให้',
                onScanned: _onCameraScan,
              ),
            ],
          )
        : field;
    final sort = NvSegmented<_Sort>(
      options: const [(_Sort.recent, 'ล่าสุด'), (_Sort.spent, 'ยอดซื้อ'), (_Sort.points, 'แต้ม')],
      value: _sort,
      onChanged: (v) => setState(() => _sort = v),
    );
    if (w < 560) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [search, const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: sort)],
      );
    }
    return Row(children: [Expanded(child: search), const SizedBox(width: 10), sort]);
  }

  Widget _tierChips(PosStore store, List<MembershipTier> tiers) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          NvChip('ทั้งหมด', selected: _tierId == null, count: store.customers.length, onTap: () => setState(() => _tierId = null)),
          for (final t in tiers) ...[
            const SizedBox(width: 8),
            NvChip(
              t.name,
              icon: NvIcons.crown,
              selected: _tierId == t.id,
              count: store.membersInTier(t),
              onTap: () => setState(() => _tierId = _tierId == t.id ? null : t.id),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── KPI tiles ─────────────────────────────

class _Kpis extends StatelessWidget {
  final PosStore store;
  const _Kpis({required this.store});

  @override
  Widget build(BuildContext context) {
    final cs = store.customers;
    final now = DateTime.now();
    final newThisMonth = cs.where((c) => c.createdAt.year == now.year && c.createdAt.month == now.month).length;
    final points = cs.fold<int>(0, (s, c) => s + c.points);
    final spent = cs.fold<int>(0, (s, c) => s + c.spent);
    final avg = cs.isEmpty ? 0 : (spent / cs.length).round();
    final tiles = [
      NvStatTile(label: 'สมาชิกทั้งหมด', value: groupDigits(cs.length), art: 'member', caption: 'คน'),
      NvStatTile(label: 'ใหม่เดือนนี้', value: groupDigits(newThisMonth), art: 'tiers', caption: thaiMonthShort(now.month), tint: NvTint.jade),
      NvStatTile(label: 'แต้มคงค้างรวม', value: groupDigits(points), art: 'token', caption: 'แต้มที่ยังไม่ได้ใช้'),
      NvStatTile(label: 'ยอดซื้อเฉลี่ย', value: baht(avg), art: 'wallet', caption: 'ต่อสมาชิก 1 คน', tint: NvTint.sapphire),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 760 ? 4 : 2;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    });
  }
}

// ───────────────────────────── list row ─────────────────────────────

class _MemberRow extends StatelessWidget {
  final Customer customer;
  final MembershipTier tier;
  final NvTint tint;
  final bool roomy;
  final bool selected;
  final bool linked;
  final VoidCallback onTap;

  const _MemberRow({
    required this.customer,
    required this.tier,
    required this.tint,
    required this.roomy,
    required this.selected,
    required this.linked,
    required this.onTap,
  });

  Widget _stat(String label, String value, {double width = 84}) => SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.money(14)),
            const SizedBox(height: 2),
            Text(label, style: Nv.ui(11, color: Nv.ink3)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return NvSheet(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: Nv.rMd,
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          NvAvatar(c.initials, hue: stableHue(c.id), size: 42, ring: linked),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    NvBadge(tier.name, tint: tint, icon: NvIcons.crown),
                    if (linked) const NvBadge('อยู่ในบิล', tint: NvTint.jade),
                    Text(
                      c.phone.isEmpty ? 'ไม่มีเบอร์โทร' : phoneFmt(c.phone),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Nv.money(12.5, color: Nv.ink3, weight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _stat('แต้ม', groupDigits(c.points), width: roomy ? 84 : 64),
          if (roomy) _stat('มาแล้ว', '${groupDigits(c.visits)} ครั้ง'),
          _stat('ยอดซื้อสะสม', baht(c.spent), width: roomy ? 100 : 84),
          const SizedBox(width: 4),
          const Icon(NvIcons.angleRight, size: 14, color: Nv.ink4),
        ],
      ),
    );
  }
}

// ───────────────────────────── detail ─────────────────────────────

class _CustomerDetail extends StatelessWidget {
  final String customerId;
  final bool inSheet;
  final ScrollController? scrollController;
  const _CustomerDetail({required this.customerId, required this.inSheet, this.scrollController});

  void _go(BuildContext context, String route) {
    final router = GoRouter.of(context);
    if (inSheet) _close(context);
    router.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final c = store.customerById(customerId);
    if (c == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: NvEmptyState(mascot: 'empty', size: 110, title: 'ไม่พบสมาชิกนี้', message: 'สมาชิกอาจถูกลบไปแล้ว'),
        ),
      );
    }
    final tiers = store.sortedTiers;
    final tier = store.tierFor(c);
    final next = store.nextTierFor(c);
    final history = store.orders.where((o) => o.customerId == c.id).toList();
    final linked = store.customerId == c.id;

    double progress = 1;
    if (next != null) {
      final span = next.tier.minSpent - tier.minSpent;
      progress = span <= 0 ? 0 : ((c.spent - tier.minSpent) / span).clamp(0.0, 1.0);
    }

    Widget info(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 22, child: Icon(icon, size: 13, color: Nv.goldInk)),
              SizedBox(width: 84, child: Text(label, style: Nv.ui(13, color: Nv.ink3))),
              Expanded(child: Text(value, style: Nv.ui(13.5, weight: FontWeight.w600))),
            ],
          ),
        );

    Widget stat(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(Nv.rSm), border: Border.all(color: Nv.lineSoft)),
            child: Column(
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: Nv.money(16))),
                const SizedBox(height: 2),
                Text(label, style: Nv.ui(11.5, color: Nv.ink3)),
              ],
            ),
          ),
        );

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(18, inSheet ? 10 : 18, 18, 22),
      children: [
        if (inSheet)
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Nv.line, borderRadius: BorderRadius.circular(3)),
            ),
          ),
        Row(
          children: [
            NvAvatar(c.initials, hue: stableHue(c.id), size: 58, ring: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.display(20)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      NvBadge(tier.name, tint: _tierTint(tiers, tier), icon: NvIcons.crown),
                      if (linked) const NvBadge('ผูกกับบิลปัจจุบัน', tint: NvTint.jade),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('สมาชิกตั้งแต่ ${thaiDate(c.createdAt)}', style: Nv.ui(12, color: Nv.ink3)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            stat('แต้มคงเหลือ', groupDigits(c.points)),
            const SizedBox(width: 8),
            stat('มาใช้บริการ', '${groupDigits(c.visits)} ครั้ง'),
            const SizedBox(width: 8),
            stat('ยอดซื้อสะสม', baht(c.spent)),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            NvButton.gold(
              linked ? 'อยู่ในบิลแล้ว · ไปหน้าขาย' : 'ใช้กับบิลปัจจุบัน',
              icon: NvIcons.cashier,
              size: NvButtonSize.sm,
              onPressed: () {
                AppScope.read(context).linkCustomer(c);
                nvToast(context, 'ผูก ${c.name} กับบิลปัจจุบันแล้ว', kind: NvToastKind.success);
                _go(context, '/cashier');
              },
            ),
            NvButton.navy('ปรับแต้ม', icon: NvIcons.coins, size: NvButtonSize.sm, onPressed: () => _adjustPoints(context, c)),
            NvButton.soft('แก้ไข', icon: NvIcons.edit, size: NvButtonSize.sm, onPressed: () => _editCustomer(context, c)),
            NvButton.soft('ลบ', icon: NvIcons.trash, size: NvButtonSize.sm, onPressed: () => _deleteCustomer(context, c, inSheet)),
          ],
        ),
        const SizedBox(height: 18),
        const NvSectionTitle('ระดับสมาชิก', icon: NvIcons.crown),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(gradient: Nv.night, borderRadius: BorderRadius.circular(Nv.rMd), border: Border.all(color: Nv.lineNightStrong)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(tier.name, style: Nv.display(17, color: Nv.gold200))),
                  Text('ลด ${tier.discountPercent}% · ${tier.pointsPer100} แต้ม/฿100', style: Nv.ui(12, color: Nv.onNight2, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: Nv.gold400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                next == null ? 'อยู่ระดับสูงสุดแล้ว' : 'ซื้อเพิ่มอีก ${baht(next.remaining)} เพื่อเลื่อนเป็น ${next.tier.name} (ลด ${next.tier.discountPercent}%)',
                style: Nv.ui(12.5, color: Nv.onNight2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const NvSectionTitle('ข้อมูลติดต่อ', icon: NvIcons.idCard),
        info(NvIcons.phone, 'เบอร์โทร', c.phone.isEmpty ? '—' : phoneFmt(c.phone)),
        info(NvIcons.envelope, 'อีเมล', c.email.isEmpty ? '—' : c.email),
        info(NvIcons.cake, 'วันเกิด', c.birthday == null ? '—' : thaiDateLong(c.birthday!)),
        info(NvIcons.note, 'บันทึก', c.note.isEmpty ? '—' : c.note),
        const SizedBox(height: 14),
        NvSectionTitle('ประวัติการซื้อ', icon: NvIcons.receipt, trailing: '${history.length} บิล'),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('ยังไม่มีบิลที่ผูกกับสมาชิกคนนี้ — ผูกสมาชิกที่หน้าขายก่อนชำระเงินเพื่อสะสมแต้ม',
                style: Nv.ui(13, color: Nv.ink3, height: 1.4)),
          )
        else ...[
          for (final o in history.take(30))
            _HistoryRow(order: o, onTap: () => _go(context, '/receipt?id=${o.id}')),
          if (history.length > 30)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('แสดง 30 บิลล่าสุดจากทั้งหมด ${history.length} บิล — ดูทั้งหมดที่เมนู "บิล"',
                  style: Nv.ui(12, color: Nv.ink3)),
            ),
        ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const _HistoryRow({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final o = order;
    final (label, tint) = switch (o.status) {
      OrderStatus.refunded => ('คืนเงินแล้ว', NvTint.lacquer),
      OrderStatus.voided => ('ยกเลิก', NvTint.neutral),
      OrderStatus.open => ('ค้างชำระ', NvTint.amber),
      OrderStatus.paid => o.refundAmount > 0 ? ('คืนบางส่วน', NvTint.amber) : ('ชำระแล้ว', NvTint.jade),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Nv.rSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              const Icon(NvIcons.receipt, size: 14, color: Nv.goldInk),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.id, style: Nv.money(13.5)),
                    Text('${thaiDateTime(o.createdAt)} · ${o.itemCount} ชิ้น', style: Nv.ui(11.5, color: Nv.ink3)),
                  ],
                ),
              ),
              NvBadge(label, tint: tint),
              const SizedBox(width: 10),
              NvMoney(o.netTotal, size: 14),
              const SizedBox(width: 6),
              const Icon(NvIcons.angleRight, size: 12, color: Nv.ink4),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── actions ─────────────────────────────

Future<void> _editCustomer(BuildContext context, Customer c) async {
  final input = await _openCustomerForm(context, edit: c);
  if (input == null || !context.mounted) return;
  final store = AppScope.read(context);
  if (store.customerById(c.id) == null) {
    nvToast(context, 'สมาชิกนี้ถูกลบไปแล้ว', kind: NvToastKind.error);
    return;
  }
  final dup = input.phone.isEmpty ? null : store.customerByPhone(input.phone);
  if (dup != null && dup.id != c.id) {
    nvToast(context, 'เบอร์ ${phoneFmt(input.phone)} เป็นของ ${dup.name} แล้ว', kind: NvToastKind.error);
    return;
  }
  // updateCustomer ไม่รับค่า null สำหรับวันเกิด — ล้างที่ตัวแบบก่อน แล้วบันทึกพร้อมกันในการเรียกเดียว
  if (input.birthday == null && c.birthday != null) c.birthday = null;
  store.updateCustomer(c, name: input.name, phone: input.phone, email: input.email, note: input.note, birthday: input.birthday);
  nvToast(context, 'บันทึกข้อมูล ${c.name} แล้ว', kind: NvToastKind.success);
}

Future<void> _adjustPoints(BuildContext context, Customer c) async {
  final key = GlobalKey<_PointsFormState>();
  final res = await showNvDialog<({int delta, String reason})>(
    context,
    title: 'ปรับแต้มสมาชิก',
    subtitle: '${c.name} · คงเหลือ ${groupDigits(c.points)} แต้ม',
    art: 'token',
    maxWidth: 440,
    body: _PointsForm(key: key, balance: c.points),
    actions: (ctx) => [
      NvButton.soft('ยกเลิก', onPressed: () => _close(ctx)),
      NvButton.gold('ถัดไป · ขออนุมัติ', icon: NvIcons.shield, onPressed: () => key.currentState?._save()),
    ],
  );
  if (res == null || !context.mounted) return;
  final mgr = await showManagerPin(context, reason: 'ปรับแต้ม ${c.name} ${res.delta > 0 ? '+' : ''}${res.delta} แต้ม');
  if (mgr == null || !context.mounted) return;
  final store = AppScope.read(context);
  if (store.customerById(c.id) == null) {
    nvToast(context, 'สมาชิกนี้ถูกลบไปแล้ว', kind: NvToastKind.error);
    return;
  }
  store.adjustPoints(c, res.delta, reason: '${res.reason} · อนุมัติโดย ${mgr.name}');
  nvToast(context, 'ปรับแต้ม ${c.name} ${res.delta > 0 ? '+' : ''}${groupDigits(res.delta)} · คงเหลือ ${groupDigits(c.points)} แต้ม',
      kind: NvToastKind.success);
}

Future<void> _deleteCustomer(BuildContext context, Customer c, bool inSheet) async {
  final ok = await showNvConfirm(
    context,
    title: 'ลบสมาชิก ${c.name}?',
    message: 'แต้มคงเหลือ ${groupDigits(c.points)} แต้มจะหายไป บิลเดิมยังอยู่แต่จะไม่ผูกกับสมาชิกคนนี้อีก — ย้อนกลับไม่ได้',
    confirmLabel: 'ลบสมาชิก',
  );
  if (!ok || !context.mounted) return;
  final mgr = await showManagerPin(context, reason: 'ลบสมาชิก ${c.name}');
  if (mgr == null || !context.mounted) return;
  final store = AppScope.read(context);
  if (store.customerById(c.id) == null) return;
  // แจ้งผลก่อนปิดแผ่นรายละเอียด (context ยังใช้งานได้ในจังหวะนี้)
  nvToast(context, 'ลบสมาชิก ${c.name} แล้ว', kind: NvToastKind.success);
  if (inSheet) _close(context);
  store.deleteCustomer(c);
}

// ───────────────────────────── customer form ─────────────────────────────

class _CustomerInput {
  final String name;
  final String phone; // digits only
  final String email;
  final String note;
  final DateTime? birthday;
  const _CustomerInput({required this.name, required this.phone, required this.email, required this.note, this.birthday});
}

Future<_CustomerInput?> _openCustomerForm(BuildContext context, {Customer? edit}) {
  final key = GlobalKey<_CustomerFormState>();
  return showNvDialog<_CustomerInput>(
    context,
    title: edit == null ? 'เพิ่มสมาชิก' : 'แก้ไขข้อมูลสมาชิก',
    subtitle: edit == null ? 'กรอกชื่อเป็นอย่างน้อย · เบอร์โทรใช้ค้นหาสมาชิกที่หน้าขาย' : edit.name,
    art: 'member',
    maxWidth: 520,
    body: _CustomerForm(key: key, edit: edit),
    actions: (ctx) => [
      NvButton.soft('ยกเลิก', onPressed: () => _close(ctx)),
      NvButton.gold('บันทึก', icon: NvIcons.floppy, onPressed: () => key.currentState?._save()),
    ],
  );
}

class _CustomerForm extends StatefulWidget {
  final Customer? edit;
  const _CustomerForm({super.key, this.edit});

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.edit?.name ?? '');
  late final _phone = TextEditingController(text: widget.edit?.phone.replaceAll(RegExp(r'\D'), '') ?? '');
  late final _email = TextEditingController(text: widget.edit?.email ?? '');
  late final _note = TextEditingController(text: widget.edit?.note ?? '');
  late DateTime? _birthday = widget.edit?.birthday;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    _close(context, _CustomerInput(
      name: _name.text.trim(),
      phone: _phone.text.replaceAll(RegExp(r'\D'), ''),
      email: _email.text.trim(),
      note: _note.text.trim(),
      birthday: _birthday,
    ));
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'เลือกวันเกิด',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked == null || !mounted) return;
    setState(() => _birthday = picked);
  }

  String? _validatePhone(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return null;
    if (!RegExp(r'^0\d{8,9}$').hasMatch(d)) return 'เบอร์โทรต้องเป็นตัวเลข 9–10 หลัก ขึ้นต้นด้วย 0';
    final dup = AppScope.read(context).customerByPhone(d);
    if (dup != null && dup.id != widget.edit?.id) return 'เบอร์นี้เป็นของสมาชิก ${dup.name} แล้ว';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvField(
            label: 'ชื่อสมาชิก *',
            controller: _name,
            icon: NvIcons.user,
            autofocus: widget.edit == null,
            formatters: [LengthLimitingTextInputFormatter(60)],
            validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'เบอร์โทร',
            controller: _phone,
            icon: NvIcons.phone,
            hint: '0812345678',
            keyboard: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            validator: _validatePhone,
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'อีเมล',
            controller: _email,
            icon: NvIcons.envelope,
            keyboard: TextInputType.emailAddress,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return null;
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : 'รูปแบบอีเมลไม่ถูกต้อง';
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('วันเกิด', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(Nv.rSm),
            onTap: _pickBirthday,
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: const Icon(NvIcons.cake, size: 15, color: Nv.goldInk),
                suffixIcon: _birthday == null
                    ? const Icon(NvIcons.calendar, size: 15, color: Nv.ink3)
                    : IconButton(
                        tooltip: 'ล้างวันเกิด',
                        icon: const Icon(NvIcons.xmark, size: 14, color: Nv.ink3),
                        onPressed: () => setState(() => _birthday = null),
                      ),
              ),
              child: Text(
                _birthday == null ? 'แตะเพื่อเลือกวันเกิด (ไม่บังคับ)' : thaiDateLong(_birthday!),
                style: Nv.ui(14.5, color: _birthday == null ? Nv.ink4 : Nv.ink),
              ),
            ),
          ),
          const SizedBox(height: 12),
          NvField(label: 'บันทึกเพิ่มเติม', controller: _note, icon: NvIcons.note, maxLines: 3, hint: 'เช่น แพ้ถั่ว · ชอบหวานน้อย'),
        ],
      ),
    );
  }
}

// ───────────────────────────── points form ─────────────────────────────

class _PointsForm extends StatefulWidget {
  final int balance;
  const _PointsForm({super.key, required this.balance});

  @override
  State<_PointsForm> createState() => _PointsFormState();
}

class _PointsFormState extends State<_PointsForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _add = true;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text) ?? 0;

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    _close(context, (delta: _add ? _value : -_value, reason: _reason.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final after = widget.balance + (_add ? _value : -_value);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: NvSegmented<bool>(
              options: const [(true, 'เพิ่มแต้ม'), (false, 'หักแต้ม')],
              value: _add,
              onChanged: (v) {
                setState(() => _add = v);
                _form.currentState?.validate();
              },
            ),
          ),
          const SizedBox(height: 14),
          NvField(
            label: 'จำนวนแต้ม *',
            controller: _amount,
            icon: NvIcons.coins,
            keyboard: TextInputType.number,
            autofocus: true,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final n = int.tryParse(v ?? '') ?? 0;
              if (n <= 0) return 'กรุณากรอกจำนวนแต้มมากกว่า 0';
              if (!_add && n > widget.balance) return 'แต้มคงเหลือมีเพียง ${groupDigits(widget.balance)} แต้ม';
              return null;
            },
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'เหตุผล *',
            controller: _reason,
            icon: NvIcons.comment,
            hint: 'เช่น แลกของรางวัล · ชดเชยบิลผิด',
            validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณาระบุเหตุผล (บันทึกในประวัติการใช้งาน)' : null,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          NvKeyValue('แต้มหลังปรับ', groupDigits(after < 0 ? 0 : after), strong: true),
          Text('ต้องให้ผู้จัดการใส่ PIN อนุมัติก่อนบันทึก', style: Nv.ui(12, color: Nv.ink3)),
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
