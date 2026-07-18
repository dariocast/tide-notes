import '../entities/note.dart';
import '../repositories/note_repository.dart';

final class WatchNotes {
  const WatchNotes(this._repository);

  final NoteRepository _repository;

  Stream<List<Note>> call() => _repository.watchNotes();
}
