import 'package:flutter_test/flutter_test.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/search/note_search.dart';

void main() {
  final timestamp = DateTime(2026, 7, 24, 12);

  Note note(String id, String content) => Note(
    id: id,
    content: content,
    createdAt: timestamp,
    updatedAt: timestamp,
    surfacedAt: timestamp,
    rescueCount: 0,
  );

  test('empty or whitespace query returns every note in source order', () {
    final notes = [
      note('newest', 'Call Alice'),
      note('middle', 'todo: buy milk'),
      note('oldest', 'Read later'),
    ];

    expect(filterNotesByContent(notes, ''), notes);
    expect(filterNotesByContent(notes, '   '), notes);
  });

  test('matches a trimmed case-insensitive substring including prefix', () {
    final matchingFirst = note('first', 'TODO: Buy Milk');
    final nonMatching = note('second', 'Call Alice');
    final matchingLast = note('third', 'todo: buy train tickets');

    expect(
      filterNotesByContent([
        matchingFirst,
        nonMatching,
        matchingLast,
      ], '  ToDo: BuY  '),
      [matchingFirst, matchingLast],
    );
  });

  test(
    'preserves internal whitespace and treats diacritics as significant',
    () {
      final oneSpace = note('one', 'book train');
      final twoSpaces = note('two', 'book  train');
      final accented = note('three', 'caffè');

      expect(filterNotesByContent([oneSpace, twoSpaces], 'book  train'), [
        twoSpaces,
      ]);
      expect(filterNotesByContent([accented], 'caffe'), isEmpty);
    },
  );
}
