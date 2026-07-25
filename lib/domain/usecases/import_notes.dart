import '../entities/note.dart';
import '../repositories/note_repository.dart';

final class ImportNotes {
  const ImportNotes(this._repository);

  final NoteRepository _repository;

  Future<int> call(List<Note> notes) => _repository.importNotes(notes);
}
