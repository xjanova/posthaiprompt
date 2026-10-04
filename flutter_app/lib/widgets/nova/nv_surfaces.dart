// Thaiprompt POS — Nova surfaces: ivory sheet, night card, gold-rim frame.
//
// by xman studio

import 'package:flutter/material.dart';

import '../../theme/nv_tokens.dart';

/// Ivory card (the website's "แผ่นงาช้าง"): paper fill, soft line, sheet
/// shadow, optional gold top hairline and tap ripple.
class NvSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool goldEdge; // thin gold line on top
  final bool selected; // gold ring
  final Color? color;
  final List<BoxShadow>? shadow;

  const NvSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Nv.s5),
    this.radius = Nv.rLg,
    this.onTap,
    this.goldEdge = false,
    this.selected = false,
    this.color,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Nv.ivory2,
        borderRadius: br,
        border: Border.all(color: selected ? Nv.gold500 : Nv.lineSoft, width: selected ? 1.6 : 1),
        boxShadow: shadow ?? (selected ? [...Nv.shadowSheet, ...Nv.goldGlow(0.6)] : Nv.shadowSheet),
      ),
      child: child,
    );
    final framed = goldEdge
        ? Stack(
            children: [
              body,
              Positioned(
                left: radius,
                right: radius,
                top: 0,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, Nv.gold400, Colors.transparent]),
                  ),
                ),
              ),
            ],
          )
        : body;
    if (onTap == null) return framed;
    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(onTap: onTap, borderRadius: br, child: framed),
    );
  }
}

/// Raised navy card for night surfaces (sidebar panels, totals, displays).
class NvNightCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool glow;
  final bool selected;

  const NvNightCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Nv.s5),
    this.radius = Nv.rLg,
    this.onTap,
    this.glow = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: Nv.nightCard,
        borderRadius: br,
        border: Border.all(color: selected ? Nv.gold400 : Nv.lineNight, width: selected ? 1.6 : 1),
        boxShadow: [
          ...Nv.shadowNight,
          if (glow || selected) ...Nv.goldGlow(0.5),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        splashColor: Nv.gold300.withValues(alpha: 0.18),
        child: card,
      ),
    );
  }
}

/// A thin animated-free gold foil rim around [child] (hero numbers, totals).
class NvGoldRim extends StatelessWidget {
  final Widget child;
  final double radius;
  final double width;
  const NvGoldRim({super.key, required this.child, this.radius = Nv.rLg, this.width = 1.4});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(width),
        decoration: BoxDecoration(gradient: Nv.foil, borderRadius: BorderRadius.circular(radius)),
        child: ClipRRect(borderRadius: BorderRadius.circular(radius - width), child: child),
      );
}

/// Gold foil text (shimmer gradient, static) for hero headings / totals.
class NvFoilText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? align;
  const NvFoilText(this.text, {super.key, required this.style, this.align});

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => Nv.foil.createShader(r),
        child: Text(text, style: style, textAlign: align),
      );
}
