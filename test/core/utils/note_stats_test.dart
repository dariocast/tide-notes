import 'package:flutter_test/flutter_test.dart';
import 'package:tide/core/utils/note_stats.dart';
import 'package:tide/domain/entities/note.dart';

void main() {
  Note note(
    String id,
    String content, {
    int rescueCount = 0,
    DateTime? createdAt,
  }) => Note(
    id: id,
    content: content,
    createdAt: createdAt ?? DateTime(2026, 7, 10),
    updatedAt: DateTime(2026, 7, 10),
    surfacedAt: DateTime(2026, 7, 10),
    rescueCount: rescueCount,
  );

  test('computes totals, averages, and the longest/most-rescued note', () {
    final notes = [
      note('1', 'short', rescueCount: 4, createdAt: DateTime(2026, 7, 10)),
      note('2', 'a somewhat longer note body here', rescueCount: 1),
    ];

    final stats = NoteStats.compute(notes, now: DateTime(2026, 7, 20));

    expect(stats.totalNotes, 2);
    expect(
      stats.totalCharacters,
      'short'.length + 'a somewhat longer note body here'.length,
    );
    expect(
      stats.longestNoteCharacters,
      'a somewhat longer note body here'.length,
    );
    expect(stats.mostRescuedCount, 4);
    expect(stats.firstNoteAt, DateTime(2026, 7, 10));
    expect(stats.notesPerDay, closeTo(2 / 10, 0.001));
    expect(stats.averageRescues, closeTo((4 + 1) / 2, 0.001));
    expect(stats.rescuesPerDay, closeTo(5 / 10, 0.001));
  });

  test('handles an empty note list without dividing by zero', () {
    final stats = NoteStats.compute(const [], now: DateTime(2026, 7, 20));

    expect(stats.totalNotes, 0);
    expect(stats.notesPerDay, 0);
    expect(stats.averageRescues, 0);
    expect(stats.firstNoteAt, isNull);
  });

  test('buckets word counts into four ranges', () {
    Note withWords(String id, int wordCount) =>
        note(id, List.filled(wordCount, 'w').join(' '));

    final notes = [
      withWords('1', 5),
      withWords('2', 25),
      withWords('3', 45),
      withWords('4', 70),
    ];

    final stats = NoteStats.compute(notes, now: DateTime(2026, 7, 20));

    expect(stats.wordCountBuckets, [1, 1, 1, 1]);
  });
}
