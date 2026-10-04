// Thaiprompt POS — Inventory (/inventory) · Nova.
//
// KPI tiles (products, stock value at cost Σ stock×cost, low, out), search +
// filter chips (all / low / out / not tracked) and one row per real product:
// picture, name, code, on-hand (big mono, coloured), unit cost and the last
// ledger movement. Row actions write through the stock ledger:
//   รับเข้า      → adjustStock(+qty, receive, reason)
//   ตรวจนับ      → countStock(counted) (a lower count needs a manager PIN)
//   ตัดของเสีย   → manager PIN → adjustStock(−qty, waste, reason)
//   ปรับลดสต็อก  → manager PIN → adjustStock(−qty, adjust, reason)
//   ประวัติ      → movesFor(code) (+ jump to the full ledger for managers)
// Products that don't track stock show "ไม่ติดตาม" and get no stock actions.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/catalog_models.dart';
import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

enum _InvFilter { all, low, out, untracked }

enum _MoveKind { receive, waste, adjust, count }

extension on _MoveKind {
  String get title => switch (this) {
        _MoveKind.receive => 'รับสินค้าเข้า',
        _MoveKind.waste => 'ตัดของเสีย',
        _MoveKind.adjust => 'ปรับลดสต็อก',
        _MoveKind.count => 'ตรวจนับสต็อก',
      };
  bool get decreases => this == _MoveKind.waste || this == _MoveKind.adjust;
  List<String> get reasons => switch (this) {
        _MoveKind.receive => const ['รับจากซัพพลายเออร์', 'ผลิตเอง', 'โอนจากสาขาอื่น', 'ได้รับคืน'],
        _MoveKind.waste => const ['หมดอายุ', 'เสียหาย / แตก', 'ทำหก / ตก', 'ใช้ภายในร้าน'],
        _MoveKind.adjust => const ['นับผิดครั้งก่อน', 'สูญหาย', 'โอนออกไปสาขาอื่น', 'บันทึกซ้ำ'],
        _MoveKind.count => const ['ตรวจนับประจำวัน', 'ตรวจนับสิ้นเดือน', 'สุ่มนับ'],
      };
}

/// What the movement dialog returns.
class _MoveInput {
  final int qty; // receive/waste/adjust: units · count: counted on-hand
  final String reason;
  const _MoveInput(this.qty, this.reason);
}

NvTint _moveTint(StockMoveType t) => switch (t) {
      StockMoveType.sale => NvTint.sapphire,
      StockMoveType.refund => NvTint.gold,
      StockMoveType.receive => NvTint.jade,
      StockMoveType.adjust => NvTint.amber,
      StockMoveType.waste => NvTint.lacquer,
      StockMoveType.count => NvTint.neutral,
    };

String _signed(int v) => v > 0 ? '+${groupDigits(v)}' : groupDigits(v);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _q = '';
  _InvFilter _filter = _InvFilter.all;

  // ───────────────────────── actions ─────────────────────────

  String _withApprover(String reason, Staff? approver, PosStore store) {
    if (approver == null || approver.id == store.currentStaff?.id) return reason;
    return '$reason · อนุมัติโดย ${approver.name}';
  }

  Future<void> _move(Product p, _MoveKind kind) async {
    Staff? approver;
    if (kind.decreases) {
      approver = await showManagerPin(context, reason: '${kind.title} "${p.name}"');
      if (approver == null || !mounted) return;
    }
    final input = await showNvDialog<_MoveInput>(
      context,
      title: kind.title,
      subtitle: '${p.name} · ${p.code}',
      art: 'inventory',
      maxWidth: 460,
      body: _MoveForm(code: p.code, kind: kind),
    );
    if (input == null || !mounted) return;

    var store = AppScope.read(context);
    var fresh = store.productByCode(p.code);
    if (fresh == null || !fresh.trackStock) {
      nvToast(context, 'ไม่พบสินค้านี้ หรือปิดการติดตามสต็อกไปแล้ว', kind: NvToastKind.error);
      return;
    }

    switch (kind) {
      case _MoveKind.receive:
        store.adjustStock(fresh, input.qty, type: StockMoveType.receive, reason: input.reason);
        nvToast(context, 'รับเข้า "${fresh.name}" +${groupDigits(input.qty)} · คงเหลือ ${groupDigits(fresh.stock)}',
            kind: NvToastKind.success);
      case _MoveKind.waste:
      case _MoveKind.adjust:
        // stock may have moved while the dialog was open (sales) — never go below 0
        final q = input.qty > fresh.stock ? fresh.stock : input.qty;
        if (q <= 0) {
          nvToast(context, 'สต็อกของ "${fresh.name}" เหลือ 0 แล้ว', kind: NvToastKind.error);
          return;
        }
        store.adjustStock(
          fresh,
          -q,
          type: kind == _MoveKind.waste ? StockMoveType.waste : StockMoveType.adjust,
          reason: _withApprover(input.reason, approver, store),
        );
        nvToast(
          context,
          '${kind == _MoveKind.waste ? 'ตัดของเสีย' : 'ปรับลด'} "${fresh.name}" −${groupDigits(q)} · คงเหลือ ${groupDigits(fresh.stock)}'
          '${q < input.qty ? ' (ลดได้เท่าที่เหลือ)' : ''}',
          kind: NvToastKind.success,
        );
      case _MoveKind.count:
        final diff = input.qty - fresh.stock;
        if (diff == 0) {
          nvToast(context, 'ยอดนับตรงกับระบบ (${groupDigits(fresh.stock)} ชิ้น) — ไม่ต้องปรับ', kind: NvToastKind.info);
          return;
        }
        var reason = input.reason.isEmpty ? 'ตรวจนับ' : input.reason;
        if (diff < 0) {
          final mgr = await showManagerPin(context, reason: 'ผลนับ "${p.name}" น้อยกว่าระบบ ${groupDigits(-diff)} ชิ้น');
          if (mgr == null || !mounted) return;
          store = AppScope.read(context);
          fresh = store.productByCode(p.code);
          if (fresh == null) return;
          reason = _withApprover(reason, mgr, store);
        }
        final before = fresh.stock;
        store.countStock(fresh, input.qty, reason: reason);
        nvToast(context, 'บันทึกผลนับ "${fresh.name}": ${groupDigits(before)} → ${groupDigits(fresh.stock)}',
            kind: NvToastKind.success);
    }
  }

  void _history(Product p) {
    final store = AppScope.read(context);
    final moves = store.movesFor(p.code);
    final shown = moves.length > 300 ? moves.sublist(0, 300) : moves;
    showNvDialog<void>(
      context,
      title: 'ประวัติสต็อก',
      subtitle: '${p.name} · ${p.code}${p.trackStock ? ' · คงเหลือ ${groupDigits(p.stock)}' : ''}',
      art: 'inventory',
      maxWidth: 680,
      body: shown.isEmpty
          ? Column(
              children: [
                NvArt.mascot('search', height: 120),
                const SizedBox(height: 8),
                Text('ยังไม่มีความเคลื่อนไหวของสินค้านี้', style: Nv.ui(14, color: Nv.ink3)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final m in shown) _MoveTile(m: m),
                if (moves.length > shown.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('แสดง ${shown.length} รายการล่าสุดจาก ${groupDigits(moves.length)}',
                        textAlign: TextAlign.center, style: Nv.ui(12.5, color: Nv.ink3)),
                  ),
              ],
            ),
      actions: (ctx) => [
        if (store.isManager)
          NvButton.ghost('เปิดสมุดสต็อก', icon: NvIcons.tableList, onPressed: () {
            Navigator.of(ctx).pop();
            context.go('/stock?q=${Uri.encodeQueryComponent(p.code)}');
          }),
        NvButton.gold('ปิด', onPressed: () => Navigator.of(ctx).pop()),
      ],
    );
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final products = store.products;
    final tracked = products.where((p) => p.trackStock).toList();
    final value = tracked.fold<int>(0, (s, p) => s + (p.stock > 0 ? p.stock : 0) * p.cost);
    final noCost = tracked.where((p) => p.cost <= 0).length;
    final low = tracked.where((p) => p.stock > 0 && p.stock <= 5).length;
    final out = tracked.where((p) => p.stock <= 0).length;
    final untracked = products.length - tracked.length;

    // newest movement per product in one pass (stockMoves is newest-first)
    final last = <String, StockMovement>{};
    for (final m in store.stockMoves) {
      last.putIfAbsent(m.code, () => m);
    }

    final q = _q.trim().toLowerCase();
    final list = products.where((p) {
      switch (_filter) {
        case _InvFilter.all:
          break;
        case _InvFilter.low:
          if (!(p.trackStock && p.stock > 0 && p.stock <= 5)) return false;
        case _InvFilter.out:
          if (!p.isOutOfStock) return false;
        case _InvFilter.untracked:
          if (p.trackStock) return false;
      }
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        // tracked items with the least stock first, then by name
        if (a.trackStock != b.trackStock) return a.trackStock ? -1 : 1;
        if (a.trackStock && a.stock != b.stock && (a.stock <= 5 || b.stock <= 5)) return a.stock.compareTo(b.stock);
        return a.name.compareTo(b.name);
      });

    return NvScaffold(
      title: 'คลังสินค้า',
      eyebrow: 'สินค้าและสต็อก',
      subtitle: 'รับเข้า · ตัดของเสีย · ปรับยอด · ตรวจนับ — ทุกการเปลี่ยนแปลงลงสมุดสต็อก',
      art: 'inventory',
      actions: [
        if (store.isManager) ...[
          NvButton.ghost('สมุดสต็อก', icon: NvIcons.tableList, onPressed: () => context.go('/stock')),
          NvButton.navy('ใบสั่งซื้อ', icon: NvIcons.clipboardCheck, onPressed: () => context.go('/po')),
        ],
      ],
      body: products.isEmpty
          ? NvEmptyState(
              mascot: 'empty',
              title: 'ยังไม่มีสินค้าในคลัง',
              message: store.isManager
                  ? 'เพิ่มสินค้าที่หน้า "เมนูและสินค้า" ก่อน แล้วกลับมารับของเข้าสต็อกที่นี่'
                  : 'ให้ผู้จัดการเพิ่มสินค้าที่หน้า "เมนูและสินค้า" ก่อน',
              actionLabel: store.isManager ? 'ไปหน้าเมนูและสินค้า' : null,
              actionIcon: NvIcons.menuBook,
              onAction: store.isManager ? () => context.go('/menu-editor') : null,
            )
          : LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 860;
              final cols = c.maxWidth >= 760 ? 4 : 2;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: GridView(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 108, // NvStatTile: 54 px art / 3 text lines + padding
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        NvStatTile(
                          label: 'จำนวนสินค้า',
                          value: groupDigits(products.length),
                          art: 'inventory',
                          caption: 'ติดตามสต็อก ${tracked.length} รายการ',
                          onTap: () => setState(() => _filter = _InvFilter.all),
                        ),
                        NvStatTile(
                          label: 'มูลค่าสต็อกตามทุน',
                          value: baht(value),
                          icon: NvIcons.coins,
                          tint: noCost > 0 ? NvTint.amber : NvTint.gold,
                          caption: noCost > 0 ? 'ยังไม่ใส่ทุน $noCost รายการ' : 'คงเหลือ × ต้นทุน',
                        ),
                        NvStatTile(
                          label: 'สต็อกต่ำ (≤ 5)',
                          value: groupDigits(low),
                          icon: NvIcons.warning,
                          tint: NvTint.amber,
                          caption: low > 0 ? 'แตะเพื่อดูรายการ' : 'ไม่มีรายการใกล้หมด',
                          onTap: () => setState(() => _filter = _InvFilter.low),
                        ),
                        NvStatTile(
                          label: 'หมดสต็อก',
                          value: groupDigits(out),
                          icon: NvIcons.boxOpen,
                          tint: NvTint.lacquer,
                          caption: out > 0 ? 'ขายไม่ได้จนกว่าจะรับเข้า' : 'ไม่มีสินค้าหมด',
                          onTap: () => setState(() => _filter = _InvFilter.out),
                        ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: wide ? 360 : c.maxWidth,
                          child: NvSearchField(hint: 'ค้นหาชื่อ รหัส หรือบาร์โค้ด', onChanged: (v) => setState(() => _q = v)),
                        ),
                        NvChip('ทั้งหมด',
                            selected: _filter == _InvFilter.all,
                            count: products.length,
                            onTap: () => setState(() => _filter = _InvFilter.all)),
                        NvChip('ใกล้หมด',
                            icon: NvIcons.warning,
                            selected: _filter == _InvFilter.low,
                            count: low,
                            onTap: () => setState(() => _filter = _InvFilter.low)),
                        NvChip('หมด',
                            icon: NvIcons.boxOpen,
                            selected: _filter == _InvFilter.out,
                            count: out,
                            onTap: () => setState(() => _filter = _InvFilter.out)),
                        NvChip('ไม่ติดตามสต็อก',
                            selected: _filter == _InvFilter.untracked,
                            count: untracked,
                            onTap: () => setState(() => _filter = _InvFilter.untracked)),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (list.isEmpty)
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 320,
                        child: NvEmptyState(mascot: 'search', title: 'ไม่พบสินค้าตามตัวกรอง', size: 140),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final p = list[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InvRow(
                            p: p,
                            icon: store.categoryById(p.categoryId)?.icon ?? NvIcons.tag,
                            last: last[p.code],
                            wide: wide,
                            onMove: (k) => _move(p, k),
                            onHistory: () => _history(p),
                          ),
                        );
                      },
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              );
            }),
    );
  }
}

// ═════════════════════════════ rows ═════════════════════════════

class _InvRow extends StatelessWidget {
  final Product p;
  final IconData icon;
  final StockMovement? last;
  final bool wide;
  final ValueChanged<_MoveKind> onMove;
  final VoidCallback onHistory;

  const _InvRow({
    required this.p,
    required this.icon,
    required this.last,
    required this.wide,
    required this.onMove,
    required this.onHistory,
  });

  Widget _stock() {
    if (!p.trackStock) return const NvBadge('ไม่ติดตาม', tint: NvTint.neutral, dot: false);
    final c = p.stock <= 0 ? Nv.lacquer : (p.stock <= 5 ? nvTint(NvTint.amber).fg : nvTint(NvTint.jade).fg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(groupDigits(p.stock), style: Nv.money(24, color: c)),
        Text(p.stock <= 0 ? 'หมดสต็อก' : (p.stock <= 5 ? 'ใกล้หมด' : 'คงเหลือ'),
            style: Nv.ui(11.5, color: c, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _last() {
    final m = last;
    if (m == null) return Text('ยังไม่มีความเคลื่อนไหว', style: Nv.ui(12, color: Nv.ink4));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            NvBadge(m.type.label, tint: _moveTint(m.type)),
            Text(_signed(m.delta),
                style: Nv.money(13, color: m.delta >= 0 ? nvTint(NvTint.jade).fg : Nv.lacquer, weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 3),
        Text('${timeAgo(m.at)}${m.by.isEmpty ? '' : ' · ${m.by}'}',
            maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11.5, color: Nv.ink3)),
      ],
    );
  }

  Widget _actions() {
    final history = NvIconButton(NvIcons.history, size: 36, tooltip: 'ประวัติ', onPressed: onHistory);
    if (!p.trackStock) return history;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        NvButton.success('รับเข้า', icon: NvIcons.plus, size: NvButtonSize.sm, onPressed: () => onMove(_MoveKind.receive)),
        NvButton.soft('ตรวจนับ', icon: NvIcons.clipboardCheck, size: NvButtonSize.sm, onPressed: () => onMove(_MoveKind.count)),
        history,
        PopupMenuButton<_MoveKind>(
          tooltip: 'ลดสต็อก (ต้องอนุมัติ)',
          icon: const Icon(NvIcons.ellipsisV, size: 15, color: Nv.ink2),
          onSelected: onMove,
          itemBuilder: (_) => [
            PopupMenuItem(
              value: _MoveKind.waste,
              enabled: p.stock > 0,
              child: Row(children: [
                const Icon(NvIcons.trash, size: 13, color: Nv.lacquer),
                const SizedBox(width: 10),
                Text('ตัดของเสีย', style: Nv.ui(14)),
              ]),
            ),
            PopupMenuItem(
              value: _MoveKind.adjust,
              enabled: p.stock > 0,
              child: Row(children: [
                const Icon(NvIcons.minusCircle, size: 13, color: Nv.goldInk),
                const SizedBox(width: 10),
                Text('ปรับลดสต็อก', style: Nv.ui(14)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(p.barcode.isEmpty ? p.code : '${p.code} · ${p.barcode}',
            maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w500)),
      ],
    );
    final cost = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(p.cost > 0 ? baht(p.cost) : '—', style: Nv.money(14, color: Nv.ink2, weight: FontWeight.w600)),
        Text('ทุน/หน่วย', style: Nv.ui(11.5, color: Nv.ink4)),
      ],
    );

    return NvSheet(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      radius: Nv.rMd,
      child: wide
          ? Row(
              children: [
                _thumb(p, icon, 50),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: name),
                SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: _stock())),
                const SizedBox(width: 18),
                SizedBox(width: 84, child: cost),
                const SizedBox(width: 22),
                Expanded(flex: 2, child: _last()),
                const SizedBox(width: 8),
                _actions(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _thumb(p, icon, 46),
                    const SizedBox(width: 12),
                    Expanded(child: name),
                    const SizedBox(width: 8),
                    _stock(),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _last()),
                    cost,
                  ],
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: _actions()),
              ],
            ),
    );
  }
}

Widget _thumb(Product p, IconData icon, double size) {
  final r = BorderRadius.circular(size * 0.24);
  Widget tile() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(gradient: Nv.btnNavy, borderRadius: r),
        child: Icon(icon, size: size * 0.36, color: Nv.gold300),
      );
  if (p.art != null) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Nv.ivoryDeep.withValues(alpha: 0.6), borderRadius: r),
      child: NvArt.food(p.art!, size: size, fallbackIcon: icon),
    );
  }
  if ((p.imageUrl ?? '').isNotEmpty) {
    return ClipRRect(
      borderRadius: r,
      child: Image.network(p.imageUrl!, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => tile()),
    );
  }
  return tile();
}

class _MoveTile extends StatelessWidget {
  final StockMovement m;
  const _MoveTile({required this.m});

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (m.reason.isNotEmpty) m.reason,
      if (m.by.isNotEmpty) 'โดย ${m.by}',
      if (m.ref.isNotEmpty) 'อ้างอิง ${m.ref}',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Nv.lineSoft))),
      child: Row(
        children: [
          SizedBox(
            width: 128,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(thaiDate(m.at), style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
                Text(hm(m.at), style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w500)),
              ],
            ),
          ),
          NvBadge(m.type.label, tint: _moveTint(m.type)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(detail.isEmpty ? '—' : detail,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink3)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(_signed(m.delta),
                textAlign: TextAlign.right,
                style: Nv.money(14, color: m.delta >= 0 ? nvTint(NvTint.jade).fg : Nv.lacquer)),
          ),
          SizedBox(
            width: 64,
            child: Text(groupDigits(m.balance), textAlign: TextAlign.right, style: Nv.money(14, color: Nv.ink2, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════ movement form ═════════════════════════════

/// Quantity + reason for one stock movement. Pops a [_MoveInput].
class _MoveForm extends StatefulWidget {
  final String code;
  final _MoveKind kind;
  const _MoveForm({required this.code, required this.kind});

  @override
  State<_MoveForm> createState() => _MoveFormState();
}

class _MoveFormState extends State<_MoveForm> {
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit(int stock) {
    final k = widget.kind;
    final n = int.tryParse(_qty.text.trim());
    final reason = _reason.text.trim();
    if (k == _MoveKind.count) {
      if (n == null) return setState(() => _error = 'กรุณาใส่จำนวนที่นับได้จริง');
    } else {
      if (n == null || n <= 0) return setState(() => _error = 'กรุณาใส่จำนวนมากกว่า 0');
      if (k.decreases && n > stock) return setState(() => _error = 'ลดได้ไม่เกินคงเหลือ ${groupDigits(stock)} ชิ้น');
      if (k.decreases && reason.isEmpty) return setState(() => _error = 'กรุณาระบุเหตุผล (ใช้ตรวจสอบย้อนหลัง)');
    }
    Navigator.of(context).pop(_MoveInput(n, reason));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = store.productByCode(widget.code);
    final stock = p?.stock ?? 0;
    final k = widget.kind;
    final n = int.tryParse(_qty.text.trim());
    final after = n == null
        ? null
        : switch (k) {
            _MoveKind.receive => stock + n,
            _MoveKind.waste || _MoveKind.adjust => stock - n,
            _MoveKind.count => n,
          };

    final confirm = switch (k) {
      _MoveKind.receive => NvButton.success('รับเข้าสต็อก', icon: NvIcons.check, onPressed: () => _submit(stock)),
      _MoveKind.waste => NvButton.danger('ตัดของเสีย', icon: NvIcons.trash, onPressed: () => _submit(stock)),
      _MoveKind.adjust => NvButton.danger('ปรับลด', icon: NvIcons.minus, onPressed: () => _submit(stock)),
      _MoveKind.count => NvButton.gold('บันทึกผลนับ', icon: NvIcons.clipboardCheck, onPressed: () => _submit(stock)),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSheet(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          radius: Nv.rMd,
          color: Nv.paper,
          child: Row(
            children: [
              Expanded(child: Text('คงเหลือในระบบ', style: Nv.ui(13.5, color: Nv.ink3))),
              Text('${groupDigits(stock)} ชิ้น', style: Nv.money(18)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(k == _MoveKind.count ? 'จำนวนที่นับได้จริง (ชิ้น)' : 'จำนวน (ชิ้น)',
            style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _qty,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: NvField.digits,
          textAlign: TextAlign.center,
          style: Nv.money(28),
          decoration: const InputDecoration(hintText: '0'),
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _submit(stock),
        ),
        if (after != null) ...[
          const SizedBox(height: 8),
          Text(
            k == _MoveKind.count
                ? (n! == stock
                    ? 'ตรงกับระบบ — ไม่มีการปรับ'
                    : 'ส่วนต่าง ${_signed(n - stock)} ชิ้น${n < stock ? ' (ต้องให้ผู้จัดการอนุมัติ)' : ''}')
                : 'คงเหลือหลังบันทึก ${groupDigits(after < 0 ? 0 : after)} ชิ้น',
            textAlign: TextAlign.center,
            style: Nv.ui(13,
                color: after < stock ? Nv.lacquer : (after > stock ? nvTint(NvTint.jade).fg : Nv.ink3),
                weight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 14),
        Text(k.decreases ? 'เหตุผล *' : 'เหตุผล / หมายเหตุ', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final r in k.reasons)
              NvChip(r, selected: _reason.text.trim() == r, onTap: () => setState(() {
                    _reason.text = r;
                    _error = null;
                  })),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reason,
          onChanged: (_) => setState(() => _error = null),
          decoration: const InputDecoration(hintText: 'พิมพ์เหตุผลเพิ่มเติม'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: Nv.ui(13, color: Nv.lacquer, weight: FontWeight.w600)),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            confirm,
          ],
        ),
      ],
    );
  }
}
