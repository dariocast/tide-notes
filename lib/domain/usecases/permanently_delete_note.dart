import '../repositories/note_repository.dart';

final class PermanentlyDeleteNote {
  const PermanentlyDeleteNote(this._repository);

  final NoteRepository _repository;

  Future<void> call(String id) => _repository.permanentlyDelete(id);
}
