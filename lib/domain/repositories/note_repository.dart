import '../entities/archive_receipt.dart';
import '../entities/delete_receipt.dart';
import '../entities/note.dart';
import '../entities/rescue_receipt.dart';

abstract interface class NoteRepository {
  Stream<List<Note>> watchNotes();

  Stream<List<Note>> watchArchivedNotes();

  Stream<List<Note>> watchDeletedNotes();

  Future<void> createNote(Note note);

  Future<int> importNotes(List<Note> notes);

  Future<void> deleteAll();

  Future<void> updateContent(String id, String content, DateTime updatedAt);

  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt);

  Future<void> undoRescue(RescueReceipt receipt);

  Future<ArchiveReceipt?> archive(String id, DateTime archivedAt);

  Future<void> restoreFromArchive(String id);

  Future<DeleteReceipt?> softDelete(String id, DateTime deletedAt);

  Future<void> restoreFromTrash(String id);

  Future<void> permanentlyDelete(String id);

  Future<void> emptyTrash();
}
