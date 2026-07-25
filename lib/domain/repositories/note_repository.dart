import '../entities/note.dart';
import '../entities/rescue_receipt.dart';

abstract interface class NoteRepository {
  Stream<List<Note>> watchNotes();

  Future<void> createNote(Note note);

  Future<int> importNotes(List<Note> notes);

  Future<void> deleteAll();

  Future<void> updateContent(String id, String content, DateTime updatedAt);

  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt);

  Future<void> undoRescue(RescueReceipt receipt);
}
