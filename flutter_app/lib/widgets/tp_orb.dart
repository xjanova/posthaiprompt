// Thaiprompt POS — decorative blurred orb (mimics mockup's tp-orb)
// by xman studio

import 'dart:ui';
import 'package:flutter/material.dart';

/// Soft colored orb used as decorative background element.
/// Matches the .tp-orb class from mockup/css/styles.css.
class TpOrb extends StatelessWidget {
  final Color color;
  final double size;
  final Alignment alignment;
  final Offset offset;
  final double opacity;
  final double blur;

  const TpOrb({
    super.key,
    required this.color,
    this.size = 320,
    this.alignment = Alignment.topLeft,
    this.offset = Offset.zero,
    this.opacity = 0.55,
    this.blur = 80,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: offset,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: opacity),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stack of 3 default orbs (teal + coral + gold) — quick page background.
class TpOrbBackdrop extends StatelessWidget {
  const TpOrbBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        TpOrb(
          color: Color(0xFF00A4B4), // teal
          size: 380,
          alignment: Alignment.topLeft,
          offset: Offset(-160, -160),
        ),
        TpOrb(
          color: Color(0xFFFF7A6B), // coral
          size: 320,
          alignment: Alignment.topRight,
          offset: Offset(80, -100),
        ),
        TpOrb(
          color: Color(0xFFE8C66A), // gold
          size: 280,
          alignment: Alignment.bottomRight,
          offset: Offset(60, 80),
        ),
      ],
    );
  }
}
