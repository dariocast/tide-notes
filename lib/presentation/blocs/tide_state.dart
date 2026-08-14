import 'package:equatable/equatable.dart';

import '../../core/error/tide_failure.dart';
import '../../domain/entities/archive_receipt.dart';
import '../../domain/entities/delete_receipt.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/rescue_receipt.dart';

final class TideState extends Equatable {
  const TideState({
    this.notes = const [],
    this.archivedNotes = const [],
    this.deletedNotes = const [],
    this.loading = false,
    this.busyNoteIds = const {},
    this.message,
    this.rescueReceipt,
    this.archiveReceipt,
    this.deleteReceipt,
    this.fatalFailure,
    this.appendCompleted = 0,
  });

  final List<Note> notes;
  final List<Note> archivedNotes;
  final List<Note> deletedNotes;
  final bool loading;
  final Set<String> busyNoteIds;
  final String? message;
  final RescueReceipt? rescueReceipt;
  final ArchiveReceipt? archiveReceipt;
  final DeleteReceipt? deleteReceipt;
  final TideFailure? fatalFailure;
  final int appendCompleted;

  factory TideState.loaded(List<Note> notes, {String? message}) =>
      TideState(notes: List.unmodifiable(notes), message: message);

  TideState copyWith({
    List<Note>? notes,
    List<Note>? archivedNotes,
    List<Note>? deletedNotes,
    bool? loading,
    Set<String>? busyNoteIds,
    String? message,
    bool clearMessage = false,
    RescueReceipt? rescueReceipt,
    bool clearRescueReceipt = false,
    ArchiveReceipt? archiveReceipt,
    bool clearArchiveReceipt = false,
    DeleteReceipt? deleteReceipt,
    bool clearDeleteReceipt = false,
    TideFailure? fatalFailure,
    bool clearFatalFailure = false,
    int? appendCompleted,
  }) => TideState(
    notes: notes ?? this.notes,
    archivedNotes: archivedNotes ?? this.archivedNotes,
    deletedNotes: deletedNotes ?? this.deletedNotes,
    loading: loading ?? this.loading,
    busyNoteIds: busyNoteIds ?? this.busyNoteIds,
    message: clearMessage ? null : message ?? this.message,
    rescueReceipt: clearRescueReceipt
        ? null
        : rescueReceipt ?? this.rescueReceipt,
    archiveReceipt: clearArchiveReceipt
        ? null
        : archiveReceipt ?? this.archiveReceipt,
    deleteReceipt: clearDeleteReceipt
        ? null
        : deleteReceipt ?? this.deleteReceipt,
    fatalFailure: clearFatalFailure ? null : fatalFailure ?? this.fatalFailure,
    appendCompleted: appendCompleted ?? this.appendCompleted,
  );

  @override
  List<Object?> get props => [
    notes,
    archivedNotes,
    deletedNotes,
    loading,
    busyNoteIds,
    message,
    rescueReceipt,
    archiveReceipt,
    deleteReceipt,
    fatalFailure,
    appendCompleted,
  ];
}
