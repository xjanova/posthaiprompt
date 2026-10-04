// Thaiprompt POS — Customer menu (/cust/menu[?table=7]) · self-order kiosk.
//
// The customer browses the live catalog on the table tablet: category pills
// (only categories that still have something orderable), a search box, and a
// food-art grid. Sold-out items stay visible with a "หมด" seal but cannot be
// ordered. Tapping a dish opens /cust/item; the gold "+" quick-adds dishes
// without required options. Everything goes into the store's SELF cart
// (never the counter cart); the floating gold bar opens /cust/cart.
//
// This file also hosts the small kiosk kit shared by every customer-facing
// screen: CustTopBar, CustFoodPicture, CustStepper, CustPill,
// CustCallWaiterButton, CustPrepBadge and a few helpers.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/catalog_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

// ═════════════════════════════ shared kiosk kit ═════════════════════════════

/// Landing route of the self-order kiosk for its current table.
String custHomeRoute(PosStore store) =>
    store.selfTable == null ? '/self-order' : '/self-order?table=${store.selfTable}';

/// Category glyph for a product (fallback: utensils).
IconData custCategoryIcon(PosStore store, Product p) => store.categoryById(p.categoryId)?.icon ?? NvIcons.utensils;

/// Options + note of a live cart line ("ใหญ่ · หวานน้อย · ไม่ใส่น้ำแข็ง").
String custLineDetail(CartLine l) => [...l.options, if (l.note.isNotEmpty) l.note].join(' · ');

/// Total qty of [code] already in the self cart.
int custQtyInSelfCart(PosStore store, String code) =>
    store.selfCart.where((l) => l.product.code == code).fold<int>(0, (s, l) => s + l.qty);

/// Text-field decoration for night (navy) kiosk surfaces.
InputDecoration custNightInput(String hint, {IconData? icon}) {
  final r = BorderRadius.circular(Nv.rMd);
  return InputDecoration(
    hintText: hint,
    hintStyle: Nv.ui(15, color: Nv.onNight3),
    counterStyle: Nv.ui(11.5, color: Nv.onNight3),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    prefixIcon: icon == null ? null : Icon(icon, size: 16, color: Nv.gold300),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(borderRadius: r, borderSide: const BorderSide(color: Nv.lineNight)),
    enabledBorder: OutlineInputBorder(borderRadius: r, borderSide: const BorderSide(color: Nv.lineNight)),
    focusedBorder: OutlineInputBorder(borderRadius: r, borderSide: const BorderSide(color: Nv.gold500, width: 1.6)),
  );
}

/// Kiosk header. Leaves room top-left for NvKiosk's logo (long-press = staff
/// exit); one row on tablets, two rows on phones.
class CustTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const CustTopBar({super.key, required this.title, this.subtitle, this.eyebrow, this.onBack, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 760;
      final titleBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null)
            Text(eyebrow!.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.eyebrow(color: Nv.gold300)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: NvFoilText(title, style: Nv.display(wide ? 30 : 24, weight: FontWeight.w700)),
          ),
          if (subtitle != null)
            Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(wide ? 15 : 13.5, color: Nv.onNight2)),
        ],
      );
      final back = onBack == null
          ? null
          : NvIconButton(NvIcons.arrowLeft, size: 56, onNight: true, tooltip: 'ย้อนกลับ', onPressed: onBack);
      final acts = <Widget>[
        for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 10), actions[i]],
      ];
      if (wide) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 20, 10),
          child: Row(
            children: [
              const SizedBox(width: 140, height: 56),
              if (back != null) ...[back, const SizedBox(width: 14)],
              Expanded(child: titleBlock),
              if (acts.isNotEmpty) const SizedBox(width: 12),
              ...acts,
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [const SizedBox(width: 136, height: 56), const Spacer(), ...acts]),
            const SizedBox(height: 6),
            Row(children: [if (back != null) ...[back, const SizedBox(width: 12)], Expanded(child: titleBlock)]),
          ],
        ),
      );
    });
  }
}

/// Product picture: food art → remote image → navy/gold tile with the
/// category glyph. Optional "หมด" seal. Needs a bounded box.
class CustFoodPicture extends StatelessWidget {
  final String? art;
  final String? imageUrl;
  final IconData icon;
  final double radius;
  final bool soldOut;

  const CustFoodPicture({
    super.key,
    this.art,
    this.imageUrl,
    this.icon = NvIcons.utensils,
    this.radius = Nv.rMd,
    this.soldOut = false,
  });

  CustFoodPicture.product(Product p, {super.key, IconData? icon, this.radius = Nv.rMd, bool? soldOut})
      : art = p.art,
        imageUrl = p.imageUrl,
        icon = icon ?? NvIcons.utensils,
        soldOut = soldOut ?? !p.canSell;

  @override
  Widget build(BuildContext context) {
    final a = art;
    final url = imageUrl?.trim() ?? '';
    final br = BorderRadius.circular(radius);
    return LayoutBuilder(builder: (context, c) {
      final s = c.biggest.shortestSide.isFinite ? c.biggest.shortestSide : 120.0;
      Widget tile() => Center(
            child: Icon(icon, size: (s * 0.34).clamp(16.0, 120.0), color: Nv.gold300.withValues(alpha: 0.9)),
          );
      final Widget content;
      if (a != null && kFoodArt.contains(a)) {
        content = Center(child: NvArt.food(a, size: s * 0.88, fallbackIcon: icon));
      } else if (url.isNotEmpty) {
        content = Image.network(url, fit: BoxFit.cover, filterQuality: FilterQuality.medium, errorBuilder: (_, _, _) => tile());
      } else {
        content = tile();
      }
      return ClipRRect(
        borderRadius: br,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: const RadialGradient(
              center: Alignment(0, -0.2),
              radius: 0.95,
              colors: [Nv.navy600, Nv.navy800, Nv.navy950],
              stops: [0, 0.55, 1],
            ),
            border: Border.all(color: Nv.lineNight),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.15),
                    radius: 0.62,
                    colors: [Nv.gold500.withValues(alpha: 0.26), Colors.transparent],
                  ),
                ),
              ),
              content,
              if (soldOut) ...[
                ColoredBox(color: Nv.navy950.withValues(alpha: 0.66)),
                Center(
                  child: Transform.rotate(
                    angle: -0.12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: (s * 0.12).clamp(8.0, 30.0), vertical: (s * 0.035).clamp(3.0, 10.0)),
                      decoration: BoxDecoration(
                        gradient: Nv.btnLacquer,
                        borderRadius: BorderRadius.circular(Nv.rPill),
                        border: Border.all(color: Nv.gold300.withValues(alpha: 0.75)),
                      ),
                      child: Text('หมด', style: Nv.display((s * 0.15).clamp(13.0, 40.0), color: Colors.white, weight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

/// Picture for a recorded ticket/order line (art snapshot + live catalog).
Widget custLinePicture(PosStore store, OrderLine l, {double size = 52}) {
  final p = store.productByCode(l.code);
  return SizedBox(
    width: size,
    height: size,
    child: CustFoodPicture(
      art: l.art ?? p?.art,
      imageUrl: p?.imageUrl,
      icon: p == null ? NvIcons.utensils : custCategoryIcon(store, p),
      radius: Nv.rSm,
    ),
  );
}

/// Big kiosk quantity stepper (56 px targets — NvStepper's 30 px buttons are
/// too small for a customer touch screen).
class CustStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final double size;

  const CustStepper({super.key, required this.value, this.onMinus, this.onPlus, this.size = 56});

  @override
  Widget build(BuildContext context) {
    Widget b(IconData icon, VoidCallback? f, bool gold, String tip) {
      final on = f != null;
      return Tooltip(
        message: tip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: f,
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gold && on ? Nv.btnGold : null,
                color: gold && on ? null : Colors.white.withValues(alpha: on ? 0.08 : 0.03),
                border: Border.all(color: on ? Nv.lineNightStrong : Nv.lineNight),
                boxShadow: gold && on ? Nv.goldGlow(0.6) : null,
              ),
              child: Icon(icon, size: size * 0.32, color: !on ? Nv.onNight3 : (gold ? const Color(0xFF1A1405) : Nv.gold200)),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        b(NvIcons.minus, onMinus, false, 'ลดจำนวน'),
        SizedBox(
          width: size * 0.95,
          child: Text('$value', textAlign: TextAlign.center, style: Nv.money(size * 0.4, color: Nv.onNight)),
        ),
        b(NvIcons.plus, onPlus, true, 'เพิ่มจำนวน'),
      ],
    );
  }
}

/// 56 px pill for categories / quick notes on night surfaces.
class CustPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const CustPill(this.label, {super.key, this.icon, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? const Color(0xFF1A1405) : Nv.onNight2;
    final br = BorderRadius.circular(Nv.rPill);
    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Nv.fast,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: selected ? Nv.btnGold : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.06),
            borderRadius: br,
            border: Border.all(color: selected ? Nv.gold300 : Nv.lineNight),
            boxShadow: selected ? Nv.goldGlow(0.7) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 17, color: selected ? fg : Nv.gold300), const SizedBox(width: 9)],
              Text(label, style: Nv.ui(16, color: fg, weight: selected ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime? _lastWaiterToggle;

/// Toggle "เรียกพนักงาน" for [table] with a confirmation toast. A second tap
/// within 0.8 s is ignored so a double-tap can't cancel the call it just made.
void custToggleWaiter(BuildContext context, int table) {
  final now = DateTime.now();
  final prev = _lastWaiterToggle;
  if (prev != null && now.difference(prev) < const Duration(milliseconds: 800)) return;
  _lastWaiterToggle = now;
  final store = AppScope.read(context);
  if (store.tablesCallingWaiter.contains(table)) {
    store.setCallWaiter(table, false);
    nvToast(context, 'ยกเลิกการเรียกพนักงานแล้ว');
    return;
  }
  final known = store.tableByNumber(table) != null || store.openTicketsForTable(table).isNotEmpty;
  if (!known) {
    nvToast(context, 'ไม่พบโต๊ะ $table ในผังร้าน · กรุณาแจ้งพนักงานที่เคาน์เตอร์', kind: NvToastKind.warning);
    return;
  }
  store.setCallWaiter(table, true);
  nvToast(context, 'เรียกพนักงานแล้ว · พนักงานกำลังไปที่โต๊ะ $table', kind: NvToastKind.success);
}

/// "เรียกพนักงาน" / "ยกเลิกการเรียก" — icon-only ([compact]) or a full button
/// with a live status line.
class CustCallWaiterButton extends StatelessWidget {
  final int table;
  final bool compact;
  final bool expand;

  const CustCallWaiterButton({super.key, required this.table, this.compact = false, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final calling = store.tablesCallingWaiter.contains(table);
    if (compact) {
      return NvIconButton(
        NvIcons.bellConcierge,
        size: 56,
        onNight: true,
        active: calling,
        tooltip: calling ? 'กำลังเรียกพนักงาน · แตะเพื่อยกเลิก' : 'เรียกพนักงาน',
        onPressed: () => custToggleWaiter(context, table),
      );
    }
    if (!calling) {
      return NvButton.navy('เรียกพนักงาน',
          icon: NvIcons.bellConcierge, size: NvButtonSize.xl, expand: expand, onPressed: () => custToggleWaiter(context, table));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Nv.amber.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(Nv.rMd),
            border: Border.all(color: Nv.amber.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(NvIcons.bellConcierge, size: 18, color: Nv.gold300),
              const SizedBox(width: 10),
              Expanded(
                child: Text('กำลังเรียกพนักงาน · พนักงานจะมาที่โต๊ะ $table ในไม่ช้า',
                    style: Nv.ui(14.5, color: Nv.gold200, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        NvButton.ghost('ยกเลิกการเรียกพนักงาน',
            onNight: true, icon: NvIcons.xmark, size: NvButtonSize.xl, expand: expand, onPressed: () => custToggleWaiter(context, table)),
      ],
    );
  }
}

/// Kitchen status pill for a ticket (customer wording).
class CustPrepBadge extends StatelessWidget {
  final Ticket ticket;
  const CustPrepBadge(this.ticket, {super.key});

  @override
  Widget build(BuildContext context) {
    if (ticket.status == TicketStatus.cancelled) return const NvBadge('ยกเลิกแล้ว', tint: NvTint.lacquer);
    return switch (ticket.prep) {
      PrepStatus.queued => const NvBadge('รับออเดอร์แล้ว', tint: NvTint.sapphire),
      PrepStatus.preparing => const NvBadge('กำลังทำ', tint: NvTint.amber),
      PrepStatus.ready => const NvBadge('พร้อมเสิร์ฟ', tint: NvTint.jade),
      PrepStatus.served => const NvBadge('เสิร์ฟแล้ว', tint: NvTint.neutral),
    };
  }
}

// ═════════════════════════════ /cust/menu ═════════════════════════════

class CustMenuScreen extends StatefulWidget {
  const CustMenuScreen({super.key});

  @override
  State<CustMenuScreen> createState() => _CustMenuScreenState();
}

class _CustMenuScreenState extends State<CustMenuScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _cat;
  int? _scheduledTable;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// `/cust/menu?table=7` points the kiosk at that table (after this frame —
  /// never mutate the store during build).
  /// Returns the valid ?table= value (or null).
  int? _syncTableParam(PosStore store) {
    final t = int.tryParse(GoRouterState.of(context).uri.queryParameters['table'] ?? '');
    if (t == null || t <= 0) return null;
    if (t == _scheduledTable || store.selfTable == t) {
      _scheduledTable = t;
      return t;
    }
    _scheduledTable = t;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.read(context).setSelfTable(t);
    });
    return t;
  }

  void _open(Product p) => context.go('/cust/item?code=${Uri.encodeQueryComponent(p.code)}');

  void _quickAdd(Product p) {
    if (p.options.any((g) => g.required)) {
      _open(p);
      return;
    }
    final store = AppScope.read(context);
    if (store.addToSelfCart(p)) {
      nvToast(context, 'เพิ่ม “${p.name}” ลงตะกร้าแล้ว', kind: NvToastKind.success);
    } else {
      nvToast(context, 'ขออภัย “${p.name}” หมดหรือมีไม่พอแล้ว', kind: NvToastKind.warning);
    }
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _cat = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final table = _syncTableParam(store) ?? store.selfTable;

    final header = CustTopBar(
      eyebrow: 'เมนูอาหาร',
      title: store.shopName,
      subtitle: table != null ? 'โต๊ะ $table · แตะเมนูเพื่อเลือก' : 'สั่งอาหารด้วยตนเอง · ชำระที่เคาน์เตอร์',
      onBack: () => context.go(table != null ? '/self-order?table=$table' : '/self-order'),
      actions: [
        if (table != null) CustCallWaiterButton(table: table, compact: true),
        NvIconButton(
          NvIcons.cart,
          size: 56,
          onNight: true,
          badge: store.selfCartCount,
          tooltip: 'ตะกร้าของฉัน',
          onPressed: () => context.go('/cust/cart'),
        ),
      ],
    );

    final sellable = store.products.where((p) => p.canSell).toList();
    if (sellable.isEmpty) {
      return NvKiosk(
        child: Column(
          children: [
            header,
            const Expanded(
              child: NvEmptyState(
                onNight: true,
                mascot: 'sleepy',
                title: 'ร้านยังไม่เปิดรับออเดอร์',
                message: 'ขออภัย ขณะนี้ยังไม่มีเมนูที่สั่งได้ กรุณาติดต่อพนักงาน',
              ),
            ),
          ],
        ),
      );
    }

    // Category order + only categories that still have something orderable.
    final sortedCats = store.sortedCategories;
    final catOrder = <String, int>{for (var i = 0; i < sortedCats.length; i++) sortedCats[i].id: i};
    final cats = sortedCats.where((c) => sellable.any((p) => p.categoryId == c.id)).toList();
    final cat = cats.any((c) => c.id == _cat) ? _cat : null;

    final q = _query.trim().toLowerCase();
    final indexed = <(int, Product)>[];
    for (var i = 0; i < store.products.length; i++) {
      final p = store.products[i];
      if (cat != null && p.categoryId != cat) continue;
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q) && !p.description.toLowerCase().contains(q)) continue;
      indexed.add((i, p));
    }
    // orderable first, then by category order, then menu order (deterministic)
    indexed.sort((a, b) {
      final s = (a.$2.canSell ? 0 : 1).compareTo(b.$2.canSell ? 0 : 1);
      if (s != 0) return s;
      final c = (catOrder[a.$2.categoryId] ?? 1 << 20).compareTo(catOrder[b.$2.categoryId] ?? 1 << 20);
      if (c != 0) return c;
      return a.$1.compareTo(b.$1);
    });
    final list = [for (final e in indexed) e.$2];

    final inCart = <String, int>{};
    for (final l in store.selfCart) {
      inCart[l.product.code] = (inCart[l.product.code] ?? 0) + l.qty;
    }
    final cartCount = store.selfCartCount;

    return NvKiosk(
      child: Column(
        children: [
          header,
          _filters(cats, cat),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: list.isEmpty
                      ? NvEmptyState(
                          onNight: true,
                          mascot: 'search',
                          title: 'ไม่พบเมนูที่ค้นหา',
                          message: q.isEmpty ? 'หมวดนี้ยังไม่มีเมนู' : 'ลองค้นหาด้วยคำอื่น หรือดูเมนูทั้งหมด',
                          actionLabel: 'ดูเมนูทั้งหมด',
                          actionIcon: NvIcons.grid,
                          onAction: _clearFilters,
                        )
                      : LayoutBuilder(builder: (context, c) {
                          final w = c.maxWidth;
                          final pad = w < 600 ? 12.0 : 20.0;
                          const gap = 14.0;
                          final cols = ((w - pad * 2 + gap) / (w < 600 ? 170 : 230)).floor().clamp(2, 6);
                          final tileW = (w - pad * 2 - gap * (cols - 1)) / cols;
                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(pad, 4, pad, cartCount > 0 ? 112 : 24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: gap,
                              crossAxisSpacing: gap,
                              mainAxisExtent: tileW * 0.78 + 132,
                            ),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final p = list[i];
                              return _MenuCard(
                                product: p,
                                icon: custCategoryIcon(store, p),
                                inCart: inCart[p.code] ?? 0,
                                onOpen: () => _open(p),
                                onQuickAdd: () => _quickAdd(p),
                                onSoldOut: () => nvToast(context, 'ขออภัย “${p.name}” หมดแล้ว', kind: NvToastKind.warning),
                              );
                            },
                          );
                        }),
                ),
                if (cartCount > 0)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: _CartBar(count: cartCount, total: store.selfCartTotal, onTap: () => context.go('/cust/cart')),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(List<Category> cats, String? cat) {
    final search = NvSearchField(
      hint: 'ค้นหาเมนู…',
      controller: _search,
      onNight: true,
      onChanged: (v) => setState(() => _query = v),
    );
    final chips = cats.isEmpty
        ? null
        : SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              children: [
                CustPill('ทั้งหมด', icon: NvIcons.grid, selected: cat == null, onTap: () => setState(() => _cat = null)),
                for (final c in cats) ...[
                  const SizedBox(width: 10),
                  CustPill(c.name, icon: c.icon, selected: cat == c.id, onTap: () => setState(() => _cat = c.id)),
                ],
              ],
            ),
          );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 900) {
        return Row(
          children: [
            Expanded(child: chips ?? const SizedBox(height: 60)),
            Padding(padding: const EdgeInsets.only(right: 20, left: 8), child: SizedBox(width: 340, child: search)),
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: search),
          if (chips != null) ...[const SizedBox(height: 8), chips],
        ],
      );
    });
  }
}

class _MenuCard extends StatelessWidget {
  final Product product;
  final IconData icon;
  final int inCart;
  final VoidCallback onOpen;
  final VoidCallback onQuickAdd;
  final VoidCallback onSoldOut;

  const _MenuCard({
    required this.product,
    required this.icon,
    required this.inCart,
    required this.onOpen,
    required this.onQuickAdd,
    required this.onSoldOut,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final can = p.canSell;
    final tag = p.tag;
    return NvNightCard(
      padding: const EdgeInsets.all(10),
      radius: Nv.rLg,
      selected: inCart > 0,
      onTap: can ? onOpen : onSoldOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: CustFoodPicture.product(p, icon: icon)),
                if (tag != null && tag.isNotEmpty && can)
                  Positioned(top: 8, left: 8, child: NvBadge(tag, tint: NvTint.gold, icon: NvIcons.star)),
                if (inCart > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      height: 30,
                      constraints: const BoxConstraints(minWidth: 30),
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(gradient: Nv.btnGold, borderRadius: BorderRadius.circular(Nv.rPill), boxShadow: Nv.goldGlow(0.6)),
                      child: Text('×$inCart', style: Nv.money(14, color: const Color(0xFF1A1405))),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Nv.ui(16, color: can ? Nv.onNight : Nv.onNight3, weight: FontWeight.w700, height: 1.3),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(baht(p.price), style: Nv.money(20, color: can ? Nv.gold200 : Nv.onNight3)),
                      ),
                      if (can && p.isLowStock)
                        Text('เหลือ ${p.stock} ที่', maxLines: 1, style: Nv.ui(11.5, color: Nv.gold300, weight: FontWeight.w600))
                      else if (p.hasOptions)
                        Text('มีตัวเลือกเพิ่มเติม', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11.5, color: Nv.onNight3)),
                    ],
                  ),
                ),
                if (can)
                  Tooltip(
                    message: p.options.any((g) => g.required) ? 'เลือกตัวเลือก' : 'ใส่ตะกร้า',
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onQuickAdd,
                        child: Ink(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: Nv.btnGold, boxShadow: Nv.goldGlow(0.7)),
                          child: const Icon(NvIcons.plus, size: 20, color: Color(0xFF1A1405)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating gold "ดูตะกร้า" bar.
class _CartBar extends StatelessWidget {
  final int count;
  final int total;
  final VoidCallback onTap;
  const _CartBar({required this.count, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(Nv.rPill);
    const ink = Color(0xFF1A1405);
    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: Ink(
          height: 72,
          decoration: BoxDecoration(gradient: Nv.btnGold, borderRadius: br, boxShadow: Nv.goldGlow(1.3)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 22, 8),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Nv.btnNavy),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(NvIcons.cart, size: 20, color: Nv.gold200),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 24),
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Nv.lacquer, borderRadius: BorderRadius.circular(12), border: Border.all(color: Nv.gold200, width: 1.5)),
                          child: Text('$count', style: Nv.money(12, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ดูตะกร้า', style: Nv.ui(17, color: ink, weight: FontWeight.w700)),
                      Text('$count รายการ', style: Nv.ui(13, color: ink.withValues(alpha: 0.75))),
                    ],
                  ),
                ),
                FittedBox(fit: BoxFit.scaleDown, child: Text(baht(total), style: Nv.money(24, color: ink))),
                const SizedBox(width: 10),
                const Icon(NvIcons.chevronRight, size: 18, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
