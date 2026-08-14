import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/tide_failure.dart';
import '../../core/utils/note_exporter.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/archive_note.dart';
import '../../domain/usecases/delete_all_notes.dart';
import '../../domain/usecases/append_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/edit_note.dart';
import '../../domain/usecases/empty_trash.dart';
import '../../domain/usecases/import_notes.dart';
import '../../domain/usecases/permanently_delete_note.dart';
import '../../domain/usecases/rescue_note.dart';
import '../../domain/usecases/restore_from_archive.dart';
import '../../domain/usecases/restore_from_trash.dart';
import '../../domain/usecases/undo_rescue.dart';
import '../../domain/usecases/watch_notes.dart';
import 'tide_event.dart';
import 'tide_state.dart';

final class TideBloc extends Bloc<TideEvent, TideState> {
  TideBloc({
    required WatchNotes watchNotes,
    required AppendNote appendNote,
    required EditNote editNote,
    required RescueNote rescueNote,
    required UndoRescue undoRescue,
    required ArchiveNote archiveNote,
    required RestoreFromArchive restoreFromArchive,
    required DeleteNote deleteNote,
    required RestoreFromTrash restoreFromTrash,
    required PermanentlyDeleteNote permanentlyDeleteNote,
    required EmptyTrash emptyTrash,
    required DeleteAllNotes deleteAllNotes,
    this.watchArchivedNotes,
    this.watchDeletedNotes,
    NoteExporter noteExporter = const NoteExporter(),
    ImportNotes? importNotes,
    this.editDebounce = const Duration(milliseconds: 350),
  }) : _watchNotes = watchNotes,
       _appendNote = appendNote,
       _editNote = editNote,
       _rescueNote = rescueNote,
       _undoRescue = undoRescue,
       _archiveNote = archiveNote,
       _restoreFromArchive = restoreFromArchive,
       _deleteNote = deleteNote,
       _restoreFromTrash = restoreFromTrash,
       _permanentlyDeleteNote = permanentlyDeleteNote,
       _emptyTrash = emptyTrash,
       _deleteAllNotes = deleteAllNotes,
       _noteExporter = noteExporter,
       _importNotes = importNotes,
       super(const TideState()) {
    on<TideStarted>(_onStarted);
    on<NotesReceived>(_onNotesReceived);
    on<ArchivedNotesReceived>(_onArchivedNotesReceived);
    on<DeletedNotesReceived>(_onDeletedNotesReceived);
    on<NotesStreamFailed>(_onNotesStreamFailed);
    on<ArchivedNotesStreamFailed>(_onArchivedNotesStreamFailed);
    on<DeletedNotesStreamFailed>(_onDeletedNotesStreamFailed);
    on<NoteAppendRequested>(_onAppendRequested);
    on<NotesDeleteAllRequested>(_onDeleteAllRequested);
    on<NotesExportRequested>(_onExportRequested);
    on<NotesImportRequested>(_onImportRequested);
    on<NotesImportFailed>(_onImportFailed);
    on<NoteEditRequested>(_onEditRequested);
    on<NoteRescueRequested>(_onRescueRequested);
    on<RescueUndoRequested>(_onUndoRequested);
    on<NoteArchiveRequested>(_onArchiveRequested);
    on<ArchiveUndoRequested>(_onArchiveUndoRequested);
    on<NoteDeleteRequested>(_onDeleteRequested);
    on<DeleteUndoRequested>(_onDeleteUndoRequested);
    on<NoteRestoreFromArchiveRequested>(_onRestoreFromArchiveRequested);
    on<NoteRestoreFromTrashRequested>(_onRestoreFromTrashRequested);
    on<NotePermanentlyDeleteRequested>(_onPermanentlyDeleteRequested);
    on<TrashEmptyRequested>(_onTrashEmptyRequested);
    on<TideMessageAcknowledged>(_onMessageAcknowledged);
  }

  final WatchNotes _watchNotes;
  final AppendNote _appendNote;
  final EditNote _editNote;
  final RescueNote _rescueNote;
  final UndoRescue _undoRescue;
  final ArchiveNote _archiveNote;
  final RestoreFromArchive _restoreFromArchive;
  final DeleteNote _deleteNote;
  final RestoreFromTrash _restoreFromTrash;
  final PermanentlyDeleteNote _permanentlyDeleteNote;
  final EmptyTrash _emptyTrash;
  final DeleteAllNotes _deleteAllNotes;
  final NoteExporter _noteExporter;
  final ImportNotes? _importNotes;
  final Stream<List<Note>> Function()? watchArchivedNotes;
  final Stream<List<Note>> Function()? watchDeletedNotes;
  final Duration editDebounce;
  final Map<String, int> _editRevisionById = {};
  final Set<String> _rescueInFlight = {};
  StreamSubscription<List<Note>>? _notesSubscription;
  StreamSubscription<List<Note>>? _archivedNotesSubscription;
  StreamSubscription<List<Note>>? _deletedNotesSubscription;
  bool _hasLoadedStream = false;

  Future<void> _onStarted(TideStarted event, Emitter<TideState> emit) async {
    emit(state.copyWith(loading: true, clearFatalFailure: true));
    await _notesSubscription?.cancel();
    await _archivedNotesSubscription?.cancel();
    await _deletedNotesSubscription?.cancel();
    _hasLoadedStream = state.notes.isNotEmpty;
    try {
      _notesSubscription = _watchNotes().listen(
        (notes) => add(NotesReceived(notes)),
        onError: (Object error, StackTrace stack) =>
            add(NotesStreamFailed(error)),
      );
      final watchArchived = watchArchivedNotes;
      if (watchArchived != null) {
        _archivedNotesSubscription = watchArchived().listen(
          (notes) => add(ArchivedNotesReceived(notes)),
          onError: (Object error, StackTrace stack) =>
              add(ArchivedNotesStreamFailed(error)),
        );
      }
      final watchDeleted = watchDeletedNotes;
      if (watchDeleted != null) {
        _deletedNotesSubscription = watchDeleted().listen(
          (notes) => add(DeletedNotesReceived(notes)),
          onError: (Object error, StackTrace stack) =>
              add(DeletedNotesStreamFailed(error)),
        );
      }
    } catch (error) {
      add(NotesStreamFailed(error));
    }
  }

  void _onNotesReceived(NotesReceived event, Emitter<TideState> emit) {
    _hasLoadedStream = true;
    emit(
      state.copyWith(
        notes: List.unmodifiable(event.notes),
        loading: false,
        clearFatalFailure: true,
      ),
    );
  }

  void _onArchivedNotesReceived(
    ArchivedNotesReceived event,
    Emitter<TideState> emit,
  ) => emit(state.copyWith(archivedNotes: List.unmodifiable(event.notes)));

  void _onDeletedNotesReceived(
    DeletedNotesReceived event,
    Emitter<TideState> emit,
  ) => emit(state.copyWith(deletedNotes: List.unmodifiable(event.notes)));

  void _onNotesStreamFailed(NotesStreamFailed event, Emitter<TideState> emit) {
    const message = "Couldn't load your stream.";
    emit(
      state.copyWith(
        loading: false,
        message: _hasLoadedStream ? message : null,
        clearMessage: !_hasLoadedStream ? true : false,
        fatalFailure: _hasLoadedStream
            ? null
            : const TideFailure(message: message, retryable: true),
      ),
    );
  }

  void _onArchivedNotesStreamFailed(
    ArchivedNotesStreamFailed event,
    Emitter<TideState> emit,
  ) => emit(state.copyWith(message: "Couldn't load archive."));

  void _onDeletedNotesStreamFailed(
    DeletedNotesStreamFailed event,
    Emitter<TideState> emit,
  ) => emit(state.copyWith(message: "Couldn't load trash."));

  Future<void> _onAppendRequested(
    NoteAppendRequested event,
    Emitter<TideState> emit,
  ) async {
    try {
      await _appendNote(event.content);
      emit(state.copyWith(appendCompleted: state.appendCompleted + 1));
    } catch (_) {
      emit(state.copyWith(message: "Couldn't save note. Try again."));
    }
  }

  Future<void> _onDeleteAllRequested(
    NotesDeleteAllRequested event,
    Emitter<TideState> emit,
  ) async {
    try {
      await _deleteAllNotes();
      emit(state.copyWith(message: 'All notes deleted.'));
    } catch (_) {
      emit(state.copyWith(message: "Couldn't delete notes. Try again."));
    }
  }

  Future<void> _onExportRequested(
    NotesExportRequested event,
    Emitter<TideState> emit,
  ) async {
    try {
      await _noteExporter(event.notes);
      emit(state.copyWith(message: 'Notes exported.'));
    } catch (_) {
      emit(state.copyWith(message: "Couldn't export notes. Try again."));
    }
  }

  Future<void> _onImportRequested(
    NotesImportRequested event,
    Emitter<TideState> emit,
  ) async {
    final importNotes = _importNotes;
    if (importNotes == null) {
      emit(state.copyWith(message: "Couldn't import notes. Try again."));
      return;
    }
    try {
      final imported = await importNotes(event.notes);
      emit(
        state.copyWith(
          message: imported == 0 ? 'No new notes imported.' : 'Notes imported.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(message: "Couldn't import notes. Try again."));
    }
  }

  void _onImportFailed(NotesImportFailed event, Emitter<TideState> emit) =>
      emit(state.copyWith(message: "Couldn't import notes. Try again."));

  Future<void> _onEditRequested(
    NoteEditRequested event,
    Emitter<TideState> emit,
  ) async {
    final revision = (_editRevisionById[event.id] ?? 0) + 1;
    _editRevisionById[event.id] = revision;
    await Future<void>.delayed(editDebounce);
    if (_editRevisionById[event.id] != revision) return;
    try {
      await _editNote(id: event.id, content: event.content);
    } catch (_) {
      if (_editRevisionById[event.id] == revision) {
        emit(state.copyWith(message: "Couldn't save note. Try again."));
      }
    }
  }

  Future<void> _onRescueRequested(
    NoteRescueRequested event,
    Emitter<TideState> emit,
  ) async {
    if (!_rescueInFlight.add(event.id)) return;
    emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, event.id}));
    try {
      final receipt = await _rescueNote(event.id);
      final busy = {...state.busyNoteIds}..remove(event.id);
      if (receipt == null) {
        emit(state.copyWith(busyNoteIds: busy));
      } else {
        emit(
          state.copyWith(
            busyNoteIds: busy,
            rescueReceipt: receipt,
            message: 'Rescued',
          ),
        );
      }
    } catch (_) {
      final busy = {...state.busyNoteIds}..remove(event.id);
      emit(state.copyWith(busyNoteIds: busy, message: "Couldn't rescue note."));
    } finally {
      _rescueInFlight.remove(event.id);
    }
  }

  Future<void> _onUndoRequested(
    RescueUndoRequested event,
    Emitter<TideState> emit,
  ) async {
    final receipt = state.rescueReceipt;
    if (receipt == null) return;
    emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, receipt.noteId}));
    try {
      await _undoRescue(receipt);
      final busy = {...state.busyNoteIds}..remove(receipt.noteId);
      emit(state.copyWith(busyNoteIds: busy, clearRescueReceipt: true));
    } catch (_) {
      final busy = {...state.busyNoteIds}..remove(receipt.noteId);
      emit(state.copyWith(busyNoteIds: busy, message: "Couldn't rescue note."));
    }
  }

  Future<void> _onArchiveRequested(
    NoteArchiveRequested event,
    Emitter<TideState> emit,
  ) async {
    if (!_rescueInFlight.add(event.id)) return;
    emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, event.id}));
    try {
      final receipt = await _archiveNote(event.id);
      final busy = {...state.busyNoteIds}..remove(event.id);
      if (receipt == null) {
        emit(state.copyWith(busyNoteIds: busy));
      } else {
        emit(
          state.copyWith(
            busyNoteIds: busy,
            archiveReceipt: receipt,
            message: 'Archived',
          ),
        );
      }
    } catch (_) {
      final busy = {...state.busyNoteIds}..remove(event.id);
      emit(
        state.copyWith(busyNoteIds: busy, message: "Couldn't archive note."),
      );
    } finally {
      _rescueInFlight.remove(event.id);
    }
  }

  Future<void> _onArchiveUndoRequested(
    ArchiveUndoRequested event,
    Emitter<TideState> emit,
  ) async {
    final receipt = state.archiveReceipt;
    if (receipt == null) return;
    emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, receipt.noteId}));
    try {
      await _restoreFromArchive(receipt.noteId);
      final busy = {...state.busyNoteIds}..remove(receipt.noteId);
      emit(state.copyWith(busyNoteIds: busy, clearArchiveReceipt: true));
    } catch (_) {
      final busy = {...state.busyNoteIds}..remove(receipt.noteId);
      emit(
        state.copyWith(busyNoteIds: busy, message: "Couldn't archive note."),
      );
    }
  }

  Future<void> _onDeleteRequested(
    NoteDeleteRequested event,
    Emitter<TideState> emit,
  ) async {
    if (!_rescueInFlight.add(event.id)) return;
    emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, event.id}));
    try {
      final receipt = await _deleteNote(event.id);
      final busy = {...state.busyNoteIds}..remove(event.id);
      if (receipt == null) {
        emit(state.copyWith(busyNoteIds: busy));
      } else {
        emit(
          state.copyWith(
            busyNoteIds: busy,
            deleteReceipt: receipt,
            message: 'Deleted',
          ),
        );
      }
    } catch (_) {
      final busy = {...state.busyNoteIds}..remove(event.id);
      emit(state.copyWith(busyNoteIds: busy, message: "Couldn't delete note."));
    } finally {
      _rescueInFlight.remove(event.id);
    }
  }

  Future<void> _onDeleteUndoRequested(
    DeleteUndoRequested event,
    Emitter<TideState> emit,
  ) async {
    final receipt = state.deleteReceipt;
    if (receipt == null) return;
    emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, receipt.noteId}));
    try {
      await _restoreFromTrash(receipt.noteId);
      final busy = {...state.busyNoteIds}..remove(receipt.noteId);
      emit(state.copyWith(busyNoteIds: busy, clearDeleteReceipt: true));
    } catch (_) {
      final busy = {...state.busyNoteIds}..remove(receipt.noteId);
      emit(state.copyWith(busyNoteIds: busy, message: "Couldn't delete note."));
    }
  }

  Future<void> _onRestoreFromArchiveRequested(
    NoteRestoreFromArchiveRequested event,
    Emitter<TideState> emit,
  ) async {
    try {
      await _restoreFromArchive(event.id);
    } catch (_) {
      emit(state.copyWith(message: "Couldn't restore note."));
    }
  }

  Future<void> _onRestoreFromTrashRequested(
    NoteRestoreFromTrashRequested event,
    Emitter<TideState> emit,
  ) async {
    try {
      await _restoreFromTrash(event.id);
    } catch (_) {
      emit(state.copyWith(message: "Couldn't restore note."));
    }
  }

  Future<void> _onPermanentlyDeleteRequested(
    NotePermanentlyDeleteRequested event,
    Emitter<TideState> emit,
  ) async {
    try {
      await _permanentlyDeleteNote(event.id);
    } catch (_) {
      emit(state.copyWith(message: "Couldn't delete note."));
    }
  }

  Future<void> _onTrashEmptyRequested(
    TrashEmptyRequested event,
    Emitter<TideState> emit,
  ) async {
    try {
      await _emptyTrash();
      emit(state.copyWith(message: 'Trash emptied.'));
    } catch (_) {
      emit(state.copyWith(message: "Couldn't empty the trash."));
    }
  }

  void _onMessageAcknowledged(
    TideMessageAcknowledged event,
    Emitter<TideState> emit,
  ) => emit(state.copyWith(clearMessage: true));

  @override
  Future<void> close() async {
    await _notesSubscription?.cancel();
    await _archivedNotesSubscription?.cancel();
    await _deletedNotesSubscription?.cancel();
    return super.close();
  }
}
