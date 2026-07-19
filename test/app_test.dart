import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/app.dart';
import 'package:tide/design/design_tokens.dart';

void main() {
  testWidgets('app supplies warm light and dark themes', (tester) async {
    await tester.pumpWidget(const TideApp(home: Placeholder()));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme!.scaffoldBackgroundColor, GLight.bgMid);
    expect(app.darkTheme!.scaffoldBackgroundColor, GDark.bgMid);
  });
}
