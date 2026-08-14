import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/design/tide_markdown.dart';

void main() {
  testWidgets('markdown style sheet uses Quicksand headings and Nunito body', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final styleSheet = tideMarkdownStyleSheet(capturedContext);

    expect(styleSheet.h1?.fontFamily, 'Quicksand');
    expect(styleSheet.h2?.fontFamily, 'Quicksand');
    expect(styleSheet.p?.fontFamily, 'Nunito');
    expect(styleSheet.code?.backgroundColor, TideColors.foam.accentSubtle);
    expect(styleSheet.blockquoteDecoration, isA<BoxDecoration>());
  });

  group('markdownBodyFor', () {
    test('returns null for single-line content', () {
      expect(markdownBodyFor('just a title'), isNull);
    });

    test('returns the joined remainder for multi-line content', () {
      expect(
        markdownBodyFor('title\n**bold**\nmore text'),
        '**bold**\nmore text',
      );
    });

    test('returns null when the remainder is only whitespace', () {
      expect(markdownBodyFor('title\n   \n\t'), isNull);
    });
  });
}
