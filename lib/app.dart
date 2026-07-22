import 'package:flutter/material.dart';

import 'design/appearance_controller.dart';
import 'design/theme.dart';

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
    builder: (_, _) => AppearanceScope(
      controller: _appearance,
      child: MaterialApp(
        title: 'Tide',
        debugShowCheckedModeBanner: false,
        theme: TideAppTheme.foam,
        darkTheme: TideAppTheme.deepTide,
        themeMode: _appearance.themeMode,
        home: widget.home,
      ),
    ),
  );
}
