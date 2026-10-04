// Thaiprompt POS — Cashier (/cashier): the selling counter.
//
// Left: one search box that filters the catalog AND takes barcode-scanner
// input (Enter adds the scanned code, focus stays for the next scan, F2 jumps
// back to it), category chips with live counts + a best-seller chip, and a
// responsive product grid (food art / shop photo / category tile, stock and
// tag badges). Products with options open a picker (required single-choice
// groups, multi-choice toppings, price deltas, qty, note).
// Right: the navy cart panel — order type, table + guests, member link,
// editable lines (voiding a line already sent to the kitchen needs a manager
// PIN), coupon, live totals, held bills, open table bills, send to kitchen,
// and the gold pay button with the open-shift guard.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/catalog_models.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

// ─────────────────────────── shared helpers ───────────────────────────

bool _sameOpts(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Units of [l]'s exact item (code + options + note) that are already on an
/// open kitchen ticket being settled by this cart.
int _sentQty(PosStore s, CartLine l) {
  if (s.activeTicketIds.isEmpty) return 0;
  var n = 0;
  for (final id in s.activeTicketIds) {
    final t = s.ticketById(id);
    if (t == null || !t.isOpen) continue;
    for (final ol in t.lines) {
      if (ol.code == l.product.code && ol.note == l.note && _sameOpts(ol.options, l.options)) n += ol.qty;
    }
  }
  return n;
}

/// Units of [l]'s exact item across every cart line (ticket loads don't merge).
int _cartQtyForItem(PosStore s, CartLine l) => s.cart
    .where((x) => x.product.code == l.product.code && x.note == l.note && _sameOpts(x.options, l.options))
    .fold(0, (a, x) => a + x.qty);

/// True when removing [removeQty] units would void something the kitchen has.
bool _voidNeedsApproval(PosStore s, CartLine l, int removeQty) {
  final sent = _sentQty(s, l);
  return sent > 0 && _cartQtyForItem(s, l) - removeQty < sent;
}

int _qtyOfProduct(PosStore s, String code) =>
    s.cart.where((l) => l.product.code == code).fold(0, (a, l) => a + l.qty);

/// The only checkout blocker left is the closed shift.
bool _isShiftBlock(PosStore s) =>
    s.cart.isNotEmpty &&
    s.currentStaff != null &&
    s.currentStaff!.role.canSell &&
    s.requireShift &&
    !s.hasOpenShift;

String _addFailMessage(PosStore s, Product p, int qty) {
  if (!p.available) return '${p.name} ปิดการขายอยู่';
  if (p.isOutOfStock) return '${p.name} สินค้าหมด';
  if (p.trackStock && _qtyOfProduct(s, p.code) + qty > p.stock) {
    return 'สต็อก ${p.name} ไม่พอ · เหลือ ${p.stock} ชิ้น';
  }
  return 'สินค้าหมด/ไม่พร้อมขาย';
}

/// Ask for the opening float and open the shift. True when a shift is open now.
Future<bool> _offerOpenShift(BuildContext context) async {
  final store = AppScope.read(context);
  if (store.hasOpenShift) return true;
  final amount = await showNvAmountDialog(
    context,
    title: 'เปิดกะการขาย',
    subtitle: 'ร้านกำหนดให้เปิดกะก่อนรับชำระเงิน · ใส่เงินทอนตั้งต้นในลิ้นชัก',
    art: 'drawer',
    confirmLabel: 'เปิดกะ',
    initial: store.shiftHistory.isNotEmpty ? store.shiftHistory.first.openingCash : null,
  );
  if (amount == null || !context.mounted) return false;
  store.openShift(openingCash: amount);
  nvToast(context, 'เปิดกะแล้ว · เงินทอนตั้งต้น ${baht(amount)}', kind: NvToastKind.success);
  return true;
}

typedef _OptionPick = ({List<String> options, int delta, String note, int qty});

// ─────────────────────────── screen ───────────────────────────

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'cashier-search');
  bool _topOnly = false; // "ขายดี" chip
  bool _cartTab = false; // narrow layout: cart instead of the grid

  @override
  void initState() {
    super.initState();
    // keep the box in step with the store's filter when coming back here
    _search.text = AppScope.read(context).searchQuery;
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _focusSearch() {
    if (_cartTab) setState(() => _cartTab = false);
    _searchFocus.requestFocus();
    _search.selection = TextSelection(baseOffset: 0, extentOffset: _search.text.length);
  }

  void _clearSearch() {
    _search.clear();
    AppScope.read(context).setSearch('');
  }

  // ── product → cart ──

  Future<void> _tapProduct(Product p, {bool announce = false}) async {
    final store = AppScope.read(context);
    if (!p.canSell) {
      nvToast(context, _addFailMessage(store, p, 1), kind: NvToastKind.warning);
      return;
    }
    if (p.hasOptions) {
      final pick = await showNvDialog<_OptionPick>(
        context,
        title: p.name,
        subtitle: 'ราคาเริ่มต้น ${baht(p.price)} · เลือกตัวเลือกแล้วกดเพิ่มลงตะกร้า',
        maxWidth: 540,
        body: _OptionPicker(product: p),
      );
      if (pick == null || !mounted) return;
      final ok = store.addProduct(p, options: pick.options, optionDelta: pick.delta, note: pick.note, qty: pick.qty);
      if (!ok) {
        nvToast(context, _addFailMessage(store, p, pick.qty), kind: NvToastKind.warning);
      } else if (announce) {
        nvToast(context, 'เพิ่ม ${p.name} × ${pick.qty}', kind: NvToastKind.success);
      }
      return;
    }
    if (!store.addProduct(p)) {
      nvToast(context, _addFailMessage(store, p, 1), kind: NvToastKind.warning);
    } else if (announce) {
      nvToast(context, 'เพิ่ม ${p.name} · ${baht(p.price)}', kind: NvToastKind.success);
    }
  }

  /// Enter in the search box: barcode / SKU first, else a single search match.
  void _onSubmitted(String raw, List<Product> visible) {
    final store = AppScope.read(context);
    final code = raw.trim();
    _searchFocus.requestFocus(); // stay ready for the next scan
    if (code.isEmpty) return;
    final p = store.productByScan(code);
    if (p != null) {
      _clearSearch();
      _tapProduct(p, announce: true);
      return;
    }
    final sellable = visible.where((x) => x.canSell).toList();
    if (sellable.length == 1) {
      _clearSearch();
      _tapProduct(sellable.first, announce: true);
      return;
    }
    nvToast(context, 'ไม่พบสินค้ารหัส "$code"', kind: NvToastKind.error);
    _search.selection = TextSelection(baseOffset: 0, extentOffset: _search.text.length);
  }

  // ── filters ──

  List<Product> _visible(PosStore store, List<String> topNames) {
    final list = store.visibleProducts;
    if (_topOnly) {
      final ranked = list.where((p) => topNames.contains(p.name)).toList()
        ..sort((a, b) => topNames.indexOf(a.name).compareTo(topNames.indexOf(b.name)));
      return ranked;
    }
    return [...list.where((p) => p.canSell), ...list.where((p) => !p.canSell)];
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final platform = Theme.of(context).platform;
    final desktop = platform == TargetPlatform.windows || platform == TargetPlatform.macOS || platform == TargetPlatform.linux;
    final last = store.lastOrder;
    return NvScaffold(
      title: 'ขายสินค้า',
      eyebrow: '${store.shopName} · ${store.branch}',
      art: 'pos',
      actions: [
        if (last != null)
          NvButton.ghost('บิลล่าสุด ${last.id}',
              icon: NvIcons.receipt, size: NvButtonSize.sm, onPressed: () => context.go('/receipt?id=${last.id}')),
      ],
      body: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.f2): _focusSearch},
        child: Focus(
          autofocus: !desktop,
          child: LayoutBuilder(builder: (context, c) {
            if (c.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: NvSegmented<bool>(
                        options: [
                          (false, 'สินค้า'),
                          (true, 'ตะกร้า ${store.cartItemCount} ชิ้น · ${baht(store.cartTotal)}'),
                        ],
                        value: _cartTab,
                        onChanged: (v) => setState(() => _cartTab = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _cartTab ? const _CartPanel() : _catalog(store, desktop)),
                ],
              );
            }
            final cartW = (c.maxWidth * 0.34).clamp(330.0, 430.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _catalog(store, desktop)),
                const SizedBox(width: 16),
                SizedBox(width: cartW, child: const _CartPanel()),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _catalog(PosStore store, bool desktop) {
    if (store.products.isEmpty) return _EmptyCatalog(isManager: store.isManager);
    final topNames = store.topProducts(limit: 12).map((e) => e.name).toList();
    final items = _visible(store, topNames);
    final inCart = <String, int>{};
    for (final l in store.cart) {
      inCart[l.product.code] = (inCart[l.product.code] ?? 0) + l.qty;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSearchField(
          hint: 'ค้นหาชื่อ / รหัส หรือสแกนบาร์โค้ด  (F2)',
          controller: _search,
          focusNode: _searchFocus,
          autofocus: desktop,
          icon: NvIcons.barcode,
          onChanged: (v) => AppScope.read(context).setSearch(v),
          onSubmitted: (v) => _onSubmitted(v, items),
        ),
        const SizedBox(height: 10),
        SizedBox(height: 40, child: _chips(store, topNames)),
        const SizedBox(height: 12),
        Expanded(child: items.isEmpty ? _noResults(store) : _grid(store, items, inCart)),
      ],
    );
  }

  Widget _chips(PosStore store, List<String> topNames) {
    final cats = store.sortedCategories;
    final topCount = store.products.where((p) => topNames.contains(p.name)).length;
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        NvChip(
          'ทั้งหมด',
          icon: NvIcons.grid,
          count: store.products.length,
          selected: !_topOnly && store.activeCategoryId == null,
          onTap: () {
            setState(() => _topOnly = false);
            AppScope.read(context).setCategory(null);
          },
        ),
        const SizedBox(width: 8),
        NvChip(
          'ขายดี',
          icon: NvIcons.fire,
          count: topCount,
          selected: _topOnly,
          onTap: () {
            setState(() => _topOnly = true);
            AppScope.read(context).setCategory(null);
          },
        ),
        for (final c in cats) ...[
          const SizedBox(width: 8),
          NvChip(
            c.name,
            icon: c.icon,
            count: store.productCountIn(c.id),
            selected: !_topOnly && store.activeCategoryId == c.id,
            onTap: () {
              setState(() => _topOnly = false);
              AppScope.read(context).setCategory(c.id);
            },
          ),
        ],
      ],
    );
  }

  Widget _noResults(PosStore store) {
    if (store.searchQuery.trim().isNotEmpty) {
      return NvEmptyState(
        mascot: 'search',
        size: 130,
        title: 'ไม่พบ "${store.searchQuery.trim()}"',
        message: 'ลองค้นด้วยชื่อ รหัสสินค้า หรือสแกนบาร์โค้ดอีกครั้ง',
        actionLabel: 'ล้างคำค้น',
        actionIcon: NvIcons.xmark,
        onAction: () {
          _clearSearch();
          _searchFocus.requestFocus();
        },
      );
    }
    if (_topOnly) {
      return NvEmptyState(
        mascot: 'search',
        size: 130,
        title: 'ยังไม่มีสินค้าขายดี',
        message: 'อันดับขายดีจะแสดงเมื่อมีบิลที่ชำระเงินแล้ว',
        actionLabel: 'ดูสินค้าทั้งหมด',
        onAction: () {
          setState(() => _topOnly = false);
          AppScope.read(context).setCategory(null);
        },
      );
    }
    return NvEmptyState(
      mascot: 'empty',
      size: 130,
      title: 'ยังไม่มีสินค้าในหมวดนี้',
      message: store.isManager ? 'เพิ่มสินค้าในหมวดนี้ได้ที่หน้า "เมนูและสินค้า"' : 'เลือกหมวดอื่น หรือดูสินค้าทั้งหมด',
      actionLabel: 'ดูสินค้าทั้งหมด',
      onAction: () => AppScope.read(context).setCategory(null),
    );
  }

  Widget _grid(PosStore store, List<Product> items, Map<String, int> inCart) {
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / 172).floor().clamp(2, 8);
      return GridView.builder(
        padding: const EdgeInsets.only(top: 2, bottom: 12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 216,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final p = items[i];
          return _ProductCard(
            product: p,
            category: store.categoryById(p.categoryId),
            inCart: inCart[p.code] ?? 0,
            onTap: () => _tapProduct(p),
          );
        },
      );
    });
  }
}

// ─────────────────────────── catalog pieces ───────────────────────────

class _EmptyCatalog extends StatelessWidget {
  final bool isManager;
  const _EmptyCatalog({required this.isManager});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NvArt.mascot('empty', height: 160),
            const SizedBox(height: 12),
            Text('ยังไม่มีเมนูสินค้า', textAlign: TextAlign.center, style: Nv.display(20)),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                isManager
                    ? 'เพิ่มเมนูและราคาเองที่หน้า "เมนูและสินค้า" หรือจับคู่เครื่องกับเซิร์ฟเวอร์ Thai Prompt ที่หน้าตั้งค่า เพื่อดึงสินค้าของร้านมาอัตโนมัติ'
                    : 'ให้ผู้จัดการเพิ่มเมนูที่หน้า "เมนูและสินค้า" หรือจับคู่เครื่องกับเซิร์ฟเวอร์ก่อนเริ่มขาย',
                textAlign: TextAlign.center,
                style: Nv.ui(13.5, color: Nv.ink3, height: 1.45),
              ),
            ),
            if (isManager) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  NvButton.gold('เพิ่มเมนู', icon: NvIcons.plus, onPressed: () => context.go('/menu-editor')),
                  NvButton.ghost('จับคู่เซิร์ฟเวอร์', icon: NvIcons.server, onPressed: () => context.go('/settings')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final Category? category;
  final int inCart;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.category, required this.inCart, required this.onTap});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final sellable = p.canSell;
    final lift = _hover && sellable;
    final br = BorderRadius.circular(Nv.rMd);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: Nv.fast,
        decoration: BoxDecoration(
          color: Nv.ivory2,
          borderRadius: br,
          border: Border.all(color: lift ? Nv.gold500 : Nv.lineSoft, width: lift ? 1.4 : 1),
          boxShadow: lift ? Nv.shadowLift : Nv.shadowSheet,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: br,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Nv.rSm),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _ProductPicture(product: p, category: widget.category),
                          if (p.tag != null && p.tag!.isNotEmpty)
                            Positioned(left: 6, top: 6, child: NvBadge(p.tag!, tint: NvTint.gold, dot: false)),
                          if (sellable && p.isLowStock)
                            Positioned(right: 6, top: 6, child: NvBadge('เหลือ ${p.stock}', tint: NvTint.amber, dot: false)),
                          if (p.hasOptions)
                            Positioned(
                              left: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Nv.navy900.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(Nv.rPill),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(NvIcons.sliders, size: 10, color: Nv.gold300),
                                    const SizedBox(width: 4),
                                    Text('ตัวเลือก', style: Nv.ui(10.5, color: Nv.gold200, weight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          if (widget.inCart > 0)
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 26),
                                height: 26,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: Nv.btnGold,
                                  borderRadius: BorderRadius.circular(13),
                                  boxShadow: Nv.goldGlow(0.6),
                                ),
                                child: Text('${widget.inCart}', style: Nv.money(12.5, color: const Color(0xFF1A1405))),
                              ),
                            ),
                          if (!sellable)
                            Positioned.fill(
                              child: Container(
                                color: Nv.navy950.withValues(alpha: 0.55),
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(gradient: Nv.btnLacquer, borderRadius: BorderRadius.circular(Nv.rPill)),
                                  child: Text(p.available ? 'สินค้าหมด' : 'ปิดการขาย',
                                      style: Nv.ui(12.5, color: Colors.white, weight: FontWeight.w700)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Nv.ui(13.5, color: sellable ? Nv.ink : Nv.ink3, weight: FontWeight.w600, height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(baht(p.price), style: Nv.money(16, color: sellable ? Nv.goldInk : Nv.ink4)),
                      const Spacer(),
                      if (sellable && p.trackStock && !p.isLowStock)
                        Flexible(
                          child: Text('คงเหลือ ${groupDigits(p.stock)}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11, color: Nv.ink4)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Product picture: food art → shop photo → navy/gold category tile.
class _ProductPicture extends StatelessWidget {
  final Product product;
  final Category? category;
  const _ProductPicture({required this.product, required this.category});

  Widget _tile() => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Nv.navy700, Nv.navy900],
          ),
        ),
        child: Center(
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Nv.lineNightStrong),
            ),
            child: Icon(category?.icon ?? NvIcons.tag, size: 24, color: Nv.gold300),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final art = product.art;
    if (art != null && art.isNotEmpty) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Nv.gold100, Nv.ivoryDeep],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: NvArt(NvAssets.food(art), fallbackIcon: category?.icon ?? NvIcons.tag),
        ),
      );
    }
    final url = product.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _tile(),
        loadingBuilder: (_, child, progress) => progress == null ? child : _tile(),
      );
    }
    return _tile();
  }
}

// ─────────────────────────── option picker ───────────────────────────

class _OptionPicker extends StatefulWidget {
  final Product product;
  const _OptionPicker({required this.product});

  @override
  State<_OptionPicker> createState() => _OptionPickerState();
}

class _OptionPickerState extends State<_OptionPicker> {
  late final List<Set<int>> _sel = [for (var i = 0; i < widget.product.options.length; i++) <int>{}];
  final _note = TextEditingController();
  int _qty = 1;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<OptionGroup> get _groups => widget.product.options;

  int get _delta {
    var d = 0;
    for (var g = 0; g < _groups.length; g++) {
      for (final i in _sel[g]) {
        d += _groups[g].choices[i].priceDelta;
      }
    }
    return d;
  }

  /// Labels in catalog order (group order, then choice order) so identical
  /// picks always merge into the same cart line.
  List<String> get _labels => [
        for (var g = 0; g < _groups.length; g++)
          for (var i = 0; i < _groups[g].choices.length; i++)
            if (_sel[g].contains(i)) _groups[g].choices[i].label,
      ];

  String? get _missing {
    for (var g = 0; g < _groups.length; g++) {
      if (_groups[g].required && _sel[g].isEmpty) return _groups[g].name;
    }
    return null;
  }

  void _toggle(int g, int i) {
    final group = _groups[g];
    setState(() {
      if (group.multi) {
        if (!_sel[g].remove(i)) _sel[g].add(i);
      } else if (_sel[g].contains(i)) {
        if (!group.required) _sel[g].clear();
      } else {
        _sel[g]
          ..clear()
          ..add(i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = widget.product;
    final inCart = _qtyOfProduct(store, p.code);
    final canPlus = !p.trackStock || inCart + _qty + 1 <= p.stock;
    final missing = _missing;
    final unit = p.price + _delta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var g = 0; g < _groups.length; g++) ...[
          Row(
            children: [
              Flexible(child: Text(_groups[g].name, style: Nv.ui(14.5, weight: FontWeight.w700))),
              const SizedBox(width: 8),
              if (_groups[g].required)
                NvBadge(_sel[g].isEmpty ? 'ต้องเลือก' : 'เลือกแล้ว',
                    tint: _sel[g].isEmpty ? NvTint.lacquer : NvTint.jade, dot: false)
              else
                NvBadge(_groups[g].multi ? 'เลือกได้หลายอย่าง' : 'ไม่บังคับ', tint: NvTint.neutral, dot: false),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _groups[g].choices.length; i++)
                _ChoicePill(
                  choice: _groups[g].choices[i],
                  selected: _sel[g].contains(i),
                  multi: _groups[g].multi,
                  onTap: () => _toggle(g, i),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Text('จำนวน', style: Nv.ui(14.5, weight: FontWeight.w700)),
            const Spacer(),
            NvStepper(
              value: _qty,
              onMinus: _qty > 1 ? () => setState(() => _qty--) : null,
              onPlus: canPlus ? () => setState(() => _qty++) : null,
            ),
          ],
        ),
        if (p.trackStock)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('คงเหลือ ${p.stock} ชิ้น${inCart > 0 ? ' · ในตะกร้าแล้ว $inCart' : ''}',
                textAlign: TextAlign.right, style: Nv.ui(11.5, color: Nv.ink3)),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLines: 1,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'หมายเหตุ (ไม่บังคับ) เช่น ไม่ใส่น้ำแข็ง · เผ็ดน้อย',
            prefixIcon: Icon(NvIcons.note, size: 15),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(missing != null ? 'กรุณาเลือก "$missing"' : 'รวม ${baht(unit)} × $_qty',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Nv.ui(13, color: missing != null ? Nv.lacquer : Nv.ink3, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Text(baht(unit * _qty), style: Nv.money(24)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            NvButton.gold(
              'เพิ่มลงตะกร้า',
              icon: NvIcons.cart,
              onPressed: missing != null
                  ? null
                  : () => Navigator.of(context).pop<_OptionPick>(
                        (options: _labels, delta: _delta, note: _note.text.trim(), qty: _qty),
                      ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final OptionChoice choice;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;
  const _ChoicePill({required this.choice, required this.selected, required this.multi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = choice.priceDelta;
    final br = BorderRadius.circular(Nv.rPill);
    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Nv.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? Nv.btnNavy : null,
            color: selected ? null : Nv.paper,
            borderRadius: br,
            border: Border.all(color: selected ? Nv.gold500.withValues(alpha: 0.8) : Nv.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                multi ? (selected ? NvIcons.squareCheck : NvIcons.square) : (selected ? NvIcons.checkCircle : NvIcons.circle),
                size: 14,
                color: selected ? Nv.gold300 : Nv.ink4,
              ),
              const SizedBox(width: 8),
              Text(choice.label,
                  style: Nv.ui(13.5, color: selected ? Nv.gold200 : Nv.ink2, weight: selected ? FontWeight.w700 : FontWeight.w500)),
              if (d != 0) ...[
                const SizedBox(width: 6),
                Text(d > 0 ? '+${baht(d)}' : baht(d), style: Nv.money(12.5, color: selected ? Nv.gold300 : Nv.goldInk)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── cart panel ───────────────────────────

class _CartPanel extends StatefulWidget {
  const _CartPanel();

  @override
  State<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<_CartPanel> {
  // ── order context ──

  Future<void> _pickTable() async {
    final store = AppScope.read(context);
    final picked = await showNvDialog<int>(
      context,
      title: 'เลือกโต๊ะ',
      subtitle: 'แตะโต๊ะที่ลูกค้านั่ง',
      art: 'table',
      maxWidth: 600,
      body: const _TablePickerBody(),
      actions: (ctx) => [NvButton.soft('ปิด', onPressed: () => Navigator.of(ctx).pop())],
    );
    if (picked == null || !mounted) return;
    store.setTable(picked < 0 ? null : picked);
  }

  Future<void> _pickMember() async {
    final store = AppScope.read(context);
    final c = await showNvDialog<Customer>(
      context,
      title: 'สมาชิก',
      subtitle: 'ค้นหาด้วยเบอร์โทรหรือชื่อ หรือเพิ่มสมาชิกใหม่',
      art: 'member',
      maxWidth: 520,
      body: const _MemberPickerBody(),
      actions: (ctx) => [NvButton.soft('ปิด', onPressed: () => Navigator.of(ctx).pop())],
    );
    if (c == null || !mounted) return;
    store.linkCustomer(c);
    final tier = store.tierFor(c);
    nvToast(
      context,
      'ผูกสมาชิก ${c.name} (${tier.name}${tier.discountPercent > 0 ? ' ลด ${tier.discountPercent}%' : ''}) กับบิลนี้แล้ว',
      kind: NvToastKind.success,
    );
  }

  Future<void> _coupon() async {
    final ok = await showNvDialog<bool>(
      context,
      title: 'คูปองส่วนลด',
      art: 'coupon',
      maxWidth: 500,
      body: const _CouponBody(),
      actions: (ctx) => [NvButton.soft('ปิด', onPressed: () => Navigator.of(ctx).pop())],
    );
    if (ok != true || !mounted) return;
    final s = AppScope.read(context);
    nvToast(context, 'ใช้คูปอง ${s.appliedCouponCode ?? ''} · ลด ${baht(s.couponDiscount)}', kind: NvToastKind.success);
  }

  // ── lines ──

  void _inc(CartLine l) {
    final store = AppScope.read(context);
    final p = l.product;
    if (p.trackStock && _qtyOfProduct(store, p.code) + 1 > p.stock) {
      nvToast(context, 'สต็อก ${p.name} ไม่พอ · เหลือ ${p.stock} ชิ้น', kind: NvToastKind.warning);
      return;
    }
    store.incLine(l);
  }

  Future<void> _dec(CartLine l) async {
    final store = AppScope.read(context);
    if (_voidNeedsApproval(store, l, 1)) {
      final mgr = await showManagerPin(context, reason: 'ลดจำนวน ${l.product.name} ที่ส่งครัวแล้ว');
      if (mgr == null || !mounted || !store.cart.contains(l)) return;
      store.log('void.line', '${l.product.name} -1 · อนุมัติโดย ${mgr.name}');
    }
    store.decLine(l);
  }

  Future<void> _remove(CartLine l) async {
    final store = AppScope.read(context);
    if (!_voidNeedsApproval(store, l, l.qty)) {
      store.removeLine(l);
      return;
    }
    final ok = await showNvConfirm(
      context,
      title: 'ลบรายการที่ส่งครัวแล้ว?',
      message: '${l.product.name} × ${l.qty} ถูกส่งเข้าครัวแล้ว การลบต้องได้รับอนุมัติจากผู้จัดการ',
      confirmLabel: 'ขออนุมัติและลบ',
    );
    if (!ok || !mounted) return;
    final mgr = await showManagerPin(context, reason: 'ลบ ${l.product.name} ที่ส่งครัวแล้ว');
    if (mgr == null || !mounted || !store.cart.contains(l)) return;
    store.log('void.line', '${l.product.name} ×${l.qty} · อนุมัติโดย ${mgr.name}');
    store.removeLine(l);
    nvToast(context, 'ลบ ${l.product.name} แล้ว · อนุมัติโดย ${mgr.name}', kind: NvToastKind.success);
  }

  Future<void> _editNote(CartLine l) async {
    final store = AppScope.read(context);
    final v = await showNvTextDialog(
      context,
      title: 'หมายเหตุ · ${l.product.name}',
      subtitle: 'เช่น ไม่ใส่ผัก · เผ็ดน้อย · แยกน้ำ',
      initial: l.note,
      hint: 'พิมพ์หมายเหตุ',
    );
    if (v == null || !mounted || !store.cart.contains(l)) return;
    store.setLineNote(l, v);
  }

  // ── bill actions ──

  Future<void> _clear() async {
    final store = AppScope.read(context);
    if (store.cart.isEmpty) return;
    final fromTicket = store.activeTicketIds.isNotEmpty;
    final ok = await showNvConfirm(
      context,
      title: fromTicket ? 'นำบิลโต๊ะออกจากตะกร้า?' : 'ล้างตะกร้า?',
      message: fromTicket
          ? 'ออเดอร์ยังค้างอยู่ในระบบ (ไม่ได้ถูกยกเลิก) เรียกบิลใหม่ได้ภายหลังที่ปุ่ม "เรียกบิล"'
          : 'ลบสินค้าทั้งหมด ${store.cartItemCount} ชิ้น พร้อมคูปองและสมาชิกที่ผูกไว้ออกจากบิลนี้',
      confirmLabel: fromTicket ? 'นำออก' : 'ล้างตะกร้า',
    );
    if (!ok || !mounted) return;
    final table = store.tableNumber;
    store.clearCart();
    // loading a table bill marks it "รอเช็คบิล" — put it back while it still has orders
    if (fromTicket && table != null) {
      final t = store.tableByNumber(table);
      if (t != null && t.status == TableStatus.billing && store.openTicketsForTable(table).isNotEmpty) {
        store.setTableStatus(t, TableStatus.seated);
      }
    }
  }

  Future<void> _hold() async {
    final store = AppScope.read(context);
    if (store.cart.isEmpty) return;
    if (store.activeTicketIds.isNotEmpty) {
      nvToast(context, 'บิลนี้เรียกมาจากออเดอร์ในครัว ไม่ต้องพัก — กด "ล้าง" แล้วเรียกบิลใหม่ภายหลังได้', kind: NvToastKind.info);
      return;
    }
    final label = await showNvTextDialog(
      context,
      title: 'พักบิล',
      subtitle: 'ตั้งชื่อเพื่อเรียกคืนง่าย (ไม่บังคับ) เช่น ชื่อลูกค้า หรือเลขคิว',
      hint: store.tableNumber != null ? 'โต๊ะ ${store.tableNumber}' : 'บิลพัก ${store.heldCarts.length + 1}',
      confirmLabel: 'พักบิล',
      art: 'receipt',
    );
    if (label == null || !mounted) return;
    final h = store.holdCart(label: label);
    if (h != null) nvToast(context, 'พักบิล "${h.label}" แล้ว · ${baht(h.total)}', kind: NvToastKind.success);
  }

  Future<void> _held() async {
    final h = await showNvDialog<HeldCart>(
      context,
      title: 'บิลที่พักไว้',
      art: 'receipt',
      maxWidth: 580,
      body: const _HeldBody(),
      actions: (ctx) => [NvButton.soft('ปิด', onPressed: () => Navigator.of(ctx).pop())],
    );
    if (h == null || !mounted) return;
    final store = AppScope.read(context);
    if (store.activeTicketIds.isNotEmpty) {
      final ok = await showNvConfirm(
        context,
        title: 'นำบิลโต๊ะออกก่อน?',
        message: 'ตะกร้าตอนนี้เป็นบิลที่เรียกจากออเดอร์ในครัว ระบบจะนำออกจากตะกร้า (ออเดอร์ยังค้างอยู่ เรียกใหม่ได้) แล้วเรียก "${h.label}" ขึ้นมาแทน',
        confirmLabel: 'เรียกบิลที่พักไว้',
        danger: false,
      );
      if (!ok || !mounted) return;
      store.clearCart();
    } else if (store.cart.isNotEmpty) {
      final ok = await showNvConfirm(
        context,
        title: 'พักบิลปัจจุบันก่อน?',
        message: 'สินค้าในตะกร้าตอนนี้ (${store.cartItemCount} ชิ้น) จะถูกพักเป็นบิลใหม่ แล้วเรียก "${h.label}" ขึ้นมาแทน',
        confirmLabel: 'พักแล้วเรียกคืน',
        danger: false,
      );
      if (!ok || !mounted) return;
    }
    if (!store.heldCarts.contains(h)) return;
    final missing = h.lines.where((j) => store.productByCode('${j['code']}') == null).length;
    store.resumeHeld(h);
    nvToast(
      context,
      'เรียกบิล "${h.label}" แล้ว${missing > 0 ? ' · ข้าม $missing รายการที่ถูกลบออกจากเมนู' : ''}',
      kind: missing > 0 ? NvToastKind.warning : NvToastKind.success,
    );
  }

  Future<void> _openBills() async {
    final pick = await showNvDialog<Object>(
      context,
      title: 'เรียกบิล',
      subtitle: 'ออเดอร์ที่ส่งครัวแล้วและยังไม่ได้ชำระเงิน',
      art: 'table',
      maxWidth: 580,
      body: const _OpenBillsBody(),
      actions: (ctx) => [NvButton.soft('ปิด', onPressed: () => Navigator.of(ctx).pop())],
    );
    if (pick == null || !mounted) return;
    final store = AppScope.read(context);
    if (store.cart.isNotEmpty && store.activeTicketIds.isEmpty) {
      final ok = await showNvConfirm(
        context,
        title: 'พักบิลปัจจุบันก่อน?',
        message: 'ตะกร้ามีสินค้า ${store.cartItemCount} ชิ้นที่ยังไม่ได้ชำระ ระบบจะพักบิลนี้ไว้ก่อน แล้วเรียกบิลที่เลือกขึ้นมา',
        confirmLabel: 'พักแล้วเรียกบิล',
        danger: false,
      );
      if (!ok || !mounted) return;
      store.holdCart();
    }
    if (pick is int) {
      if (!store.loadTableToCart(pick)) {
        nvToast(context, 'โต๊ะ $pick ไม่มีออเดอร์ค้างแล้ว', kind: NvToastKind.warning);
        return;
      }
      nvToast(context, 'เรียกบิลโต๊ะ $pick · ${baht(store.cartTotal)}', kind: NvToastKind.success);
    } else if (pick is Ticket) {
      if (!pick.isOpen) {
        nvToast(context, 'ออเดอร์ ${pick.id} ถูกปิดไปแล้ว', kind: NvToastKind.warning);
        return;
      }
      store.loadTicketToCart(pick);
      nvToast(context, 'เรียกบิล ${pick.id} · ${baht(store.cartTotal)}', kind: NvToastKind.success);
    }
  }

  Future<void> _sendKitchen() async {
    final store = AppScope.read(context);
    if (store.cart.isEmpty) return;
    if (store.activeTicketIds.isNotEmpty) {
      nvToast(context, 'รายการนี้อยู่ในครัวแล้ว — รับชำระเงินได้เลย', kind: NvToastKind.info);
      return;
    }
    if (store.orderType == OrderType.delivery) {
      nvToast(context, 'เดลิเวอรี่ให้รับชำระก่อน แล้วสร้างงานจัดส่งจากหน้าใบเสร็จ', kind: NvToastKind.info);
      return;
    }
    if (store.orderType == OrderType.dineIn && store.tableNumber == null) {
      nvToast(context, 'เลือกโต๊ะก่อนส่งครัว', kind: NvToastKind.info);
      await _pickTable();
      if (!mounted || store.tableNumber == null || store.cart.isEmpty) return;
    }
    final kitchen = store.kitchenEnabled;
    final t = store.sendCartToKitchen(
      source: store.orderType == OrderType.dineIn ? OrderSource.table : OrderSource.counter,
    );
    if (t == null) return;
    // the ticket keeps the member's name; don't let the link leak into the next bill
    store.linkCustomer(null);
    nvToast(
      context,
      '${kitchen ? 'ส่งครัวแล้ว' : 'เปิดบิลค้างแล้ว'} · ${t.id} · ${t.tableNumber != null ? 'โต๊ะ ${t.tableNumber}' : 'กลับบ้าน'} — ชำระได้ที่ปุ่ม "เรียกบิล"',
      kind: NvToastKind.success,
    );
  }

  bool _paying = false;

  Future<void> _pay() async {
    final store = AppScope.read(context);
    if (store.cart.isEmpty || _paying) return;
    if (_isShiftBlock(store)) {
      nvToast(context, store.checkoutBlockReason, kind: NvToastKind.warning);
      _paying = true;
      final opened = await _offerOpenShift(context);
      _paying = false;
      if (!opened || !mounted) return;
    }
    final reason = store.checkoutBlockReason;
    if (reason.isNotEmpty) {
      nvToast(context, reason, kind: NvToastKind.warning);
      return;
    }
    context.go('/payment');
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final open = store.openTickets;
    final openBills = {for (final t in open) if (t.tableNumber != null) t.tableNumber}.length +
        open.where((t) => t.tableNumber == null).length;
    final fromTicket = store.activeTicketIds.isNotEmpty;
    final dineIn = store.orderType == OrderType.dineIn;

    return NvNightCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: LayoutBuilder(builder: (context, c) {
        final compact = c.maxHeight < 620;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ออเดอร์ ${store.openOrderId}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.display(17, color: Nv.onNight)),
                      Text('${store.currentStaff?.name ?? '—'} · ${store.cartItemCount} ชิ้น',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.onNight3)),
                    ],
                  ),
                ),
                NvIconButton(NvIcons.layers,
                    size: 38, onNight: true, badge: store.heldCarts.length, tooltip: 'บิลที่พักไว้', onPressed: _held),
                const SizedBox(width: 6),
                NvIconButton(NvIcons.bellConcierge,
                    size: 38, onNight: true, badge: openBills, tooltip: 'เรียกบิลโต๊ะ / ออเดอร์ค้าง', onPressed: _openBills),
                const SizedBox(width: 6),
                NvIconButton(NvIcons.trash,
                    size: 38, onNight: true, tooltip: 'ล้างตะกร้า', onPressed: store.cart.isEmpty ? null : _clear),
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NvSegmented<OrderType>(
                  onNight: true,
                  options: [for (final t in OrderType.values) (t, t.label)],
                  value: store.orderType,
                  onChanged: (t) {
                    final s = AppScope.read(context);
                    if (t == s.orderType) return;
                    if (s.activeTicketIds.isNotEmpty) {
                      // settling a table/kitchen bill keeps its type so the table is freed on payment
                      nvToast(context, 'บิลที่เรียกจากออเดอร์ในครัวเปลี่ยนประเภทไม่ได้', kind: NvToastKind.info);
                      return;
                    }
                    s.setOrderType(t);
                  },
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            if (dineIn) ...[
              Row(
                children: [
                  Expanded(
                    child: _NightPill(
                      icon: NvIcons.chair,
                      label: store.tableNumber == null ? 'เลือกโต๊ะ' : 'โต๊ะ ${store.tableNumber}',
                      highlight: store.tableNumber != null,
                      onTap: fromTicket ? null : _pickTable,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(NvIcons.users, size: 13, color: Nv.onNight3),
                  const SizedBox(width: 4),
                  NvStepper(
                    value: store.guests,
                    onNight: true,
                    onMinus: store.guests > 1 ? () => AppScope.read(context).setGuests(store.guests - 1) : null,
                    onPlus: () => AppScope.read(context).setGuests(store.guests + 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            _memberRow(store),
            Divider(height: compact ? 14 : 20, color: Nv.lineNight),
            Expanded(
              child: store.cart.isEmpty
                  ? const _EmptyCart()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: store.cart.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: Nv.lineNight),
                      itemBuilder: (context, i) {
                        final l = store.cart[i];
                        return _CartLineRow(
                          line: l,
                          sentQty: fromTicket ? _sentQty(store, l) : 0,
                          onMinus: () => _dec(l),
                          onPlus: () => _inc(l),
                          onNote: () => _editNote(l),
                          onRemove: () => _remove(l),
                        );
                      },
                    ),
            ),
            Divider(height: compact ? 14 : 20, color: Nv.lineNight),
            _totals(store, compact),
            SizedBox(height: compact ? 8 : 12),
            Row(
              children: [
                Expanded(
                  child: _NightAction(
                    icon: NvIcons.coupon,
                    label: store.appliedCouponCode ?? 'คูปอง',
                    active: store.appliedCouponCode != null,
                    onTap: store.cart.isEmpty ? null : _coupon,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NightAction(
                    icon: NvIcons.fire,
                    label: store.kitchenEnabled ? 'ส่งครัว' : 'เปิดบิลค้าง',
                    onTap: store.cart.isEmpty || fromTicket || store.orderType == OrderType.delivery ? null : _sendKitchen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NightAction(
                    icon: NvIcons.pause,
                    label: 'พักบิล',
                    onTap: store.cart.isEmpty || fromTicket ? null : _hold,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            NvButton.gold(
              store.cart.isEmpty ? 'ชำระเงิน' : 'ชำระเงิน ${baht(store.cartTotal)}',
              icon: NvIcons.circleDollar,
              size: compact ? NvButtonSize.lg : NvButtonSize.xl,
              expand: true,
              onPressed: store.cart.isEmpty ? null : _pay,
            ),
          ],
        );
      }),
    );
  }

  Widget _memberRow(PosStore store) {
    final c = store.linkedCustomer;
    final unlink = NvIconButton(
      NvIcons.xmark,
      size: 30,
      onNight: true,
      tooltip: 'ยกเลิกการผูกสมาชิก',
      onPressed: () => AppScope.read(context).linkCustomer(null),
    );
    if (c == null) {
      if (store.customerName != null) {
        return _NightPill(icon: NvIcons.user, label: store.customerName!, caption: 'ลูกค้า (ไม่ใช่สมาชิก)', onTap: _pickMember, trailing: unlink);
      }
      return _NightPill(icon: NvIcons.userPlus, label: 'ผูกสมาชิก', caption: 'ค้นหาเบอร์โทร / ชื่อ หรือเพิ่มใหม่', onTap: _pickMember);
    }
    final tier = store.tierFor(c);
    return _NightPill(
      icon: NvIcons.crown,
      label: c.name,
      caption: '${tier.name} · ${groupDigits(c.points)} แต้ม${tier.discountPercent > 0 ? ' · ลด ${tier.discountPercent}%' : ''}',
      highlight: true,
      onTap: _pickMember,
      trailing: unlink,
    );
  }

  Widget _totals(PosStore s, bool compact) {
    Widget kv(String label, String value, {Color? color, bool warn = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Nv.ui(13, color: warn ? Nv.gold400 : Nv.onNight2, weight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              Text(value, style: Nv.money(13.5, color: color ?? Nv.onNight, weight: FontWeight.w600)),
            ],
          ),
        );

    final rows = <Widget>[kv('ยอดรวม · ${s.cartItemCount} ชิ้น', baht(s.cartSubtotal))];
    if (compact && s.cartDiscount > 0) {
      rows.add(kv('ส่วนลด · ${s.discountNote}', '-${baht(s.cartDiscount)}', color: Nv.jadeLight));
    } else {
      if (s.couponDiscount > 0) rows.add(kv('คูปอง ${s.appliedCouponCode}', '-${baht(s.couponDiscount)}', color: Nv.jadeLight));
      final promo = s.appliedPromotion;
      if (promo != null && s.promoDiscount > 0) rows.add(kv('โปรโมชั่น · ${promo.name}', '-${baht(s.promoDiscount)}', color: Nv.jadeLight));
      final c = s.linkedCustomer;
      if (c != null && s.memberDiscount > 0) {
        final t = s.tierFor(c);
        rows.add(kv('สมาชิก ${t.name} -${t.discountPercent}%', '-${baht(s.memberDiscount)}', color: Nv.jadeLight));
      }
    }
    final code = s.appliedCouponCode;
    if (code != null && s.couponDiscount == 0) {
      final why = s.couponByCode(code)?.blockReason(s.cartSubtotal, DateTime.now()) ?? 'ไม่พบคูปอง';
      rows.add(kv('คูปอง $code ใช้ไม่ได้: ${why.isEmpty ? 'ไม่มีส่วนลด' : why}', '฿0', warn: true));
    }
    if (s.vatEnabled) {
      final pct = (s.vatRate * 100).round();
      rows.add(kv(s.vatInclusive ? 'VAT $pct% (รวมในราคาแล้ว)' : 'VAT $pct%', baht(s.cartTax)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...rows,
        const SizedBox(height: 4),
        Row(
          children: [
            Text('ยอดชำระ', style: Nv.ui(15, color: Nv.onNight, weight: FontWeight.w700)),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: NvFoilText(baht(s.cartTotal), style: Nv.money(compact ? 26 : 30)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final showArt = c.maxHeight > 170;
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showArt) NvArt.mascot('empty', height: (c.maxHeight * 0.5).clamp(80.0, 140.0)),
              const SizedBox(height: 8),
              Text('ยังไม่มีสินค้าในตะกร้า', textAlign: TextAlign.center, style: Nv.display(16, color: Nv.onNight)),
              const SizedBox(height: 4),
              Text('แตะสินค้า หรือสแกนบาร์โค้ดเพื่อเริ่มขาย',
                  textAlign: TextAlign.center, style: Nv.ui(12.5, color: Nv.onNight3)),
            ],
          ),
        ),
      );
    });
  }
}

class _CartLineRow extends StatelessWidget {
  final CartLine line;
  final int sentQty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onNote;
  final VoidCallback onRemove;

  const _CartLineRow({
    required this.line,
    required this.sentQty,
    required this.onMinus,
    required this.onPlus,
    required this.onNote,
    required this.onRemove,
  });

  Widget _mini(IconData icon, String tip, VoidCallback onTap, {bool danger = false}) => Tooltip(
        message: tip,
        child: InkResponse(
          onTap: onTap,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 13, color: danger ? Nv.lacquerLight : Nv.onNight2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final detail = [...line.options, if (line.note.isNotEmpty) line.note].join(' · ');
    return InkWell(
      onLongPress: onNote,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(line.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Nv.ui(14, color: Nv.onNight, weight: FontWeight.w600, height: 1.25)),
                  if (detail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.gold300)),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('@${baht(line.unitPrice)}', style: Nv.money(12, color: Nv.onNight3, weight: FontWeight.w500)),
                      if (sentQty > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(NvIcons.fire, size: 10, color: Nv.gold400),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text('ในครัว $sentQty',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11, color: Nv.gold300)),
                        ),
                      ],
                      const Spacer(),
                      _mini(NvIcons.note, 'หมายเหตุ', onNote),
                      _mini(NvIcons.trash, 'ลบรายการ', onRemove, danger: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(baht(line.lineTotal), style: Nv.money(15, color: Nv.gold200)),
                const SizedBox(height: 6),
                NvStepper(value: line.qty, onNight: true, onMinus: onMinus, onPlus: onPlus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet pill button on the navy panel (table, member).
class _NightPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? caption;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool highlight;

  const _NightPill({required this.icon, required this.label, this.caption, this.onTap, this.trailing, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(Nv.rMd);
    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        splashColor: Nv.gold300.withValues(alpha: 0.15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: highlight ? 0.09 : 0.05),
            borderRadius: br,
            border: Border.all(color: highlight ? Nv.gold500.withValues(alpha: 0.55) : Nv.lineNight),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: Nv.gold300),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(13.5, color: Nv.onNight, weight: FontWeight.w600)),
                    if (caption != null)
                      Text(caption!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11.5, color: Nv.onNight3)),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                const Icon(NvIcons.chevronRight, size: 11, color: Nv.onNight3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-over-label action tile on the navy panel.
class _NightAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  const _NightAction({required this.icon, required this.label, this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final br = BorderRadius.circular(Nv.rMd);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          splashColor: Nv.gold300.withValues(alpha: 0.15),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: active ? 0.10 : 0.05),
              borderRadius: br,
              border: Border.all(color: active ? Nv.gold500.withValues(alpha: 0.7) : Nv.lineNight),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: Nv.gold300),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Nv.ui(12, color: active ? Nv.gold200 : Nv.onNight2, weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── dialog bodies ───────────────────────────

class _TablePickerBody extends StatelessWidget {
  const _TablePickerBody();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final tables = List.of(store.tables)..sort((a, b) => a.number.compareTo(b.number));
    if (tables.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NvArt.mascot('empty', height: 110),
          const SizedBox(height: 8),
          Text('ยังไม่มีโต๊ะในระบบ', style: Nv.display(17)),
          const SizedBox(height: 4),
          Text(
            store.isManager
                ? 'สร้างโต๊ะและจัดผังร้านที่หน้า "ออกแบบผังร้าน" ก่อน หรือเลือก "กลับบ้าน" เพื่อขายแบบไม่ระบุโต๊ะ'
                : 'ให้ผู้จัดการสร้างโต๊ะที่หน้า "ออกแบบผังร้าน" หรือเลือก "กลับบ้าน" แทน',
            textAlign: TextAlign.center,
            style: Nv.ui(13.5, color: Nv.ink3, height: 1.45),
          ),
          if (store.isManager) ...[
            const SizedBox(height: 14),
            NvButton.gold('ไปออกแบบผังร้าน', icon: NvIcons.penRuler, onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.go('/floor-designer');
            }),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: NvChip('ไม่ระบุโต๊ะ',
              icon: NvIcons.xmark, selected: store.tableNumber == null, onTap: () => Navigator.of(context).pop(-1)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final t in tables)
              SizedBox(
                width: 116,
                child: NvSheet(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  radius: Nv.rMd,
                  selected: store.tableNumber == t.number,
                  onTap: () => Navigator.of(context).pop(t.number),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${t.number}', style: Nv.money(24)),
                      Text('${t.seats} ที่ · ${t.zone}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11, color: Nv.ink3)),
                      const SizedBox(height: 6),
                      NvBadge(t.status.label, tint: _tableTint(t.status)),
                      if (store.tableBillTotal(t.number) > 0) ...[
                        const SizedBox(height: 4),
                        Text('ค้าง ${baht(store.tableBillTotal(t.number))}', style: Nv.money(11.5, color: Nv.lacquer)),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

NvTint _tableTint(TableStatus s) => switch (s) {
      TableStatus.free => NvTint.jade,
      TableStatus.seated => NvTint.amber,
      TableStatus.reserved => NvTint.sapphire,
      TableStatus.billing => NvTint.lacquer,
    };

class _MemberPickerBody extends StatefulWidget {
  const _MemberPickerBody();

  @override
  State<_MemberPickerBody> createState() => _MemberPickerBodyState();
}

class _MemberPickerBodyState extends State<_MemberPickerBody> {
  final _q = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _adding = false;
  String? _error;

  @override
  void dispose() {
    _q.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _startAdd() {
    final q = _q.text.trim();
    final digits = q.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _adding = true;
      _error = null;
      if (digits.isNotEmpty && digits.length == q.replaceAll(RegExp(r'[\s-]'), '').length) {
        _phone.text = digits.length > 10 ? digits.substring(0, 10) : digits;
      } else if (q.isNotEmpty) {
        _name.text = q;
      }
    });
  }

  void _save() {
    final store = AppScope.read(context);
    final name = _name.text.trim();
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (name.isEmpty) {
      setState(() => _error = 'กรุณากรอกชื่อสมาชิก');
      return;
    }
    if (phone.isNotEmpty && (phone.length < 9 || phone.length > 10)) {
      setState(() => _error = 'เบอร์โทรต้องมี 9–10 หลัก');
      return;
    }
    final existing = phone.isEmpty ? null : store.customerByPhone(phone);
    if (existing != null) {
      // same phone = same person: link the existing record instead of a duplicate
      Navigator.of(context).pop(existing);
      return;
    }
    final c = store.addCustomer(name, phone: phone);
    Navigator.of(context).pop(c);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (_adding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NvField(label: 'ชื่อสมาชิก', controller: _name, icon: NvIcons.user, autofocus: true),
          const SizedBox(height: 12),
          NvField(
            label: 'เบอร์โทร (ไม่บังคับ แต่ช่วยค้นหาครั้งหน้า)',
            controller: _phone,
            icon: NvIcons.phone,
            keyboard: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            onSubmitted: (_) => _save(),
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
              NvButton.soft('กลับไปค้นหา', icon: NvIcons.arrowLeft, onPressed: () => setState(() => _adding = false)),
              NvButton.gold('บันทึกและผูกกับบิล', icon: NvIcons.userCheck, onPressed: _save),
            ],
          ),
        ],
      );
    }
    final all = store.searchCustomers(_q.text);
    final shown = all.take(30).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _q,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (shown.length == 1) Navigator.of(context).pop(shown.first);
          },
          decoration: const InputDecoration(hintText: 'เบอร์โทร หรือ ชื่อ', prefixIcon: Icon(NvIcons.search, size: 15)),
        ),
        const SizedBox(height: 12),
        if (store.customers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('ยังไม่มีสมาชิกในระบบ — เพิ่มสมาชิกคนแรกได้เลย',
                textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.ink3)),
          )
        else if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('ไม่พบสมาชิกที่ตรงกับ "${_q.text.trim()}"',
                textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.ink3)),
          )
        else
          for (final c in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NvSheet(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                radius: Nv.rMd,
                selected: store.customerId == c.id,
                onTap: () => Navigator.of(context).pop(c),
                child: Row(
                  children: [
                    NvAvatar(c.initials, hue: store.tierFor(c).hue, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w600)),
                          Text(c.phone.isEmpty ? 'ไม่มีเบอร์โทร' : phoneFmt(c.phone), style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NvBadge(store.tierFor(c).name, tint: NvTint.gold, icon: NvIcons.crown),
                        const SizedBox(height: 3),
                        Text('${groupDigits(c.points)} แต้ม', style: Nv.ui(11.5, color: Nv.ink3)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        if (all.length > shown.length)
          Text('แสดง ${shown.length} จาก ${all.length} รายการ — พิมพ์เพิ่มเพื่อค้นหาให้แคบลง',
              textAlign: TextAlign.center, style: Nv.ui(12, color: Nv.ink3)),
        const SizedBox(height: 10),
        NvButton.ghost('เพิ่มสมาชิกใหม่', icon: NvIcons.userPlus, expand: true, onPressed: _startAdd),
      ],
    );
  }
}

class _CouponBody extends StatefulWidget {
  const _CouponBody();

  @override
  State<_CouponBody> createState() => _CouponBodyState();
}

class _CouponBodyState extends State<_CouponBody> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _apply(String code) {
    final c = code.trim();
    if (c.isEmpty) {
      setState(() => _error = 'กรอกรหัสคูปอง');
      return;
    }
    final err = AppScope.read(context).tryApplyCoupon(c);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final now = DateTime.now();
    final applied = store.appliedCouponCode;
    final active = store.couponDefs.where((d) => d.active).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (applied != null) ...[
          NvSheet(
            padding: const EdgeInsets.all(12),
            radius: Nv.rMd,
            color: Nv.jadeTint,
            child: Row(
              children: [
                const Icon(NvIcons.checkCircle, size: 16, color: Nv.jade),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    store.couponDiscount > 0
                        ? 'ใช้คูปอง $applied อยู่ · ลด ${baht(store.couponDiscount)}'
                        : 'คูปอง $applied ยังไม่มีผลกับบิลนี้',
                    style: Nv.ui(13.5, color: Nv.ink2, weight: FontWeight.w600),
                  ),
                ),
                NvButton.soft('ยกเลิกคูปอง', size: NvButtonSize.sm, onPressed: () {
                  AppScope.read(context).removeCoupon();
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _code,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: _apply,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: const InputDecoration(hintText: 'กรอกรหัสคูปอง', prefixIcon: Icon(NvIcons.coupon, size: 15)),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
          ),
        const SizedBox(height: 10),
        NvButton.gold('ใช้คูปอง', icon: NvIcons.check, expand: true, onPressed: () => _apply(_code.text)),
        const SizedBox(height: 16),
        Text('คูปองที่เปิดใช้งาน', style: Nv.ui(13.5, color: Nv.ink2, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (active.isEmpty)
          Text(
            store.isManager ? 'ยังไม่มีคูปอง — สร้างได้ที่หน้า "คูปอง"' : 'ยังไม่มีคูปองที่เปิดใช้งาน',
            style: Nv.ui(13, color: Nv.ink3),
          )
        else
          for (final d in active)
            Builder(builder: (context) {
              final why = d.blockReason(store.cartSubtotal, now);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NvSheet(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  radius: Nv.rMd,
                  selected: applied == d.code,
                  onTap: () => _apply(d.code),
                  child: Row(
                    children: [
                      const Icon(NvIcons.coupon, size: 16, color: Nv.goldInk),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(d.code, style: Nv.money(14.5)),
                            Text(
                              [if (d.name.isNotEmpty) d.name, d.summary, if (d.minSpend > 0) 'ขั้นต่ำ ${baht(d.minSpend)}'].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Nv.ui(12, color: Nv.ink3),
                            ),
                            if (why.isNotEmpty) Text(why, style: Nv.ui(11.5, color: Nv.amber, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (why.isEmpty) Text('ใช้', style: Nv.ui(13, color: Nv.goldInk, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            }),
      ],
    );
  }
}

class _HeldBody extends StatelessWidget {
  const _HeldBody();

  static Future<void> _delete(BuildContext context, HeldCart h) async {
    final store = AppScope.read(context);
    final ok = await showNvConfirm(
      context,
      title: 'ลบบิลที่พัก?',
      message: 'ลบ "${h.label}" (${baht(h.total)}) ถาวร ไม่สามารถกู้คืนได้',
      confirmLabel: 'ลบบิล',
    );
    if (!ok) return;
    store.deleteHeld(h);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final list = store.heldCarts;
    if (list.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NvArt.mascot('sleepy', height: 110),
          const SizedBox(height: 8),
          Text('ยังไม่มีบิลที่พักไว้', style: Nv.display(17)),
          const SizedBox(height: 4),
          Text('กด "พักบิล" ในตะกร้าเพื่อพักบิลไว้ชั่วคราว แล้วเรียกคืนได้ที่นี่',
              textAlign: TextAlign.center, style: Nv.ui(13, color: Nv.ink3)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final h in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NvSheet(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              radius: Nv.rMd,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(h.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14.5, weight: FontWeight.w700)),
                        Text(
                          '${h.type.label}${h.tableNumber != null ? ' · โต๊ะ ${h.tableNumber}' : ''} · '
                          '${h.lines.fold<int>(0, (s, j) => s + ((j['qty'] as num?)?.toInt() ?? 0))} ชิ้น · '
                          'พักเมื่อ ${hm(h.createdAt)} (${timeAgo(h.createdAt)})',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Nv.ui(12, color: Nv.ink3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(baht(h.total), style: Nv.money(15.5)),
                  const SizedBox(width: 8),
                  NvIconButton(NvIcons.trash,
                      size: 36, color: Nv.lacquer, tooltip: 'ลบบิลที่พัก', onPressed: () => _delete(context, h)),
                  const SizedBox(width: 6),
                  NvButton.gold('เรียกคืน', size: NvButtonSize.sm, onPressed: () => Navigator.of(context).pop(h)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OpenBillsBody extends StatelessWidget {
  const _OpenBillsBody();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final open = store.openTickets;
    final tables = {for (final t in open) if (t.tableNumber != null) t.tableNumber!}.toList()..sort();
    final loose = open.where((t) => t.tableNumber == null).toList();
    final now = DateTime.now();
    if (tables.isEmpty && loose.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NvArt.mascot('empty', height: 110),
          const SizedBox(height: 8),
          Text('ไม่มีบิลค้างชำระ', style: Nv.display(17)),
          const SizedBox(height: 4),
          Text('ออเดอร์ที่กด "ส่งครัว" หรือลูกค้าสั่งเองจะแสดงที่นี่เพื่อรับชำระเงิน',
              textAlign: TextAlign.center, style: Nv.ui(13, color: Nv.ink3)),
        ],
      );
    }

    Widget tile({
      required String title,
      required String caption,
      required int total,
      required bool loaded,
      required bool calling,
      required VoidCallback onTap,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NvSheet(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            radius: Nv.rMd,
            selected: loaded,
            onTap: onTap,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: Nv.ui(14.5, weight: FontWeight.w700)),
                          if (loaded) const NvBadge('อยู่ในตะกร้า', tint: NvTint.jade),
                          if (calling) const NvBadge('เรียกพนักงาน', tint: NvTint.amber, icon: NvIcons.bell),
                        ],
                      ),
                      Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(baht(total), style: Nv.money(15.5)),
                const SizedBox(width: 8),
                const Icon(NvIcons.chevronRight, size: 12, color: Nv.ink4),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tables.isNotEmpty) ...[
          const NvSectionTitle('โต๊ะ', icon: NvIcons.chair),
          for (final n in tables)
            Builder(builder: (context) {
              final ts = store.openTicketsForTable(n);
              final first = ts.map((t) => t.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
              final items = ts.fold<int>(0, (s, t) => s + t.itemCount);
              return tile(
                title: 'โต๊ะ $n',
                caption: '${ts.length} ออเดอร์ · $items ชิ้น · เปิดเมื่อ ${hm(first)} (${elapsed(now.difference(first))})',
                total: store.tableBillTotal(n),
                loaded: ts.any((t) => store.activeTicketIds.contains(t.id)),
                calling: ts.any((t) => t.callWaiter) || (store.tableByNumber(n)?.callWaiter ?? false),
                onTap: () => Navigator.of(context).pop<Object>(n),
              );
            }),
        ],
        if (loose.isNotEmpty) ...[
          const SizedBox(height: 4),
          const NvSectionTitle('กลับบ้าน / ไม่ระบุโต๊ะ', icon: NvIcons.bag),
          for (final t in loose)
            tile(
              title: '${t.id} · ${t.customerName ?? t.source.label}',
              caption: '${t.itemCount} ชิ้น · ${t.staffName.isEmpty ? '' : '${t.staffName} · '}${hm(t.createdAt)} · ${t.prep.label}',
              total: t.total,
              loaded: store.activeTicketIds.contains(t.id),
              calling: t.callWaiter,
              onTap: () => Navigator.of(context).pop<Object>(t),
            ),
        ],
      ],
    );
  }
}
