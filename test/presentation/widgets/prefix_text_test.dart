import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/presentation/widgets/prefix_text.dart';

void main() {
  testWidgets('prefix text exposes unchanged full content to semantics', (
    tester,
  ) async {
    const content = 'todo: ship the note';
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: const Scaffold(body: PrefixText(content: content, index: 0)),
      ),
    );

    expect(find.bySemanticsLabel(content), findsOneWidget);
    expect(find.byType(RichText), findsOneWidget);
  });

  testWidgets('color is applied only to the parsed prefix', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: const Scaffold(
          body: PrefixText(content: 'idea: calm capture', index: 8),
        ),
      ),
    );

    expect(find.byType(ShaderMask), findsNothing);
    final richText = tester.widget<RichText>(find.byType(RichText));
    final root = richText.text as TextSpan;
    expect(root.style?.color, GFoam.ink);
    expect(root.children, hasLength(2));
    expect((root.children!.first as TextSpan).style?.color, isNot(GFoam.ink));
    expect((root.children!.last as TextSpan).style?.color, isNull);
  });
}
