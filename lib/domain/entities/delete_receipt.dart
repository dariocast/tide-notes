import 'package:equatable/equatable.dart';

final class DeleteReceipt extends Equatable {
  const DeleteReceipt({required this.noteId, required this.deletedAt});

  final String noteId;
  final DateTime deletedAt;

  @override
  List<Object> get props => [noteId, deletedAt];
}
