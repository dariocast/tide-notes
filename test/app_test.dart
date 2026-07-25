import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/app.dart';
import 'package:tide/design/appearance_controller.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';

void main() {
  Future<MaterialApp> pumpWithSelection(
    WidgetTester tester,
    TideThemeSelection selection,
  ) async {
    await tester.pumpWidget(
      TideApp(
        home: const Placeholder(),
        appearance: AppearanceController.inMemory(selection: selection),
      ),
    );
    return tester.widget<MaterialApp>(find.byType(MaterialApp));
  }

  testWidgets('System selection uses Foam/Deep Tide with ThemeMode.system', (
    tester,
  ) async {
    final app = await pumpWithSelection(tester, TideThemeSelection.system);
    expect(app.title, 'Tide');
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme!.scaffoldBackgroundColor, GFoam.bgMid);
    expect(app.darkTheme!.scaffoldBackgroundColor, GDeepTide.bgMid);
  });

  testWidgets('Foam selection forces ThemeMode.light', (tester) async {
    final app = await pumpWithSelection(tester, TideThemeSelection.foam);
    expect(app.themeMode, ThemeMode.light);
    expect(app.theme!.scaffoldBackgroundColor, GFoam.bgMid);
  });

  testWidgets(
    'Deep Tide selection forces ThemeMode.dark with Deep Tide dark theme',
    (tester) async {
      final app = await pumpWithSelection(tester, TideThemeSelection.deepTide);
      expect(app.themeMode, ThemeMode.dark);
      expect(app.darkTheme!.scaffoldBackgroundColor, GDeepTide.bgMid);
    },
  );

  testWidgets('Abyss selection forces ThemeMode.dark with TideAppTheme.abyss', (
    tester,
  ) async {
    final app = await pumpWithSelection(tester, TideThemeSelection.abyss);
    expect(app.themeMode, ThemeMode.dark);
    expect(
      app.darkTheme!.scaffoldBackgroundColor,
      TideAppTheme.abyss.scaffoldBackgroundColor,
    );
    expect(app.darkTheme!.scaffoldBackgroundColor, Colors.black);
  });
}
