import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/blocs/tide_state.dart';
import 'package:tide/presentation/pages/deleted_notes_page.dart';

import '../../support/stub_tide_bloc.dart';

void main() {
  testWidgets('shows an illustrated empty state with nothing deleted', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: BlocProvider<TideBloc>(
          create: (_) => StubTideBloc(const TideState()),
          child: const DeletedNotesPage(),
        ),
      ),
    );

    expect(find.text('Deleted Notes is empty.'), findsOneWidget);
  });

  testWidgets('swipe-left permanently deletes a single note', (tester) async {
    final note = Note(
      id: 'd1',
      content: 'idea: trashed',
      createdAt: DateTime(2026, 7, 18),
      updatedAt: DateTime(2026, 7, 18),
      surfacedAt: DateTime(2026, 7, 18),
      rescueCount: 0,
      deletedAt: DateTime(2026, 7, 18),
    );
    final bloc = StubTideBloc(TideState(deletedNotes: [note]));
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: BlocProvider<TideBloc>.value(
          value: bloc,
          child: const DeletedNotesPage(),
        ),
      ),
    );

    // PrefixText renders the note's first line via a bare RichText, not a
    // Text/EditableText widget, so find.text/find.textContaining can't see
    // it; assert on its Semantics label instead (see archive_page_test.dart).
    expect(find.bySemanticsLabel(RegExp('trashed')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('note-row')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(bloc.events, contains(isA<NotePermanentlyDeleteRequested>()));
  });

  testWidgets('swipe-right restores a single note', (tester) async {
    final note = Note(
      id: 'd1',
      content: 'idea: trashed',
      createdAt: DateTime(2026, 7, 18),
      updatedAt: DateTime(2026, 7, 18),
      surfacedAt: DateTime(2026, 7, 18),
      rescueCount: 0,
      deletedAt: DateTime(2026, 7, 18),
    );
    final bloc = StubTideBloc(TideState(deletedNotes: [note]));
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: BlocProvider<TideBloc>.value(
          value: bloc,
          child: const DeletedNotesPage(),
        ),
      ),
    );

    // Task 6/8 discovered that DismissiblePane needs a frame pumped
    // mid-gesture before it will treat a released drag as a completed
    // dismiss; a plain tester.drag() delivers its whole down/move/up
    // sequence in one go with no frame pumped in between, so the gesture
    // silently falls back to "open the pane" instead of dismissing.
    // tester.timedDrag() spreads the pointer moves across real frames,
    // matching how Slidable's ScrollMotion notices the gesture in
    // production.
    await tester.timedDrag(
      find.byKey(const ValueKey('note-row')),
      const Offset(400, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(bloc.events, contains(isA<NoteRestoreFromTrashRequested>()));
  });

  testWidgets('Delete All Permanently asks for confirmation before emptying', (
    tester,
  ) async {
    final note = Note(
      id: 'd1',
      content: 'idea: trashed',
      createdAt: DateTime(2026, 7, 18),
      updatedAt: DateTime(2026, 7, 18),
      surfacedAt: DateTime(2026, 7, 18),
      rescueCount: 0,
      deletedAt: DateTime(2026, 7, 18),
    );
    final bloc = StubTideBloc(TideState(deletedNotes: [note]));
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: BlocProvider<TideBloc>.value(
          value: bloc,
          child: const DeletedNotesPage(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('empty-trash')));
    await tester.pumpAndSettle();
    expect(bloc.events, isNot(contains(isA<TrashEmptyRequested>())));

    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();

    expect(bloc.events, contains(isA<TrashEmptyRequested>()));
  });
}
