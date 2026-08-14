import '../repositories/note_repository.dart';

final class RestoreFromTrash {
  const RestoreFromTrash(this._repository);

  final NoteRepository _repository;

  Future<void> call(String id) => _repository.restoreFromTrash(id);
}
