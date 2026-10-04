// Thaiprompt POS — รับออเดอร์จากมือถือพนักงาน (/mobile/order).
//
// Phone-first waiter ordering: pick the table + guests, search / filter the
// live menu, tap + (products with modifiers open an options dialog — required
// single choice, multi toppings, price deltas, qty, kitchen note). The sticky
// cart bar opens the cart sheet: steppers, line notes, remove (with undo), a
// bill note, then "ส่งครัว" (unpaid ticket, source = มือถือพนักงาน) or
// "ชำระเงิน" (→ /payment when checkout is allowed).
//
// The menu / table / cart building blocks below (MobileCatalog,
// MobileTableBar, MobileCartLineTile, MobileTotals, mobileAddProduct,
// mobilePickTable, mobileGoToPayment) are shared with /m/cashier.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/catalog_models.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';

// ═════════════════════════ shared building blocks ═════════════════════════

/// Product picture: food art → network image → navy tile with the category icon.
class MobileProductThumb extends StatelessWidget {
  final Product product;
  final double size;
  const MobileProductThumb(this.product, {super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final icon = AppScope.of(context).categoryById(p.categoryId)?.icon ?? NvIcons.utensils;
    final r = BorderRadius.circular(size * 0.24);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: Nv.btnNavy, borderRadius: r, border: Border.all(color: Nv.lineNightStrong)),
      child: Icon(icon, size: size * 0.4, color: Nv.gold300),
    );
    final art = p.art;
    if (art != null && art.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Nv.gold100, borderRadius: r),
        child: NvArt.food(art, size: size, fallbackIcon: icon),
      );
    }
    final url = p.imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: r,
        child: Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
      );
    }
    return fallback;
  }
}

typedef _OptionPick = ({List<String> options, int delta, String note, int qty});

/// Add [p] to the counter cart: guards sold-out / unavailable, opens the
/// options dialog for products with modifiers. True when something was added.
Future<bool> mobileAddProduct(BuildContext context, Product p) async {
  final store = AppScope.read(context);
  if (!p.canSell) {
    nvToast(context, p.available ? '${p.name} หมดแล้ว' : '${p.name} งดขายอยู่', kind: NvToastKind.warning);
    return false;
  }
  if (!p.hasOptions) {
    final ok = store.addProduct(p);
    if (!ok) nvToast(context, 'สต็อก ${p.name} ไม่พอ', kind: NvToastKind.warning);
    return ok;
  }
  final pick = await showNvDialog<_OptionPick>(
    context,
    title: p.name,
    subtitle: '${baht(p.price)} · เลือกตัวเลือก',
    maxWidth: 520,
    body: _OptionPicker(product: p),
  );
  if (pick == null || !context.mounted) return false;
  final ok = store.addProduct(p, options: pick.options, optionDelta: pick.delta, note: pick.note, qty: pick.qty);
  if (ok) {
    nvToast(context, 'เพิ่ม ${p.name} ×${pick.qty} แล้ว', kind: NvToastKind.success);
  } else {
    nvToast(context, 'สต็อก ${p.name} ไม่พอสำหรับ ${pick.qty} ที่', kind: NvToastKind.warning);
  }
  return ok;
}

class _OptionPicker extends StatefulWidget {
  final Product product;
  const _OptionPicker({required this.product});

  @override
  State<_OptionPicker> createState() => _OptionPickerState();
}

class _OptionPickerState extends State<_OptionPicker> {
  late final List<Set<int>> _sel;
  final TextEditingController _note = TextEditingController();
  int _qty = 1;

  List<OptionGroup> get _groups => widget.product.options;

  @override
  void initState() {
    super.initState();
    // required single-choice groups start on their first choice (fast ordering)
    _sel = [
      for (final g in _groups) (g.required && !g.multi && g.choices.isNotEmpty) ? <int>{0} : <int>{},
    ];
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _valid {
    for (var i = 0; i < _groups.length; i++) {
      if (_groups[i].required && _groups[i].choices.isNotEmpty && _sel[i].isEmpty) return false;
    }
    return true;
  }

  int get _delta {
    var d = 0;
    for (var i = 0; i < _groups.length; i++) {
      for (final j in _sel[i]) {
        d += _groups[i].choices[j].priceDelta;
      }
    }
    return d;
  }

  List<String> get _labels => [
        for (var i = 0; i < _groups.length; i++)
          for (final j in (_sel[i].toList()..sort())) _groups[i].choices[j].label,
      ];

  void _toggle(int i, int j) {
    final g = _groups[i];
    setState(() {
      if (g.multi) {
        if (!_sel[i].remove(j)) _sel[i].add(j);
      } else if (_sel[i].contains(j)) {
        if (!g.required) _sel[i].clear();
      } else {
        _sel[i]
          ..clear()
          ..add(j);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final unit = p.price + _delta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _groups.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(_groups[i].name, style: Nv.ui(14.5, weight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    if (_groups[i].required)
                      NvBadge('ต้องเลือก', tint: _sel[i].isEmpty ? NvTint.amber : NvTint.jade, dot: false)
                    else
                      NvBadge(_groups[i].multi ? 'เลือกได้หลายอย่าง' : 'ไม่บังคับ', tint: NvTint.neutral, dot: false),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var j = 0; j < _groups[i].choices.length; j++)
                      NvChip(
                        _groups[i].choices[j].priceDelta == 0
                            ? _groups[i].choices[j].label
                            : '${_groups[i].choices[j].label} ${baht(_groups[i].choices[j].priceDelta, sign: true)}',
                        selected: _sel[i].contains(j),
                        icon: _sel[i].contains(j) ? NvIcons.check : null,
                        onTap: () => _toggle(i, j),
                      ),
                  ],
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(child: Text('จำนวน', style: Nv.ui(14.5, weight: FontWeight.w700))),
            NvStepper(
              value: _qty,
              onMinus: _qty > 1 ? () => setState(() => _qty--) : null,
              onPlus: _qty < 99 ? () => setState(() => _qty++) : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLines: 2,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'หมายเหตุถึงครัว เช่น ไม่ใส่ผัก',
            prefixIcon: Icon(NvIcons.note, size: 15),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            const SizedBox(width: 10),
            Expanded(
              child: NvButton.gold(
                'เพิ่มลงตะกร้า · ${baht(unit * _qty)}',
                icon: NvIcons.plus,
                expand: true,
                onPressed: _valid
                    ? () => Navigator.of(context).pop<_OptionPick>(
                          (options: _labels, delta: _delta, note: _note.text.trim(), qty: _qty),
                        )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Search + category chips + product list, wired to the store filters.
class MobileCatalog extends StatefulWidget {
  const MobileCatalog({super.key});

  @override
  State<MobileCatalog> createState() => _MobileCatalogState();
}

class _MobileCatalogState extends State<MobileCatalog> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    // the filter lives in the store (shared with the counter) — show it
    _search = TextEditingController(text: AppScope.read(context).searchQuery);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Scanner / Enter: an exact barcode or SKU adds straight to the cart.
  Future<void> _submit(String raw) async {
    final store = AppScope.read(context);
    final p = store.productByScan(raw);
    if (p == null) return;
    final added = await mobileAddProduct(context, p);
    if (!added || !mounted) return;
    _search.clear();
    store.setSearch('');
  }

  /// Camera scan → the same add-to-cart path as the scanner / Enter above
  /// (mobileAddProduct: sold-out guard, options dialog). A plain product also
  /// gets a toast since the camera hides the cart; unknown codes land in the
  /// search box (filtering the menu) with an error toast.
  Future<void> _onCameraScan(String raw) async {
    if (!mounted) return;
    final code = raw.trim();
    if (code.isEmpty) return;
    final store = AppScope.read(context);
    final p = store.productByScan(code);
    if (p == null) {
      _search.text = code;
      store.setSearch(code);
      nvToast(context, 'ไม่พบสินค้ารหัส "$code"', kind: NvToastKind.error);
      return;
    }
    final added = await mobileAddProduct(context, p);
    if (!added || !mounted) return;
    _search.clear();
    store.setSearch('');
    if (!p.hasOptions) nvToast(context, 'เพิ่ม ${p.name} แล้ว · ${baht(p.price)}', kind: NvToastKind.success);
  }

  void _clearFilters() {
    final store = AppScope.read(context);
    _search.clear();
    store.setSearch('');
    store.setCategory(null);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final cats = store.sortedCategories;
    final items = store.visibleProducts;
    final inCart = <String, int>{};
    for (final l in store.cart) {
      inCart[l.product.code] = (inCart[l.product.code] ?? 0) + l.qty;
    }
    final filtered = store.searchQuery.trim().isNotEmpty || store.activeCategoryId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: NvSearchField(
                controller: _search,
                hint: 'ค้นหาเมนู · รหัส · บาร์โค้ด',
                onChanged: (v) => AppScope.read(context).setSearch(v),
                onSubmitted: _submit,
              ),
            ),
            if (nvCameraScanSupported) ...[
              const SizedBox(width: 8),
              NvScanButton(title: 'สแกนเมนูเข้าตะกร้า', onScanned: _onCameraScan),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              NvChip(
                'ทั้งหมด',
                selected: store.activeCategoryId == null,
                count: store.products.length,
                onTap: () => AppScope.read(context).setCategory(null),
              ),
              for (final c in cats)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: NvChip(
                    c.name,
                    icon: c.icon,
                    selected: store.activeCategoryId == c.id,
                    count: store.productCountIn(c.id),
                    onTap: () => AppScope.read(context).setCategory(c.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: items.isEmpty
              ? NvEmptyState(
                  mascot: store.products.isEmpty ? 'empty' : 'search',
                  size: 120,
                  title: store.products.isEmpty ? 'ยังไม่มีเมนู' : 'ไม่พบเมนูที่ค้นหา',
                  message: store.products.isEmpty
                      ? 'เพิ่มสินค้าในหน้า "เมนูและสินค้า" หรือซิงก์จากเซิร์ฟเวอร์ก่อนเริ่มขาย'
                      : 'ลองคำค้นอื่น หรือเลือกหมวด "ทั้งหมด"',
                  actionLabel: store.products.isEmpty
                      ? (store.isManager ? 'ไปหน้าเมนู' : null)
                      : (filtered ? 'ล้างตัวกรอง' : null),
                  actionIcon: store.products.isEmpty ? NvIcons.menuBook : NvIcons.filter,
                  onAction: store.products.isEmpty ? () => context.go('/menu-editor') : _clearFilters,
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 6),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ProductRow(product: items[i], inCart: inCart[items[i].code] ?? 0),
                ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final int inCart;
  const _ProductRow({required this.product, required this.inCart});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final sellable = p.canSell;
    final status = !p.available ? 'งดขาย' : (p.isOutOfStock ? 'หมด' : null);
    return Opacity(
      opacity: sellable ? 1 : 0.55,
      child: NvSheet(
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        radius: Nv.rMd,
        selected: inCart > 0,
        onTap: sellable ? () => mobileAddProduct(context, p) : null,
        child: Row(
          children: [
            MobileProductThumb(p, size: 58),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(15, weight: FontWeight.w600, height: 1.25)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(baht(p.price), style: Nv.money(14.5, color: Nv.goldInk)),
                      if (status != null)
                        NvBadge(status, tint: NvTint.lacquer, dot: false)
                      else if (p.isLowStock)
                        NvBadge('เหลือ ${p.stock}', tint: NvTint.amber, dot: false),
                      if (p.hasOptions) const NvBadge('มีตัวเลือก', tint: NvTint.neutral, dot: false),
                      if (p.tag != null && p.tag!.isNotEmpty) NvBadge(p.tag!, tint: NvTint.gold, dot: false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (inCart > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(gradient: Nv.btnNavy, borderRadius: BorderRadius.circular(Nv.rPill)),
                child: Text('×$inCart', style: Nv.money(12.5, color: Nv.gold200)),
              ),
              const SizedBox(width: 8),
            ],
            _AddButton(onTap: sellable ? () => mobileAddProduct(context, p) : null),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Tooltip(
      message: on ? 'เพิ่มลงตะกร้า' : 'สั่งไม่ได้',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: on ? Nv.btnGold : null,
              color: on ? null : Nv.ivoryDeep,
              boxShadow: on ? Nv.goldGlow(0.6) : null,
            ),
            child: Icon(NvIcons.plus, size: 16, color: on ? const Color(0xFF1A1405) : Nv.ink4),
          ),
        ),
      ),
    );
  }
}

// ── tables ──

({Color fill, Color border, Color fg}) _tableTone(TableStatus s) => switch (s) {
      TableStatus.free => (fill: Nv.paper, border: Nv.line, fg: Nv.ink),
      TableStatus.seated => (fill: Nv.gold100, border: Nv.gold500, fg: Nv.goldInk),
      TableStatus.billing => (fill: Nv.lacquerTint, border: Nv.lacquer, fg: Nv.lacquerDeep),
      TableStatus.reserved => (fill: Nv.sapphireTint, border: Nv.sapphire, fg: Nv.sapphire),
    };

/// Table picker → points the counter cart at the chosen table (or none).
Future<void> mobilePickTable(BuildContext context) async {
  final store = AppScope.read(context);
  if (store.activeTicketIds.isNotEmpty) {
    nvToast(context, 'ตะกร้านี้เป็นบิลของโต๊ะ ${store.tableNumber ?? ''} ที่ส่งครัวแล้ว — ชำระเงินหรือล้างตะกร้าก่อนเปลี่ยนโต๊ะ',
        kind: NvToastKind.warning);
    return;
  }
  final picked = await showNvDialog<int>(
    context,
    title: 'เลือกโต๊ะ',
    subtitle: 'ตอนนี้: ${store.tableNumber == null ? 'ไม่ระบุโต๊ะ' : 'โต๊ะ ${store.tableNumber}'}',
    art: 'table',
    maxWidth: 560,
    body: const _TablePickerBody(),
    actions: (ctx) => [NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(ctx).pop())],
  );
  if (picked == null || !context.mounted) return;
  if (picked == 0) {
    store.setTable(null);
    return;
  }
  store.setTable(picked);
  final t = store.tableByNumber(picked);
  if (t != null && t.guests > 0) store.setGuests(t.guests);
}

class _TablePickerBody extends StatelessWidget {
  const _TablePickerBody();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final current = store.tableNumber;
    final zones = <String>[];
    for (final t in store.tables) {
      if (!zones.contains(t.zone)) zones.add(t.zone);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NvSheet(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          radius: Nv.rMd,
          color: Nv.paper,
          selected: current == null,
          onTap: () => Navigator.of(context).pop(0),
          child: Row(
            children: [
              const Icon(NvIcons.bag, size: 15, color: Nv.goldInk),
              const SizedBox(width: 10),
              Expanded(child: Text('ไม่ระบุโต๊ะ', style: Nv.ui(14.5, weight: FontWeight.w700))),
              Text('กลับบ้าน / ยังไม่เลือก', style: Nv.ui(12, color: Nv.ink3)),
            ],
          ),
        ),
        if (store.tables.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('ยังไม่มีโต๊ะในผังร้าน — ผู้จัดการเพิ่มได้ที่ "ออกแบบผังร้าน"',
                textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.ink3)),
          ),
        for (final z in zones) ...[
          const SizedBox(height: 14),
          Text(z, style: Nv.ui(13, color: Nv.ink3, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in store.tables.where((t) => t.zone == z)) _TableChoice(table: t, selected: t.number == current),
            ],
          ),
        ],
      ],
    );
  }
}

class _TableChoice extends StatelessWidget {
  final TableInfo table;
  final bool selected;
  const _TableChoice({required this.table, required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = table;
    final tone = _tableTone(t.status);
    final bill = AppScope.of(context).tableBillTotal(t.number);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Nv.rMd),
        onTap: () => Navigator.of(context).pop(t.number),
        child: Container(
          width: 84,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: tone.fill,
            borderRadius: BorderRadius.circular(Nv.rMd),
            border: Border.all(color: selected ? Nv.navy800 : tone.border, width: selected ? 2.4 : 1.2),
          ),
          child: Column(
            children: [
              Text('${t.number}', style: Nv.display(20, color: tone.fg, weight: FontWeight.w700)),
              Text(bill > 0 ? baht(bill) : t.status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bill > 0 ? Nv.money(11.5, color: tone.fg) : Nv.ui(11.5, color: tone.fg, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Table chip (opens the picker) + guests stepper.
class MobileTableBar extends StatelessWidget {
  const MobileTableBar({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final table = store.tableNumber;
    final bill = table == null ? 0 : store.tableBillTotal(table);
    return Row(
      children: [
        Expanded(
          child: NvSheet(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            radius: Nv.rMd,
            onTap: () => mobilePickTable(context),
            child: Row(
              children: [
                const Icon(NvIcons.chair, size: 15, color: Nv.goldInk),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(table == null ? 'เลือกโต๊ะ' : 'โต๊ะ $table',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15, weight: FontWeight.w700)),
                ),
                if (bill > 0) ...[
                  Text('ค้าง ${baht(bill)}', style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w600)),
                  const SizedBox(width: 6),
                ],
                const Icon(NvIcons.chevronDown, size: 12, color: Nv.ink3),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        NvSheet(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          radius: Nv.rMd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Tooltip(message: 'จำนวนลูกค้า', child: Icon(NvIcons.users, size: 14, color: Nv.goldInk)),
              const SizedBox(width: 6),
              NvStepper(
                value: store.guests,
                onMinus: store.guests > 1 ? () => AppScope.read(context).setGuests(store.guests - 1) : null,
                onPlus: store.guests < 99 ? () => AppScope.read(context).setGuests(store.guests + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One live cart line: stepper, note, remove (undo). When the cart is a table
/// bill already sent to the kitchen, decreasing / removing needs a manager.
class MobileCartLineTile extends StatelessWidget {
  final CartLine line;
  const MobileCartLineTile(this.line, {super.key});

  Future<bool> _approve(BuildContext context, String what) async {
    final store = AppScope.read(context);
    if (store.activeTicketIds.isEmpty) return true;
    final s = await showManagerPin(context, reason: '$what (รายการที่ส่งครัวแล้ว)');
    if (s == null) return false;
    store.log('void.line', '$what · อนุมัติโดย ${s.name}');
    return true;
  }

  Future<void> _dec(BuildContext context) async {
    final store = AppScope.read(context);
    final l = line;
    final ok = await _approve(context, 'ลด ${l.product.name} 1 ที่');
    if (!ok || !store.cart.contains(l)) return;
    store.decLine(l);
  }

  Future<void> _remove(BuildContext context) async {
    final store = AppScope.read(context);
    final l = line;
    final sent = store.activeTicketIds.isNotEmpty;
    final ok = await _approve(context, 'ลบ ${l.product.name} ×${l.qty}');
    if (!ok || !context.mounted || !store.cart.contains(l)) return;
    if (!sent) {
      // toast first: this tile leaves the tree once the line is gone
      nvToast(
        context,
        'ลบ ${l.product.name} ×${l.qty} แล้ว',
        actionLabel: 'เลิกทำ',
        onAction: () => store.addProduct(l.product, options: l.options, optionDelta: l.optionDelta, note: l.note, qty: l.qty),
      );
    }
    store.removeLine(l);
  }

  Future<void> _note(BuildContext context) async {
    final store = AppScope.read(context);
    final v = await showNvTextDialog(
      context,
      title: 'หมายเหตุ · ${line.product.name}',
      hint: 'เช่น ไม่เผ็ด · แยกน้ำ',
      initial: line.note,
      confirmLabel: 'บันทึก',
    );
    if (v == null || !store.cart.contains(line)) return;
    store.setLineNote(line, v);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l = line;
    final p = l.product;
    final sent = store.activeTicketIds.isNotEmpty;
    final inCart = store.cart.where((x) => x.product.code == p.code).fold<int>(0, (s, x) => s + x.qty);
    final canInc = !p.trackStock || inCart < p.stock;
    final detail = [...l.options, if (l.note.isNotEmpty) l.note].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MobileProductThumb(p, size: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(14.5, weight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(baht(l.lineTotal), style: Nv.money(15)),
                  ],
                ),
                if (detail.isNotEmpty)
                  Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.goldInk, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${baht(l.unitPrice)} / ที่', style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    NvStepper(
                      value: l.qty,
                      onMinus: () => _dec(context),
                      onPlus: canInc ? () => AppScope.read(context).incLine(l) : null,
                    ),
                    const Spacer(),
                    if (!sent) NvIconButton(NvIcons.note, size: 34, tooltip: 'หมายเหตุรายการ', onPressed: () => _note(context)),
                    const SizedBox(width: 6),
                    NvIconButton(NvIcons.trash, size: 34, color: Nv.lacquer, tooltip: 'ลบรายการ', onPressed: () => _remove(context)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _vatPct(double rate) {
  final p = rate * 100;
  return p == p.roundToDouble() ? p.round().toString() : p.toStringAsFixed(1);
}

/// Cart totals: subtotal, every discount, VAT, total.
class MobileTotals extends StatelessWidget {
  const MobileTotals({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final promo = store.appliedPromotion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NvKeyValue('ยอดรวม (${store.cartItemCount} รายการ)', baht(store.cartSubtotal)),
        if (store.couponDiscount > 0)
          NvKeyValue('คูปอง ${store.appliedCouponCode ?? ''}', baht(-store.couponDiscount), valueColor: Nv.jade),
        if (store.promoDiscount > 0)
          NvKeyValue('โปรโมชั่น${promo == null ? '' : ' · ${promo.name}'}', baht(-store.promoDiscount), valueColor: Nv.jade),
        if (store.memberDiscount > 0) NvKeyValue('ส่วนลดสมาชิก', baht(-store.memberDiscount), valueColor: Nv.jade),
        if (store.vatEnabled)
          NvKeyValue(
            store.vatInclusive ? 'VAT ${_vatPct(store.vatRate)}% (รวมในราคา)' : 'VAT ${_vatPct(store.vatRate)}%',
            baht(store.cartTax),
          ),
        const Divider(height: 18),
        NvKeyValue('ยอดชำระ', baht(store.cartTotal), strong: true),
      ],
    );
  }
}

/// Go to /payment when checkout is allowed, otherwise toast the reason
/// (with a shortcut to open the shift). True when navigating.
bool mobileGoToPayment(BuildContext context) {
  final store = AppScope.read(context);
  final why = store.checkoutBlockReason;
  if (why.isNotEmpty) {
    final router = GoRouter.of(context);
    final shift = store.cart.isNotEmpty && store.requireShift && !store.hasOpenShift;
    nvToast(context, why,
        kind: NvToastKind.warning, actionLabel: shift ? 'เปิดกะ' : null, onAction: shift ? () => router.go('/shift') : null);
    return false;
  }
  context.go('/payment');
  return true;
}

// ═════════════════════════ the waiter screen ═════════════════════════

typedef _SheetAction = ({bool pay, String note});

class MobileOrderScreen extends StatefulWidget {
  const MobileOrderScreen({super.key});

  @override
  State<MobileOrderScreen> createState() => _MobileOrderScreenState();
}

class _MobileOrderScreenState extends State<MobileOrderScreen> {
  bool _busy = false;

  Future<void> _openCart() async {
    final res = await showModalBottomSheet<_SheetAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SizedBox(height: MediaQuery.sizeOf(ctx).height * 0.86, child: const _CartSheet()),
    );
    if (res == null || !mounted) return;
    if (res.pay) {
      mobileGoToPayment(context);
    } else {
      await _send(res.note);
    }
  }

  Future<void> _send(String note) async {
    if (_busy) return;
    final store = AppScope.read(context);
    if (store.cart.isEmpty) return;
    if (store.activeTicketIds.isNotEmpty) {
      nvToast(context, 'ตะกร้านี้เป็นบิลโต๊ะที่ส่งครัวแล้ว — ชำระเงินหรือล้างตะกร้า', kind: NvToastKind.error);
      return;
    }
    _busy = true;
    try {
      if (store.orderType == OrderType.dineIn && store.tableNumber == null) {
        final ok = await showNvConfirm(
          context,
          title: 'ยังไม่ได้เลือกโต๊ะ',
          message: 'ส่งออเดอร์เข้าครัวโดยไม่ระบุโต๊ะ? บิลจะค้างไว้ชำระที่แคชเชียร์',
          confirmLabel: 'ส่งเลย',
          danger: false,
        );
        if (!ok || !mounted) return;
      }
      final t = store.sendCartToKitchen(source: OrderSource.mobile, note: note);
      if (t == null || !mounted) return;
      nvToast(
        context,
        'ส่งครัวแล้ว · ${t.id}${t.tableNumber != null ? ' · โต๊ะ ${t.tableNumber}' : ''} · ${t.itemCount} รายการ',
        kind: NvToastKind.success,
      );
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final label = [
      store.tableNumber == null ? 'ไม่ระบุโต๊ะ' : 'โต๊ะ ${store.tableNumber}',
      '${store.guests} ท่าน',
      if (store.linkedCustomer != null) store.linkedCustomer!.name,
    ].join(' · ');
    return NvScaffold(
      title: 'รับออเดอร์',
      art: 'qr',
      subtitle: 'สั่งอาหารข้างโต๊ะ · ส่งเข้าครัวทันที',
      actions: [NvIconButton(NvIcons.chair, tooltip: 'ผังโต๊ะ', onPressed: () => context.go('/tablet/floor'))],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MobileTableBar(),
              const SizedBox(height: 12),
              const Expanded(child: MobileCatalog()),
              const SizedBox(height: 10),
              _CartBar(count: store.cartItemCount, total: store.cartTotal, label: label, onOpen: _openCart),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final int count;
  final int total;
  final String label;
  final VoidCallback onOpen;
  const _CartBar({required this.count, required this.total, required this.label, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final empty = count == 0;
    return NvNightCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      onTap: empty ? null : onOpen,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(color: Nv.lineNight),
                ),
                child: const Icon(NvIcons.cart, size: 18, color: Nv.gold300),
              ),
              if (!empty)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: Nv.btnGold, borderRadius: BorderRadius.circular(10)),
                    child: Text(count > 99 ? '99+' : '$count', style: Nv.money(11, color: const Color(0xFF1A1405))),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(empty ? 'ยังไม่มีรายการ' : '$count รายการ', style: Nv.ui(14, color: Nv.onNight, weight: FontWeight.w700)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.onNight3)),
              ],
            ),
          ),
          Text(baht(total), style: Nv.money(19, color: Nv.gold200)),
          const SizedBox(width: 10),
          NvButton.gold('ตะกร้า', size: NvButtonSize.sm, trailing: NvIcons.chevronUp, onPressed: empty ? null : onOpen),
        ],
      ),
    );
  }
}

class _CartSheet extends StatefulWidget {
  const _CartSheet();

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _clear(BuildContext context) async {
    final store = AppScope.read(context);
    final sent = store.activeTicketIds.isNotEmpty;
    final ok = await showNvConfirm(
      context,
      title: 'ล้างตะกร้า?',
      message: sent
          ? 'นำบิลโต๊ะ ${store.tableNumber ?? ''} ออกจากตะกร้า — ออเดอร์ที่ส่งครัวแล้วยังค้างอยู่ครบ'
          : 'รายการ ${store.cartItemCount} รายการในตะกร้าจะถูกล้าง',
      confirmLabel: 'ล้างตะกร้า',
    );
    if (!ok) return;
    store.clearCart();
  }

  @override
  Widget build(BuildContext context) {
    // own messenger so toasts (e.g. undo remove) show above the sheet
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(builder: _content),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final store = AppScope.of(context);
    final lines = store.cart;
    final sent = store.activeTicketIds.isNotEmpty;
    final handle = Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(color: Nv.line, borderRadius: BorderRadius.circular(3)),
      ),
    );
    if (lines.isEmpty) {
      return Column(
        children: [
          handle,
          Expanded(
            child: NvEmptyState(
              mascot: 'empty',
              size: 130,
              title: 'ตะกร้ายังว่าง',
              message: 'แตะ + ที่เมนูเพื่อเพิ่มรายการ',
              actionLabel: 'กลับไปเลือกเมนู',
              onAction: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          handle,
          Row(
            children: [
              Text('ตะกร้า', style: Nv.display(21)),
              const SizedBox(width: 10),
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    NvBadge(store.tableNumber == null ? 'ไม่ระบุโต๊ะ' : 'โต๊ะ ${store.tableNumber}', tint: NvTint.navy, icon: NvIcons.chair),
                    NvBadge('${store.guests} ท่าน', tint: NvTint.neutral, icon: NvIcons.users),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: () => _clear(context),
                icon: const Icon(NvIcons.trash, size: 13, color: Nv.lacquer),
                label: Text('ล้าง', style: Nv.ui(13, color: Nv.lacquer, weight: FontWeight.w600)),
              ),
            ],
          ),
          if (sent)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Nv.amberTint,
                borderRadius: BorderRadius.circular(Nv.rSm),
                border: Border.all(color: Nv.amber.withValues(alpha: 0.5)),
              ),
              child: Text(
                'บิลโต๊ะ ${store.tableNumber ?? ''} ที่ส่งครัวแล้ว — ชำระเงินได้เลย (ลด/ลบรายการต้องให้ผู้จัดการอนุมัติ)',
                style: Nv.ui(12.5, color: const Color(0xFF8A5A00), weight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  MobileCartLineTile(lines[i], key: ObjectKey(lines[i])),
                ],
                const SizedBox(height: 10),
                if (!sent)
                  TextField(
                    controller: _note,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'หมายเหตุถึงครัว (ทั้งบิล)',
                      prefixIcon: Icon(NvIcons.note, size: 15),
                    ),
                  ),
                const SizedBox(height: 12),
                const MobileTotals(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: NvButton.navy(
                  'ส่งครัว',
                  icon: NvIcons.fire,
                  size: NvButtonSize.lg,
                  expand: true,
                  onPressed: sent ? null : () => Navigator.of(context).pop<_SheetAction>((pay: false, note: _note.text.trim())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NvButton.gold(
                  'ชำระเงิน',
                  icon: NvIcons.moneyBill,
                  size: NvButtonSize.lg,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop<_SheetAction>((pay: true, note: '')),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
