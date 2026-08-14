import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/presentation/pages/note_edit_page.dart';

void main() {
  testWidgets('shows the note content and a live markdown preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: NoteEditPage(content: 'idea: title\n**bold**', onSave: (_) {}),
      ),
    );

    expect(find.text('idea: title\n**bold**'), findsOneWidget);
    final bold = tester.widget<Text>(find.text('bold'));
    // flutter_markdown_plus renders inline text via Text.rich, so the
    // resolved style (including the bold weight from the markdown style
    // sheet's `strong` style) lives on the underlying TextSpan rather than
    // on Text.style itself. Same quirk documented in note_card_test.dart
    // for Task 5.
    expect(bold.textSpan?.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('confirming calls onSave with the edited text', (tester) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: NoteEditPage(
          content: 'original',
          onSave: (value) => saved = value,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('edit-page-input')),
      'changed',
    );
    await tester.tap(find.byKey(const ValueKey('edit-page-confirm')));
    await tester.pumpAndSettle();

    expect(saved, 'changed');
  });

  testWidgets('closing does not call onSave', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: NoteEditPage(content: 'original', onSave: (_) => called = true),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('edit-page-input')),
      'changed',
    );
    await tester.tap(find.byKey(const ValueKey('edit-page-close')));
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });
}
