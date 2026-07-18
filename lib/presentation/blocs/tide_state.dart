import 'package:equatable/equatable.dart';

import '../../core/error/tide_failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/rescue_receipt.dart';

final class TideState extends Equatable {
  const TideState({
    this.notes = const [],
    this.loading = false,
    this.busyNoteIds = const {},
    this.message,
    this.rescueReceipt,
    this.fatalFailure,
    this.appendCompleted = 0,
  });

  final List<Note> notes;
  final bool loading;
  final Set<String> busyNoteIds;
  final String? message;
  final RescueReceipt? rescueReceipt;
  final TideFailure? fatalFailure;
  final int appendCompleted;

  factory TideState.loaded(List<Note> notes, {String? message}) =>
      TideState(notes: List.unmodifiable(notes), message: message);

  TideState copyWith({
    List<Note>? notes,
    bool? loading,
    Set<String>? busyNoteIds,
    String? message,
    bool clearMessage = false,
    RescueReceipt? rescueReceipt,
    bool clearRescueReceipt = false,
    TideFailure? fatalFailure,
    bool clearFatalFailure = false,
    int? appendCompleted,
  }) => TideState(
    notes: notes ?? this.notes,
    loading: loading ?? this.loading,
    busyNoteIds: busyNoteIds ?? this.busyNoteIds,
    message: clearMessage ? null : message ?? this.message,
    rescueReceipt: clearRescueReceipt
        ? null
        : rescueReceipt ?? this.rescueReceipt,
    fatalFailure: clearFatalFailure ? null : fatalFailure ?? this.fatalFailure,
    appendCompleted: appendCompleted ?? this.appendCompleted,
  );

  @override
  List<Object?> get props => [
    notes,
    loading,
    busyNoteIds,
    message,
    rescueReceipt,
    fatalFailure,
    appendCompleted,
  ];
}
