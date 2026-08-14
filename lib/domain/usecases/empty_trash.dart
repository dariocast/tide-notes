import '../repositories/note_repository.dart';

final class EmptyTrash {
  const EmptyTrash(this._repository);

  final NoteRepository _repository;

  Future<void> call() => _repository.emptyTrash();
}
