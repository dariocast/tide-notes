import '../../core/utils/content_normalizer.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';
import 'usecase_types.dart';

final class AppendNote {
  AppendNote(this._repository, {required Now now, required NewId newId})
    : _now = now,
      _newId = newId;

  final NoteRepository _repository;
  final Now _now;
  final NewId _newId;

  Future<Note> call(String content) async {
    final normalized = normalizeContent(content);
    final timestamp = _now();
    final note = Note(
      id: _newId(),
      content: normalized,
      createdAt: timestamp,
      updatedAt: timestamp,
      surfacedAt: timestamp,
      rescueCount: 0,
    );
    await _repository.createNote(note);
    return note;
  }
}
