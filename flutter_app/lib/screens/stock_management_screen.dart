// Thaiprompt POS — Stock ledger (/stock) · Nova.
//
// The real store.stockMoves ledger (sales, refunds, receipts, waste, manual
// adjustments, counts — written by checkout, refunds, inventory and POs):
// time, product, type badge, ±qty, balance after, reason, by, reference.
// Filters: type chips, period (วันนี้ / 7 วัน / 30 วัน / ทั้งหมด), product
// search (prefilled from ?q=CODE when opened from inventory history). Summary
// tiles per type follow the period + search. "พิมพ์รายงาน" prints the current
// filtered view as a multi-page A4 report; "แชร์ PDF" saves / shares it.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/print/print_service.dart';
import '../models/extra_models.dart';
import '../print/stock_report_doc.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

enum _Period { today, d7, d30, all }

extension on _Period {
  String get label => switch (this) {
        _Period.today => 'วันนี้',
        _Period.d7 => '7 วัน',
        _Period.d30 => '30 วัน',
        _Period.all => 'ทั้งหมด',
      };
}

NvTint _tint(StockMoveType t) => switch (t) {
      StockMoveType.sale => NvTint.sapphire,
      StockMoveType.refund => NvTint.gold,
      StockMoveType.receive => NvTint.jade,
      StockMoveType.adjust => NvTint.amber,
      StockMoveType.waste => NvTint.lacquer,
      StockMoveType.count => NvTint.neutral,
    };

String _signed(int v) => v > 0 ? '+${groupDigits(v)}' : groupDigits(v);

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final TextEditingController _search = TextEditingController();
  String _q = '';
  StockMoveType? _type;
  _Period _period = _Period.d7;
  bool _routeRead = false;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final q = GoRouterState.of(context).uri.queryParameters['q'];
    if (q != null && q.trim().isNotEmpty) {
      _search.text = q.trim();
      _q = q.trim();
      _period = _Period.all; // coming from a product's history → show all of it
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  DateTime? _start(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      _Period.today => today,
      _Period.d7 => today.subtract(const Duration(days: 6)),
      _Period.d30 => today.subtract(const Duration(days: 29)),
      _Period.all => null,
    };
  }

  String _periodLabel(DateTime now) {
    final s = _start(now);
    return switch (_period) {
      _Period.today => 'วันนี้ · ${thaiDate(now)}',
      _Period.all => 'ทั้งหมดที่บันทึกไว้',
      _ => '${_period.label} · ${thaiDate(s!)} – ${thaiDate(now)}',
    };
  }

  /// Period + search (all types) — feeds the summary tiles and type counts.
  List<StockMovement> _base(PosStore store, DateTime now) {
    final start = _start(now);
    final q = _q.trim().toLowerCase();
    return store.stockMoves.where((m) {
      if (start != null && m.at.isBefore(start)) return false;
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) || m.code.toLowerCase().contains(q) || m.ref.toLowerCase().contains(q);
    }).toList();
  }

  List<StockMovement> _visible(List<StockMovement> base) => _type == null ? base : base.where((m) => m.type == _type).toList();

  Future<void> _report({required bool share}) async {
    final store = AppScope.read(context);
    final now = DateTime.now();
    final list = _visible(_base(store, now));
    if (list.isEmpty) {
      nvToast(context, 'ไม่มีรายการตามตัวกรองนี้ให้พิมพ์', kind: NvToastKind.warning);
      return;
    }
    final pages = stockReportPages(StockReportData(
      shopName: store.shopName,
      branch: store.branch,
      phone: store.shopPhone,
      address: store.shopAddress,
      periodLabel: _periodLabel(now),
      typeLabel: _type?.label ?? 'ทุกประเภท',
      search: _q.trim(),
      printedAt: now,
      printedBy: store.actorName,
      moves: list,
    ));
    setState(() => _busy = true);
    // A4 always goes through the system dialog (the saved printer is the receipt roll)
    final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${hm(now).replaceAll(':', '')}';
    final Future<PrintResult> job = share
        ? A4Pages.sharePages(context, pages, fileName: 'stock-report-$stamp')
        : A4Pages.printPages(context, pages, jobName: 'รายงานสต็อก ${_periodLabel(now)}');
    final res = await job;
    if (!mounted) return;
    setState(() => _busy = false);
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final now = DateTime.now();
    final base = _base(store, now);
    final rows = _visible(base);

    int units(StockMoveType t) => base.where((m) => m.type == t).fold(0, (s, m) => s + m.delta);
    int count(StockMoveType t) => base.where((m) => m.type == t).length;
    final adjustNet = units(StockMoveType.adjust) + units(StockMoveType.count);

    return NvScaffold(
      title: 'สมุดสต็อก',
      eyebrow: 'สินค้าและสต็อก',
      subtitle: 'ความเคลื่อนไหวเข้า–ออกทุกรายการ · ${_periodLabel(now)}',
      art: 'inventory',
      actions: [
        NvButton.soft('แชร์ PDF', icon: NvIcons.share, onPressed: _busy || store.stockMoves.isEmpty ? null : () => _report(share: true)),
        NvButton.gold('พิมพ์รายงาน',
            icon: NvIcons.print, loading: _busy, onPressed: _busy || store.stockMoves.isEmpty ? null : () => _report(share: false)),
      ],
      body: store.stockMoves.isEmpty
          ? NvEmptyState(
              mascot: 'search',
              title: 'ยังไม่มีความเคลื่อนไหวสต็อก',
              message: 'เมื่อขายสินค้าที่ติดตามสต็อก รับของ ตัดของเสีย หรือตรวจนับ รายการจะขึ้นที่นี่พร้อมคงเหลือ',
              actionLabel: 'ไปหน้าคลังสินค้า',
              actionIcon: NvIcons.inventory,
              onAction: () => context.go('/inventory'),
            )
          : LayoutBuilder(builder: (context, c) {
              final table = c.maxWidth >= 860;
              final cols = c.maxWidth >= 760 ? 4 : 2;
              return CustomScrollView(
                slivers: [
                  // ── summary tiles ──
                  SliverToBoxAdapter(
                    child: GridView(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 104,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        NvStatTile(
                          label: 'ขายออก',
                          value: '${groupDigits(-units(StockMoveType.sale))} ชิ้น',
                          icon: NvIcons.cart,
                          tint: NvTint.sapphire,
                          caption: '${count(StockMoveType.sale)} รายการ',
                          onTap: () => setState(() => _type = StockMoveType.sale),
                        ),
                        NvStatTile(
                          label: 'รับเข้า',
                          value: '${groupDigits(units(StockMoveType.receive))} ชิ้น',
                          icon: NvIcons.dolly,
                          tint: NvTint.jade,
                          caption: '${count(StockMoveType.receive)} รายการ',
                          onTap: () => setState(() => _type = StockMoveType.receive),
                        ),
                        NvStatTile(
                          label: 'ของเสีย',
                          value: '${groupDigits(-units(StockMoveType.waste))} ชิ้น',
                          icon: NvIcons.trash,
                          tint: NvTint.lacquer,
                          caption: '${count(StockMoveType.waste)} รายการ',
                          onTap: () => setState(() => _type = StockMoveType.waste),
                        ),
                        NvStatTile(
                          label: 'ปรับยอด / ตรวจนับ',
                          value: '${_signed(adjustNet)} ชิ้น',
                          icon: NvIcons.scale,
                          tint: NvTint.amber,
                          caption: '${count(StockMoveType.adjust) + count(StockMoveType.count)} รายการ',
                          onTap: () => setState(() => _type = StockMoveType.adjust),
                        ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // ── filters ──
                  SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: c.maxWidth >= 700 ? 320 : c.maxWidth,
                          child: NvSearchField(
                            hint: 'ค้นหาสินค้า รหัส หรือเลขอ้างอิง',
                            controller: _search,
                            onChanged: (v) => setState(() => _q = v),
                          ),
                        ),
                        NvSegmented<_Period>(
                          options: [for (final p in _Period.values) (p, p.label)],
                          value: _period,
                          onChanged: (v) => setState(() => _period = v),
                        ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        NvChip('ทุกประเภท', selected: _type == null, count: base.length, onTap: () => setState(() => _type = null)),
                        for (final t in StockMoveType.values)
                          NvChip(t.label, selected: _type == t, count: count(t), onTap: () => setState(() => _type = t)),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  if (rows.isEmpty)
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 300,
                        child: NvEmptyState(
                          mascot: 'search',
                          title: 'ไม่พบรายการตามตัวกรอง',
                          message: 'ลองขยายช่วงเวลา เปลี่ยนประเภท หรือคำค้น',
                          size: 130,
                        ),
                      ),
                    )
                  else ...[
                    if (table)
                      PinnedHeaderSliver(
                        child: ColoredBox(color: Nv.ivory, child: _TableHeader(count: rows.length)),
                      ),
                    SliverList.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) => table ? _LedgerRow(m: rows[i], odd: i.isOdd) : _LedgerCard(m: rows[i]),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              );
            }),
    );
  }
}

// ═════════════════════════════ table ═════════════════════════════

const double _wTime = 150;
const double _wType = 96;
const double _wQty = 76;
const double _wBal = 76;
const double _wBy = 100;
const double _wRef = 96;

class _TableHeader extends StatelessWidget {
  final int count;
  const _TableHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    Text h(String t, {TextAlign a = TextAlign.left}) =>
        Text(t, textAlign: a, style: Nv.ui(12, color: Nv.gold200, weight: FontWeight.w700));
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(gradient: Nv.btnNavy, borderRadius: BorderRadius.circular(Nv.rSm)),
      child: Row(
        children: [
          SizedBox(width: _wTime, child: h('วันที่ · เวลา')),
          Expanded(flex: 3, child: h('สินค้า ($count รายการ)')),
          SizedBox(width: _wType, child: h('ประเภท')),
          SizedBox(width: _wQty, child: h('จำนวน', a: TextAlign.right)),
          SizedBox(width: _wBal, child: h('คงเหลือ', a: TextAlign.right)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: h('เหตุผล')),
          SizedBox(width: _wBy, child: h('โดย')),
          SizedBox(width: _wRef, child: h('อ้างอิง')),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final StockMovement m;
  final bool odd;
  const _LedgerRow({required this.m, required this.odd});

  @override
  Widget build(BuildContext context) {
    final up = m.delta >= 0;
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: odd ? Nv.ivory2 : Nv.paper,
        border: const Border(bottom: BorderSide(color: Nv.lineSoft)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _wTime,
            child: Text(thaiDateTime(m.at), style: Nv.ui(12.5, color: Nv.ink2)),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w600)),
                Text(m.code, style: Nv.money(11.5, color: Nv.ink3, weight: FontWeight.w500)),
              ],
            ),
          ),
          SizedBox(width: _wType, child: Align(alignment: Alignment.centerLeft, child: NvBadge(m.type.label, tint: _tint(m.type)))),
          SizedBox(
            width: _wQty,
            child: Text(_signed(m.delta),
                textAlign: TextAlign.right, style: Nv.money(15, color: up ? nvTint(NvTint.jade).fg : Nv.lacquer)),
          ),
          SizedBox(
            width: _wBal,
            child: Text(groupDigits(m.balance), textAlign: TextAlign.right, style: Nv.money(14, color: Nv.ink2, weight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(m.reason.isEmpty ? '—' : m.reason,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink3)),
          ),
          SizedBox(
            width: _wBy,
            child: Text(m.by.isEmpty ? '—' : m.by, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink2)),
          ),
          SizedBox(
            width: _wRef,
            child: Text(m.ref.isEmpty ? '—' : m.ref,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// Narrow layouts: one card per movement.
class _LedgerCard extends StatelessWidget {
  final StockMovement m;
  const _LedgerCard({required this.m});

  @override
  Widget build(BuildContext context) {
    final up = m.delta >= 0;
    final detail = [
      if (m.reason.isNotEmpty) m.reason,
      if (m.by.isNotEmpty) 'โดย ${m.by}',
      if (m.ref.isNotEmpty) m.ref,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NvSheet(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        radius: Nv.rMd,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    NvBadge(m.type.label, tint: _tint(m.type)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(thaiDateTime(m.at),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('${m.name} · ${m.code}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w600)),
                  if (detail.isNotEmpty)
                    Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_signed(m.delta), style: Nv.money(17, color: up ? nvTint(NvTint.jade).fg : Nv.lacquer)),
                Text('คงเหลือ ${groupDigits(m.balance)}', style: Nv.ui(11.5, color: Nv.ink3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
