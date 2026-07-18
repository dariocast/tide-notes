import 'package:flutter/material.dart';

import 'core/theme/tide_theme.dart';

class TideApp extends StatelessWidget {
  const TideApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Tide',
    debugShowCheckedModeBanner: false,
    theme: TideTheme.light,
    darkTheme: TideTheme.dark,
    themeMode: ThemeMode.system,
    home: home,
  );
}
