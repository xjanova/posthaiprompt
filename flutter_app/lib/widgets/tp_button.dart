// Thaiprompt POS — Branded buttons
// by xman studio

import 'package:flutter/material.dart';
import '../theme/tp_tokens.dart';

class TpPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double fontSize;

  const TpPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 50,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: TpTokens.tealGradient,
        borderRadius: BorderRadius.circular(TpTokens.radMd),
        boxShadow: TpTokens.coloredGlow(TpTokens.teal),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(TpTokens.radMd),
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TpCoralButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailing;
  final double height;
  final double fontSize;

  const TpCoralButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailing,
    this.height = 60,
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: TpTokens.coralGradient,
        borderRadius: BorderRadius.circular(TpTokens.radMd),
        boxShadow: TpTokens.coloredGlow(TpTokens.coral),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(TpTokens.radMd),
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  Icon(trailing, color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TpGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  const TpGhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TpTokens.radMd),
        border: Border.all(color: TpTokens.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(TpTokens.radMd),
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: TpTokens.inkSoft, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: TpTokens.inkSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand mark (gradient teal→navy circle with "ท") — mirror of mockup BrandMark.
class TpBrandMark extends StatelessWidget {
  final double size;
  const TpBrandMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: TpTokens.tealGradient,
        boxShadow: TpTokens.coloredGlow(TpTokens.teal, intensity: 0.45),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'ท',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Positioned(
            right: size * 0.05,
            bottom: size * 0.05,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: TpTokens.coralGradient,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
