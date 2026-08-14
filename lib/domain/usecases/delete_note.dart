import '../entities/delete_receipt.dart';
import '../repositories/note_repository.dart';
import 'usecase_types.dart';

final class DeleteNote {
  DeleteNote(this._repository, {required Now now}) : _now = now;

  final NoteRepository _repository;
  final Now _now;

  Future<DeleteReceipt?> call(String id) => _repository.softDelete(id, _now());
}
