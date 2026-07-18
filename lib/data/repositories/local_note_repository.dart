import 'package:drift/drift.dart';

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
      (_database.select(_database.noteRecords)..orderBy([
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
  Future<void> createNote(Note note) => _database
      .into(_database.noteRecords)
      .insert(NoteModel.fromEntity(note).toCompanion());

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
}
