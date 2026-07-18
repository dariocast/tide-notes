import '../entities/rescue_receipt.dart';
import '../repositories/note_repository.dart';

final class UndoRescue {
  const UndoRescue(this._repository);

  final NoteRepository _repository;

  Future<void> call(RescueReceipt receipt) => _repository.undoRescue(receipt);
}
