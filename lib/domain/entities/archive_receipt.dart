import 'package:equatable/equatable.dart';

final class ArchiveReceipt extends Equatable {
  const ArchiveReceipt({required this.noteId, required this.archivedAt});

  final String noteId;
  final DateTime archivedAt;

  @override
  List<Object> get props => [noteId, archivedAt];
}
