// Thaiprompt POS — ThemeData (Nova · ivory day surfaces, navy chrome, gold CTA).
//
// Fonts are bundled (assets/fonts) so the POS renders identically offline:
// Anuphan for UI (same as thaiprompt.online), Trirong for display headings,
// JetBrains Mono for money. Material defaults (dialogs, inputs, snackbars,
// switches, chips) are restyled here so every un-customised widget is already
// on-brand.
//
// by xman studio

import 'package:flutter/material.dart';

import 'nv_tokens.dart';

class TpTheme {
  TpTheme._();

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light, fontFamily: Nv.fontUi);
    final text = base.textTheme.apply(fontFamily: Nv.fontUi, bodyColor: Nv.ink, displayColor: Nv.ink);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Nv.rSm),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: Nv.gold600,
        onPrimary: Color(0xFF1A1405),
        primaryContainer: Nv.gold100,
        onPrimaryContainer: Nv.goldInk,
        secondary: Nv.navy700,
        onSecondary: Nv.onNight,
        tertiary: Nv.jade,
        surface: Nv.ivory2,
        onSurface: Nv.ink,
        surfaceContainerHighest: Nv.ivoryDeep,
        error: Nv.lacquer,
        onError: Colors.white,
        outline: Nv.line,
      ),
      scaffoldBackgroundColor: Nv.ivory,
      canvasColor: Nv.ivory,
      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(fontFamily: Nv.fontDisplay, fontWeight: FontWeight.w700),
        displayMedium: text.displayMedium?.copyWith(fontFamily: Nv.fontDisplay, fontWeight: FontWeight.w700),
        headlineLarge: text.headlineLarge?.copyWith(fontFamily: Nv.fontDisplay, fontWeight: FontWeight.w600),
        headlineMedium: text.headlineMedium?.copyWith(fontFamily: Nv.fontDisplay, fontWeight: FontWeight.w600),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      dividerTheme: const DividerThemeData(color: Nv.line, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: Nv.ink2, size: 18),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Nv.navy700,
          foregroundColor: Nv.gold200,
          minimumSize: const Size(64, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Nv.rPill)),
          textStyle: const TextStyle(fontFamily: Nv.fontUi, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Nv.gold400,
          foregroundColor: const Color(0xFF1A1405),
          elevation: 0,
          minimumSize: const Size(64, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Nv.rPill)),
          textStyle: const TextStyle(fontFamily: Nv.fontUi, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Nv.ink2,
          minimumSize: const Size(64, 44),
          side: const BorderSide(color: Nv.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Nv.rPill)),
          textStyle: const TextStyle(fontFamily: Nv.fontUi, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Nv.goldInk,
          textStyle: const TextStyle(fontFamily: Nv.fontUi, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Nv.paper,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: const TextStyle(color: Nv.ink4, fontSize: 14),
        labelStyle: const TextStyle(color: Nv.ink3, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: Nv.goldInk, fontWeight: FontWeight.w600),
        prefixIconColor: Nv.ink3,
        border: border(Nv.line),
        enabledBorder: border(Nv.line),
        focusedBorder: border(Nv.gold500, 1.6),
        errorBorder: border(Nv.lacquer),
        focusedErrorBorder: border(Nv.lacquer, 1.6),
      ),
      cardTheme: CardThemeData(
        color: Nv.ivory2,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nv.rLg),
          side: const BorderSide(color: Nv.lineSoft),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Nv.ivory2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nv.rXl),
          side: const BorderSide(color: Color(0x59D4A64A)),
        ),
        titleTextStyle: const TextStyle(
            fontFamily: Nv.fontDisplay, fontSize: 21, fontWeight: FontWeight.w600, color: Nv.ink),
        contentTextStyle: const TextStyle(fontFamily: Nv.fontUi, fontSize: 14.5, color: Nv.ink2, height: 1.45),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Nv.ivory2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Nv.rXl))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Nv.navy800,
        contentTextStyle: const TextStyle(fontFamily: Nv.fontUi, color: Nv.onNight, fontSize: 14),
        actionTextColor: Nv.gold300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nv.rMd),
          side: const BorderSide(color: Nv.lineNightStrong),
        ),
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : Nv.ink4),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Nv.gold500 : Nv.ivoryDeep),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Nv.gold500 : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Color(0xFF1A1405)),
        side: const BorderSide(color: Nv.ink4, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Nv.gold600 : Nv.ink4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Nv.paper,
        selectedColor: Nv.navy700,
        labelStyle: const TextStyle(fontFamily: Nv.fontUi, fontSize: 13, color: Nv.ink2),
        secondaryLabelStyle: const TextStyle(fontFamily: Nv.fontUi, fontSize: 13, color: Nv.gold200),
        side: const BorderSide(color: Nv.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Nv.rPill)),
        checkmarkColor: Nv.gold300,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Nv.gold500, linearTrackColor: Nv.ivoryDeep),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Nv.navy900.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Nv.lineNightStrong),
        ),
        textStyle: const TextStyle(fontFamily: Nv.fontUi, fontSize: 12, color: Nv.onNight),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Nv.ivory2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nv.rMd),
          side: const BorderSide(color: Nv.line),
        ),
        textStyle: const TextStyle(fontFamily: Nv.fontUi, fontSize: 14, color: Nv.ink),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Nv.navy900,
        foregroundColor: Nv.onNight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: Nv.fontDisplay, color: Nv.onNight, fontSize: 19, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Nv.navy900,
        height: 70,
        elevation: 0,
        indicatorColor: Nv.gold400.withValues(alpha: 0.18),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: Nv.fontUi, fontSize: 11, fontWeight: FontWeight.w600, color: Nv.onNight2),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Nv.ink,
        unselectedLabelColor: Nv.ink3,
        indicatorColor: Nv.gold500,
        dividerColor: Nv.line,
        labelStyle: TextStyle(fontFamily: Nv.fontUi, fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontFamily: Nv.fontUi, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(Nv.gold500.withValues(alpha: 0.45)),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
      ),
      splashColor: Nv.gold300.withValues(alpha: 0.22),
      highlightColor: Nv.gold300.withValues(alpha: 0.12),
      hoverColor: Nv.gold300.withValues(alpha: 0.08),
      focusColor: Nv.gold300.withValues(alpha: 0.18),
    );
  }
}
