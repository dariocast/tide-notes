import 'package:drift/drift.dart';

import '../../domain/entities/note.dart';
import '../datasources/local/tide_database.dart';

final class NoteModel {
  const NoteModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.surfacedAt,
    required this.rescueCount,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime surfacedAt;
  final int rescueCount;

  factory NoteModel.fromRecord(NoteRecord record) => NoteModel(
    id: record.id,
    content: record.content,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    surfacedAt: record.surfacedAt,
    rescueCount: record.rescueCount,
  );

  factory NoteModel.fromEntity(Note note) => NoteModel(
    id: note.id,
    content: note.content,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
    surfacedAt: note.surfacedAt,
    rescueCount: note.rescueCount,
  );

  Note toEntity() => Note(
    id: id,
    content: content,
    createdAt: createdAt,
    updatedAt: updatedAt,
    surfacedAt: surfacedAt,
    rescueCount: rescueCount,
  );

  NoteRecordsCompanion toCompanion() => NoteRecordsCompanion(
    id: Value(id),
    content: Value(content),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    surfacedAt: Value(surfacedAt),
    rescueCount: Value(rescueCount),
  );
}
