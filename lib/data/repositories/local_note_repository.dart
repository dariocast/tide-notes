import 'package:drift/drift.dart';

import '../../domain/entities/archive_receipt.dart';
import '../../domain/entities/delete_receipt.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/rescue_receipt.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/local/tide_database.dart';
import '../models/note_model.dart';

final class LocalNoteRepository implements NoteRepository {
  const LocalNoteRepository(this._database);

  final TideDatabase _database;

  @override
  Stream<List<Note>> watchNotes() =>
      (_database.select(_database.noteRecords)
            ..where(
              (table) => table.archivedAt.isNull() & table.deletedAt.isNull(),
            )
            ..orderBy([
              (table) => OrderingTerm.desc(table.surfacedAt),
              (table) => OrderingTerm.desc(table.id),
            ]))
          .watch()
          .map(
            (rows) => rows
                .map(NoteModel.fromRecord)
                .map((model) => model.toEntity())
                .toList(growable: false),
          );

  @override
  Stream<List<Note>> watchArchivedNotes() =>
      (_database.select(_database.noteRecords)
            ..where(
              (table) =>
                  table.archivedAt.isNotNull() & table.deletedAt.isNull(),
            )
            ..orderBy([(table) => OrderingTerm.desc(table.archivedAt)]))
          .watch()
          .map(
            (rows) => rows
                .map(NoteModel.fromRecord)
                .map((model) => model.toEntity())
                .toList(growable: false),
          );

  @override
  Stream<List<Note>> watchDeletedNotes() =>
      (_database.select(_database.noteRecords)
            ..where((table) => table.deletedAt.isNotNull())
            ..orderBy([(table) => OrderingTerm.desc(table.deletedAt)]))
          .watch()
          .map(
            (rows) => rows
                .map(NoteModel.fromRecord)
                .map((model) => model.toEntity())
                .toList(growable: false),
          );

  @override
  Future<void> createNote(Note note) => _database
      .into(_database.noteRecords)
      .insert(NoteModel.fromEntity(note).toCompanion());

  @override
  Future<int> importNotes(List<Note> notes) async {
    var imported = 0;
    await _database.transaction(() async {
      for (final note in notes) {
        final existing = await (_database.select(
          _database.noteRecords,
        )..where((table) => table.id.equals(note.id))).getSingleOrNull();
        if (existing != null) continue;
        await _database
            .into(_database.noteRecords)
            .insert(NoteModel.fromEntity(note).toCompanion());
        imported++;
      }
    });
    return imported;
  }

  @override
  Future<void> deleteAll() => _database.delete(_database.noteRecords).go();

  @override
  Future<void> updateContent(
    String id,
    String content,
    DateTime updatedAt,
  ) async {
    await (_database.update(
      _database.noteRecords,
    )..where((table) => table.id.equals(id))).write(
      NoteRecordsCompanion(
        content: Value(content),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  @override
  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt) =>
      _database.transaction(() async {
        final current = await (_database.select(
          _database.noteRecords,
        )..where((table) => table.id.equals(id))).getSingleOrNull();
        if (current == null) return null;

        final receipt = RescueReceipt(
          noteId: current.id,
          previousSurfacedAt: current.surfacedAt,
          previousRescueCount: current.rescueCount,
          rescuedSurfacedAt: surfacedAt,
        );
        await (_database.update(
          _database.noteRecords,
        )..where((table) => table.id.equals(id))).write(
          NoteRecordsCompanion(
            surfacedAt: Value(surfacedAt),
            rescueCount: Value(current.rescueCount + 1),
          ),
        );
        return receipt;
      });

  @override
  Future<void> undoRescue(RescueReceipt receipt) =>
      _database.transaction(() async {
        await (_database.update(_database.noteRecords)..where(
              (table) =>
                  table.id.equals(receipt.noteId) &
                  table.surfacedAt.equals(receipt.rescuedSurfacedAt),
            ))
            .write(
              NoteRecordsCompanion(
                surfacedAt: Value(receipt.previousSurfacedAt),
                rescueCount: Value(receipt.previousRescueCount),
              ),
            );
      });

  @override
  Future<ArchiveReceipt?> archive(String id, DateTime archivedAt) =>
      _database.transaction(() async {
        final current = await (_database.select(
          _database.noteRecords,
        )..where((table) => table.id.equals(id))).getSingleOrNull();
        if (current == null) return null;
        await (_database.update(_database.noteRecords)
              ..where((table) => table.id.equals(id)))
            .write(NoteRecordsCompanion(archivedAt: Value(archivedAt)));
        return ArchiveReceipt(noteId: id, archivedAt: archivedAt);
      });

  @override
  Future<void> restoreFromArchive(String id) async {
    await (_database.update(_database.noteRecords)
          ..where((table) => table.id.equals(id)))
        .write(const NoteRecordsCompanion(archivedAt: Value(null)));
  }

  @override
  Future<DeleteReceipt?> softDelete(String id, DateTime deletedAt) =>
      _database.transaction(() async {
        final current = await (_database.select(
          _database.noteRecords,
        )..where((table) => table.id.equals(id))).getSingleOrNull();
        if (current == null) return null;
        await (_database.update(_database.noteRecords)
              ..where((table) => table.id.equals(id)))
            .write(NoteRecordsCompanion(deletedAt: Value(deletedAt)));
        return DeleteReceipt(noteId: id, deletedAt: deletedAt);
      });

  @override
  Future<void> restoreFromTrash(String id) async {
    await (_database.update(_database.noteRecords)
          ..where((table) => table.id.equals(id)))
        .write(const NoteRecordsCompanion(deletedAt: Value(null)));
  }

  @override
  Future<void> permanentlyDelete(String id) => (_database.delete(
    _database.noteRecords,
  )..where((table) => table.id.equals(id))).go();

  @override
  Future<void> emptyTrash() => (_database.delete(
    _database.noteRecords,
  )..where((table) => table.deletedAt.isNotNull())).go();
}
