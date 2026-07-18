import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/app.dart';

void main() {
  testWidgets('app supplies calm light and ocean dark themes', (tester) async {
    await tester.pumpWidget(const TideApp(home: Placeholder()));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme!.scaffoldBackgroundColor, const Color(0xFFF3F5F4));
    expect(app.darkTheme!.scaffoldBackgroundColor, const Color(0xFF081B25));
  });
}
