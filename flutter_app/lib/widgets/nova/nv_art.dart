// Thaiprompt POS — Nova art assets (3D icons, food art, mascot, kanok, scenes).
//
// All pictures were generated in ChatGPT (via Chrome) to match the website's
// Nova set, or copied straight from thaiprompt.online (mascot "น้องพร้อม",
// kanok corner, deco objects, logo). Reference them ONLY through [NvArt] /
// [NvAssets] so a missing file shows a tidy fallback instead of a red box.
//
// by xman studio

import 'package:flutter/material.dart';

import '../../theme/nv_tokens.dart';

class NvAssets {
  NvAssets._();

  static const _root = 'assets/nova';

  /// 3D module / payment icons (256²): pos payment receipt kitchen table display
  /// qr delivery refund dashboard inventory menu member staff shift po
  /// accounting tax branch coupon discount tiers affiliate barcode shipping nfc
  /// settings cash promptpay card wallet token printer drawer sync shield
  static String icon(String key) => '$_root/icons/$key.webp';

  /// Food art (320²): thai_tea coffee rice noodle dessert snack bakery juice grocery
  static String food(String key) => '$_root/food/$key.webp';

  /// Mascot น้องพร้อม: welcome present face cheer wai present_tab empty search
  /// sleepy chef gift clock
  static String mascot(String key) => '$_root/mascot/$key.webp';

  /// Deco objects from the website: lantern lotus coins bell garland elephant
  /// lamp umbrella gift crystal scroll bag
  static String deco(String key) => '$_root/deco/$key.webp';

  /// Scenes: login-hero display-bg food-banner hero-temple
  static String art(String key) => '$_root/art/$key.webp';

  /// Website category art: amulet beauty books electronics fashion food health
  /// home pets sports toys wallet
  static String cat(String key) => '$_root/cat/$key.webp';

  static const logoOnDark = '$_root/brand/logo-on-dark.webp';
  static const logoOnLight = '$_root/brand/logo-on-light.webp';
  static const mark = '$_root/brand/mark.webp';
  static const kanokCorner = '$_root/brand/kanok-corner.webp';
  static const kanokCornerWeb = '$_root/brand/kanok-gold.webp';
  static const kanokDivider = '$_root/brand/kanok-divider.webp';
  static const kanokLine = '$_root/brand/kanok-line.webp';
  static const kanokMedallion = '$_root/brand/kanok-medallion.webp';
  static const medallionWeb = '$_root/brand/tabbar-kanok-medallion.webp';
  static const archWeb = '$_root/brand/tabbar-kanok-arch.webp';
}

/// Asset image with a graceful fallback (gold-outlined placeholder).
class NvArt extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final double opacity;
  final IconData? fallbackIcon;

  const NvArt(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.opacity = 1,
    this.fallbackIcon,
  });

  /// 3D module icon, square.
  NvArt.icon(String name, {super.key, double size = 56, this.opacity = 1, this.fallbackIcon})
      : path = NvAssets.icon(name),
        width = size,
        height = size,
        fit = BoxFit.contain,
        alignment = Alignment.center;

  NvArt.food(String name, {super.key, double size = 96, this.opacity = 1, this.fallbackIcon})
      : path = NvAssets.food(name),
        width = size,
        height = size,
        fit = BoxFit.contain,
        alignment = Alignment.center;

  NvArt.mascot(String name, {super.key, this.width, this.height = 220, this.opacity = 1, this.fallbackIcon})
      : path = NvAssets.mascot(name),
        fit = BoxFit.contain,
        alignment = Alignment.bottomCenter;

  NvArt.deco(String name, {super.key, double size = 80, this.opacity = 1, this.fallbackIcon})
      : path = NvAssets.deco(name),
        width = size,
        height = size,
        fit = BoxFit.contain,
        alignment = Alignment.center;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Icon(fallbackIcon ?? Icons.image_outlined,
              size: ((width ?? height ?? 40) * 0.45).clamp(14, 48), color: Nv.gold500.withValues(alpha: 0.6)),
        ),
      ),
    );
    return opacity >= 1 ? img : Opacity(opacity: opacity, child: img);
  }
}

/// Four gold kanok corners framing a box (ornamental — ignores pointer).
/// Must be a DIRECT child of a [Stack]: it fills the stack (Positioned.fill)
/// so it works even when the stack is sized by its other children.
class NvKanokCorners extends StatelessWidget {
  final double size;
  final double opacity;
  final EdgeInsets inset;
  final bool top;
  final bool bottom;

  const NvKanokCorners({
    super.key,
    this.size = 90,
    this.opacity = 0.9,
    this.inset = const EdgeInsets.all(6),
    this.top = true,
    this.bottom = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget corner(double sx, double sy) => Transform.scale(
          scaleX: sx,
          scaleY: sy,
          child: NvArt(NvAssets.kanokCorner, width: size, height: size, opacity: opacity),
        );
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            if (top) Positioned(left: inset.left, top: inset.top, child: corner(1, 1)),
            if (top) Positioned(right: inset.right, top: inset.top, child: corner(-1, 1)),
            if (bottom) Positioned(left: inset.left, bottom: inset.bottom, child: corner(1, -1)),
            if (bottom) Positioned(right: inset.right, bottom: inset.bottom, child: corner(-1, -1)),
          ],
        ),
      ),
    );
  }
}

/// Centered kanok divider (generated gold ornament) for section breaks.
class NvKanokDivider extends StatelessWidget {
  final double width;
  final bool thin;
  final double opacity;
  const NvKanokDivider({super.key, this.width = 280, this.thin = false, this.opacity = 1});

  @override
  Widget build(BuildContext context) => Center(
        child: NvArt(
          thin ? NvAssets.kanokLine : NvAssets.kanokDivider,
          width: width,
          height: width * (thin ? 0.146 : 0.25),
          opacity: opacity,
        ),
      );
}
