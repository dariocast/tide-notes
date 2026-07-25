import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tide/core/utils/note_importer.dart';
import 'package:tide/domain/entities/note.dart';

void main() {
  final timestamp = DateTime(2026, 7, 24, 12);

  test('imports notes exported as a JSON array', () {
    final bytes = utf8.encode(
      jsonEncode([
        {
          'id': 'note-1',
          'content': 'Remember the tide',
          'createdAt': timestamp.toIso8601String(),
          'updatedAt': timestamp.toIso8601String(),
          'surfacedAt': timestamp.toIso8601String(),
          'rescueCount': 2,
        },
      ]),
    );

    final notes = NoteImporter().parse(bytes);

    expect(notes, [
      Note(
        id: 'note-1',
        content: 'Remember the tide',
        createdAt: timestamp,
        updatedAt: timestamp,
        surfacedAt: timestamp,
        rescueCount: 2,
      ),
    ]);
  });

  test('rejects malformed or incomplete export files', () {
    expect(
      () => NoteImporter().parse(utf8.encode('{"content":"missing"}')),
      throwsFormatException,
    );
    expect(
      () => NoteImporter().parse(utf8.encode('not json')),
      throwsFormatException,
    );
  });
}
