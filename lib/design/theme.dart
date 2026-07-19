import 'package:flutter/material.dart';

import 'design_tokens.dart';

abstract final class GravityAppTheme {
  static ThemeData get light => _build(Brightness.light, GravityTheme.light);
  static ThemeData get dark => _build(Brightness.dark, GravityTheme.dark);

  static ThemeData _build(Brightness brightness, GravityTheme g) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: g.accent,
      onPrimary: g.textOnAccent,
      secondary: g.rescue,
      onSecondary: g.ink,
      error: g.danger,
      onError: g.ink,
      surface: g.surface,
      onSurface: g.ink,
    );
    final text = TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'InstrumentSerif',
        fontSize: 44,
        height: 1.06,
        fontWeight: FontWeight.w400,
        letterSpacing: -.16,
        color: g.ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'InstrumentSerif',
        fontSize: 32,
        height: 1.3,
        fontWeight: FontWeight.w400,
        letterSpacing: -.32,
        color: g.ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'InstrumentSerif',
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w400,
        letterSpacing: -.16,
        color: g.accentMuted,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 20,
        height: 1.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -.16,
        color: g.ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 18,
        height: 1.6,
        fontWeight: FontWeight.w400,
        color: g.textSecondary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: g.ink,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 15,
        height: 1,
        fontWeight: FontWeight.w600,
        letterSpacing: -.16,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: g.textMuted,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: g.textGhost,
      ),
    );
    final shape = const RoundedRectangleBorder();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: g.bgMid,
      extensions: [g],
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: text,
      cardTheme: CardThemeData(
        shape: shape,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        shape: shape,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: shape,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: shape,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: g.lineSubtle,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: g.lineStrong),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: g.lineStrong),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: g.rescue, width: 2),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: g.textGhost),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(g.accent),
          foregroundColor: WidgetStatePropertyAll(g.textOnAccent),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, GLayout.minTouchTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
          shape: WidgetStatePropertyAll(shape),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(g.ink.withValues(alpha: .06)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(g.ink),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, GLayout.minTouchTarget),
          ),
          shape: WidgetStatePropertyAll(shape),
          side: WidgetStatePropertyAll(BorderSide(color: g.lineSubtle)),
          overlayColor: WidgetStatePropertyAll(g.ink.withValues(alpha: .06)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(g.ink),
          minimumSize: const WidgetStatePropertyAll(
            Size.square(GLayout.minTouchTarget),
          ),
          overlayColor: WidgetStatePropertyAll(g.ink.withValues(alpha: .06)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: g.accent,
        selectionColor: g.accent.withValues(alpha: .24),
      ),
    );
  }
}
