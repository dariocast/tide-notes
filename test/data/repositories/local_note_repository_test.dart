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
}

Note note(String id, DateTime surfacedAt) => Note(
  id: id,
  content: id,
  createdAt: surfacedAt,
  updatedAt: surfacedAt,
  surfacedAt: surfacedAt,
  rescueCount: 0,
);
