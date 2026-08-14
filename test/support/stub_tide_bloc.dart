import 'package:tide/domain/entities/archive_receipt.dart';
import 'package:tide/domain/entities/delete_receipt.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/domain/entities/rescue_receipt.dart';
import 'package:tide/domain/repositories/note_repository.dart';
import 'package:tide/domain/usecases/append_note.dart';
import 'package:tide/domain/usecases/archive_note.dart';
import 'package:tide/domain/usecases/delete_all_notes.dart';
import 'package:tide/domain/usecases/delete_note.dart';
import 'package:tide/domain/usecases/edit_note.dart';
import 'package:tide/domain/usecases/empty_trash.dart';
import 'package:tide/domain/usecases/permanently_delete_note.dart';
import 'package:tide/domain/usecases/rescue_note.dart';
import 'package:tide/domain/usecases/restore_from_archive.dart';
import 'package:tide/domain/usecases/restore_from_trash.dart';
import 'package:tide/domain/usecases/undo_rescue.dart';
import 'package:tide/domain/usecases/watch_notes.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/blocs/tide_state.dart';

/// A [TideBloc] for widget tests that renders a specific [TideState] without
/// a working repository underneath. `add` only records the dispatched event
/// instead of running it, so a page under test can assert "the right event
/// was dispatched" while a real `TideBloc` would otherwise immediately try
/// (and fail) to hit `_InertNoteRepository`'s empty/no-op implementation.
final class StubTideBloc extends TideBloc {
  StubTideBloc(TideState initial)
    : super(
        watchNotes: WatchNotes(_repository),
        appendNote: AppendNote(
          _repository,
          now: DateTime.now,
          newId: () => 'id',
        ),
        editNote: EditNote(_repository, now: DateTime.now),
        rescueNote: RescueNote(_repository, now: DateTime.now),
        undoRescue: UndoRescue(_repository),
        archiveNote: ArchiveNote(_repository, now: DateTime.now),
        restoreFromArchive: RestoreFromArchive(_repository),
        deleteNote: DeleteNote(_repository, now: DateTime.now),
        restoreFromTrash: RestoreFromTrash(_repository),
        permanentlyDeleteNote: PermanentlyDeleteNote(_repository),
        emptyTrash: EmptyTrash(_repository),
        deleteAllNotes: DeleteAllNotes(_repository),
      ) {
    emit(initial);
  }

  static final _repository = _InertNoteRepository();

  final List<TideEvent> events = [];

  @override
  void add(TideEvent event) {
    events.add(event);
  }
}

final class _InertNoteRepository implements NoteRepository {
  @override
  Stream<List<Note>> watchNotes() => const Stream.empty();

  @override
  Stream<List<Note>> watchArchivedNotes() => const Stream.empty();

  @override
  Stream<List<Note>> watchDeletedNotes() => const Stream.empty();

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
