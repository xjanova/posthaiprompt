// Thaiprompt POS — Design tokens
// Single source of truth: mockup/DESIGN_TOKENS.json (sRGB hex pre-converted from oklch).
// DO NOT estimate values. If a value isn't here, add it to DESIGN_TOKENS.json first,
// then mirror here. See mockup/CLAUDE.md anti-drift rules.

import 'package:flutter/material.dart';

/// Design tokens for Thaiprompt POS — single source of truth for colors, radii, spacing.
class TpTokens {
  TpTokens._();

  // ═══ Brand palette (from DESIGN_TOKENS.json color.*) ═══
  // Teal / primary
  static const teal       = Color(0xFF00BDBE); // primary
  static const tealDeep   = Color(0xFF008889); // primaryDeep
  static const tealLight  = Color(0xFF5DE7DC); // primaryLight (gradient top)
  static const tealSoft   = Color(0xFFB8F2EA); // primarySoft
  static const tealTint   = Color(0xFFD4FBFA); // primaryTint
  // legacy aliases used by widgets — keep mapping during refactor
  static const tealMist   = tealTint;

  // Coral / accent
  static const coral      = Color(0xFFFF6F69);
  static const coralLight = Color(0xFFFF9A8A);
  static const coralDeep  = Color(0xFFC53637);
  static const coralTint  = Color(0xFFFFE8E4);

  // Gold / premium
  static const gold       = Color(0xFFEDBC4A);
  static const goldLight  = Color(0xFFFBD35F);
  static const goldDeep   = Color(0xFFCA8A10);
  static const goldTint   = Color(0xFFFFF0D4);

  // Indigo / total + dark
  static const indigo     = Color(0xFF1A2B56);
  static const indigoDeep = Color(0xFF0C1331);

  // Purple / premium tier
  static const purple     = Color(0xFF4845A5);
  static const purpleDeep = Color(0xFF35226A);

  // ═══ Surface backgrounds ═══
  static const cream      = Color(0xFFF5FBFE); // bgCream
  static const pearl      = Color(0xFFE9F4F7); // bgPearl
  static const bg1        = Color(0xFFF1FAFD); // bgGradTop
  static const bg2        = Color(0xFFE0F3F4); // bgGradBot

  // ═══ Ink (text colors) ═══
  static const ink     = Color(0xFF141B24); // primary text
  static const inkSoft = Color(0xFF454E58); // secondary text
  static const inkMute = Color(0xFF80878F); // hint / placeholder
  static const line    = Color(0xFFD0D9DE); // dividers
  static const lineSoft = Color(0xFFE0E7EC); // soft divider (derived)

  // ═══ Status ═══
  static const success     = Color(0xFF1C8742); // successFg
  static const successDeep = Color(0xFF006925);
  static const successBg   = Color(0xFFCAFACB);

  static const warning     = Color(0xFFD29923); // warningFg
  static const warningDeep = Color(0xFF7C4800);
  static const warningBg   = Color(0xFFFFE6AE);

  static const danger      = Color(0xFFE85854); // dangerFg
  static const dangerDeep  = Color(0xFFB94642);
  static const dangerBg    = Color(0xFFFFD7D0);

  // Inactive / unselected indicator
  static const neutral = Color(0xFF9EBDCC);

  // ═══ Ambient background orbs ═══
  static const ambient1 = Color(0xFF8EFAF9); // teal
  static const ambient2 = Color(0xFFFFC4BD); // coral
  static const ambient3 = Color(0xFFCAE2FF); // lavender
  static const ambient4 = Color(0xFFFFE4A2); // gold

  // ═══ Glass surface ═══
  static const glassFillTop   = Color(0xC7FFFFFF); // 78%
  static const glassFillBot   = Color(0x7AFFFFFF); // 48%
  static const glassBorder    = Color(0xA6FFFFFF); // 65%
  static const glassHighlight = Color(0xD9FFFFFF); // 85%
  // legacy aliases
  static const glassWhite     = glassFillTop;
  static const glassWhiteSoft = glassFillBot;
  static const glassStroke    = glassBorder;

  // ═══ Cinnamon (customer order flow 36-39 only) ═══
  static const cinnamonTop = Color(0xFF6B3221);
  static const cinnamonBot = Color(0xFF3A1E18);
  static const cinnamonGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [cinnamonTop, cinnamonBot],
    // 160° in CSS ≈ topLeft → bottomRight in Flutter
  );

  // ═══ Gradients (from DESIGN_TOKENS.json gradient.*) ═══
  // All linear 180° (top → bottom) unless noted.
  static const tealGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [tealLight, tealDeep], // primaryButton: #5DE7DC → #008889
  );
  static const coralGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [coralLight, coralDeep], // #FF9A8A → #C53637
  );
  static const goldGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [goldLight, goldDeep], // #FBD35F → #CA8A10
  );
  static const indigoGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [indigo, indigoDeep], // 140° indigoTotal
  );
  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [purple, purpleDeep, Color(0xFF1F1240)],
    stops: [0.0, 0.7, 1.0],
  );
  static const canvasGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [bg1, bg2], // appBg
  );
  // mint kept as alias (no token in handoff — fall back to teal)
  static const mintGradient = tealGradient;
  static const mint = teal;

  // ═══ Radii ═══
  static const radSm   = 10.0;
  static const radMd   = 16.0;
  static const radLg   = 22.0;
  static const radXl   = 30.0;
  static const radPill = 999.0;

  // ═══ Spacing (DESIGN_TOKENS.json space.*) ═══
  static const sp1  = 4.0;
  static const sp2  = 8.0;
  static const sp3  = 12.0;
  static const sp4  = 14.0;
  static const sp5  = 18.0;
  static const sp6  = 22.0;
  static const sp7  = 24.0;
  static const sp8  = 32.0;
  static const sp10 = 40.0;
  static const sp12 = 48.0;
  static const sp16 = 64.0;

  // ═══ Shadows ═══
  // Single-layer fallbacks (use glassShadow() for the canonical 4-layer look)
  static const shadowSoft = [
    BoxShadow(color: Color(0x141F2A3A), offset: Offset(0, 8), blurRadius: 22),
  ];
  static const shadowMid = [
    BoxShadow(color: Color(0x261F2A3A), offset: Offset(0, 16), blurRadius: 40),
  ];
  static const shadowDeep = [
    BoxShadow(color: Color(0x331F2A3A), offset: Offset(0, 24), blurRadius: 60),
  ];

  /// Canonical glass shadow stack — mirrors `--tp-glass-shadow` from styles.css.
  /// CSS has 4 layers; Flutter BoxShadow can stack any number — keep all 4.
  static List<BoxShadow> glassShadow({double intensity = 1.0}) => [
    BoxShadow(
      color: const Color(0xE6FFFFFF), // 90% white top inset highlight
      offset: const Offset(0, 1),
      blurRadius: 0,
      spreadRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      color: const Color(0x0A14284B), // 4% dark bottom inset
      offset: const Offset(0, -1),
      blurRadius: 0,
      spreadRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      color: Color(0x381F2A3A).withValues(alpha: 0.22 * intensity),
      offset: const Offset(0, 10),
      blurRadius: 28,
      spreadRadius: -12,
    ),
    BoxShadow(
      color: Color(0x471F2A3A).withValues(alpha: 0.28 * intensity),
      offset: const Offset(0, 30),
      blurRadius: 60,
      spreadRadius: -30,
    ),
  ];

  /// 3D button shadow — mirrors `--tp-btn-shadow`.
  static List<BoxShadow> btn3DShadow({Color? tintColor, double tintAlpha = 0.55}) => [
    const BoxShadow(
      color: Color(0x99FFFFFF), // 60% white top inset
      offset: Offset(0, 1),
      blurRadius: 0,
      spreadRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
    const BoxShadow(
      color: Color(0x0F000000), // 6% dark bottom inset
      offset: Offset(0, -2),
      blurRadius: 0,
      spreadRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      color: (tintColor ?? const Color(0xFF1F2A3A)).withValues(alpha: tintAlpha * 0.4),
      offset: const Offset(0, 6),
      blurRadius: 14,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: const Color(0xFF1F2A3A).withValues(alpha: 0.18),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];

  /// Colored glow under a brand-colored element.
  static List<BoxShadow> coloredGlow(Color c, {double intensity = 0.45}) => [
    BoxShadow(
      color: c.withValues(alpha: intensity),
      offset: const Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  // ═══ Blur ═══
  static const blurGlass = 22.0; // backdrop-filter on .tp-glass
  static const blurDeep  = 32.0;

  // ═══ Type ═══
  static const fontFamily = 'Prompt';
  static const fontMono   = 'JetBrainsMono';

  // Font sizes (DESIGN_TOKENS.json size.*)
  static const fsDisplay  = 64.0;
  static const fsTitle    = 28.0;
  static const fsSubtitle = 22.0;
  static const fsH3       = 17.0;
  static const fsBody     = 14.0;
  static const fsLabel    = 12.0;
  static const fsTiny     = 11.0;
  static const fsMicro    = 10.0;

  static const textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: fsDisplay,  fontWeight: FontWeight.w700, height: 1.05, color: ink),
    titleLarge:   TextStyle(fontSize: fsTitle,    fontWeight: FontWeight.w700, height: 1.15, color: ink, letterSpacing: -0.5),
    titleMedium:  TextStyle(fontSize: fsSubtitle, fontWeight: FontWeight.w600, height: 1.25, color: ink),
    titleSmall:   TextStyle(fontSize: fsH3,       fontWeight: FontWeight.w600, height: 1.25, color: ink),
    bodyLarge:    TextStyle(fontSize: 16,         fontWeight: FontWeight.w400, height: 1.45, color: ink),
    bodyMedium:   TextStyle(fontSize: fsBody,     fontWeight: FontWeight.w400, height: 1.40, color: ink),
    bodySmall:    TextStyle(fontSize: fsLabel,    fontWeight: FontWeight.w400, height: 1.35, color: inkSoft),
    labelLarge:   TextStyle(fontSize: 13,         fontWeight: FontWeight.w500, letterSpacing: 0.5, color: inkSoft),
    labelSmall:   TextStyle(fontSize: fsTiny,     fontWeight: FontWeight.w500, letterSpacing: 1.5, color: inkMute),
  );
}
