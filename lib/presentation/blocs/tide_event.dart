import 'package:equatable/equatable.dart';

import '../../domain/entities/note.dart';

sealed class TideEvent extends Equatable {
  const TideEvent();
}

final class TideStarted extends TideEvent {
  const TideStarted();

  @override
  List<Object> get props => [];
}

final class NoteAppendRequested extends TideEvent {
  const NoteAppendRequested(this.content);

  final String content;

  @override
  List<Object> get props => [content];
}

final class NotesDeleteAllRequested extends TideEvent {
  const NotesDeleteAllRequested();

  @override
  List<Object> get props => [];
}

final class NotesExportRequested extends TideEvent {
  const NotesExportRequested(this.notes);

  final List<Note> notes;

  @override
  List<Object> get props => [notes];
}

final class NoteEditRequested extends TideEvent {
  const NoteEditRequested(this.id, this.content);

  final String id;
  final String content;

  @override
  List<Object> get props => [id, content];
}

final class NoteRescueRequested extends TideEvent {
  const NoteRescueRequested(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

final class RescueUndoRequested extends TideEvent {
  const RescueUndoRequested();

  @override
  List<Object> get props => [];
}

final class TideMessageAcknowledged extends TideEvent {
  const TideMessageAcknowledged();

  @override
  List<Object> get props => [];
}

final class NotesReceived extends TideEvent {
  const NotesReceived(this.notes);

  final List<Note> notes;

  @override
  List<Object> get props => [notes];
}

final class NotesStreamFailed extends TideEvent {
  const NotesStreamFailed(this.error);

  final Object error;

  @override
  List<Object> get props => [error];
}
