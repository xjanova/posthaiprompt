// Thaiprompt POS — Nova design tokens (ธีมโนวา).
//
// Mirrors `public/theme-nova/nova.css` on thaiprompt.online so the POS and the
// website read as one brand: royal navy night + polished gold + ivory sheets,
// Thai kanok ornaments, Anuphan (UI) / Trirong (display) / JetBrains Mono
// (numbers). Every Nova widget and screen pulls colors, radii, shadows and type
// from here — never hand-type a hex in a screen.
//
// by xman studio

import 'package:flutter/material.dart';

class Nv {
  Nv._();

  // ═══ Navy (night) ═══ — --nv-navy-*
  static const navy950 = Color(0xFF040816);
  static const navy900 = Color(0xFF070D20);
  static const navy850 = Color(0xFF0A1530);
  static const navy800 = Color(0xFF0D1B3D);
  static const navy700 = Color(0xFF132552);
  static const navy600 = Color(0xFF1B3270);
  static const navy500 = Color(0xFF28438A); // hover / focus on night

  // ═══ Gold ═══ — --nv-gold-*
  static const gold100 = Color(0xFFFFF4D6);
  static const gold200 = Color(0xFFFBE3A8);
  static const gold300 = Color(0xFFF5D27F);
  static const gold400 = Color(0xFFF0C96A);
  static const gold500 = Color(0xFFD4A64A);
  static const gold600 = Color(0xFFB8862B);
  static const goldInk = Color(0xFF946714); // gold text that stays readable on ivory

  // ═══ Ivory (day sheets) ═══
  static const ivory = Color(0xFFF4F0E7); // --nv-ivory · page
  static const ivory2 = Color(0xFFFAF7F0); // raised card
  static const paper = Color(0xFFFFFDF8); // inputs, receipts
  static const ivoryDeep = Color(0xFFE9E2D2); // pressed / track

  // ═══ Ink ═══
  static const ink = Color(0xFF141A2B); // --nv-ink
  static const ink2 = Color(0xFF3D4558);
  static const ink3 = Color(0xFF6B7489); // --nv-ink-3
  static const ink4 = Color(0xFF9AA1B2);
  static const line = Color(0xFFE3DACB); // divider on ivory
  static const lineSoft = Color(0xFFEFE8DA);

  // ═══ On night ═══
  static const onNight = Color(0xFFF3ECDA); // --nv-on-night
  static const onNight2 = Color(0xC2ECE5D2); // 76%
  static const onNight3 = Color(0x85ECE5D2); // 52%
  static const lineNight = Color(0x2EF5D27F); // gold hairline on navy (18%)
  static const lineNightStrong = Color(0x73F5D27F); // 45%

  // ═══ Status (jewel tones that sit well beside gold) ═══
  static const lacquer = Color(0xFFB4322B); // Thai lacquer red — danger / void
  static const lacquerLight = Color(0xFFD9564C);
  static const lacquerDeep = Color(0xFF8E2620);
  static const lacquerTint = Color(0xFFF8E1DD);
  static const jade = Color(0xFF2F8A5B); // success / paid / online
  static const jadeLight = Color(0xFF4FB07D);
  static const jadeTint = Color(0xFFDDF1E5);
  static const amber = Color(0xFFC98A1B); // warning / low stock
  static const amberTint = Color(0xFFFBEFD3);
  static const sapphire = Color(0xFF2D5BA8); // info / links
  static const sapphireTint = Color(0xFFDFE8F7);
  static const amethyst = Color(0xFF4B3A7A); // premium tier
  static const amethystDeep = Color(0xFF2C2150);

  // ═══ Gradients ═══
  /// --nv-foil · animated shimmer text / borders.
  static const foil = LinearGradient(
    begin: Alignment(-1, -0.2),
    end: Alignment(1, 0.2),
    colors: [Color(0xFFFFF1C7), gold300, gold500, gold200, Color(0xFFC8962F), gold300],
    stops: [0.0, 0.2, 0.42, 0.58, 0.78, 1.0],
  );

  /// --nv-btn-gold · primary CTA.
  static const btnGold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gold200, gold400, gold500],
    stops: [0.0, 0.38, 1.0],
  );

  static const btnNavy = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navy600, navy800],
  );

  static const btnLacquer = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lacquerLight, lacquerDeep],
  );

  static const btnJade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [jadeLight, Color(0xFF1F6B44)],
  );

  /// Night panel (sidebar, totals, displays).
  static const night = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy800, navy900, navy950],
    stops: [0.0, 0.55, 1.0],
  );

  /// Ivory page wash.
  static const day = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F4EB), ivory, Color(0xFFEFE9DC)],
    stops: [0.0, 0.6, 1.0],
  );

  /// Raised navy card on a night background.
  static const nightCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xF0132552), Color(0xF00A1530)],
  );

  // ═══ Radii ═══
  static const rXs = 8.0;
  static const rSm = 12.0;
  static const rMd = 16.0;
  static const rLg = 20.0;
  static const rXl = 28.0;
  static const rPill = 999.0;

  // ═══ Spacing ═══
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;

  // ═══ Shadows ═══
  /// --nv-shadow · ivory sheets.
  static const shadowSheet = [
    BoxShadow(color: Color(0x0D141A2B), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x2E141A2B), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -12),
  ];

  static const shadowLift = [
    BoxShadow(color: Color(0x14141A2B), offset: Offset(0, 2), blurRadius: 6),
    BoxShadow(color: Color(0x3D141A2B), offset: Offset(0, 22), blurRadius: 44, spreadRadius: -16),
  ];

  /// Deep drop under navy panels on a night background.
  static const shadowNight = [
    BoxShadow(color: Color(0x99000000), offset: Offset(0, 24), blurRadius: 50, spreadRadius: -20),
  ];

  /// Gold CTA glow (inset highlight is painted by the button itself).
  static List<BoxShadow> goldGlow([double k = 1]) => [
        BoxShadow(
          color: gold400.withValues(alpha: 0.55 * k),
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> tintGlow(Color c, [double k = 1]) => [
        BoxShadow(
          color: c.withValues(alpha: 0.38 * k),
          offset: const Offset(0, 8),
          blurRadius: 20,
          spreadRadius: -8,
        ),
      ];

  // ═══ Motion ═══
  static const ease = Cubic(0.22, 1, 0.36, 1); // --nv-ease
  static const fast = Duration(milliseconds: 160);
  static const med = Duration(milliseconds: 280);

  // ═══ Type ═══
  static const fontUi = 'Anuphan';
  static const fontDisplay = 'Trirong';
  static const fontMono = 'JetBrainsMono';

  static const tnum = [FontFeature.tabularFigures()];

  /// JetBrains Mono has no Thai block (฿, Thai digits) → fall back to Anuphan.
  static const monoFallback = [fontUi];

  /// Display headline (Trirong) — page titles, hero numbers' captions.
  static TextStyle display(double size, {Color color = ink, FontWeight weight = FontWeight.w600}) =>
      TextStyle(fontFamily: fontDisplay, fontSize: size, fontWeight: weight, color: color, height: 1.2);

  /// Money / counts / SKUs — mono + tabular figures (anti-drift rule #9).
  static TextStyle money(double size, {Color color = ink, FontWeight weight = FontWeight.w700}) => TextStyle(
        fontFamily: fontMono,
        fontFamilyFallback: monoFallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: tnum,
        height: 1.1,
      );

  static TextStyle ui(double size, {Color color = ink, FontWeight weight = FontWeight.w400, double? height}) =>
      TextStyle(fontFamily: fontUi, fontSize: size, fontWeight: weight, color: color, height: height);

  /// Eyebrow label above sections. No letter-spacing: tracking pulls Thai
  /// vowel/tone marks off their base consonant.
  static TextStyle eyebrow({Color color = goldInk}) => TextStyle(
        fontFamily: fontUi,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Tracked eyebrow for LATIN-only labels ("POINT OF SALE").
  static TextStyle eyebrowLatin({Color color = goldInk}) => TextStyle(
        fontFamily: fontUi,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
        color: color,
      );
}
