// Thaiprompt POS — Design tokens (mirror of mockup/css/tokens.css + MAUI Tokens.xaml)
// by xman studio

import 'package:flutter/material.dart';

/// Design tokens for Thaiprompt POS — single source of truth for colors, radii, spacing.
class TpTokens {
  TpTokens._();

  // ═══ Brand palette ═══
  static const teal       = Color(0xFF00A4B4);
  static const tealDeep   = Color(0xFF0E6E7E);
  static const tealLight  = Color(0xFFCFEAF2);
  static const tealMist   = Color(0xFFE8F5F8);
  static const coral      = Color(0xFFFF7A6B);
  static const coralDeep  = Color(0xFFD85A4A);
  static const coralLight = Color(0xFFFCD9D2);
  static const gold       = Color(0xFFE8C66A);
  static const goldDeep   = Color(0xFFB89642);
  static const goldLight  = Color(0xFFF8E8B8);
  static const indigo     = Color(0xFF283250);
  static const indigoDeep = Color(0xFF1A2236);
  static const purple     = Color(0xFF7A5BC4);
  static const mint       = Color(0xFF5BC8A4);

  // ═══ Surface ═══
  static const cream = Color(0xFFFBFAF6);
  static const pearl = Color(0xFFEFF2F5);
  static const bg1   = Color(0xFFF4F8FB);
  static const bg2   = Color(0xFFE5EFF3);

  // ═══ Ink ═══
  static const ink      = Color(0xFF1F2A3A);
  static const inkSoft  = Color(0xFF5C6B7E);
  static const inkMute  = Color(0xFF8895A6);
  static const line     = Color(0xFFD8DFE6);
  static const lineSoft = Color(0xFFE8EDF2);

  // ═══ Status ═══
  static const success = Color(0xFF3CB371);
  static const warning = Color(0xFFE8B14A);
  static const danger  = Color(0xFFE8523C);

  // ═══ Glass ═══
  static const glassWhite       = Color(0xE6FFFFFF); // 90%
  static const glassWhiteSoft   = Color(0xB3FFFFFF); // 70%
  static const glassStroke      = Color(0x80FFFFFF); // 50%

  // ═══ Gradients ═══
  static const tealGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF13C4D4), tealDeep],
  );
  static const coralGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFF8B7C), coralDeep],
  );
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFF4D87A), goldDeep],
  );
  static const indigoGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF3A4A6E), indigoDeep],
  );
  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF9B7CD4), Color(0xFF5A4090)],
  );
  static const mintGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF7AD8B4), Color(0xFF3CA988)],
  );
  static const canvasGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [bg1, Color(0xFFE8F0F4), Color(0xFFE0EAEF)],
    stops: [0.0, 0.5, 1.0],
  );

  // ═══ Radii ═══
  static const radSm   = 10.0;
  static const radMd   = 16.0;
  static const radLg   = 22.0;
  static const radXl   = 30.0;
  static const radPill = 999.0;

  // ═══ Spacing ═══
  static const sp1  = 4.0;
  static const sp2  = 8.0;
  static const sp3  = 12.0;
  static const sp4  = 16.0;
  static const sp5  = 20.0;
  static const sp6  = 24.0;
  static const sp8  = 32.0;
  static const sp10 = 40.0;
  static const sp12 = 48.0;
  static const sp16 = 64.0;

  // ═══ Shadows ═══
  static const shadowSoft = [
    BoxShadow(color: Color(0x141F2A3A), offset: Offset(0, 8), blurRadius: 22),
  ];
  static const shadowMid = [
    BoxShadow(color: Color(0x261F2A3A), offset: Offset(0, 16), blurRadius: 40),
  ];
  static const shadowDeep = [
    BoxShadow(color: Color(0x331F2A3A), offset: Offset(0, 24), blurRadius: 60),
  ];

  /// Multi-layer glass shadow stack — mimics mockup's layered look.
  static List<BoxShadow> glassShadow({double intensity = 1.0}) => [
    BoxShadow(
      color: const Color(0xE6FFFFFF).withValues(alpha: 0.9),
      offset: const Offset(0, 1),
      blurRadius: 0,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF1F2A3A).withValues(alpha: 0.10 * intensity),
      offset: const Offset(0, 12),
      blurRadius: 30,
      spreadRadius: -8,
    ),
    BoxShadow(
      color: const Color(0xFF1F2A3A).withValues(alpha: 0.08 * intensity),
      offset: const Offset(0, 30),
      blurRadius: 60,
      spreadRadius: -20,
    ),
  ];

  /// Colored shadow under a colored element (e.g. teal shadow under teal button).
  static List<BoxShadow> coloredGlow(Color c, {double intensity = 0.45}) => [
    BoxShadow(
      color: c.withValues(alpha: intensity),
      offset: const Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  // ═══ Type ═══
  static const fontFamily = 'Prompt'; // falls back to system if not bundled

  static const textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 64, fontWeight: FontWeight.w700, height: 1.05, color: ink),
    titleLarge:   TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, color: ink, letterSpacing: -0.5),
    titleMedium:  TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.25, color: ink),
    titleSmall:   TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.25, color: ink),
    bodyLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45, color: ink),
    bodyMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: ink),
    bodySmall:    TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.35, color: inkSoft),
    labelLarge:   TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: inkSoft),
    labelSmall:   TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.5, color: inkMute),
  );
}
