import '../entities/rescue_receipt.dart';
import '../repositories/note_repository.dart';
import 'usecase_types.dart';

final class RescueNote {
  RescueNote(this._repository, {required Now now}) : _now = now;

  final NoteRepository _repository;
  final Now _now;

  Future<RescueReceipt?> call(String id) => _repository.rescue(id, _now());
}
