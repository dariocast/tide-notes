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

  testWidgets('color is applied only to the parsed prefix', (tester) async {
    const bodyColor = Color(0xFF516068);
    await tester.pumpWidget(
      MaterialApp(
        theme: TideTheme.light,
        home: const Scaffold(
          body: DefaultTextStyle(
            style: TextStyle(color: bodyColor),
            child: PrefixText(content: 'idea: calm capture', index: 8),
          ),
        ),
      ),
    );

    expect(find.byType(ShaderMask), findsNothing);
    final richText = tester.widget<RichText>(find.byType(RichText));
    final root = richText.text as TextSpan;
    expect(root.style?.color, bodyColor);
    expect(root.children, hasLength(2));
    expect((root.children!.first as TextSpan).style?.color, isNot(bodyColor));
    expect((root.children!.last as TextSpan).style?.color, isNull);
  });
}
