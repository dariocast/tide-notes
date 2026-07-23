import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/tide_failure.dart';
import '../../core/utils/note_exporter.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/delete_all_notes.dart';
import '../../domain/usecases/append_note.dart';
import '../../domain/usecases/edit_note.dart';
import '../../domain/usecases/rescue_note.dart';
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
    required DeleteAllNotes deleteAllNotes,
    NoteExporter noteExporter = const NoteExporter(),
    this.editDebounce = const Duration(milliseconds: 350),
  }) : _watchNotes = watchNotes,
       _appendNote = appendNote,
       _editNote = editNote,
       _rescueNote = rescueNote,
       _undoRescue = undoRescue,
       _deleteAllNotes = deleteAllNotes,
       _noteExporter = noteExporter,
       super(const TideState()) {
    on<TideStarted>(_onStarted);
    on<NotesReceived>(_onNotesReceived);
    on<NotesStreamFailed>(_onNotesStreamFailed);
    on<NoteAppendRequested>(_onAppendRequested);
    on<NotesDeleteAllRequested>(_onDeleteAllRequested);
    on<NotesExportRequested>(_onExportRequested);
    on<NoteEditRequested>(_onEditRequested);
    on<NoteRescueRequested>(_onRescueRequested);
    on<RescueUndoRequested>(_onUndoRequested);
    on<TideMessageAcknowledged>(_onMessageAcknowledged);
  }

  final WatchNotes _watchNotes;
  final AppendNote _appendNote;
  final EditNote _editNote;
  final RescueNote _rescueNote;
  final UndoRescue _undoRescue;
  final DeleteAllNotes _deleteAllNotes;
  final NoteExporter _noteExporter;
  final Duration editDebounce;
  final Map<String, int> _editRevisionById = {};
  final Set<String> _rescueInFlight = {};
  StreamSubscription<List<Note>>? _notesSubscription;
  bool _hasLoadedStream = false;

  Future<void> _onStarted(TideStarted event, Emitter<TideState> emit) async {
    emit(state.copyWith(loading: true, clearFatalFailure: true));
    await _notesSubscription?.cancel();
    _hasLoadedStream = state.notes.isNotEmpty;
    try {
      _notesSubscription = _watchNotes().listen(
        (notes) => add(NotesReceived(notes)),
        onError: (Object error, StackTrace stack) =>
            add(NotesStreamFailed(error)),
      );
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

  void _onMessageAcknowledged(
    TideMessageAcknowledged event,
    Emitter<TideState> emit,
  ) => emit(state.copyWith(clearMessage: true));

  @override
  Future<void> close() async {
    await _notesSubscription?.cancel();
    return super.close();
  }
}
