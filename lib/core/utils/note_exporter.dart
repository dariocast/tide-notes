import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../../domain/entities/note.dart';

typedef ShareTideFile = Future<ShareResult> Function(ShareParams params);

final class NoteExporter {
  const NoteExporter({this.now, this.share});

  final DateTime Function()? now;
  final ShareTideFile? share;

  Future<void> call(List<Note> notes) async {
    final timestamp = now?.call() ?? DateTime.now();
    final fileName = 'tide-${_fileTimestamp(timestamp)}.tide';
    final json = jsonEncode(notes.map(_toJson).toList(growable: false));
    await (share ?? SharePlus.instance.share)(
      ShareParams(
        files: [
          XFile.fromData(utf8.encode(json), mimeType: 'application/json'),
        ],
        fileNameOverrides: [fileName],
        title: 'Tide notes',
      ),
    );
  }

  static Map<String, Object> _toJson(Note note) => {
    'id': note.id,
    'content': note.content,
    'createdAt': note.createdAt.toIso8601String(),
    'updatedAt': note.updatedAt.toIso8601String(),
    'surfacedAt': note.surfacedAt.toIso8601String(),
    'rescueCount': note.rescueCount,
  };

  static String _fileTimestamp(DateTime value) {
    String twoDigits(int component) => component.toString().padLeft(2, '0');

    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}'
        '_${twoDigits(value.hour)}-${twoDigits(value.minute)}';
  }
}
