// Thaiprompt POS — Nova backdrops.
//
// NvBackdrop.night — royal navy with a soft gold glow, a sprinkle of stars and
//   two gold "silk" threads (the website hero's สายไหมทอง), painted once into a
//   RepaintBoundary: zero per-frame cost, so a POS left on all day stays cool.
// NvBackdrop.day — warm ivory paper with faint gold threads and a whisper of
//   kanok in the corners, for back-office work surfaces.
//
// by xman studio

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/nv_tokens.dart';
import 'nv_art.dart';

enum NvTone { night, day }

class NvBackdrop extends StatelessWidget {
  final NvTone tone;
  final Widget? child;
  final bool kanok; // corner ornaments
  final String? image; // optional scene behind (NvAssets.art(...))
  final double imageOpacity;
  final Alignment imageAlignment;

  const NvBackdrop.night({
    super.key,
    this.child,
    this.kanok = true,
    this.image,
    this.imageOpacity = 1,
    this.imageAlignment = Alignment.center,
  }) : tone = NvTone.night;

  const NvBackdrop.day({super.key, this.child, this.kanok = true})
      : tone = NvTone.day,
        image = null,
        imageOpacity = 1,
        imageAlignment = Alignment.center;

  @override
  Widget build(BuildContext context) {
    final night = tone == NvTone.night;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: night ? const _NightPainter() : const _DayPainter(),
            child: const SizedBox.expand(),
          ),
        ),
        if (image != null)
          Positioned.fill(
            child: Opacity(
              opacity: imageOpacity,
              child: Image.asset(image!, fit: BoxFit.cover, alignment: imageAlignment, filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => const SizedBox()),
            ),
          ),
        if (kanok)
          NvKanokCorners(
            size: night ? 120 : 110,
            opacity: night ? 0.55 : 0.16,
            inset: EdgeInsets.zero,
          ),
        ?child,
      ],
    );
  }
}

class _NightPainter extends CustomPainter {
  const _NightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..shader = Nv.night.createShader(r));
    // warm glow top-right + cool glow bottom-left
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.08),
      size.shortestSide * 0.75,
      Paint()
        ..shader = RadialGradient(colors: [Nv.gold500.withValues(alpha: 0.16), Colors.transparent])
            .createShader(Rect.fromCircle(center: Offset(size.width * 0.82, size.height * 0.08), radius: size.shortestSide * 0.75)),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.95),
      size.shortestSide * 0.7,
      Paint()
        ..shader = RadialGradient(colors: [Nv.navy500.withValues(alpha: 0.35), Colors.transparent])
            .createShader(Rect.fromCircle(center: Offset(size.width * 0.1, size.height * 0.95), radius: size.shortestSide * 0.7)),
    );
    // stars (deterministic)
    final rnd = math.Random(7);
    final star = Paint();
    final count = (size.width * size.height / 9000).clamp(40, 260).toInt();
    for (var i = 0; i < count; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.85);
      final big = rnd.nextDouble() > 0.93;
      star.color = (big ? Nv.gold200 : Nv.onNight).withValues(alpha: big ? 0.7 : 0.12 + rnd.nextDouble() * 0.3);
      canvas.drawCircle(p, big ? 1.4 : 0.8, star);
    }
    _silk(canvas, size, Nv.gold400.withValues(alpha: 0.22), 0.62, 0.07);
    _silk(canvas, size, Nv.gold200.withValues(alpha: 0.12), 0.7, -0.05);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DayPainter extends CustomPainter {
  const _DayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..shader = Nv.day.createShader(r));
    canvas.drawCircle(
      Offset(size.width * 0.9, -size.height * 0.1),
      size.shortestSide * 0.8,
      Paint()
        ..shader = RadialGradient(colors: [Nv.gold200.withValues(alpha: 0.35), Colors.transparent])
            .createShader(Rect.fromCircle(center: Offset(size.width * 0.9, -size.height * 0.1), radius: size.shortestSide * 0.8)),
    );
    _silk(canvas, size, Nv.gold500.withValues(alpha: 0.10), 0.78, 0.05);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A long soft gold thread across the canvas (website "สายไหมทอง").
void _silk(Canvas canvas, Size size, Color color, double yFrac, double tilt) {
  final path = Path();
  final y0 = size.height * yFrac;
  path.moveTo(-20, y0);
  for (var x = 0.0; x <= size.width + 40; x += 40) {
    final t = x / size.width;
    path.lineTo(x, y0 + math.sin(t * math.pi * 2.2) * size.height * 0.06 - t * size.height * tilt);
  }
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
  );
}
