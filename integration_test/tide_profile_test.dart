import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tide/app.dart';
import 'package:tide/domain/entities/archive_receipt.dart';
import 'package:tide/domain/entities/delete_receipt.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/domain/entities/rescue_receipt.dart';
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

  testWidgets(
    '10,000-note stream scrolls for 30 seconds in profile mode',
    (tester) async {
      final timestamp = DateTime(2026, 7, 19, 12);
      final notes = List.generate(
        10000,
        (index) => Note(
          id: 'note-${10000 - index}',
          content: index.isEven
              ? 'idea: profile stream note $index'
              : 'profile stream note $index',
          createdAt: timestamp.subtract(Duration(minutes: index)),
          updatedAt: timestamp.subtract(Duration(minutes: index)),
          surfacedAt: timestamp.subtract(Duration(minutes: index)),
          rescueCount: index % 4,
        ),
      );
      final repository = _ProfileRepository(notes);
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
        archiveNote: ArchiveNote(repository, now: () => timestamp),
        restoreFromArchive: RestoreFromArchive(repository),
        deleteNote: DeleteNote(repository, now: () => timestamp),
        restoreFromTrash: RestoreFromTrash(repository),
        permanentlyDeleteNote: PermanentlyDeleteNote(repository),
        emptyTrash: EmptyTrash(repository),
        deleteAllNotes: DeleteAllNotes(repository),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        TideApp(
          home: BlocProvider.value(
            value: bloc,
            child: TidePage(now: () => timestamp),
          ),
        ),
      );
      bloc.add(const TideStarted());
      await tester.pumpAndSettle();

      expect(find.byType(NoteCard).evaluate().length, lessThan(100));
      final stopwatch = Stopwatch()..start();
      while (stopwatch.elapsed < const Duration(seconds: 30)) {
        await tester.fling(
          find.byKey(const ValueKey('note-list')),
          const Offset(0, -700),
          1400,
        );
        await tester.pump(const Duration(milliseconds: 450));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        expect(find.byType(NoteCard).evaluate().length, lessThan(100));
      }
      stopwatch.stop();
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

final class _ProfileRepository implements NoteRepository {
  const _ProfileRepository(this.notes);

  final List<Note> notes;

  @override
  Stream<List<Note>> watchNotes() => Stream.value(notes);

  @override
  Future<void> createNote(Note note) async {}

  @override
  Future<int> importNotes(List<Note> notes) async => 0;

  @override
  Future<void> deleteAll() async {}

  @override
  Future<void> updateContent(
    String id,
    String content,
    DateTime updatedAt,
  ) async {}

  @override
  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt) async => null;

  @override
  Future<void> undoRescue(RescueReceipt receipt) async {}

  @override
  Stream<List<Note>> watchArchivedNotes() => const Stream.empty();

  @override
  Stream<List<Note>> watchDeletedNotes() => const Stream.empty();

  @override
  Future<ArchiveReceipt?> archive(String id, DateTime archivedAt) async => null;

  @override
  Future<void> restoreFromArchive(String id) async {}

  @override
  Future<DeleteReceipt?> softDelete(String id, DateTime deletedAt) async =>
      null;

  @override
  Future<void> restoreFromTrash(String id) async {}

  @override
  Future<void> permanentlyDelete(String id) async {}

  @override
  Future<void> emptyTrash() async {}
}
