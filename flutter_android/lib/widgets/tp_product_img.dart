// Thaiprompt POS — Product image placeholder (mirror of mockup TPProductImg)
// Gradient swatch by hue + diagonal stripes overlay + glassy monogram orb.
// by xman studio

import 'package:flutter/material.dart';

/// Gradient product image placeholder matching the mockup's `TPProductImg`.
///
/// - hue: 0–360 OKLCH-ish hue (mockup uses oklch — we approximate via HSV)
/// - label: short SKU/code shown bottom-left (mono)
/// - kind: "rect" (default) or "circle" — shape of the central glass orb
class TpProductImg extends StatelessWidget {
  final int hue;
  final String? label;
  final String kind;
  final double borderRadius;

  const TpProductImg({
    super.key,
    this.hue = 195,
    this.label,
    this.kind = 'rect',
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    // Simulate oklch gradient via HSL (close enough for placeholder).
    final base = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.55, 0.78).toColor();
    final mid = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.65, 0.62).toColor();
    final deep = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.55, 0.42).toColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.6, 1.0],
                colors: [base, mid, deep],
              ),
            ),
          ),
          // Diagonal stripe pattern overlay
          Opacity(
            opacity: 0.35,
            child: CustomPaint(
              painter: _StripePainter(),
            ),
          ),
          // Bottom shadow gradient (depth)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Glassy orb in middle
          Center(
            child: Container(
              width: kind == 'circle' ? 56 : 60,
              height: kind == 'circle' ? 56 : 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(kind == 'circle' ? 999 : 10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 6),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    offset: const Offset(0, 1),
                    blurRadius: 0,
                    spreadRadius: -1,
                  ),
                ],
              ),
            ),
          ),
          // Monogram label (bottom-left)
          if (label != null)
            Positioned(
              left: 8, bottom: 6,
              child: Text(
                label!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    const stride = 16.0;
    final diag = size.width + size.height;
    for (var i = -size.height; i < diag; i += stride) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
