import '../../domain/entities/note.dart';

List<Note> filterNotesByContent(List<Note> notes, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return notes;

  return notes
      .where((note) => note.content.toLowerCase().contains(normalizedQuery))
      .toList(growable: false);
}
