import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/core/theme/tide_theme.dart';
import 'package:tide/presentation/widgets/prefix_text.dart';

void main() {
  testWidgets('prefix text exposes unchanged full content to semantics', (
    tester,
  ) async {
    const content = 'todo: ship the note';
    await tester.pumpWidget(
      MaterialApp(
        theme: TideTheme.light,
        home: const Scaffold(body: PrefixText(content: content, index: 0)),
      ),
    );

    expect(find.bySemanticsLabel(content), findsOneWidget);
    expect(find.byType(RichText), findsOneWidget);
  });
}
