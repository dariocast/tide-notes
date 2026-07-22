import 'package:flutter/material.dart';

import 'design_tokens.dart';

const _fontFallback = ['.AppleSystemUIFont', 'Roboto', 'sans-serif'];

abstract final class TideAppTheme {
  static ThemeData get foam => _build(Brightness.light, TideColors.foam);
  static ThemeData get deepTide => _build(Brightness.dark, TideColors.deepTide);
  static ThemeData get abyss => _build(Brightness.dark, TideColors.abyss);

  static ThemeData _build(Brightness brightness, TideColors colors) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.textOnAccent,
      secondary: colors.rescue,
      onSecondary: colors.ink,
      error: colors.danger,
      onError: colors.ink,
      surface: colors.surface,
      onSurface: colors.ink,
    );
    final text = TextTheme(
      headlineMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontFamilyFallback: _fontFallback,
        fontSize: 30,
        height: 1.20,
        fontWeight: FontWeight.w500,
        color: colors.ink,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontFamilyFallback: _fontFallback,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w400,
        color: colors.ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Nunito',
        fontFamilyFallback: _fontFallback,
        fontSize: 18,
        height: 1.50,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Nunito',
        fontFamilyFallback: _fontFallback,
        fontSize: 17,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: colors.ink,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Nunito',
        fontFamilyFallback: _fontFallback,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: colors.textMuted,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Nunito',
        fontFamilyFallback: _fontFallback,
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Nunito',
        fontFamilyFallback: _fontFallback,
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: colors.textMuted,
      ),
    );
    final shape = RoundedRectangleBorder(borderRadius: GShapes.control);
    final theme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bgMid,
      extensions: [colors],
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
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
        color: colors.lineSubtle,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.lineStrong),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.lineStrong),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.rescue, width: 2),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: colors.textMuted),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(colors.accent),
          foregroundColor: WidgetStatePropertyAll(colors.textOnAccent),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, GLayout.minTouchTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
          shape: WidgetStatePropertyAll(shape),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(
            colors.ink.withValues(alpha: .06),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colors.ink),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, GLayout.minTouchTarget),
          ),
          shape: WidgetStatePropertyAll(shape),
          side: WidgetStatePropertyAll(BorderSide(color: colors.lineSubtle)),
          overlayColor: WidgetStatePropertyAll(
            colors.ink.withValues(alpha: .06),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colors.ink),
          minimumSize: const WidgetStatePropertyAll(
            Size.square(GLayout.minTouchTarget),
          ),
          overlayColor: WidgetStatePropertyAll(
            colors.ink.withValues(alpha: .06),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent,
        selectionColor: colors.accent.withValues(alpha: .24),
      ),
    );
    final defaults = theme.textTheme;
    TextStyle nunitoDefault(TextStyle? base) => (base ?? const TextStyle())
        .copyWith(fontFamily: 'Nunito', fontFamilyFallback: _fontFallback);
    return theme.copyWith(
      textTheme: TextTheme(
        displayLarge: nunitoDefault(defaults.displayLarge),
        displayMedium: nunitoDefault(defaults.displayMedium),
        displaySmall: nunitoDefault(defaults.displaySmall),
        headlineLarge: nunitoDefault(defaults.headlineLarge),
        headlineMedium: text.headlineMedium,
        headlineSmall: nunitoDefault(defaults.headlineSmall),
        titleLarge: text.titleLarge,
        titleMedium: nunitoDefault(defaults.titleMedium),
        titleSmall: nunitoDefault(defaults.titleSmall),
        bodyLarge: text.bodyLarge,
        bodyMedium: text.bodyMedium,
        bodySmall: text.bodySmall,
        labelLarge: text.labelLarge,
        labelMedium: nunitoDefault(defaults.labelMedium),
        labelSmall: text.labelSmall,
      ),
    );
  }
}
