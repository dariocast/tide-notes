import 'dart:convert';

import '../../domain/entities/note.dart';

final class NoteImporter {
  const NoteImporter();

  List<Note> parse(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! List) throw const FormatException('Expected note list');

      return List<Note>.unmodifiable(
        decoded.map(_parseNote).toList(growable: false),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid Tide export: $error');
    }
  }

  Note _parseNote(Object? value) {
    if (value is! Map) throw const FormatException('Invalid note');

    final id = value['id'];
    final content = value['content'];
    final createdAt = value['createdAt'];
    final updatedAt = value['updatedAt'];
    final surfacedAt = value['surfacedAt'];
    final rescueCount = value['rescueCount'];
    if (id is! String ||
        content is! String ||
        createdAt is! String ||
        updatedAt is! String ||
        surfacedAt is! String ||
        rescueCount is! int ||
        rescueCount < 0) {
      throw const FormatException('Invalid note fields');
    }

    try {
      return Note(
        id: id,
        content: content,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        surfacedAt: DateTime.parse(surfacedAt),
        rescueCount: rescueCount,
      );
    } on FormatException {
      throw const FormatException('Invalid note dates');
    }
  }
}
