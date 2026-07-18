import '../../core/utils/content_normalizer.dart';
import '../repositories/note_repository.dart';
import 'usecase_types.dart';

final class EditNote {
  EditNote(this._repository, {required Now now}) : _now = now;

  final NoteRepository _repository;
  final Now _now;

  Future<void> call({required String id, required String content}) async {
    await _repository.updateContent(id, normalizeContent(content), _now());
  }
}
