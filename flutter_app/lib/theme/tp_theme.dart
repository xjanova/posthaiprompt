// Thaiprompt POS — ThemeData factory (with Prompt font from Google Fonts)
// by xman studio

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tp_tokens.dart';

class TpTheme {
  TpTheme._();

  static ThemeData light() {
    // Prompt — primary UI font (covers TH + EN, matches mockup spec).
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final textTheme = GoogleFonts.promptTextTheme(base.textTheme).apply(
      bodyColor: TpTokens.ink,
      displayColor: TpTokens.ink,
    );

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: TpTokens.teal,
        onPrimary: Colors.white,
        secondary: TpTokens.coral,
        onSecondary: Colors.white,
        tertiary: TpTokens.gold,
        onTertiary: TpTokens.indigo,
        surface: Colors.white,
        onSurface: TpTokens.ink,
        error: TpTokens.danger,
      ),
      scaffoldBackgroundColor: TpTokens.bg1,
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.prompt(textStyle: TpTokens.textTheme.displayLarge),
        titleLarge:   GoogleFonts.prompt(textStyle: TpTokens.textTheme.titleLarge),
        titleMedium:  GoogleFonts.prompt(textStyle: TpTokens.textTheme.titleMedium),
        titleSmall:   GoogleFonts.prompt(textStyle: TpTokens.textTheme.titleSmall),
        bodyLarge:    GoogleFonts.prompt(textStyle: TpTokens.textTheme.bodyLarge),
        bodyMedium:   GoogleFonts.prompt(textStyle: TpTokens.textTheme.bodyMedium),
        bodySmall:    GoogleFonts.prompt(textStyle: TpTokens.textTheme.bodySmall),
        labelLarge:   GoogleFonts.prompt(textStyle: TpTokens.textTheme.labelLarge),
        labelSmall:   GoogleFonts.prompt(textStyle: TpTokens.textTheme.labelSmall),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TpTokens.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TpTokens.radMd)),
          textStyle: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TpTokens.inkSoft,
          minimumSize: const Size.fromHeight(44),
          side: const BorderSide(color: TpTokens.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TpTokens.radMd)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TpTokens.radLg)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: TpTokens.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.prompt(
          color: TpTokens.ink, fontSize: 18, fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        height: 70,
        elevation: 0,
        indicatorColor: TpTokens.tealLight,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      splashColor: TpTokens.tealLight.withValues(alpha: 0.3),
      highlightColor: TpTokens.tealLight.withValues(alpha: 0.2),
    );
  }
}
