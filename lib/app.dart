import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'design/appearance_controller.dart';
import 'design/theme.dart';
import 'l10n/tide_localizations.dart';

class TideApp extends StatefulWidget {
  const TideApp({super.key, required this.home, this.appearance});

  final Widget home;
  final AppearanceController? appearance;

  @override
  State<TideApp> createState() => _TideAppState();
}

class _TideAppState extends State<TideApp> {
  late final AppearanceController _appearance =
      widget.appearance ?? AppearanceController.inMemory();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _appearance,
    builder: (_, _) {
      final selection = _appearance.selection;
      final themeMode = switch (selection) {
        TideThemeSelection.system => ThemeMode.system,
        TideThemeSelection.foam => ThemeMode.light,
        TideThemeSelection.deepTide ||
        TideThemeSelection.abyss => ThemeMode.dark,
      };
      final darkTheme = selection == TideThemeSelection.abyss
          ? TideAppTheme.abyss
          : TideAppTheme.deepTide;
      return AppearanceScope(
        controller: _appearance,
        child: MaterialApp(
          title: 'Tide',
          debugShowCheckedModeBanner: false,
          theme: TideAppTheme.foam,
          darkTheme: darkTheme,
          themeMode: themeMode,
          locale: _appearance.locale,
          supportedLocales: const [Locale('en'), Locale('it')],
          localizationsDelegates: const [
            TideLocalizationsDelegate(),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: widget.home,
        ),
      );
    },
  );
}
