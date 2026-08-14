import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/data/datasources/local/tide_database.dart';
import 'package:tide/data/repositories/local_note_repository.dart';
import 'package:tide/domain/entities/note.dart';

void main() {
  late TideDatabase database;
  late LocalNoteRepository repository;

  final base = DateTime(2026, 7, 18, 12);
  final older = note('a', base);
  final newer = note('b', base.add(const Duration(minutes: 1)));

  setUp(() {
    database = TideDatabase.forTesting(NativeDatabase.memory());
    repository = LocalNoteRepository(database);
  });

  tearDown(() => database.close());

  test('watch emits notes by surfacedAt then id descending', () async {
    await repository.createNote(older);
    await repository.createNote(newer);

    expect(await repository.watchNotes().first, [newer, older]);
  });

  test('edit persists content without changing surfacedAt', () async {
    await repository.createNote(older);
    final later = base.add(const Duration(hours: 1));

    await repository.updateContent(older.id, 'edited', later);

    final actual = (await repository.watchNotes().first).single;
    expect(actual.content, 'edited');
    expect(actual.updatedAt, later);
    expect(actual.surfacedAt, older.surfacedAt);
  });

  test('deleteAll removes every note', () async {
    await repository.createNote(older);
    await repository.createNote(newer);

    await repository.deleteAll();

    expect(await repository.watchNotes().first, isEmpty);
  });

  test('imports notes and ignores IDs already in the local database', () async {
    await repository.createNote(older);

    final imported = await repository.importNotes([older, newer]);

    expect(imported, 1);
    expect(await repository.watchNotes().first, [newer, older]);
  });

  test('rescue is atomic and returns previous values', () async {
    await repository.createNote(older);
    final later = base.add(const Duration(hours: 1));

    final receipt = await repository.rescue(older.id, later);
    final actual = (await repository.watchNotes().first).single;

    expect(receipt!.previousSurfacedAt, older.surfacedAt);
    expect(actual.surfacedAt, later);
    expect(actual.rescueCount, 1);
  });

  test('undo only applies when rescuedSurfacedAt still matches', () async {
    await repository.createNote(older);
    final later = base.add(const Duration(hours: 1));
    final latest = base.add(const Duration(hours: 2));

    final firstReceipt = await repository.rescue(older.id, later);
    await repository.rescue(older.id, latest);
    await repository.undoRescue(firstReceipt!);

    final actual = (await repository.watchNotes().first).single;
    expect(actual.surfacedAt, latest);
    expect(actual.rescueCount, 2);
  });

  test('watchNotes excludes archived and deleted notes', () async {
    await repository.createNote(older);
    await repository.createNote(newer);

    await repository.archive(older.id, base);
    final afterArchive = await repository.watchNotes().first;
    expect(afterArchive, [newer]);

    await repository.softDelete(newer.id, base);
    final afterDelete = await repository.watchNotes().first;
    expect(afterDelete, isEmpty);
  });

  test(
    'watchArchivedNotes and watchDeletedNotes are mutually exclusive',
    () async {
      await repository.createNote(older);
      await repository.createNote(newer);

      await repository.archive(older.id, base);
      await repository.softDelete(newer.id, base);

      expect((await repository.watchArchivedNotes().first).single.id, older.id);
      expect((await repository.watchDeletedNotes().first).single.id, newer.id);
    },
  );

  test(
    'archive then restoreFromArchive returns note to the main stream',
    () async {
      await repository.createNote(older);

      final receipt = await repository.archive(older.id, base);
      expect(receipt!.noteId, older.id);
      expect(await repository.watchNotes().first, isEmpty);

      await repository.restoreFromArchive(older.id);
      expect((await repository.watchNotes().first).single.archivedAt, isNull);
    },
  );

  test(
    'softDelete then restoreFromTrash returns note to the main stream',
    () async {
      await repository.createNote(older);

      final receipt = await repository.softDelete(older.id, base);
      expect(receipt!.noteId, older.id);
      expect(await repository.watchDeletedNotes().first, hasLength(1));

      await repository.restoreFromTrash(older.id);
      expect((await repository.watchNotes().first).single.deletedAt, isNull);
    },
  );

  test('permanentlyDelete removes a single trashed note for good', () async {
    await repository.createNote(older);
    await repository.createNote(newer);
    await repository.softDelete(older.id, base);
    await repository.softDelete(newer.id, base);

    await repository.permanentlyDelete(older.id);

    expect((await repository.watchDeletedNotes().first).single.id, newer.id);
  });

  test(
    'emptyTrash removes every trashed note but leaves active notes alone',
    () async {
      await repository.createNote(older);
      await repository.createNote(newer);
      await repository.softDelete(older.id, base);

      await repository.emptyTrash();

      expect(await repository.watchDeletedNotes().first, isEmpty);
      expect(await repository.watchNotes().first, [newer]);
    },
  );
}

Note note(
  String id,
  DateTime surfacedAt, {
  DateTime? archivedAt,
  DateTime? deletedAt,
}) => Note(
  id: id,
  content: id,
  createdAt: surfacedAt,
  updatedAt: surfacedAt,
  surfacedAt: surfacedAt,
  rescueCount: 0,
  archivedAt: archivedAt,
  deletedAt: deletedAt,
);
