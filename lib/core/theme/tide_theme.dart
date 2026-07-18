import 'package:flutter/material.dart';

import 'tide_colors.dart';

abstract final class TideTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: TideColors.pearl,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TideColors.aqua,
      brightness: Brightness.light,
      surface: TideColors.pearl,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: TideColors.ocean,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TideColors.powder,
      brightness: Brightness.dark,
      surface: TideColors.ocean,
    ),
  );
}
