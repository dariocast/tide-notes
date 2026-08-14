import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/presentation/pages/tide_tutorial_page.dart';

void main() {
  testWidgets('shows demo notes that can be swiped without side effects', (
    tester,
  ) async {
    // NOTE: unlike the plan's original snippet, this does not first pump
    // with `theme: null`. NoteCard's PrefixText (added after this plan was
    // written) reads `Theme.of(context).extension<TideColors>()!`, which
    // default MaterialApp theming doesn't provide -- pumping without the
    // real Tide theme crashes during build. Every other widget test in
    // this suite pumps with `TideAppTheme.foam` from the start for the
    // same reason.
    await tester.pumpWidget(
      MaterialApp(theme: TideAppTheme.foam, home: const TideTutorialPage()),
    );

    expect(find.byKey(const ValueKey('tutorial-note-0')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('tutorial-note-0')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tutorial-note-0')), findsOneWidget);
  });

  testWidgets('long-press opens the edit page against demo content only', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: TideAppTheme.foam, home: const TideTutorialPage()),
    );

    await tester.longPress(find.byKey(const ValueKey('tutorial-note-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-page-input')), findsOneWidget);
  });
}
