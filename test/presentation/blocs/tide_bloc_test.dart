import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tide/core/utils/note_exporter.dart';
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
import 'package:tide/domain/usecases/import_notes.dart';
import 'package:tide/domain/usecases/permanently_delete_note.dart';
import 'package:tide/domain/usecases/rescue_note.dart';
import 'package:tide/domain/usecases/restore_from_archive.dart';
import 'package:tide/domain/usecases/restore_from_trash.dart';
import 'package:tide/domain/usecases/undo_rescue.dart';
import 'package:tide/domain/usecases/watch_notes.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/blocs/tide_state.dart';

void main() {
  final now = DateTime(2026, 7, 18, 12);
  final note = Note(
    id: 'n1',
    content: 'todo: ship',
    createdAt: now,
    updatedAt: now,
    surfacedAt: now,
    rescueCount: 0,
  );

  late FakeNoteRepository repository;
  late TideBloc bloc;

  TideBloc buildBloc({Duration editDebounce = Duration.zero}) {
    bloc = TideBloc(
      watchNotes: WatchNotes(repository),
      appendNote: AppendNote(repository, now: () => now, newId: () => 'new'),
      editNote: EditNote(repository, now: () => now),
      rescueNote: RescueNote(repository, now: () => now),
      undoRescue: UndoRescue(repository),
      archiveNote: ArchiveNote(repository, now: () => now),
      restoreFromArchive: RestoreFromArchive(repository),
      deleteNote: DeleteNote(repository, now: () => now),
      restoreFromTrash: RestoreFromTrash(repository),
      permanentlyDeleteNote: PermanentlyDeleteNote(repository),
      emptyTrash: EmptyTrash(repository),
      deleteAllNotes: DeleteAllNotes(repository),
      importNotes: ImportNotes(repository),
      watchArchivedNotes: repository.watchArchivedNotes,
      watchDeletedNotes: repository.watchDeletedNotes,
      editDebounce: editDebounce,
    );
    return bloc;
  }

  setUp(() => repository = FakeNoteRepository());
  tearDown(() async {
    await bloc.close();
    await repository.dispose();
  });

  blocTest<TideBloc, TideState>(
    'started subscribes and emits notes',
    build: () => buildBloc(),
    act: (bloc) async {
      bloc.add(const TideStarted());
      await Future<void>.delayed(Duration.zero);
      repository.emit([note]);
    },
    expect: () => [
      isA<TideState>().having((state) => state.loading, 'loading', true),
      isA<TideState>().having((state) => state.notes, 'notes', [note]),
    ],
  );

  blocTest<TideBloc, TideState>(
    'append failure emits user message without dropping notes',
    build: () {
      repository.notes = [note];
      repository.failAppend = true;
      return buildBloc();
    },
    seed: () => TideState.loaded([note]),
    act: (bloc) => bloc.add(const NoteAppendRequested('new note')),
    expect: () => [
      isA<TideState>()
          .having((state) => state.notes, 'notes', [note])
          .having(
            (state) => state.message,
            'message',
            "Couldn't save note. Try again.",
          ),
    ],
  );

  blocTest<TideBloc, TideState>(
    'delete all emits confirmation message after repository succeeds',
    build: () => buildBloc(),
    seed: () => TideState.loaded([note]),
    act: (bloc) => bloc.add(const NotesDeleteAllRequested()),
    expect: () => [
      isA<TideState>().having(
        (state) => state.message,
        'message',
        'All notes deleted.',
      ),
    ],
    verify: (_) => expect(repository.notes, isEmpty),
  );

  blocTest<TideBloc, TideState>(
    'export requests sharing the current note snapshot',
    build: () {
      return TideBloc(
        watchNotes: WatchNotes(repository),
        appendNote: AppendNote(repository, now: () => now, newId: () => 'new'),
        editNote: EditNote(repository, now: () => now),
        rescueNote: RescueNote(repository, now: () => now),
        undoRescue: UndoRescue(repository),
        archiveNote: ArchiveNote(repository, now: () => now),
        restoreFromArchive: RestoreFromArchive(repository),
        deleteNote: DeleteNote(repository, now: () => now),
        restoreFromTrash: RestoreFromTrash(repository),
        permanentlyDeleteNote: PermanentlyDeleteNote(repository),
        emptyTrash: EmptyTrash(repository),
        deleteAllNotes: DeleteAllNotes(repository),
        noteExporter: NoteExporter(
          now: () => now,
          share: (_) async =>
              const ShareResult('test', ShareResultStatus.success),
        ),
      );
    },
    act: (bloc) => bloc.add(NotesExportRequested([note])),
    expect: () => [
      isA<TideState>().having(
        (state) => state.message,
        'message',
        'Notes exported.',
      ),
    ],
  );

  blocTest<TideBloc, TideState>(
    'import persists notes and emits confirmation message',
    build: () => buildBloc(),
    act: (bloc) => bloc.add(NotesImportRequested([note])),
    expect: () => [
      isA<TideState>().having(
        (state) => state.message,
        'message',
        'Notes imported.',
      ),
    ],
    verify: (_) => expect(repository.notes, [note]),
  );

  blocTest<TideBloc, TideState>(
    'rapid edits persist only newest content',
    build: () => buildBloc(editDebounce: const Duration(milliseconds: 10)),
    act: (bloc) async {
      bloc.add(const NoteEditRequested('n1', 'old'));
      bloc.add(const NoteEditRequested('n1', 'newest'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    },
    verify: (_) => expect(repository.updatedContents, ['newest']),
  );

  blocTest<TideBloc, TideState>(
    'duplicate rescue while in flight invokes use case once',
    build: () => buildBloc(),
    seed: () => TideState.loaded([note]),
    act: (bloc) async {
      bloc.add(const NoteRescueRequested('n1'));
      bloc.add(const NoteRescueRequested('n1'));
      await Future<void>.delayed(Duration.zero);
      repository.completeRescue();
    },
    verify: (_) => expect(repository.rescueCalls, 1),
  );

  blocTest<TideBloc, TideState>(
    'successful rescue exposes receipt and message, undo clears receipt',
    build: () => buildBloc(),
    seed: () => TideState.loaded([note]),
    act: (bloc) async {
      repository.rescueResult = RescueReceipt(
        noteId: note.id,
        previousSurfacedAt: note.surfacedAt,
        previousRescueCount: 0,
        rescuedSurfacedAt: now,
      );
      bloc.add(const NoteRescueRequested('n1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RescueUndoRequested());
    },
    expect: () => [
      isA<TideState>().having((state) => state.busyNoteIds, 'busy note ids', {
        'n1',
      }),
      isA<TideState>()
          .having((state) => state.message, 'message', 'Rescued')
          .having((state) => state.rescueReceipt, 'receipt', isNotNull),
      isA<TideState>().having((state) => state.busyNoteIds, 'busy note ids', {
        'n1',
      }),
      isA<TideState>().having((state) => state.rescueReceipt, 'receipt', null),
    ],
  );

  blocTest<TideBloc, TideState>(
    'archiving a note sets an archive receipt and shows a message',
    build: () {
      repository.notes = [note];
      return buildBloc();
    },
    seed: () => TideState.loaded([note]),
    act: (bloc) => bloc.add(const NoteArchiveRequested('n1')),
    expect: () => [
      isA<TideState>().having((state) => state.busyNoteIds, 'busy note ids', {
        'n1',
      }),
      isA<TideState>()
          .having(
            (state) => state.archiveReceipt?.noteId,
            'archiveReceipt',
            'n1',
          )
          .having((state) => state.message, 'message', 'Archived'),
    ],
  );

  blocTest<TideBloc, TideState>(
    'undoing an archive clears the receipt',
    build: () {
      repository.notes = [note];
      return buildBloc();
    },
    seed: () => TideState.loaded([note]),
    act: (bloc) async {
      bloc.add(const NoteArchiveRequested('n1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ArchiveUndoRequested());
    },
    expect: () => [
      isA<TideState>().having((state) => state.busyNoteIds, 'busy note ids', {
        'n1',
      }),
      isA<TideState>().having(
        (state) => state.archiveReceipt,
        'archiveReceipt',
        isNotNull,
      ),
      isA<TideState>().having((state) => state.busyNoteIds, 'busy note ids', {
        'n1',
      }),
      isA<TideState>().having(
        (state) => state.archiveReceipt,
        'archiveReceipt',
        isNull,
      ),
    ],
  );

  blocTest<TideBloc, TideState>(
    'deleting a note sets a delete receipt and shows a message',
    build: () {
      repository.notes = [note];
      return buildBloc();
    },
    seed: () => TideState.loaded([note]),
    act: (bloc) => bloc.add(const NoteDeleteRequested('n1')),
    expect: () => [
      isA<TideState>().having((state) => state.busyNoteIds, 'busy note ids', {
        'n1',
      }),
      isA<TideState>()
          .having((state) => state.deleteReceipt?.noteId, 'deleteReceipt', 'n1')
          .having((state) => state.message, 'message', 'Deleted'),
    ],
  );

  blocTest<TideBloc, TideState>(
    'TideStarted also loads archived and deleted notes',
    build: () => buildBloc(),
    act: (bloc) async {
      bloc.add(const TideStarted());
      await Future<void>.delayed(Duration.zero);
      repository.emit([note]);
      repository.archivedController.add([note]);
      repository.deletedController.add([note]);
    },
    wait: const Duration(milliseconds: 1),
    expect: () => [
      isA<TideState>().having((state) => state.loading, 'loading', true),
      isA<TideState>().having((state) => state.notes, 'notes', isNotEmpty),
      isA<TideState>().having(
        (state) => state.archivedNotes,
        'archivedNotes',
        isNotEmpty,
      ),
      isA<TideState>().having(
        (state) => state.deletedNotes,
        'deletedNotes',
        isNotEmpty,
      ),
    ],
  );

  blocTest<TideBloc, TideState>(
    'stream error preserves last notes',
    build: () => buildBloc(),
    seed: () => TideState.loaded([note]),
    act: (bloc) async {
      bloc.add(const TideStarted());
      await Future<void>.delayed(Duration.zero);
      repository.emitError(StateError('offline'));
    },
    expect: () => [
      isA<TideState>().having((state) => state.loading, 'loading', true),
      isA<TideState>()
          .having((state) => state.notes, 'notes', [note])
          .having(
            (state) => state.message,
            'message',
            "Couldn't load your stream.",
          ),
    ],
  );

  blocTest<TideBloc, TideState>(
    'archived stream error surfaces a message without a fatal failure',
    build: () => buildBloc(),
    seed: () => TideState.loaded([note]),
    act: (bloc) async {
      bloc.add(const TideStarted());
      await Future<void>.delayed(Duration.zero);
      repository.archivedController.addError(StateError('offline'));
    },
    expect: () => [
      isA<TideState>().having((state) => state.loading, 'loading', true),
      isA<TideState>()
          .having((state) => state.message, 'message', "Couldn't load archive.")
          .having((state) => state.fatalFailure, 'fatalFailure', isNull),
    ],
  );

  blocTest<TideBloc, TideState>(
    'deleted stream error surfaces a message without a fatal failure',
    build: () => buildBloc(),
    seed: () => TideState.loaded([note]),
    act: (bloc) async {
      bloc.add(const TideStarted());
      await Future<void>.delayed(Duration.zero);
      repository.deletedController.addError(StateError('offline'));
    },
    expect: () => [
      isA<TideState>().having((state) => state.loading, 'loading', true),
      isA<TideState>()
          .having((state) => state.message, 'message', "Couldn't load trash.")
          .having((state) => state.fatalFailure, 'fatalFailure', isNull),
    ],
  );

  blocTest<TideBloc, TideState>(
    'message acknowledgement clears message',
    build: () => buildBloc(),
    seed: () => TideState.loaded([note], message: 'error'),
    act: (bloc) => bloc.add(const TideMessageAcknowledged()),
    expect: () => [
      isA<TideState>().having((state) => state.message, 'message', null),
    ],
  );
}

final class FakeNoteRepository implements NoteRepository {
  final StreamController<List<Note>> controller =
      StreamController<List<Note>>.broadcast();
  final StreamController<List<Note>> archivedController =
      StreamController<List<Note>>.broadcast();
  final StreamController<List<Note>> deletedController =
      StreamController<List<Note>>.broadcast();
  final List<String> updatedContents = [];
  List<Note> notes = [];
  bool failAppend = false;
  int rescueCalls = 0;
  RescueReceipt? rescueResult;
  Completer<RescueReceipt?>? rescueCompleter;

  @override
  Stream<List<Note>> watchNotes() => controller.stream;

  @override
  Future<void> createNote(Note note) async {
    if (failAppend) throw StateError('failed');
    notes = [...notes, note];
  }

  @override
  Future<int> importNotes(List<Note> importedNotes) async {
    var count = 0;
    for (final imported in importedNotes) {
      if (notes.any((note) => note.id == imported.id)) continue;
      notes = [...notes, imported];
      count++;
    }
    return count;
  }

  @override
  Future<void> deleteAll() async => notes = [];

  @override
  Future<void> updateContent(
    String id,
    String content,
    DateTime updatedAt,
  ) async {
    updatedContents.add(content);
  }

  @override
  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt) {
    rescueCalls++;
    final completer = rescueCompleter ??= Completer<RescueReceipt?>();
    if (rescueResult != null && !completer.isCompleted) {
      completer.complete(rescueResult);
    }
    return completer.future;
  }

  void completeRescue() {
    final completer = rescueCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(rescueResult);
    }
  }

  @override
  Future<void> undoRescue(RescueReceipt receipt) async {}

  @override
  Stream<List<Note>> watchArchivedNotes() => archivedController.stream;

  @override
  Stream<List<Note>> watchDeletedNotes() => deletedController.stream;

  @override
  Future<ArchiveReceipt?> archive(String id, DateTime archivedAt) async {
    if (!notes.any((note) => note.id == id)) return null;
    archivedController.add(notes.where((note) => note.id == id).toList());
    return ArchiveReceipt(noteId: id, archivedAt: archivedAt);
  }

  @override
  Future<void> restoreFromArchive(String id) async {
    archivedController.add(const []);
  }

  @override
  Future<DeleteReceipt?> softDelete(String id, DateTime deletedAt) async {
    if (!notes.any((note) => note.id == id)) return null;
    deletedController.add(notes.where((note) => note.id == id).toList());
    return DeleteReceipt(noteId: id, deletedAt: deletedAt);
  }

  @override
  Future<void> restoreFromTrash(String id) async {
    deletedController.add(const []);
  }

  @override
  Future<void> permanentlyDelete(String id) async {}

  @override
  Future<void> emptyTrash() async {}

  void emit(List<Note> value) => controller.add(value);

  void emitError(Object error) => controller.addError(error);

  Future<void> dispose() async {
    await controller.close();
    await archivedController.close();
    await deletedController.close();
  }
}
