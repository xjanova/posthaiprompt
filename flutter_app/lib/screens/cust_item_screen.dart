// Thaiprompt POS — Customer item detail (/cust/item?code=P0001) · self-order kiosk.
//
// Loads the real product by code. Option groups come from Product.options:
// required single-choice groups must be picked (radio cards), multi groups
// are checkboxes, every choice shows its price delta. Qty stepper is capped
// by remaining stock (minus what is already in the self cart), a free-text
// note with quick phrases goes to the kitchen, and the gold button shows the
// live total = (price + Σ deltas) × qty. "ใส่ตะกร้า" adds to the SELF cart
// and returns to the menu.
//
// by xman studio

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/catalog_models.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';
import 'cust_menu_screen.dart';

/// Quick kitchen notes the customer can tap (appended to the note field).
const List<String> _kQuickNotes = ['ไม่เผ็ด', 'เผ็ดน้อย', 'เผ็ดมาก', 'ไม่ใส่ผัก', 'ไม่ใส่ผงชูรส', 'แยกน้ำ', 'ไม่ใส่น้ำแข็ง'];

class CustItemScreen extends StatefulWidget {
  const CustItemScreen({super.key});

  @override
  State<CustItemScreen> createState() => _CustItemScreenState();
}

class _CustItemScreenState extends State<CustItemScreen> {
  final _note = TextEditingController();
  final Map<int, int> _single = {};
  final Map<int, Set<int>> _multi = {};
  int _qty = 1;
  bool _adding = false;
  String? _code;

  @override
  void initState() {
    super.initState();
    _note.addListener(_onNote);
  }

  @override
  void dispose() {
    _note.removeListener(_onNote);
    _note.dispose();
    super.dispose();
  }

  void _onNote() {
    if (mounted) setState(() {});
  }

  void _toggleQuickNote(String phrase) {
    final parts = _note.text.split(RegExp(r'\s*·\s*')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.contains(phrase)) {
      parts.remove(phrase);
    } else {
      parts.add(phrase);
    }
    final next = parts.join(' · ');
    if (next.length > 80) {
      nvToast(context, 'หมายเหตุยาวเกินไป', kind: NvToastKind.warning);
      return;
    }
    _note.text = next;
    _note.selection = TextSelection.collapsed(offset: next.length);
  }

  void _add(Product p, List<String> labels, int delta, int qty) {
    if (_adding) return;
    _adding = true;
    final store = AppScope.read(context);
    final ok = store.addToSelfCart(p, options: labels, optionDelta: delta, note: _note.text.trim(), qty: qty);
    if (!ok) {
      _adding = false;
      nvToast(context, 'ขออภัย “${p.name}” หมดหรือมีไม่พอแล้ว', kind: NvToastKind.error);
      setState(() {});
      return;
    }
    nvToast(context, 'เพิ่ม “${p.name}” × $qty ลงตะกร้าแล้ว', kind: NvToastKind.success);
    context.go('/cust/menu');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final code = GoRouterState.of(context).uri.queryParameters['code'] ?? '';
    if (code != _code) {
      // a different dish → start fresh (plain field reset, no rebuild needed)
      _code = code;
      _single.clear();
      _multi.clear();
      _qty = 1;
      _adding = false;
    }
    final p = code.isEmpty ? null : store.productByCode(code);

    if (p == null) {
      return NvKiosk(
        child: Column(
          children: [
            CustTopBar(eyebrow: 'รายละเอียดเมนู', title: store.shopName, onBack: () => context.go('/cust/menu')),
            Expanded(
              child: NvEmptyState(
                onNight: true,
                mascot: 'search',
                title: 'ไม่พบเมนูนี้',
                message: 'เมนูนี้อาจถูกนำออกจากร้านแล้ว ลองเลือกเมนูอื่นนะคะ',
                actionLabel: 'กลับไปหน้าเมนู',
                actionIcon: NvIcons.arrowLeft,
                onAction: () => context.go('/cust/menu'),
              ),
            ),
          ],
        ),
      );
    }

    // ── resolve the current choice set ──
    final labels = <String>[];
    final missing = <String>[];
    var delta = 0;
    for (var gi = 0; gi < p.options.length; gi++) {
      final g = p.options[gi];
      if (g.multi) {
        final sel = (_multi[gi] ?? const <int>{}).where((i) => i < g.choices.length).toList()..sort();
        if (g.required && sel.isEmpty) missing.add(g.name);
        for (final i in sel) {
          labels.add(g.choices[i].label);
          delta += g.choices[i].priceDelta;
        }
      } else {
        final i = _single[gi];
        if (i == null || i >= g.choices.length) {
          if (g.required) missing.add(g.name);
        } else {
          labels.add(g.choices[i].label);
          delta += g.choices[i].priceDelta;
        }
      }
    }

    final inCart = custQtyInSelfCart(store, p.code);
    final maxQty = p.trackStock ? p.stock - inCart : 99;
    final int qty = maxQty <= 1 ? 1 : (_qty < 1 ? 1 : (_qty > maxQty ? maxQty : _qty));
    final unit = p.price + delta;
    final total = unit * qty;
    final canAdd = p.canSell && maxQty > 0 && missing.isEmpty && !_adding;
    final category = store.categoryById(p.categoryId);
    final icon = custCategoryIcon(store, p);

    final String buttonLabel;
    if (!p.canSell) {
      buttonLabel = 'เมนูนี้หมดแล้ว';
    } else if (maxQty <= 0) {
      buttonLabel = 'ในตะกร้าครบจำนวนที่มีแล้ว';
    } else {
      buttonLabel = 'ใส่ตะกร้า';
    }

    final details = <Widget>[
      Text(p.name, style: Nv.display(28, color: Nv.onNight, weight: FontWeight.w700)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(baht(p.price), style: Nv.money(24, color: Nv.gold200)),
          if (p.tag != null && p.tag!.isNotEmpty) NvBadge(p.tag!, tint: NvTint.gold, icon: NvIcons.star),
          if (!p.canSell) const NvBadge('หมดชั่วคราว', tint: NvTint.lacquer),
          if (p.canSell && p.isLowStock) NvBadge('เหลือ ${p.stock} ที่', tint: NvTint.amber),
          if (inCart > 0) NvBadge('อยู่ในตะกร้าแล้ว $inCart', tint: NvTint.jade, icon: NvIcons.cart),
        ],
      ),
      if (p.description.trim().isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(p.description.trim(), style: Nv.ui(15.5, color: Nv.onNight2, height: 1.55)),
      ],
      const SizedBox(height: 14),
      const NvKanokDivider(width: 240, thin: true, opacity: 0.8),
      for (var gi = 0; gi < p.options.length; gi++) ...[
        const SizedBox(height: 16),
        _groupSection(gi, p.options[gi], missing.contains(p.options[gi].name)),
      ],
      const SizedBox(height: 20),
      Row(
        children: [
          const Icon(NvIcons.comment, size: 15, color: Nv.gold300),
          const SizedBox(width: 8),
          Text('หมายเหตุถึงครัว', style: Nv.ui(18, color: Nv.onNight, weight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('(ไม่บังคับ)', style: Nv.ui(13, color: Nv.onNight3)),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final n in _kQuickNotes)
            CustPill(n, selected: _note.text.split(RegExp(r'\s*·\s*')).map((s) => s.trim()).contains(n), onTap: () => _toggleQuickNote(n)),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _note,
        maxLength: 80,
        style: Nv.ui(16, color: Nv.onNight),
        cursorColor: Nv.gold400,
        decoration: custNightInput('พิมพ์เพิ่มเติม เช่น ไม่ใส่ถั่ว แพ้อาหารทะเล', icon: NvIcons.pen),
      ),
      const SizedBox(height: 12),
    ];

    Widget picture(double radius) => Stack(
          children: [
            Positioned.fill(
              child: NvGoldRim(
                radius: radius,
                child: CustFoodPicture.product(p, icon: icon, radius: radius - 1.4),
              ),
            ),
            const NvKanokCorners(size: 64, opacity: 0.85, inset: EdgeInsets.all(4)),
          ],
        );

    return NvKiosk(
      child: Column(
        children: [
          CustTopBar(
            eyebrow: category?.name ?? 'รายละเอียดเมนู',
            title: store.shopName,
            subtitle: store.selfTable != null ? 'โต๊ะ ${store.selfTable}' : null,
            onBack: () => context.go('/cust/menu'),
            actions: [
              NvIconButton(
                NvIcons.cart,
                size: 56,
                onNight: true,
                badge: store.selfCartCount,
                tooltip: 'ตะกร้าของฉัน',
                onPressed: () => context.go('/cust/cart'),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final bar = _bottomBar(
                // one-row bar only when the right column has room for it
                wide: wide && c.maxWidth * 0.58 >= 640,
                qty: qty,
                maxQty: maxQty,
                total: total,
                unit: unit,
                missing: missing,
                label: buttonLabel,
                onAdd: canAdd ? () => _add(p, labels, delta, qty) : null,
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: c.maxWidth * 0.42,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 10, 20),
                        child: Center(child: AspectRatio(aspectRatio: 1, child: picture(Nv.rXl))),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(padding: const EdgeInsets.fromLTRB(14, 4, 24, 16), children: details),
                          ),
                          bar,
                        ],
                      ),
                    ),
                  ],
                );
              }
              final picH = math.min(300.0, c.maxWidth * 0.72);
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                      children: [
                        SizedBox(height: picH, child: Center(child: AspectRatio(aspectRatio: 1, child: picture(Nv.rLg)))),
                        const SizedBox(height: 16),
                        ...details,
                      ],
                    ),
                  ),
                  bar,
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _groupSection(int gi, OptionGroup g, bool isMissing) {
    final String hint;
    if (g.multi) {
      hint = g.required ? 'ต้องเลือกอย่างน้อย 1' : 'เลือกได้หลายอย่าง';
    } else {
      hint = g.required ? 'ต้องเลือก 1 อย่าง' : 'ไม่บังคับ';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(g.name, style: Nv.ui(18, color: Nv.onNight, weight: FontWeight.w700))),
            const SizedBox(width: 10),
            if (g.required)
              NvBadge(hint, tint: isMissing ? NvTint.amber : NvTint.gold, dot: !isMissing, icon: isMissing ? NvIcons.warning : null)
            else
              Text(hint, style: Nv.ui(13, color: Nv.onNight3)),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          const gap = 10.0;
          final cols = c.maxWidth >= 560 ? 3 : 2;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var ci = 0; ci < g.choices.length; ci++)
                SizedBox(
                  width: w,
                  child: _ChoiceCard(
                    choice: g.choices[ci],
                    multi: g.multi,
                    selected: g.multi ? (_multi[gi]?.contains(ci) ?? false) : _single[gi] == ci,
                    onTap: () => setState(() {
                      if (g.multi) {
                        final set = _multi.putIfAbsent(gi, () => <int>{});
                        if (!set.remove(ci)) set.add(ci);
                      } else if (_single[gi] == ci && !g.required) {
                        _single.remove(gi);
                      } else {
                        _single[gi] = ci;
                      }
                    }),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _bottomBar({
    required bool wide,
    required int qty,
    required int maxQty,
    required int total,
    required int unit,
    required List<String> missing,
    required String label,
    required VoidCallback? onAdd,
  }) {
    final stepper = CustStepper(
      value: qty,
      onMinus: qty > 1 ? () => setState(() => _qty = qty - 1) : null,
      onPlus: qty < maxQty ? () => setState(() => _qty = qty + 1) : null,
    );
    final totalBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(qty > 1 ? '${baht(unit)} × $qty' : 'ราคารวม', style: Nv.ui(13, color: Nv.onNight3)),
        FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(total), style: Nv.money(30))),
      ],
    );
    final button = NvButton.gold(label, icon: NvIcons.cart, size: NvButtonSize.xl, expand: true, onPressed: onAdd);
    final warn = missing.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(NvIcons.warning, size: 15, color: Nv.gold400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('กรุณาเลือก: ${missing.join(', ')}',
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(14.5, color: Nv.gold300, weight: FontWeight.w600)),
                ),
              ],
            ),
          );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Nv.navy900.withValues(alpha: 0.94),
        border: const Border(top: BorderSide(color: Nv.lineNight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?warn,
          if (wide)
            Row(
              children: [
                stepper,
                const SizedBox(width: 18),
                Expanded(child: Align(alignment: Alignment.centerRight, child: totalBlock)),
                const SizedBox(width: 18),
                SizedBox(width: 260, child: button),
              ],
            )
          else ...[
            Row(children: [stepper, const SizedBox(width: 12), Expanded(child: Align(alignment: Alignment.centerRight, child: totalBlock))]),
            const SizedBox(height: 10),
            button,
          ],
        ],
      ),
    );
  }
}

/// Radio / checkbox card for one option choice (≥ 60 px tall).
class _ChoiceCard extends StatelessWidget {
  final OptionChoice choice;
  final bool multi;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({required this.choice, required this.multi, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(Nv.rMd);
    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Nv.fast,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Nv.gold400.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.05),
            borderRadius: br,
            border: Border.all(color: selected ? Nv.gold400 : Nv.lineNight, width: selected ? 1.6 : 1),
            boxShadow: selected ? Nv.goldGlow(0.5) : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: Nv.fast,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: multi ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: multi ? BorderRadius.circular(6) : null,
                  gradient: selected ? Nv.btnGold : null,
                  border: Border.all(color: selected ? Nv.gold300 : Nv.lineNightStrong, width: 1.6),
                ),
                child: selected ? const Icon(NvIcons.check, size: 12, color: Color(0xFF1A1405)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(choice.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Nv.ui(16, color: selected ? Nv.gold100 : Nv.onNight, weight: selected ? FontWeight.w700 : FontWeight.w500)),
              ),
              if (choice.priceDelta != 0) ...[
                const SizedBox(width: 8),
                Text(baht(choice.priceDelta, sign: true), style: Nv.money(14.5, color: Nv.gold300)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
