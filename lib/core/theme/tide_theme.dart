import 'package:flutter/material.dart';

import 'tide_colors.dart';

abstract final class TideTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: TideColors.aqua,
          brightness: Brightness.light,
          surface: TideColors.pearl,
        ).copyWith(
          primary: TideColors.rescue,
          onSurface: TideColors.ink,
          surfaceContainerHighest: TideColors.mist,
          outline: TideColors.lightMuted,
          outlineVariant: TideColors.lightLine,
        );
    return _build(
      brightness: Brightness.light,
      scheme: scheme,
      canvas: TideColors.pearl,
      text: TideColors.ink,
      divider: TideColors.lightLine,
    );
  }

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: TideColors.powder,
          brightness: Brightness.dark,
          surface: TideColors.ocean,
        ).copyWith(
          primary: TideColors.aqua,
          onSurface: TideColors.moon,
          surfaceContainerHighest: TideColors.darkSurface,
          outline: TideColors.darkMuted,
          outlineVariant: TideColors.darkLine,
        );
    return _build(
      brightness: Brightness.dark,
      scheme: scheme,
      canvas: TideColors.ocean,
      text: TideColors.moon,
      divider: TideColors.darkLine,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color canvas,
    required Color text,
    required Color divider,
  }) {
    final baseTextTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: canvas,
      colorScheme: scheme,
      textTheme: baseTextTheme.apply(bodyColor: text, displayColor: text),
      dividerTheme: DividerThemeData(color: divider, thickness: 0.7, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: scheme.outline),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.square(48),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.24),
      ),
    );
  }
}
