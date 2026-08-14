import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tide/app.dart';
import 'package:tide/data/datasources/local/tide_database.dart';
import 'package:tide/data/repositories/local_note_repository.dart';
import 'package:tide/domain/repositories/note_repository.dart';
import 'package:tide/domain/usecases/append_note.dart';
import 'package:tide/domain/usecases/archive_note.dart';
import 'package:tide/domain/usecases/edit_note.dart';
import 'package:tide/domain/usecases/delete_all_notes.dart';
import 'package:tide/domain/usecases/delete_note.dart';
import 'package:tide/domain/usecases/empty_trash.dart';
import 'package:tide/domain/usecases/permanently_delete_note.dart';
import 'package:tide/domain/usecases/rescue_note.dart';
import 'package:tide/domain/usecases/restore_from_archive.dart';
import 'package:tide/domain/usecases/restore_from_trash.dart';
import 'package:tide/domain/usecases/undo_rescue.dart';
import 'package:tide/domain/usecases/watch_notes.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/pages/tide_page.dart';
import 'package:tide/presentation/widgets/note_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('append edit rescue undo survives database reopen', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp('tide-flow-');
    final file = File('${directory.path}/tide.sqlite');
    final database = TideDatabase.forTesting(NativeDatabase(file));
    final repository = LocalNoteRepository(database);
    final bloc = _createBloc(repository);
    addTearDown(() async {
      await bloc.close();
      await database.close();
      await directory.delete(recursive: true);
    });

    await tester.pumpWidget(
      TideApp(
        home: BlocProvider.value(value: bloc, child: const TidePage()),
      ),
    );
    bloc.add(const TideStarted());
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('composer-input')),
      'first thought',
    );
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('composer-input')),
      'second thought',
    );
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NoteCard).first);
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));
    final editor = find.byType(TextField).last;
    await tester.showKeyboard(editor);
    await tester.enterText(editor, 'edited second thought');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));

    final beforeRescue = await repository.watchNotes().first;
    expect(
      beforeRescue.map((note) => note.content),
      contains('edited second thought'),
    );

    await tester.drag(find.byType(Dismissible), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Rescued'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    await bloc.close();
    await database.close();
    final reopened = TideDatabase.forTesting(NativeDatabase(file));
    final reopenedRepository = LocalNoteRepository(reopened);
    addTearDown(() async {
      await reopened.close();
    });
    final persisted = await reopenedRepository.watchNotes().first;

    expect(persisted.map((note) => note.content), [
      'edited second thought',
      'first thought',
    ]);
    expect(
      persisted.map((note) => note.surfacedAt),
      beforeRescue.map((note) => note.surfacedAt),
    );
    expect(persisted.every((note) => note.rescueCount == 0), isTrue);
  });
}

TideBloc _createBloc(NoteRepository repository) => TideBloc(
  watchNotes: WatchNotes(repository),
  appendNote: AppendNote(
    repository,
    now: DateTime.now,
    newId: () => DateTime.now().microsecondsSinceEpoch.toString(),
  ),
  editNote: EditNote(repository, now: DateTime.now),
  rescueNote: RescueNote(repository, now: DateTime.now),
  undoRescue: UndoRescue(repository),
  archiveNote: ArchiveNote(repository, now: DateTime.now),
  restoreFromArchive: RestoreFromArchive(repository),
  deleteNote: DeleteNote(repository, now: DateTime.now),
  restoreFromTrash: RestoreFromTrash(repository),
  permanentlyDeleteNote: PermanentlyDeleteNote(repository),
  emptyTrash: EmptyTrash(repository),
  deleteAllNotes: DeleteAllNotes(repository),
);
