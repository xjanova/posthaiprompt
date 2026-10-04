// Thaiprompt POS — Legacy token names, re-pointed at the Nova palette.
//
// The 39 screens were first written against the turquoise/coral mockup tokens.
// The brand moved to the website's Nova theme (navy + gold + ivory), so every
// legacy name below now resolves to a Nova value from `nv_tokens.dart`. Keep
// the names stable (screens still compile), but new code should use [Nv]
// directly — `teal` reading as "gold" is a migration shim, not a design term.
//
// by xman studio

import 'package:flutter/material.dart';

import 'nv_tokens.dart';

class TpTokens {
  TpTokens._();

  // ═══ "Primary" (was teal) → Nova gold ═══
  static const teal = Nv.gold600;
  static const tealDeep = Nv.goldInk;
  static const tealLight = Nv.gold300;
  static const tealSoft = Nv.gold200;
  static const tealTint = Nv.gold100;
  static const tealMist = tealTint;

  // ═══ "Accent" (was coral) → Thai lacquer red ═══
  static const coral = Nv.lacquer;
  static const coralLight = Nv.lacquerLight;
  static const coralDeep = Nv.lacquerDeep;
  static const coralTint = Nv.lacquerTint;

  // ═══ Gold ═══
  static const gold = Nv.gold400;
  static const goldLight = Nv.gold300;
  static const goldDeep = Nv.gold600;
  static const goldTint = Nv.gold100;

  // ═══ "Indigo" → Nova navy ═══
  static const indigo = Nv.navy800;
  static const indigoDeep = Nv.navy950;

  // ═══ "Purple" (premium tier) → amethyst ═══
  static const purple = Nv.amethyst;
  static const purpleDeep = Nv.amethystDeep;

  // ═══ Surfaces → ivory ═══
  static const cream = Nv.paper;
  static const pearl = Nv.ivory2;
  static const bg1 = Nv.ivory;
  static const bg2 = Color(0xFFEFE9DC);

  // ═══ Ink ═══
  static const ink = Nv.ink;
  static const inkSoft = Nv.ink2;
  static const inkMute = Nv.ink3;
  static const line = Nv.line;
  static const lineSoft = Nv.lineSoft;

  // ═══ Status ═══
  static const success = Nv.jade;
  static const successDeep = Color(0xFF1F6B44);
  static const successBg = Nv.jadeTint;
  static const warning = Nv.amber;
  static const warningDeep = Color(0xFF7C5200);
  static const warningBg = Nv.amberTint;
  static const danger = Nv.lacquer;
  static const dangerDeep = Nv.lacquerDeep;
  static const dangerBg = Nv.lacquerTint;
  static const neutral = Nv.ink4;

  // ═══ Ambient (old orb colors → warm gold/navy glows) ═══
  static const ambient1 = Color(0xFFF5D27F);
  static const ambient2 = Color(0xFFE9C9A0);
  static const ambient3 = Color(0xFFC9D3EA);
  static const ambient4 = Color(0xFFFBE3A8);

  // ═══ Glass → ivory glass ═══
  static const glassFillTop = Color(0xF2FFFDF8);
  static const glassFillBot = Color(0xD9FAF7F0);
  static const glassBorder = Color(0x66D4A64A);
  static const glassHighlight = Color(0xE6FFFFFF);
  static const glassWhite = glassFillTop;
  static const glassWhiteSoft = glassFillBot;
  static const glassStroke = glassBorder;

  // ═══ Customer order flow (36-39) — night navy instead of cinnamon ═══
  static const cinnamonTop = Nv.navy700;
  static const cinnamonBot = Nv.navy950;
  static const cinnamonGradient = Nv.night;

  // ═══ Gradients ═══
  static const tealGradient = Nv.btnGold;
  static const coralGradient = Nv.btnLacquer;
  static const goldGradient = Nv.btnGold;
  static const indigoGradient = Nv.night;
  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Nv.amethyst, Nv.amethystDeep, Nv.navy950],
    stops: [0.0, 0.7, 1.0],
  );
  static const canvasGradient = Nv.day;
  static const mintGradient = Nv.btnJade;
  static const mint = Nv.jade;

  // ═══ Radii ═══
  static const radSm = Nv.rSm;
  static const radMd = Nv.rMd;
  static const radLg = Nv.rLg;
  static const radXl = Nv.rXl;
  static const radPill = Nv.rPill;

  // ═══ Spacing ═══
  static const sp1 = 4.0;
  static const sp2 = 8.0;
  static const sp3 = 12.0;
  static const sp4 = 14.0;
  static const sp5 = 18.0;
  static const sp6 = 22.0;
  static const sp7 = 24.0;
  static const sp8 = 32.0;
  static const sp10 = 40.0;
  static const sp12 = 48.0;
  static const sp16 = 64.0;

  // ═══ Shadows ═══
  static const shadowSoft = Nv.shadowSheet;
  static const shadowMid = Nv.shadowLift;
  static const shadowDeep = Nv.shadowLift;

  /// Nova sheet shadow with a gold hairline glint on top.
  static List<BoxShadow> glassShadow({double intensity = 1.0}) => [
        const BoxShadow(
          color: Color(0xCCFFFFFF),
          offset: Offset(0, 1),
          blurStyle: BlurStyle.inner,
        ),
        BoxShadow(
          color: const Color(0x14141A2B).withValues(alpha: 0.08 * intensity),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
        BoxShadow(
          color: const Color(0x2E141A2B).withValues(alpha: 0.18 * intensity),
          offset: const Offset(0, 14),
          blurRadius: 34,
          spreadRadius: -14,
        ),
      ];

  static List<BoxShadow> btn3DShadow({Color? tintColor, double tintAlpha = 0.55}) => [
        const BoxShadow(color: Color(0xB3FFFFFF), offset: Offset(0, 1), blurStyle: BlurStyle.inner),
        const BoxShadow(color: Color(0x598A6420), offset: Offset(0, -2), blurStyle: BlurStyle.inner),
        BoxShadow(
          color: (tintColor ?? Nv.gold400).withValues(alpha: tintAlpha),
          offset: const Offset(0, 8),
          blurRadius: 22,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> coloredGlow(Color c, {double intensity = 0.45}) => [
        BoxShadow(
          color: c.withValues(alpha: intensity * 0.8),
          offset: const Offset(0, 10),
          blurRadius: 22,
          spreadRadius: -8,
        ),
      ];

  // ═══ Blur ═══
  static const blurGlass = 18.0;
  static const blurDeep = 28.0;

  // ═══ Type ═══
  static const fontFamily = Nv.fontUi;
  static const fontMono = Nv.fontMono;

  static const fsDisplay = 64.0;
  static const fsTitle = 28.0;
  static const fsSubtitle = 22.0;
  static const fsH3 = 17.0;
  static const fsBody = 14.0;
  static const fsLabel = 12.0;
  static const fsTiny = 11.0;
  static const fsMicro = 10.0;

  static const textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: fsDisplay, fontWeight: FontWeight.w700, height: 1.05, color: ink),
    titleLarge: TextStyle(fontSize: fsTitle, fontWeight: FontWeight.w700, height: 1.15, color: ink),
    titleMedium: TextStyle(fontSize: fsSubtitle, fontWeight: FontWeight.w600, height: 1.25, color: ink),
    titleSmall: TextStyle(fontSize: fsH3, fontWeight: FontWeight.w600, height: 1.25, color: ink),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45, color: ink),
    bodyMedium: TextStyle(fontSize: fsBody, fontWeight: FontWeight.w400, height: 1.40, color: ink),
    bodySmall: TextStyle(fontSize: fsLabel, fontWeight: FontWeight.w400, height: 1.35, color: inkSoft),
    labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.3, color: inkSoft),
    labelSmall: TextStyle(fontSize: fsTiny, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: inkMute),
  );
}
