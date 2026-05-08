// Thaiprompt POS — Glass card widget (mimics mockup's tp-glass)
// by xman studio

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tp_tokens.dart';

/// Glass-morphism card using BackdropFilter blur.
/// Use over decorative orbs/gradient backgrounds for the glass effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? fill;
  final Color? stroke;
  final List<BoxShadow>? shadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = TpTokens.radLg,
    this.blur = 22,
    this.fill,
    this.stroke,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow ?? TpTokens.glassShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  (fill ?? Colors.white).withValues(alpha: 0.85),
                  (fill ?? Colors.white).withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(
                color: stroke ?? Colors.white.withValues(alpha: 0.55),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Solid white card with soft drop shadow (no blur).
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = TpTokens.radLg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: TpTokens.shadowSoft,
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: TpTokens.tealLight.withValues(alpha: 0.3),
        child: card,
      ),
    );
  }
}

/// Floating elevated card (deeper shadow).
class FloatingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const FloatingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = TpTokens.radXl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: TpTokens.shadowDeep,
      ),
      padding: padding,
      child: child,
    );
  }
}
