import '../../domain/entities/note.dart';

final class NoteStats {
  const NoteStats({
    required this.totalNotes,
    required this.totalCharacters,
    required this.longestNoteCharacters,
    required this.mostRescuedCount,
    required this.firstNoteAt,
    required this.notesPerDay,
    required this.averageRescues,
    required this.rescuesPerDay,
    required this.wordCountBuckets,
  });

  final int totalNotes;
  final int totalCharacters;
  final int longestNoteCharacters;
  final int mostRescuedCount;
  final DateTime? firstNoteAt;
  final double notesPerDay;
  final double averageRescues;
  final double rescuesPerDay;
  final List<int> wordCountBuckets;

  static NoteStats compute(List<Note> notes, {required DateTime now}) {
    if (notes.isEmpty) {
      return const NoteStats(
        totalNotes: 0,
        totalCharacters: 0,
        longestNoteCharacters: 0,
        mostRescuedCount: 0,
        firstNoteAt: null,
        notesPerDay: 0,
        averageRescues: 0,
        rescuesPerDay: 0,
        wordCountBuckets: [0, 0, 0, 0],
      );
    }

    final totalCharacters = notes.fold<int>(
      0,
      (sum, note) => sum + note.content.length,
    );
    final longestNoteCharacters = notes
        .map((note) => note.content.length)
        .reduce((a, b) => a > b ? a : b);
    final mostRescuedCount = notes
        .map((note) => note.rescueCount)
        .reduce((a, b) => a > b ? a : b);
    final firstNoteAt = notes
        .map((note) => note.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final totalRescues = notes.fold<int>(
      0,
      (sum, note) => sum + note.rescueCount,
    );
    final ageInDays = now.difference(firstNoteAt).inDays.clamp(1, 1 << 30);

    final buckets = List<int>.filled(4, 0);
    for (final note in notes) {
      final words = note.content
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
      final bucket = words <= 21
          ? 0
          : words <= 41
          ? 1
          : words <= 61
          ? 2
          : 3;
      buckets[bucket]++;
    }

    return NoteStats(
      totalNotes: notes.length,
      totalCharacters: totalCharacters,
      longestNoteCharacters: longestNoteCharacters,
      mostRescuedCount: mostRescuedCount,
      firstNoteAt: firstNoteAt,
      notesPerDay: notes.length / ageInDays,
      averageRescues: totalRescues / notes.length,
      rescuesPerDay: totalRescues / ageInDays,
      wordCountBuckets: buckets,
    );
  }
}
