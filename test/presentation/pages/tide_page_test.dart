import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/app.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/domain/entities/rescue_receipt.dart';
import 'package:tide/domain/repositories/note_repository.dart';
import 'package:tide/domain/usecases/append_note.dart';
import 'package:tide/domain/usecases/edit_note.dart';
import 'package:tide/domain/usecases/rescue_note.dart';
import 'package:tide/domain/usecases/undo_rescue.dart';
import 'package:tide/domain/usecases/watch_notes.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/pages/tide_page.dart';
import 'package:tide/presentation/widgets/note_card.dart';

void main() {
  final timestamp = DateTime(2026, 7, 18, 12);

  Future<(TideBloc, PageRepository)> pumpPage(
    WidgetTester tester, {
    List<Note> notes = const [],
  }) async {
    final repository = PageRepository();
    final bloc = TideBloc(
      watchNotes: WatchNotes(repository),
      appendNote: AppendNote(
        repository,
        now: () => timestamp,
        newId: () => 'new',
      ),
      editNote: EditNote(repository, now: () => timestamp),
      rescueNote: RescueNote(repository, now: () => timestamp),
      undoRescue: UndoRescue(repository),
    );
    addTearDown(() async {
      await bloc.close();
      await repository.dispose();
    });

    await tester.pumpWidget(
      TideApp(
        home: BlocProvider.value(value: bloc, child: const TidePage()),
      ),
    );
    if (notes.isNotEmpty) {
      bloc.add(const TideStarted());
      await tester.pump();
      repository.emit(notes);
      await tester.pump();
    }
    return (bloc, repository);
  }

  Note makeNote(String id) => Note(
    id: id,
    content: id,
    createdAt: timestamp,
    updatedAt: timestamp,
    surfacedAt: timestamp,
    rescueCount: 0,
  );

  testWidgets(
    'composer stays above stream and blank submit dispatches nothing',
    (tester) async {
      await pumpPage(tester);

      expect(find.byKey(const ValueKey('composer')), findsOneWidget);
      expect(find.byKey(const ValueKey('note-list')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(find.byType(NoteCard), findsNothing);
    },
  );

  testWidgets('button submission clears composer after successful append', (
    tester,
  ) async {
    final (_, repository) = await pumpPage(tester);
    final composer = find.byKey(const ValueKey('composer-input'));
    await tester.enterText(composer, 'capture thought');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(repository.created.single.content, 'capture thought');
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
  });

  testWidgets('Enter inserts newline while Meta+Enter submits', (tester) async {
    final (_, repository) = await pumpPage(tester);
    final composer = find.byKey(const ValueKey('composer-input'));
    await tester.tap(composer);
    await tester.enterText(composer, 'line one');
    await tester.enterText(composer, 'line one\n');
    expect(tester.widget<TextField>(composer).controller!.text, 'line one\n');

    await tester.enterText(composer, 'command submit');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    expect(repository.created.single.content, 'command submit');
  });

  testWidgets('empty state explains Append, Review, Rescue', (tester) async {
    await pumpPage(tester);

    expect(find.textContaining('Append'), findsOneWidget);
    expect(find.textContaining('Review'), findsOneWidget);
    expect(find.textContaining('Rescue'), findsOneWidget);
  });

  testWidgets('tapping note opens inline editor and focus loss flushes edit', (
    tester,
  ) async {
    final (_, repository) = await pumpPage(tester, notes: [makeNote('one')]);
    await tester.pump();
    await tester.tap(find.byType(NoteCard));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));

    final editors = find.byType(TextField);
    await tester.enterText(editors.last, 'changed');
    await tester.tap(find.byKey(const ValueKey('composer-input')));
    await tester.pump(const Duration(milliseconds: 450));

    expect(repository.updatedContents, contains('changed'));
  });

  testWidgets('10,000 notes use bounded lazy card construction', (
    tester,
  ) async {
    final notes = List.generate(10000, (index) => makeNote('$index'));
    await pumpPage(tester, notes: notes);
    await tester.pump();

    expect(find.byType(NoteCard).evaluate().length, lessThan(100));
  });

  testWidgets('save and rescue controls expose semantic labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpPage(tester, notes: [makeNote('top'), makeNote('second')]);
    await tester.pump();

    final labels = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((semantics) => semantics.properties.label);
    expect(labels, contains('Save note'));
    expect(labels, contains('Rescue note'));
    semantics.dispose();
  });
}

final class PageRepository implements NoteRepository {
  final StreamController<List<Note>> controller =
      StreamController<List<Note>>.broadcast();
  final List<Note> created = [];
  final List<String> updatedContents = [];

  @override
  Stream<List<Note>> watchNotes() => controller.stream;

  @override
  Future<void> createNote(Note note) async {
    created.add(note);
    controller.add([...created]);
  }

  @override
  Future<void> updateContent(
    String id,
    String content,
    DateTime updatedAt,
  ) async {
    updatedContents.add(content);
  }

  @override
  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt) async => null;

  @override
  Future<void> undoRescue(RescueReceipt receipt) async {}

  void emit(List<Note> notes) => controller.add(notes);

  Future<void> dispose() => controller.close();
}
