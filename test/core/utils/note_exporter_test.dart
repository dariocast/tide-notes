import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tide/core/utils/note_exporter.dart';
import 'package:tide/domain/entities/note.dart';

void main() {
  final timestamp = DateTime(2026, 7, 23, 14, 5);
  final note = Note(
    id: 'n1',
    content: 'idea: export',
    createdAt: timestamp,
    updatedAt: timestamp.add(const Duration(minutes: 1)),
    surfacedAt: timestamp.add(const Duration(minutes: 2)),
    rescueCount: 3,
  );

  test(
    'serializes every note field and uses a human-readable tide filename',
    () async {
      ShareParams? received;
      await NoteExporter(
        now: () => timestamp,
        share: (params) async {
          received = params;
          return const ShareResult('test', ShareResultStatus.success);
        },
      )([note]);

      expect(received!.fileNameOverrides, ['tide-2026-07-23_14-05.tide']);
      final file = received!.files!.single;
      expect(file.mimeType, 'application/json');
      expect(jsonDecode(await file.readAsString()), [
        {
          'id': 'n1',
          'content': 'idea: export',
          'createdAt': '2026-07-23T14:05:00.000',
          'updatedAt': '2026-07-23T14:06:00.000',
          'surfacedAt': '2026-07-23T14:07:00.000',
          'rescueCount': 3,
        },
      ]);
    },
  );

  test('exports an empty note array', () async {
    ShareParams? received;
    await NoteExporter(
      now: () => timestamp,
      share: (params) async {
        received = params;
        return const ShareResult('test', ShareResultStatus.dismissed);
      },
    )([]);

    expect(await received!.files!.single.readAsString(), '[]');
  });
}
