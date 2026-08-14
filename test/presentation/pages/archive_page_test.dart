import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/blocs/tide_state.dart';
import 'package:tide/presentation/pages/archive_page.dart';

import '../../support/stub_tide_bloc.dart';

void main() {
  testWidgets('shows an illustrated empty state with no archived notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: BlocProvider<TideBloc>(
          create: (_) => StubTideBloc(const TideState()),
          child: const ArchivePage(),
        ),
      ),
    );

    expect(find.text('Archive is empty.'), findsOneWidget);
    expect(find.byKey(const ValueKey('archive-empty-icon')), findsOneWidget);
  });

  testWidgets('lists archived notes and restores on swipe-right', (
    tester,
  ) async {
    final note = Note(
      id: 'a1',
      content: 'idea: archived one',
      createdAt: DateTime(2026, 7, 18),
      updatedAt: DateTime(2026, 7, 18),
      surfacedAt: DateTime(2026, 7, 18),
      rescueCount: 0,
      archivedAt: DateTime(2026, 7, 18),
    );
    final bloc = StubTideBloc(TideState(archivedNotes: [note]));
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: BlocProvider<TideBloc>.value(
          value: bloc,
          child: const ArchivePage(),
        ),
      ),
    );

    // PrefixText renders the note's first line via a bare RichText, not a
    // Text/EditableText widget, so find.text/find.textContaining can't see
    // it (see note_card_test.dart's "renders lines after the first as
    // markdown" test for the same discovery). PrefixText does expose the
    // full line as a Semantics label, so assert on that instead.
    expect(find.bySemanticsLabel(RegExp('archived one')), findsOneWidget);

    // Task 6 discovered that DismissiblePane needs a frame pumped
    // mid-gesture ("isDismissibleReady") before it will treat a released
    // drag as a completed dismiss; a plain tester.drag() delivers its
    // whole down/move/up sequence in one go with no frame pumped in
    // between, so the gesture silently falls back to "open the pane"
    // instead of dismissing. tester.timedDrag() spreads the pointer moves
    // across real frames, matching how Slidable's ScrollMotion notices the
    // gesture in production.
    await tester.timedDrag(
      find.byKey(const ValueKey('note-row')),
      const Offset(400, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(bloc.events, contains(isA<NoteRestoreFromArchiveRequested>()));
  });
}
