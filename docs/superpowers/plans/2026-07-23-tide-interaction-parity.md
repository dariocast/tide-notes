# Tide Interaction Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port Gravity's interaction model — swipe-left action panel, long-press full-screen edit, archive/trash lifecycle, local stats, an interactive tutorial, a sectioned settings menu, search polish, and read-only markdown rendering — onto Tide's existing Atlantic visual foundation, without borrowing any Gravity color, typography, icon asset, or copy.

**Architecture:** Extend `Note` with two nullable lifecycle timestamps (`archivedAt`, `deletedAt`) and add matching repository streams/usecases/BLoC events, following the exact shape of the existing Rescue/Undo feature. Layer new gestures onto `NoteCard` via `flutter_slidable` (replacing the bare `Dismissible`). Add three new read-only screens (Archive, Deleted Notes, Tide Stats) and one interactive one (Tutorial), all reachable from a re-sectioned Settings menu. Render note content as markdown for display only — `Note.content` stays a plain string everywhere; only presentation changes.

**Tech Stack:** Flutter 3 / Dart, flutter_bloc, Drift, `flutter_slidable`, `flutter_markdown_plus`, `share_plus` (already present), Tide's existing `TideIcons` (Font Awesome) and `TideColors`/`TextTheme` tokens.

---

## File Map

- Modify `pubspec.yaml`: add `flutter_slidable` and `flutter_markdown_plus`.
- Modify `lib/domain/entities/note.dart`: add `archivedAt`/`deletedAt`.
- Create `lib/domain/entities/archive_receipt.dart`, `lib/domain/entities/delete_receipt.dart`.
- Modify `lib/domain/repositories/note_repository.dart`: new streams and mutation methods.
- Modify `lib/data/datasources/local/tide_database.dart` (+ regenerate `.g.dart`): new columns, schema migration.
- Modify `lib/data/models/note_model.dart`, `lib/data/repositories/local_note_repository.dart`.
- Create `lib/domain/usecases/archive_note.dart`, `restore_from_archive.dart`, `delete_note.dart`, `restore_from_trash.dart`, `permanently_delete_note.dart`, `empty_trash.dart`.
- Modify `lib/presentation/blocs/tide_event.dart`, `tide_state.dart`, `tide_bloc.dart`.
- Modify `lib/design/tide_icons.dart`.
- Modify `lib/presentation/widgets/note_composer.dart`.
- Create `lib/design/tide_markdown.dart`.
- Modify `lib/presentation/widgets/note_card.dart`, `lib/presentation/widgets/note_stream.dart`, `lib/presentation/pages/tide_page.dart`.
- Create `lib/presentation/pages/note_edit_page.dart`.
- Create `lib/design/tide_illustrations.dart`, `lib/presentation/pages/archive_page.dart`, `lib/presentation/pages/deleted_notes_page.dart`.
- Create `lib/core/utils/note_stats.dart`, `lib/presentation/pages/tide_stats_page.dart`.
- Create `lib/presentation/pages/tide_tutorial_page.dart`.
- Modify `lib/presentation/widgets/tide_settings.dart`, `lib/presentation/widgets/tide_header.dart`.
- Modify `lib/presentation/widgets/tide_search_header.dart`, `lib/presentation/search/note_search.dart`.
- Modify `lib/main.dart`: wire the new usecases and streams into the real `TideBloc`.
- Modify `lib/l10n/tide_localizations.dart`.
- Create `test/support/stub_tide_bloc.dart`; modify test fakes and add new tests across `test/core`, `test/domain`, `test/data`, `test/design`, `test/presentation`.
- Modify `audit-styles.md`.

Domain and BLoC changes are additive only: every new field defaults to `null`/absent, every new usecase/event is a new file, and no existing method signature changes.

---

### Task 1: Archive/Trash Domain Model, Drift Schema, and Repository Queries

**Files:**
- Modify: `lib/domain/entities/note.dart`
- Create: `lib/domain/entities/archive_receipt.dart`
- Create: `lib/domain/entities/delete_receipt.dart`
- Modify: `lib/domain/repositories/note_repository.dart`
- Modify: `lib/data/datasources/local/tide_database.dart`
- Modify: `lib/data/models/note_model.dart`
- Modify: `lib/data/repositories/local_note_repository.dart`
- Modify: `test/data/repositories/local_note_repository_test.dart`
- Modify: `test/domain/usecases/note_usecases_test.dart`
- Modify: `test/presentation/blocs/tide_bloc_test.dart`

- [ ] **Step 1: Write failing repository tests for archive/trash lifecycle**

In `test/data/repositories/local_note_repository_test.dart`, update the `note()` helper to accept the two new nullable fields (defaulting to `null`) and add these tests:

```dart
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
```

```dart
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

test('watchArchivedNotes and watchDeletedNotes are mutually exclusive', () async {
  await repository.createNote(older);
  await repository.createNote(newer);

  await repository.archive(older.id, base);
  await repository.softDelete(newer.id, base);

  expect((await repository.watchArchivedNotes().first).single.id, older.id);
  expect((await repository.watchDeletedNotes().first).single.id, newer.id);
});

test('archive then restoreFromArchive returns note to the main stream', () async {
  await repository.createNote(older);

  final receipt = await repository.archive(older.id, base);
  expect(receipt!.noteId, older.id);
  expect(await repository.watchNotes().first, isEmpty);

  await repository.restoreFromArchive(older.id);
  expect((await repository.watchNotes().first).single.archivedAt, isNull);
});

test('softDelete then restoreFromTrash returns note to the main stream', () async {
  await repository.createNote(older);

  final receipt = await repository.softDelete(older.id, base);
  expect(receipt!.noteId, older.id);
  expect(await repository.watchDeletedNotes().first, hasLength(1));

  await repository.restoreFromTrash(older.id);
  expect((await repository.watchNotes().first).single.deletedAt, isNull);
});

test('permanentlyDelete removes a single trashed note for good', () async {
  await repository.createNote(older);
  await repository.createNote(newer);
  await repository.softDelete(older.id, base);
  await repository.softDelete(newer.id, base);

  await repository.permanentlyDelete(older.id);

  expect((await repository.watchDeletedNotes().first).single.id, newer.id);
});

test('emptyTrash removes every trashed note but leaves active notes alone', () async {
  await repository.createNote(older);
  await repository.createNote(newer);
  await repository.softDelete(older.id, base);

  await repository.emptyTrash();

  expect(await repository.watchDeletedNotes().first, isEmpty);
  expect(await repository.watchNotes().first, [newer]);
});
```

- [ ] **Step 2: Run red tests**

```bash
flutter test test/data/repositories/local_note_repository_test.dart
```

Expected: compile failure — `Note` has no `archivedAt`/`deletedAt` parameters and `NoteRepository` has no `archive`/`softDelete`/etc. methods yet.

- [ ] **Step 3: Add the two lifecycle fields to `Note`**

In `lib/domain/entities/note.dart`, add both fields as optional named constructor parameters defaulting to `null`, and include them in `props`. Do **not** add them to `copyWith` — nothing in the domain layer mutates them via `copyWith`; every archive/delete/restore mutation goes straight through the repository, which reconstructs a fresh `Note` from the updated Drift row.

```dart
final class Note extends Equatable {
  const Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.surfacedAt,
    required this.rescueCount,
    this.archivedAt,
    this.deletedAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime surfacedAt;
  final int rescueCount;
  final DateTime? archivedAt;
  final DateTime? deletedAt;

  Note copyWith({
    String? content,
    DateTime? updatedAt,
    DateTime? surfacedAt,
    int? rescueCount,
  }) => Note(
    id: id,
    content: content ?? this.content,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    surfacedAt: surfacedAt ?? this.surfacedAt,
    rescueCount: rescueCount ?? this.rescueCount,
    archivedAt: archivedAt,
    deletedAt: deletedAt,
  );

  @override
  List<Object?> get props => [
    id,
    content,
    createdAt,
    updatedAt,
    surfacedAt,
    rescueCount,
    archivedAt,
    deletedAt,
  ];
}
```

Note `props` changes from `List<Object>` to `List<Object?>` since the two new fields are nullable.

- [ ] **Step 4: Create the two new receipts**

`lib/domain/entities/archive_receipt.dart`:

```dart
import 'package:equatable/equatable.dart';

final class ArchiveReceipt extends Equatable {
  const ArchiveReceipt({required this.noteId, required this.archivedAt});

  final String noteId;
  final DateTime archivedAt;

  @override
  List<Object> get props => [noteId, archivedAt];
}
```

`lib/domain/entities/delete_receipt.dart`:

```dart
import 'package:equatable/equatable.dart';

final class DeleteReceipt extends Equatable {
  const DeleteReceipt({required this.noteId, required this.deletedAt});

  final String noteId;
  final DateTime deletedAt;

  @override
  List<Object> get props => [noteId, deletedAt];
}
```

Unlike `RescueReceipt`, neither receipt needs "previous value" fields: archiving/deleting only ever sets a timestamp on a note that didn't have one, so undo is simply clearing it back to `null` — there is no prior state to restore.

- [ ] **Step 5: Extend the repository interface**

In `lib/domain/repositories/note_repository.dart`, add:

```dart
import '../entities/archive_receipt.dart';
import '../entities/delete_receipt.dart';
```

and these members to `NoteRepository`:

```dart
Stream<List<Note>> watchArchivedNotes();

Stream<List<Note>> watchDeletedNotes();

Future<ArchiveReceipt?> archive(String id, DateTime archivedAt);

Future<void> restoreFromArchive(String id);

Future<DeleteReceipt?> softDelete(String id, DateTime deletedAt);

Future<void> restoreFromTrash(String id);

Future<void> permanentlyDelete(String id);

Future<void> emptyTrash();
```

- [ ] **Step 6: Add the two nullable columns and a schema migration**

In `lib/data/datasources/local/tide_database.dart`, add the columns to `NoteRecords`:

```dart
class NoteRecords extends Table {
  TextColumn get id => text()();

  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get surfacedAt => dateTime()();

  IntColumn get rescueCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
```

Bump the schema version and add a migration:

```dart
@DriftDatabase(tables: [NoteRecords])
class TideDatabase extends _$TideDatabase {
  TideDatabase() : super(driftDatabase(name: 'tide'));

  TideDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(noteRecords, noteRecords.archivedAt);
        await migrator.addColumn(noteRecords, noteRecords.deletedAt);
      }
    },
  );
}
```

Regenerate the generated database code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Map the new columns through `NoteModel`**

In `lib/data/models/note_model.dart`, add `archivedAt`/`deletedAt` to the constructor, `fromRecord`, `fromEntity`, `toEntity`, and `toCompanion`:

```dart
final class NoteModel {
  const NoteModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.surfacedAt,
    required this.rescueCount,
    this.archivedAt,
    this.deletedAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime surfacedAt;
  final int rescueCount;
  final DateTime? archivedAt;
  final DateTime? deletedAt;

  factory NoteModel.fromRecord(NoteRecord record) => NoteModel(
    id: record.id,
    content: record.content,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    surfacedAt: record.surfacedAt,
    rescueCount: record.rescueCount,
    archivedAt: record.archivedAt,
    deletedAt: record.deletedAt,
  );

  factory NoteModel.fromEntity(Note note) => NoteModel(
    id: note.id,
    content: note.content,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
    surfacedAt: note.surfacedAt,
    rescueCount: note.rescueCount,
    archivedAt: note.archivedAt,
    deletedAt: note.deletedAt,
  );

  Note toEntity() => Note(
    id: id,
    content: content,
    createdAt: createdAt,
    updatedAt: updatedAt,
    surfacedAt: surfacedAt,
    rescueCount: rescueCount,
    archivedAt: archivedAt,
    deletedAt: deletedAt,
  );

  NoteRecordsCompanion toCompanion() => NoteRecordsCompanion(
    id: Value(id),
    content: Value(content),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    surfacedAt: Value(surfacedAt),
    rescueCount: Value(rescueCount),
    archivedAt: Value(archivedAt),
    deletedAt: Value(deletedAt),
  );
}
```

- [ ] **Step 8: Implement the new repository methods**

In `lib/data/repositories/local_note_repository.dart`, add the import for the two receipts, change `watchNotes()` to exclude archived/deleted rows, and add the six new methods:

```dart
import '../../domain/entities/archive_receipt.dart';
import '../../domain/entities/delete_receipt.dart';
```

```dart
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
Future<ArchiveReceipt?> archive(String id, DateTime archivedAt) =>
    _database.transaction(() async {
      final current = await (_database.select(
        _database.noteRecords,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (current == null) return null;
      await (_database.update(
        _database.noteRecords,
      )..where((table) => table.id.equals(id))).write(
        NoteRecordsCompanion(archivedAt: Value(archivedAt)),
      );
      return ArchiveReceipt(noteId: id, archivedAt: archivedAt);
    });

@override
Future<void> restoreFromArchive(String id) async {
  await (_database.update(
    _database.noteRecords,
  )..where((table) => table.id.equals(id))).write(
    const NoteRecordsCompanion(archivedAt: Value(null)),
  );
}

@override
Future<DeleteReceipt?> softDelete(String id, DateTime deletedAt) =>
    _database.transaction(() async {
      final current = await (_database.select(
        _database.noteRecords,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (current == null) return null;
      await (_database.update(
        _database.noteRecords,
      )..where((table) => table.id.equals(id))).write(
        NoteRecordsCompanion(deletedAt: Value(deletedAt)),
      );
      return DeleteReceipt(noteId: id, deletedAt: deletedAt);
    });

@override
Future<void> restoreFromTrash(String id) async {
  await (_database.update(
    _database.noteRecords,
  )..where((table) => table.id.equals(id))).write(
    const NoteRecordsCompanion(deletedAt: Value(null)),
  );
}

@override
Future<void> permanentlyDelete(String id) => (_database.delete(
  _database.noteRecords,
)..where((table) => table.id.equals(id))).go();

@override
Future<void> emptyTrash() => (_database.delete(
  _database.noteRecords,
)..where((table) => table.deletedAt.isNotNull())).go();
```

`Value(null)` (not omitting the field) is required to explicitly write a SQL `NULL` and clear the column — Drift companions otherwise leave a column untouched when absent.

- [ ] **Step 9: Update the two in-memory `FakeNoteRepository` test doubles**

`NoteRepository` now has more members, so both existing fakes fail to compile until updated. In `test/domain/usecases/note_usecases_test.dart`'s `FakeNoteRepository`, add:

```dart
@override
Stream<List<Note>> watchArchivedNotes() => const Stream.empty();

@override
Stream<List<Note>> watchDeletedNotes() => const Stream.empty();

@override
Future<ArchiveReceipt?> archive(String id, DateTime archivedAt) async {
  final index = seeded.indexWhere((note) => note.id == id);
  if (index == -1) return null;
  seeded[index] = Note(
    id: seeded[index].id,
    content: seeded[index].content,
    createdAt: seeded[index].createdAt,
    updatedAt: seeded[index].updatedAt,
    surfacedAt: seeded[index].surfacedAt,
    rescueCount: seeded[index].rescueCount,
    archivedAt: archivedAt,
  );
  return ArchiveReceipt(noteId: id, archivedAt: archivedAt);
}

@override
Future<void> restoreFromArchive(String id) async {}

@override
Future<DeleteReceipt?> softDelete(String id, DateTime deletedAt) async {
  final index = seeded.indexWhere((note) => note.id == id);
  if (index == -1) return null;
  return DeleteReceipt(noteId: id, deletedAt: deletedAt);
}

@override
Future<void> restoreFromTrash(String id) async {}

@override
Future<void> permanentlyDelete(String id) async {}

@override
Future<void> emptyTrash() async {}
```

Add the matching imports (`archive_receipt.dart`, `delete_receipt.dart`). Do the same in `test/presentation/blocs/tide_bloc_test.dart`'s `FakeNoteRepository` — mirror the identical member additions shown above, adapted to that file's existing field/method style (check `rescueResult`/`rescueCompleter` for the pattern already used for `rescue`, and follow it if you want `archive`/`softDelete` to support the same completer-based async-in-flight testing later tasks will need; a synchronous fake like the one above is sufficient for this task alone).

- [ ] **Step 10: Format, verify, and commit Task 1**

```bash
dart format lib/domain lib/data test/data test/domain test/presentation/blocs
flutter test test/data/repositories/local_note_repository_test.dart test/domain/usecases/note_usecases_test.dart test/presentation/blocs/tide_bloc_test.dart
flutter analyze
git add pubspec.lock lib/domain/entities/note.dart lib/domain/entities/archive_receipt.dart lib/domain/entities/delete_receipt.dart lib/domain/repositories/note_repository.dart lib/data/datasources/local/tide_database.dart lib/data/datasources/local/tide_database.g.dart lib/data/models/note_model.dart lib/data/repositories/local_note_repository.dart test/data/repositories/local_note_repository_test.dart test/domain/usecases/note_usecases_test.dart test/presentation/blocs/tide_bloc_test.dart
git commit -m "feat: add archive and trash lifecycle to the note store"
```

---

### Task 2: Archive, Delete, and Restore Usecases

**Files:**
- Create: `lib/domain/usecases/archive_note.dart`
- Create: `lib/domain/usecases/restore_from_archive.dart`
- Create: `lib/domain/usecases/delete_note.dart`
- Create: `lib/domain/usecases/restore_from_trash.dart`
- Create: `lib/domain/usecases/permanently_delete_note.dart`
- Create: `lib/domain/usecases/empty_trash.dart`
- Modify: `test/domain/usecases/note_usecases_test.dart`

Check `lib/domain/usecases/usecase_types.dart` first — it defines the `Now` typedef (`typedef Now = DateTime Function();`) already used by `RescueNote`/`AppendNote`; reuse it rather than redefining.

- [ ] **Step 1: Write failing usecase tests**

Add to `test/domain/usecases/note_usecases_test.dart` (alongside the existing `rescue`/`undo` setup):

```dart
late ArchiveNote archiveNote;
late RestoreFromArchive restoreFromArchive;
late DeleteNote deleteNote;
late RestoreFromTrash restoreFromTrash;
late PermanentlyDeleteNote permanentlyDeleteNote;
late EmptyTrash emptyTrash;
```

inside `setUp`, alongside the existing usecase construction:

```dart
archiveNote = ArchiveNote(repository, now: () => now);
restoreFromArchive = RestoreFromArchive(repository);
deleteNote = DeleteNote(repository, now: () => now);
restoreFromTrash = RestoreFromTrash(repository);
permanentlyDeleteNote = PermanentlyDeleteNote(repository);
emptyTrash = EmptyTrash(repository);
```

and the tests:

```dart
test('archiveNote returns a receipt and restoreFromArchive clears it', () async {
  final receipt = await archiveNote('n1');

  expect(receipt!.noteId, 'n1');
  expect(repository.seeded.single.archivedAt, now);

  await restoreFromArchive('n1');

  expect(repository.seeded.single.archivedAt, isNull);
});

test('deleteNote returns a receipt and restoreFromTrash clears it', () async {
  final receipt = await deleteNote('n1');

  expect(receipt!.noteId, 'n1');

  await restoreFromTrash('n1');
});

test('permanentlyDeleteNote and emptyTrash call through to the repository', () async {
  await permanentlyDeleteNote('n1');
  await emptyTrash();
});
```

Import the new usecases at the top of the file:

```dart
import 'package:tide/domain/entities/archive_receipt.dart';
import 'package:tide/domain/entities/delete_receipt.dart';
import 'package:tide/domain/usecases/archive_note.dart';
import 'package:tide/domain/usecases/delete_note.dart';
import 'package:tide/domain/usecases/empty_trash.dart';
import 'package:tide/domain/usecases/permanently_delete_note.dart';
import 'package:tide/domain/usecases/restore_from_archive.dart';
import 'package:tide/domain/usecases/restore_from_trash.dart';
```

Update the fake's `archive`/`softDelete` (added in Task 1 Step 9) so `permanentlyDelete`/`emptyTrash`/`restoreFromArchive`/`restoreFromTrash` are meaningfully exercised — the simple no-op bodies from Task 1 are sufficient for these tests since they only assert the call completes and, for archive/delete, that the receipt shape and the mutated `archivedAt` are correct.

- [ ] **Step 2: Run red tests**

```bash
flutter test test/domain/usecases/note_usecases_test.dart
```

Expected: compile failure — none of the six usecase classes exist yet.

- [ ] **Step 3: Implement the six usecases**

`lib/domain/usecases/archive_note.dart`:

```dart
import '../entities/archive_receipt.dart';
import '../repositories/note_repository.dart';
import 'usecase_types.dart';

final class ArchiveNote {
  ArchiveNote(this._repository, {required Now now}) : _now = now;

  final NoteRepository _repository;
  final Now _now;

  Future<ArchiveReceipt?> call(String id) => _repository.archive(id, _now());
}
```

`lib/domain/usecases/restore_from_archive.dart`:

```dart
import '../repositories/note_repository.dart';

final class RestoreFromArchive {
  const RestoreFromArchive(this._repository);

  final NoteRepository _repository;

  Future<void> call(String id) => _repository.restoreFromArchive(id);
}
```

`lib/domain/usecases/delete_note.dart`:

```dart
import '../entities/delete_receipt.dart';
import '../repositories/note_repository.dart';
import 'usecase_types.dart';

final class DeleteNote {
  DeleteNote(this._repository, {required Now now}) : _now = now;

  final NoteRepository _repository;
  final Now _now;

  Future<DeleteReceipt?> call(String id) => _repository.softDelete(id, _now());
}
```

`lib/domain/usecases/restore_from_trash.dart`:

```dart
import '../repositories/note_repository.dart';

final class RestoreFromTrash {
  const RestoreFromTrash(this._repository);

  final NoteRepository _repository;

  Future<void> call(String id) => _repository.restoreFromTrash(id);
}
```

`lib/domain/usecases/permanently_delete_note.dart`:

```dart
import '../repositories/note_repository.dart';

final class PermanentlyDeleteNote {
  const PermanentlyDeleteNote(this._repository);

  final NoteRepository _repository;

  Future<void> call(String id) => _repository.permanentlyDelete(id);
}
```

`lib/domain/usecases/empty_trash.dart`:

```dart
import '../repositories/note_repository.dart';

final class EmptyTrash {
  const EmptyTrash(this._repository);

  final NoteRepository _repository;

  Future<void> call() => _repository.emptyTrash();
}
```

- [ ] **Step 4: Run tests, format, analyze, commit**

```bash
flutter test test/domain/usecases/note_usecases_test.dart
dart format lib/domain/usecases test/domain/usecases
flutter analyze
git add lib/domain/usecases/archive_note.dart lib/domain/usecases/restore_from_archive.dart lib/domain/usecases/delete_note.dart lib/domain/usecases/restore_from_trash.dart lib/domain/usecases/permanently_delete_note.dart lib/domain/usecases/empty_trash.dart test/domain/usecases/note_usecases_test.dart
git commit -m "feat: add archive and trash usecases"
```

---

### Task 3: BLoC Wiring — Events, State, and Archived/Deleted Streams

**Files:**
- Modify: `lib/presentation/blocs/tide_event.dart`
- Modify: `lib/presentation/blocs/tide_state.dart`
- Modify: `lib/presentation/blocs/tide_bloc.dart`
- Modify: `lib/main.dart`
- Modify: `lib/l10n/tide_localizations.dart`
- Modify: `test/presentation/blocs/tide_bloc_test.dart`

`TideBloc` already owns every note mutation (append, edit, rescue, undo, delete-all, import, export) behind one `TideState`. This task keeps that single-source-of-truth shape: archive/delete/restore go through the same bloc, and the Archive/Deleted Notes screens (built in Tasks 8–9) read `state.archivedNotes`/`state.deletedNotes` from it rather than subscribing to the repository directly.

- [ ] **Step 1: Write failing BLoC tests**

Add to `test/presentation/blocs/tide_bloc_test.dart`. First extend that file's `FakeNoteRepository` (from Task 1 Step 9) so `watchArchivedNotes()`/`watchDeletedNotes()` are backed by controllable streams instead of `Stream.empty()`:

```dart
final StreamController<List<Note>> archivedController =
    StreamController<List<Note>>.broadcast();
final StreamController<List<Note>> deletedController =
    StreamController<List<Note>>.broadcast();

@override
Stream<List<Note>> watchArchivedNotes() => archivedController.stream;

@override
Stream<List<Note>> watchDeletedNotes() => deletedController.stream;
```

(Keep the archive/softDelete/restore method bodies from Task 1 Step 9, but have `archive`/`softDelete`/`restoreFromArchive`/`restoreFromTrash` push an updated list onto `archivedController`/`deletedController` the same way the existing `rescue` method pushes onto the main stream via `_emit()` — mirror that helper for the two new lists.)

Then add the bloc construction parameters and tests, following the existing rescue test shape exactly:

```dart
bloc = TideBloc(
  watchNotes: WatchNotes(repository),
  appendNote: AppendNote(repository, now: () => now, newId: () => 'new'),
  editNote: EditNote(repository, now: () => now),
  rescueNote: RescueNote(repository, now: () => now),
  undoRescue: UndoRescue(repository),
  archiveNote: ArchiveNote(repository, now: () => now),
  restoreFromArchive: RestoreFromArchive(repository),
  deleteNote: DeleteNote(repository, now: () => now),
  restoreFromTrash: RestoreFromTrash(repository),
  permanentlyDeleteNote: PermanentlyDeleteNote(repository),
  emptyTrash: EmptyTrash(repository),
  deleteAllNotes: DeleteAllNotes(repository),
);
```

```dart
blocTest<TideBloc, TideState>(
  'archiving a note sets an archive receipt and shows a message',
  build: () => bloc,
  act: (bloc) => bloc
    ..add(const TideStarted())
    ..add(const NoteArchiveRequested('n1')),
  wait: const Duration(milliseconds: 1),
  expect: () => [
    isA<TideState>().having((s) => s.loading, 'loading', true),
    isA<TideState>().having((s) => s.notes, 'notes', isNotEmpty),
    isA<TideState>()
        .having((s) => s.archiveReceipt?.noteId, 'archiveReceipt', 'n1')
        .having((s) => s.message, 'message', 'Archived'),
  ],
);

blocTest<TideBloc, TideState>(
  'undoing an archive clears the receipt',
  build: () => bloc,
  act: (bloc) => bloc
    ..add(const TideStarted())
    ..add(const NoteArchiveRequested('n1'))
    ..add(const ArchiveUndoRequested()),
  wait: const Duration(milliseconds: 1),
  expect: () => [
    isA<TideState>().having((s) => s.loading, 'loading', true),
    isA<TideState>().having((s) => s.notes, 'notes', isNotEmpty),
    isA<TideState>().having((s) => s.archiveReceipt, 'archiveReceipt', isNotNull),
    isA<TideState>().having((s) => s.archiveReceipt, 'archiveReceipt', isNull),
  ],
);

blocTest<TideBloc, TideState>(
  'deleting a note sets a delete receipt and shows a message',
  build: () => bloc,
  act: (bloc) => bloc
    ..add(const TideStarted())
    ..add(const NoteDeleteRequested('n1')),
  wait: const Duration(milliseconds: 1),
  expect: () => [
    isA<TideState>().having((s) => s.loading, 'loading', true),
    isA<TideState>().having((s) => s.notes, 'notes', isNotEmpty),
    isA<TideState>()
        .having((s) => s.deleteReceipt?.noteId, 'deleteReceipt', 'n1')
        .having((s) => s.message, 'message', 'Deleted'),
  ],
);

blocTest<TideBloc, TideState>(
  'TideStarted also loads archived and deleted notes',
  build: () => bloc,
  act: (bloc) {
    bloc.add(const TideStarted());
    repository.archivedController.add([repository.seeded.single]);
    repository.deletedController.add([repository.seeded.single]);
  },
  wait: const Duration(milliseconds: 1),
  expect: () => [
    isA<TideState>().having((s) => s.loading, 'loading', true),
    isA<TideState>().having((s) => s.notes, 'notes', isNotEmpty),
    isA<TideState>().having((s) => s.archivedNotes, 'archivedNotes', isNotEmpty),
    isA<TideState>().having((s) => s.deletedNotes, 'deletedNotes', isNotEmpty),
  ],
);
```

Add the corresponding imports (`archive_note.dart`, `restore_from_archive.dart`, `delete_note.dart`, `restore_from_trash.dart`, `permanently_delete_note.dart`, `empty_trash.dart`) to the test file.

- [ ] **Step 2: Run red tests**

```bash
flutter test test/presentation/blocs/tide_bloc_test.dart
```

Expected: compile failure — `TideBloc` doesn't accept the new constructor parameters yet, and `NoteArchiveRequested`/`ArchiveUndoRequested`/`NoteDeleteRequested` don't exist.

- [ ] **Step 3: Add the new events**

In `lib/presentation/blocs/tide_event.dart`, add:

```dart
final class NoteArchiveRequested extends TideEvent {
  const NoteArchiveRequested(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

final class ArchiveUndoRequested extends TideEvent {
  const ArchiveUndoRequested();

  @override
  List<Object> get props => [];
}

final class NoteDeleteRequested extends TideEvent {
  const NoteDeleteRequested(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

final class DeleteUndoRequested extends TideEvent {
  const DeleteUndoRequested();

  @override
  List<Object> get props => [];
}

final class NoteRestoreFromArchiveRequested extends TideEvent {
  const NoteRestoreFromArchiveRequested(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

final class NoteRestoreFromTrashRequested extends TideEvent {
  const NoteRestoreFromTrashRequested(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

final class NotePermanentlyDeleteRequested extends TideEvent {
  const NotePermanentlyDeleteRequested(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

final class TrashEmptyRequested extends TideEvent {
  const TrashEmptyRequested();

  @override
  List<Object> get props => [];
}

final class ArchivedNotesReceived extends TideEvent {
  const ArchivedNotesReceived(this.notes);

  final List<Note> notes;

  @override
  List<Object> get props => [notes];
}

final class DeletedNotesReceived extends TideEvent {
  const DeletedNotesReceived(this.notes);

  final List<Note> notes;

  @override
  List<Object> get props => [notes];
}
```

- [ ] **Step 4: Extend `TideState`**

In `lib/presentation/blocs/tide_state.dart`, add the two receipts and the two new note lists:

```dart
import '../../domain/entities/archive_receipt.dart';
import '../../domain/entities/delete_receipt.dart';
```

```dart
final class TideState extends Equatable {
  const TideState({
    this.notes = const [],
    this.archivedNotes = const [],
    this.deletedNotes = const [],
    this.loading = false,
    this.busyNoteIds = const {},
    this.message,
    this.rescueReceipt,
    this.archiveReceipt,
    this.deleteReceipt,
    this.fatalFailure,
    this.appendCompleted = 0,
  });

  final List<Note> notes;
  final List<Note> archivedNotes;
  final List<Note> deletedNotes;
  final bool loading;
  final Set<String> busyNoteIds;
  final String? message;
  final RescueReceipt? rescueReceipt;
  final ArchiveReceipt? archiveReceipt;
  final DeleteReceipt? deleteReceipt;
  final TideFailure? fatalFailure;
  final int appendCompleted;

  factory TideState.loaded(List<Note> notes, {String? message}) =>
      TideState(notes: List.unmodifiable(notes), message: message);

  TideState copyWith({
    List<Note>? notes,
    List<Note>? archivedNotes,
    List<Note>? deletedNotes,
    bool? loading,
    Set<String>? busyNoteIds,
    String? message,
    bool clearMessage = false,
    RescueReceipt? rescueReceipt,
    bool clearRescueReceipt = false,
    ArchiveReceipt? archiveReceipt,
    bool clearArchiveReceipt = false,
    DeleteReceipt? deleteReceipt,
    bool clearDeleteReceipt = false,
    TideFailure? fatalFailure,
    bool clearFatalFailure = false,
    int? appendCompleted,
  }) => TideState(
    notes: notes ?? this.notes,
    archivedNotes: archivedNotes ?? this.archivedNotes,
    deletedNotes: deletedNotes ?? this.deletedNotes,
    loading: loading ?? this.loading,
    busyNoteIds: busyNoteIds ?? this.busyNoteIds,
    message: clearMessage ? null : message ?? this.message,
    rescueReceipt: clearRescueReceipt
        ? null
        : rescueReceipt ?? this.rescueReceipt,
    archiveReceipt: clearArchiveReceipt
        ? null
        : archiveReceipt ?? this.archiveReceipt,
    deleteReceipt: clearDeleteReceipt
        ? null
        : deleteReceipt ?? this.deleteReceipt,
    fatalFailure: clearFatalFailure ? null : fatalFailure ?? this.fatalFailure,
    appendCompleted: appendCompleted ?? this.appendCompleted,
  );

  @override
  List<Object?> get props => [
    notes,
    archivedNotes,
    deletedNotes,
    loading,
    busyNoteIds,
    message,
    rescueReceipt,
    archiveReceipt,
    deleteReceipt,
    fatalFailure,
    appendCompleted,
  ];
}
```

- [ ] **Step 5: Wire the bloc**

In `lib/presentation/blocs/tide_bloc.dart`, add the six new usecase dependencies, two more stream subscriptions started/cancelled alongside the existing one, and handlers for every new event. Add these imports:

```dart
import '../../domain/usecases/archive_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/empty_trash.dart';
import '../../domain/usecases/permanently_delete_note.dart';
import '../../domain/usecases/restore_from_archive.dart';
import '../../domain/usecases/restore_from_trash.dart';
```

Update the constructor:

```dart
TideBloc({
  required WatchNotes watchNotes,
  required AppendNote appendNote,
  required EditNote editNote,
  required RescueNote rescueNote,
  required UndoRescue undoRescue,
  required ArchiveNote archiveNote,
  required RestoreFromArchive restoreFromArchive,
  required DeleteNote deleteNote,
  required RestoreFromTrash restoreFromTrash,
  required PermanentlyDeleteNote permanentlyDeleteNote,
  required EmptyTrash emptyTrash,
  required DeleteAllNotes deleteAllNotes,
  this.watchArchivedNotes,
  this.watchDeletedNotes,
  NoteExporter noteExporter = const NoteExporter(),
  ImportNotes? importNotes,
  this.editDebounce = const Duration(milliseconds: 350),
}) : _watchNotes = watchNotes,
     _appendNote = appendNote,
     _editNote = editNote,
     _rescueNote = rescueNote,
     _undoRescue = undoRescue,
     _archiveNote = archiveNote,
     _restoreFromArchive = restoreFromArchive,
     _deleteNote = deleteNote,
     _restoreFromTrash = restoreFromTrash,
     _permanentlyDeleteNote = permanentlyDeleteNote,
     _emptyTrash = emptyTrash,
     _deleteAllNotes = deleteAllNotes,
     _noteExporter = noteExporter,
     _importNotes = importNotes,
     super(const TideState()) {
  on<TideStarted>(_onStarted);
  on<NotesReceived>(_onNotesReceived);
  on<ArchivedNotesReceived>(_onArchivedNotesReceived);
  on<DeletedNotesReceived>(_onDeletedNotesReceived);
  on<NotesStreamFailed>(_onNotesStreamFailed);
  on<NoteAppendRequested>(_onAppendRequested);
  on<NotesDeleteAllRequested>(_onDeleteAllRequested);
  on<NotesExportRequested>(_onExportRequested);
  on<NotesImportRequested>(_onImportRequested);
  on<NotesImportFailed>(_onImportFailed);
  on<NoteEditRequested>(_onEditRequested);
  on<NoteRescueRequested>(_onRescueRequested);
  on<RescueUndoRequested>(_onUndoRequested);
  on<NoteArchiveRequested>(_onArchiveRequested);
  on<ArchiveUndoRequested>(_onArchiveUndoRequested);
  on<NoteDeleteRequested>(_onDeleteRequested);
  on<DeleteUndoRequested>(_onDeleteUndoRequested);
  on<NoteRestoreFromArchiveRequested>(_onRestoreFromArchiveRequested);
  on<NoteRestoreFromTrashRequested>(_onRestoreFromTrashRequested);
  on<NotePermanentlyDeleteRequested>(_onPermanentlyDeleteRequested);
  on<TrashEmptyRequested>(_onTrashEmptyRequested);
  on<TideMessageAcknowledged>(_onMessageAcknowledged);
}

final WatchNotes _watchNotes;
final AppendNote _appendNote;
final EditNote _editNote;
final RescueNote _rescueNote;
final UndoRescue _undoRescue;
final ArchiveNote _archiveNote;
final RestoreFromArchive _restoreFromArchive;
final DeleteNote _deleteNote;
final RestoreFromTrash _restoreFromTrash;
final PermanentlyDeleteNote _permanentlyDeleteNote;
final EmptyTrash _emptyTrash;
final DeleteAllNotes _deleteAllNotes;
final NoteExporter _noteExporter;
final ImportNotes? _importNotes;
final Stream<List<Note>> Function()? watchArchivedNotes;
final Stream<List<Note>> Function()? watchDeletedNotes;
final Duration editDebounce;
final Map<String, int> _editRevisionById = {};
final Set<String> _rescueInFlight = {};
StreamSubscription<List<Note>>? _notesSubscription;
StreamSubscription<List<Note>>? _archivedNotesSubscription;
StreamSubscription<List<Note>>? _deletedNotesSubscription;
bool _hasLoadedStream = false;
```

`watchArchivedNotes`/`watchDeletedNotes` are optional constructor parameters (function references, matching how `WatchNotes` itself is already a thin callable usecase) so every existing call site that constructs a `TideBloc` without them keeps compiling; `TidePage`'s production wiring (Task 8/9) will supply real ones.

Update `_onStarted` to also (re)subscribe to both new streams:

```dart
Future<void> _onStarted(TideStarted event, Emitter<TideState> emit) async {
  emit(state.copyWith(loading: true, clearFatalFailure: true));
  await _notesSubscription?.cancel();
  await _archivedNotesSubscription?.cancel();
  await _deletedNotesSubscription?.cancel();
  _hasLoadedStream = state.notes.isNotEmpty;
  try {
    _notesSubscription = _watchNotes().listen(
      (notes) => add(NotesReceived(notes)),
      onError: (Object error, StackTrace stack) =>
          add(NotesStreamFailed(error)),
    );
    final watchArchived = watchArchivedNotes;
    if (watchArchived != null) {
      _archivedNotesSubscription = watchArchived().listen(
        (notes) => add(ArchivedNotesReceived(notes)),
      );
    }
    final watchDeleted = watchDeletedNotes;
    if (watchDeleted != null) {
      _deletedNotesSubscription = watchDeleted().listen(
        (notes) => add(DeletedNotesReceived(notes)),
      );
    }
  } catch (error) {
    add(NotesStreamFailed(error));
  }
}

void _onArchivedNotesReceived(
  ArchivedNotesReceived event,
  Emitter<TideState> emit,
) => emit(state.copyWith(archivedNotes: List.unmodifiable(event.notes)));

void _onDeletedNotesReceived(
  DeletedNotesReceived event,
  Emitter<TideState> emit,
) => emit(state.copyWith(deletedNotes: List.unmodifiable(event.notes)));
```

Add the archive/delete/restore handlers, mirroring `_onRescueRequested`/`_onUndoRequested` exactly (same busy-set bookkeeping, same in-flight guard reused across both new flows and the existing one so a note can't be archived and deleted concurrently):

```dart
Future<void> _onArchiveRequested(
  NoteArchiveRequested event,
  Emitter<TideState> emit,
) async {
  if (!_rescueInFlight.add(event.id)) return;
  emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, event.id}));
  try {
    final receipt = await _archiveNote(event.id);
    final busy = {...state.busyNoteIds}..remove(event.id);
    if (receipt == null) {
      emit(state.copyWith(busyNoteIds: busy));
    } else {
      emit(
        state.copyWith(
          busyNoteIds: busy,
          archiveReceipt: receipt,
          message: 'Archived',
        ),
      );
    }
  } catch (_) {
    final busy = {...state.busyNoteIds}..remove(event.id);
    emit(
      state.copyWith(busyNoteIds: busy, message: "Couldn't archive note."),
    );
  } finally {
    _rescueInFlight.remove(event.id);
  }
}

Future<void> _onArchiveUndoRequested(
  ArchiveUndoRequested event,
  Emitter<TideState> emit,
) async {
  final receipt = state.archiveReceipt;
  if (receipt == null) return;
  emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, receipt.noteId}));
  try {
    await _restoreFromArchive(receipt.noteId);
    final busy = {...state.busyNoteIds}..remove(receipt.noteId);
    emit(state.copyWith(busyNoteIds: busy, clearArchiveReceipt: true));
  } catch (_) {
    final busy = {...state.busyNoteIds}..remove(receipt.noteId);
    emit(
      state.copyWith(busyNoteIds: busy, message: "Couldn't archive note."),
    );
  }
}

Future<void> _onDeleteRequested(
  NoteDeleteRequested event,
  Emitter<TideState> emit,
) async {
  if (!_rescueInFlight.add(event.id)) return;
  emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, event.id}));
  try {
    final receipt = await _deleteNote(event.id);
    final busy = {...state.busyNoteIds}..remove(event.id);
    if (receipt == null) {
      emit(state.copyWith(busyNoteIds: busy));
    } else {
      emit(
        state.copyWith(
          busyNoteIds: busy,
          deleteReceipt: receipt,
          message: 'Deleted',
        ),
      );
    }
  } catch (_) {
    final busy = {...state.busyNoteIds}..remove(event.id);
    emit(state.copyWith(busyNoteIds: busy, message: "Couldn't delete note."));
  } finally {
    _rescueInFlight.remove(event.id);
  }
}

Future<void> _onDeleteUndoRequested(
  DeleteUndoRequested event,
  Emitter<TideState> emit,
) async {
  final receipt = state.deleteReceipt;
  if (receipt == null) return;
  emit(state.copyWith(busyNoteIds: {...state.busyNoteIds, receipt.noteId}));
  try {
    await _restoreFromTrash(receipt.noteId);
    final busy = {...state.busyNoteIds}..remove(receipt.noteId);
    emit(state.copyWith(busyNoteIds: busy, clearDeleteReceipt: true));
  } catch (_) {
    final busy = {...state.busyNoteIds}..remove(receipt.noteId);
    emit(state.copyWith(busyNoteIds: busy, message: "Couldn't delete note."));
  }
}

Future<void> _onRestoreFromArchiveRequested(
  NoteRestoreFromArchiveRequested event,
  Emitter<TideState> emit,
) async {
  try {
    await _restoreFromArchive(event.id);
  } catch (_) {
    emit(state.copyWith(message: "Couldn't restore note."));
  }
}

Future<void> _onRestoreFromTrashRequested(
  NoteRestoreFromTrashRequested event,
  Emitter<TideState> emit,
) async {
  try {
    await _restoreFromTrash(event.id);
  } catch (_) {
    emit(state.copyWith(message: "Couldn't restore note."));
  }
}

Future<void> _onPermanentlyDeleteRequested(
  NotePermanentlyDeleteRequested event,
  Emitter<TideState> emit,
) async {
  try {
    await _permanentlyDeleteNote(event.id);
  } catch (_) {
    emit(state.copyWith(message: "Couldn't delete note."));
  }
}

Future<void> _onTrashEmptyRequested(
  TrashEmptyRequested event,
  Emitter<TideState> emit,
) async {
  try {
    await _emptyTrash();
    emit(state.copyWith(message: 'Trash emptied.'));
  } catch (_) {
    emit(state.copyWith(message: "Couldn't empty the trash."));
  }
}
```

Update `close()` to also cancel the two new subscriptions:

```dart
@override
Future<void> close() async {
  await _notesSubscription?.cancel();
  await _archivedNotesSubscription?.cancel();
  await _deletedNotesSubscription?.cancel();
  return super.close();
}
```

- [ ] **Step 6: Wire the new usecases into the real `TideBloc` in `lib/main.dart`**

`_TideBootstrapState.build` in `lib/main.dart` is where `TideBloc` is actually constructed for the running app (wrapped in a `BlocProvider` around `TideApp`/`MaterialApp` — high enough in the tree that pages pushed later via `Navigator.push`, including the Archive/Deleted Notes/Stats/Tutorial pages built in Tasks 8–11, already inherit it with no further changes needed there). Everything built in Tasks 1–3 is otherwise dead code in the running app until this constructor call is updated. Add the imports:

```dart
import 'domain/usecases/archive_note.dart';
import 'domain/usecases/delete_note.dart';
import 'domain/usecases/empty_trash.dart';
import 'domain/usecases/permanently_delete_note.dart';
import 'domain/usecases/restore_from_archive.dart';
import 'domain/usecases/restore_from_trash.dart';
```

and update the `TideBloc(...)` call:

```dart
create: (_) => TideBloc(
  watchNotes: WatchNotes(repository),
  appendNote: AppendNote(
    repository,
    now: DateTime.now,
    newId: uuid.v4,
  ),
  editNote: EditNote(repository, now: DateTime.now),
  rescueNote: RescueNote(repository, now: DateTime.now),
  undoRescue: UndoRescue(repository),
  archiveNote: ArchiveNote(repository, now: DateTime.now),
  restoreFromArchive: RestoreFromArchive(repository),
  deleteNote: DeleteNote(repository, now: DateTime.now),
  restoreFromTrash: RestoreFromTrash(repository),
  permanentlyDeleteNote: PermanentlyDeleteNote(repository),
  emptyTrash: EmptyTrash(repository),
  deleteAllNotes: DeleteAllNotes(repository),
  importNotes: ImportNotes(repository),
  watchArchivedNotes: repository.watchArchivedNotes,
  watchDeletedNotes: repository.watchDeletedNotes,
)..add(const TideStarted()),
```

- [ ] **Step 7: Add the new transient messages to `TideLocalizations`**

In `lib/l10n/tide_localizations.dart`, extend the `message` switch:

```dart
String message(String value) => switch (value) {
  'Rescued' => isItalian ? 'Riportata a galla' : 'Rescued',
  'Archived' => isItalian ? 'Archiviata' : 'Archived',
  'Deleted' => isItalian ? 'Eliminata' : 'Deleted',
  'Trash emptied.' => isItalian ? 'Cestino svuotato.' : value,
  "Couldn't archive note." =>
    isItalian ? 'Impossibile archiviare la nota.' : value,
  "Couldn't delete note." =>
    isItalian ? 'Impossibile eliminare la nota.' : value,
  "Couldn't restore note." =>
    isItalian ? 'Impossibile ripristinare la nota.' : value,
  "Couldn't empty the trash." =>
    isItalian ? 'Impossibile svuotare il cestino.' : value,
  "Couldn't load your stream." =>
    isItalian ? 'Impossibile caricare il flusso.' : value,
  "Couldn't save note. Try again." =>
    isItalian ? 'Impossibile salvare la nota. Riprova.' : value,
  'All notes deleted.' =>
    isItalian ? 'Tutte le note sono state eliminate.' : value,
  "Couldn't delete notes. Try again." =>
    isItalian ? 'Impossibile eliminare le note. Riprova.' : value,
  'Notes exported.' => isItalian ? 'Note esportate.' : value,
  'Notes imported.' => isItalian ? 'Note importate.' : value,
  'No new notes imported.' =>
    isItalian ? 'Nessuna nuova nota importata.' : value,
  "Couldn't export notes. Try again." =>
    isItalian ? 'Impossibile esportare le note. Riprova.' : value,
  "Couldn't import notes. Try again." =>
    isItalian ? 'Impossibile importare le note. Riprova.' : value,
  "Couldn't rescue note." =>
    isItalian ? 'Impossibile riportare a galla la nota.' : value,
  _ => value,
};
```

`TidePage`'s existing `BlocConsumer` listener already special-cases `'Rescued'` to avoid popping a snackbar for it (since the row's own undo affordance is the feedback). In Task 6, when `TidePage` wires the new archive/delete flows, add `'Archived'` and `'Deleted'` to that same special-case check so they behave identically (undo affordance instead of a snackbar) rather than duplicating that logic now.

- [ ] **Step 8: Run tests, format, analyze, commit**

```bash
flutter test test/presentation/blocs/tide_bloc_test.dart
flutter analyze
dart format lib/presentation/blocs lib/l10n lib/main.dart test/presentation/blocs
git add lib/presentation/blocs/tide_event.dart lib/presentation/blocs/tide_state.dart lib/presentation/blocs/tide_bloc.dart lib/main.dart lib/l10n/tide_localizations.dart test/presentation/blocs/tide_bloc_test.dart
git commit -m "feat: wire archive and trash flows into TideBloc"
```

Run `flutter run -d macos` (or any connected device) at least once after this step and confirm the app still launches and the existing stream/rescue/undo flow works end to end — this is the first task where a mistake in the new `lib/main.dart` wiring would otherwise only surface at runtime, not in `flutter test`.

---

### Task 4: Composer Paste-from-Clipboard Icon

**Files:**
- Modify: `lib/design/tide_icons.dart`
- Modify: `lib/presentation/widgets/note_composer.dart`
- Modify: `lib/l10n/tide_localizations.dart`
- Modify: `test/presentation/widgets/note_composer_test.dart` (create if it doesn't already exist as a standalone file — check first with `find test -iname "*composer*"`; if composer coverage currently lives inside `test/presentation/pages/tide_page_test.dart`, add the test there instead, following that file's existing pattern for locating the composer)

- [ ] **Step 1: Write a failing test**

```dart
testWidgets('paste icon inserts clipboard content into the composer', (
  tester,
) async {
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.getData') {
      return {'text': 'pasted thought'};
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: Scaffold(
        body: NoteComposer(appendCompleted: 0, onSubmit: (_) {}),
      ),
    ),
  );

  await tester.tap(find.byKey(const ValueKey('composer-paste')));
  await tester.pump();

  expect(
    tester.widget<TextField>(find.byKey(const ValueKey('composer-input'))).controller!.text,
    'pasted thought',
  );
});
```

- [ ] **Step 2: Run red test**

```bash
flutter test test/presentation/pages/tide_page_test.dart -N "paste icon"
```

(Adjust the `-N` filter/path to wherever the test landed per Step 1's file check.) Expected: FAIL — no widget keyed `composer-paste` exists.

- [ ] **Step 3: Add the icon role**

In `lib/design/tide_icons.dart`, add:

```dart
static const paste = FontAwesomeIcons.paste;
```

- [ ] **Step 4: Add the paste button to `NoteComposer`**

In `lib/presentation/widgets/note_composer.dart`, add a `_pasteFromClipboard` method and a new `IconButton` before the existing submit button in the `Row`'s `children`:

```dart
Future<void> _pasteFromClipboard() async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final text = data?.text;
  if (text == null || text.isEmpty) return;
  final selection = _controller.selection;
  final newText = selection.isValid
      ? _controller.text.replaceRange(selection.start, selection.end, text)
      : _controller.text + text;
  _controller.text = newText;
  _controller.selection = TextSelection.collapsed(
    offset: (selection.isValid ? selection.start : _controller.text.length) +
        text.length,
  );
}
```

```dart
Semantics(
  label: l10n.pasteFromClipboard,
  button: true,
  onTap: _pasteFromClipboard,
  child: IconButton(
    key: const ValueKey('composer-paste'),
    onPressed: _pasteFromClipboard,
    tooltip: l10n.pasteFromClipboard,
    icon: const FaIcon(TideIcons.paste, size: 18),
  ),
),
Semantics(
  label: l10n.saveNote,
  button: true,
  onTap: _submit,
  child: IconButton(
    onPressed: _submit,
    tooltip: l10n.saveNote,
    icon: const FaIcon(TideIcons.insert, size: 18),
  ),
),
```

(The second block is the existing submit button, shown here only to make the ordering — paste before submit — unambiguous; do not duplicate it, just insert the new `Semantics`/`IconButton` immediately above it.)

- [ ] **Step 5: Add the localized label**

In `lib/l10n/tide_localizations.dart`:

```dart
String get pasteFromClipboard =>
    isItalian ? 'Incolla dagli appunti' : 'Paste from clipboard';
```

- [ ] **Step 6: Run tests, format, analyze, commit**

```bash
flutter test test/presentation/pages/tide_page_test.dart
dart format lib/design/tide_icons.dart lib/presentation/widgets/note_composer.dart lib/l10n/tide_localizations.dart test/presentation/pages/tide_page_test.dart
flutter analyze
git add lib/design/tide_icons.dart lib/presentation/widgets/note_composer.dart lib/l10n/tide_localizations.dart test/presentation/pages/tide_page_test.dart
git commit -m "feat: add paste-from-clipboard to the composer"
```

---

### Task 5: Read-Only Markdown Rendering

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/design/tide_markdown.dart`
- Create: `test/design/tide_markdown_test.dart`
- Modify: `lib/presentation/widgets/note_card.dart`
- Modify: `test/presentation/widgets/note_card_test.dart`

`Note.content` stays a plain string; the composer and both edit surfaces (existing inline edit, and the new full-screen `NoteEditPage` in Task 7) keep editing it as plain text. Only the **read** presentation changes: `PrefixText`'s existing single-line, colored-prefix rendering of the note's first line is untouched (it already handles the common single-line-note case correctly). Any additional lines after the first (`content.split('\n').skip(1)`) are rendered as markdown, since that's where Gravity's block-level structure (headings, lists, quotes, code) actually appears — a title/prefix line followed by a rendered body, not markdown syntax colliding with the colored prefix on line one.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies`:

```yaml
  flutter_markdown_plus: ^1.0.12
```

```bash
flutter pub get
```

- [ ] **Step 2: Write a failing pure test for the style sheet**

Create `test/design/tide_markdown_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/design/tide_markdown.dart';

void main() {
  testWidgets('markdown style sheet uses Quicksand headings and Nunito body', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final styleSheet = tideMarkdownStyleSheet(capturedContext);

    expect(styleSheet.h1?.fontFamily, 'Quicksand');
    expect(styleSheet.h2?.fontFamily, 'Quicksand');
    expect(styleSheet.p?.fontFamily, 'Nunito');
    expect(styleSheet.code?.backgroundColor, TideColors.foam.accentSubtle);
    expect(styleSheet.blockquoteDecoration, isA<BoxDecoration>());
  });
}
```

- [ ] **Step 3: Run red test**

```bash
flutter test test/design/tide_markdown_test.dart
```

Expected: compile failure — `tideMarkdownStyleSheet` doesn't exist.

- [ ] **Step 4: Implement the style sheet factory**

Create `lib/design/tide_markdown.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'design_helpers.dart';
import 'design_tokens.dart';

/// Maps Tide's existing typography and palette tokens onto the markdown
/// renderer so a theme switch restyles rendered note content automatically,
/// without a second set of colors/fonts to keep in sync.
MarkdownStyleSheet tideMarkdownStyleSheet(BuildContext context) {
  final g = tideColorsOf(context);
  final text = Theme.of(context).textTheme;

  return MarkdownStyleSheet(
    h1: text.headlineMedium,
    h2: text.titleLarge,
    p: text.bodyMedium,
    strong: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    em: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
    code: text.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      backgroundColor: g.accentSubtle,
    ),
    codeblockDecoration: BoxDecoration(
      color: g.accentSubtle,
      borderRadius: GShapes.control,
    ),
    blockquote: text.bodyMedium?.copyWith(color: g.textMuted),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: g.lineSubtle, width: 3)),
    ),
    listBullet: text.bodyMedium?.copyWith(color: g.accent),
    blockSpacing: GSpace.s2,
  );
}
```

- [ ] **Step 5: Run style-sheet test to verify it passes**

```bash
flutter test test/design/tide_markdown_test.dart
```

Expected: PASS.

- [ ] **Step 6: Write a failing widget test for multi-line rendering in `NoteCard`**

Add to `test/presentation/widgets/note_card_test.dart`:

```dart
testWidgets('renders lines after the first as markdown', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: Scaffold(
        body: NoteCard(
          note: note('idea: title\n**bold body**'),
          index: 1,
          onChanged: (_) {},
          onRescue: () {},
        ),
      ),
    ),
  );

  final rendered = tester.widget<Text>(find.text('bold body'));
  expect(rendered.style?.fontWeight, FontWeight.w700);
});

testWidgets('single-line notes render exactly as before, no markdown body', (
  tester,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: Scaffold(
        body: NoteCard(
          note: note('idea: single line'),
          index: 1,
          onChanged: (_) {},
          onRescue: () {},
        ),
      ),
    ),
  );

  expect(find.byType(MarkdownBody), findsNothing);
});
```

(Use whatever `note(...)` helper this test file already defines for constructing a `Note` — check the top of `test/presentation/widgets/note_card_test.dart` before adding these; adapt the two literals above to that helper's actual parameter name for content.)

- [ ] **Step 7: Run red tests**

```bash
flutter test test/presentation/widgets/note_card_test.dart
```

Expected: FAIL — both bold text and `MarkdownBody` are absent today; the second test's "no markdown body" expectation currently trivially passes, so only the first is red until Step 8.

- [ ] **Step 8: Render the markdown body in `NoteCard`**

In `lib/presentation/widgets/note_card.dart`, import the package and the style sheet:

```dart
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../design/tide_markdown.dart';
```

In `build`, after computing `metadata`, split the note body once:

```dart
final lines = widget.note.content.split('\n');
final markdownBody = lines.length > 1 ? lines.skip(1).join('\n') : null;
```

In the `Column` inside the row (the one currently containing the `if (_editing) TextField(...) else PrefixText(...)` branch), add the rendered body directly after the `PrefixText`/`TextField` branch and before the `SizedBox(height: GSpace.s1)` metadata spacer, only in the non-editing state:

```dart
if (_editing)
  TextField(/* unchanged, see existing code */)
else ...[
  PrefixText(content: widget.note.content, index: widget.index),
  if (markdownBody != null)
    Padding(
      padding: const EdgeInsets.only(top: GSpace.s1),
      child: MarkdownBody(
        data: markdownBody,
        styleSheet: tideMarkdownStyleSheet(context),
        shrinkWrap: true,
      ),
    ),
],
const SizedBox(height: GSpace.s1),
Text(metadata, style: Theme.of(context).textTheme.bodySmall),
```

`PrefixText` itself is untouched — it still only ever sees and renders `widget.note.content` as before via `content: widget.note.content`, so its own prefix-parsing behavior (and every existing `PrefixText` test) is unaffected; the only change is that `NoteCard` now additionally renders everything after the first newline as markdown underneath it.

- [ ] **Step 9: Run tests, format, analyze, commit**

```bash
flutter test test/presentation/widgets/note_card_test.dart test/design/tide_markdown_test.dart
dart format lib/design/tide_markdown.dart lib/presentation/widgets/note_card.dart test/design/tide_markdown_test.dart test/presentation/widgets/note_card_test.dart
flutter analyze
git add pubspec.yaml pubspec.lock lib/design/tide_markdown.dart lib/presentation/widgets/note_card.dart test/design/tide_markdown_test.dart test/presentation/widgets/note_card_test.dart
git commit -m "feat: render multi-line note content as markdown"
```

---

### Task 6: Swipe Gestures — Migrate to `flutter_slidable` and Add the Action Panel

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/design/tide_icons.dart`
- Modify: `lib/l10n/tide_localizations.dart`
- Modify: `lib/presentation/widgets/note_card.dart`
- Modify: `lib/presentation/widgets/note_stream.dart`
- Modify: `lib/presentation/pages/tide_page.dart`
- Modify: `test/presentation/widgets/note_card_test.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`

Today's swipe-right rescue is a bare `Dismissible(direction: DismissDirection.startToEnd, confirmDismiss: () async { ...; return false; })` — it runs a side effect and always springs back rather than actually removing the row. Swipe-left needs the opposite shape: a **persistent** revealed action row (Archive/Delete/Share/Copy), not a complete-and-vanish gesture. `flutter_slidable`'s `Slidable` widget supports both directions from one widget (`startActionPane` and `endActionPane`), including a `DismissiblePane` for the start side that accepts the exact same `confirmDismiss`-returns-`false`-after-side-effect contract `Dismissible` already uses — so this task replaces the `Dismissible` with a single `Slidable`, rather than nesting two competing gesture-detecting widgets. Verify `flutter_slidable`'s current API against what's installed (`flutter pub add flutter_slidable` and check the generated `.dart_tool/package_config.json`/pub cache for the package's own example if any signature below doesn't match) — the exact intent that must hold regardless of minor signature differences: **swipe-right still fires `onRescue` and always springs back; swipe-left reveals four persistent buttons that stay open until dismissed or tapped.**

- [ ] **Step 1: Add the dependency**

```yaml
  flutter_slidable: ^4.0.0
```

```bash
flutter pub get
```

- [ ] **Step 2: Add the four new icon roles and their labels**

In `lib/design/tide_icons.dart`:

```dart
static const archive = FontAwesomeIcons.boxArchive;
static const share = FontAwesomeIcons.shareNodes;
static const copy = FontAwesomeIcons.copy;
```

(`restore` reuses the existing `TideIcons.surface`; `delete` reuses the existing `TideIcons.deleteAll`.)

In `lib/l10n/tide_localizations.dart`:

```dart
String get archiveNote => isItalian ? 'Archivia' : 'Archive';
String get deleteNote => isItalian ? 'Elimina' : 'Delete';
String get shareNote => isItalian ? 'Condividi' : 'Share';
String get copyNote => isItalian ? 'Copia' : 'Copy';
String get noteCopied => isItalian ? 'Nota copiata.' : 'Note copied.';
```

Add `'Note copied.'` to the existing `message` switch added in Task 3 Step 6:

```dart
'Note copied.' => isItalian ? 'Nota copiata.' : value,
```

- [ ] **Step 3: Write failing widget tests for the action panel**

Add to `test/presentation/widgets/note_card_test.dart`:

```dart
testWidgets('swipe-left reveals Archive, Delete, Share, and Copy', (
  tester,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: Scaffold(
        body: NoteCard(
          note: note('idea: swipe me'),
          index: 1,
          onChanged: (_) {},
          onRescue: () {},
          onArchive: () {},
          onDelete: () {},
          onShare: () {},
          onCopy: () {},
        ),
      ),
    ),
  );

  await tester.drag(find.byKey(const ValueKey('note-row')), const Offset(-400, 0));
  await tester.pumpAndSettle();

  expect(find.text('Archive'), findsOneWidget);
  expect(find.text('Delete'), findsOneWidget);
  expect(find.text('Share'), findsOneWidget);
  expect(find.text('Copy'), findsOneWidget);
});

testWidgets('tapping Archive in the revealed panel calls onArchive', (
  tester,
) async {
  var archived = false;
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: Scaffold(
        body: NoteCard(
          note: note('idea: swipe me'),
          index: 1,
          onChanged: (_) {},
          onRescue: () {},
          onArchive: () => archived = true,
          onDelete: () {},
          onShare: () {},
          onCopy: () {},
        ),
      ),
    ),
  );

  await tester.drag(find.byKey(const ValueKey('note-row')), const Offset(-400, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Archive'));
  await tester.pumpAndSettle();

  expect(archived, isTrue);
});

testWidgets('swipe-right still rescues exactly as before', (tester) async {
  var rescued = false;
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: Scaffold(
        body: NoteCard(
          note: note('idea: swipe me'),
          index: 1,
          onChanged: (_) {},
          onRescue: () => rescued = true,
        ),
      ),
    ),
  );

  await tester.drag(find.byKey(const ValueKey('note-row')), const Offset(400, 0));
  await tester.pumpAndSettle();

  expect(rescued, isTrue);
});
```

- [ ] **Step 4: Run red tests**

```bash
flutter test test/presentation/widgets/note_card_test.dart
```

Expected: compile failure — `NoteCard` has no `onArchive`/`onDelete`/`onShare`/`onCopy` parameters yet.

- [ ] **Step 5: Add the four new optional callbacks to `NoteCard`**

```dart
class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.index,
    required this.onChanged,
    required this.onRescue,
    this.onArchive,
    this.onDelete,
    this.onShare,
    this.onCopy,
    this.onUndo,
    this.busy = false,
    this.rescueEnabled = true,
    this.haptic = defaultTideHaptic,
    this.now = defaultNoteNow,
    this.onEditingChanged,
  });

  final Note note;
  final int index;
  final bool busy;
  final bool rescueEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onRescue;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onCopy;
  final VoidCallback? onUndo;
  final VoidCallback haptic;
  final DateTime Function() now;
  final ValueChanged<bool>? onEditingChanged;
```

- [ ] **Step 6: Replace the `Dismissible` wrapper with `Slidable`**

Replace the final `return Semantics(... child: Dismissible(...))` block at the bottom of `build` with:

```dart
final actions = <Widget>[
  if (widget.onArchive != null)
    SlidableAction(
      onPressed: (_) => widget.onArchive!(),
      backgroundColor: g.textMuted.withValues(alpha: 0.16),
      foregroundColor: g.textMuted,
      icon: TideIcons.archive.icon,
      label: l10n.archiveNote,
    ),
  if (widget.onDelete != null)
    SlidableAction(
      onPressed: (_) => widget.onDelete!(),
      backgroundColor: g.dangerSoft,
      foregroundColor: g.danger,
      icon: TideIcons.deleteAll.icon,
      label: l10n.deleteNote,
    ),
  if (widget.onShare != null)
    SlidableAction(
      onPressed: (_) => widget.onShare!(),
      backgroundColor: g.accentSubtle,
      foregroundColor: g.accent,
      icon: TideIcons.share.icon,
      label: l10n.shareNote,
    ),
  if (widget.onCopy != null)
    SlidableAction(
      onPressed: (_) => widget.onCopy!(),
      backgroundColor: g.accentSubtle.withValues(alpha: 0.6),
      foregroundColor: g.accentMuted,
      icon: TideIcons.copy.icon,
      label: l10n.copyNote,
    ),
];

return Semantics(
  label: l10n.rescueNote,
  hint: widget.note.content,
  button: true,
  customSemanticsActions: {
    CustomSemanticsAction(label: l10n.rescueNote): widget.onRescue,
  },
  child: Slidable(
    key: ValueKey(widget.note.id),
    startActionPane: ActionPane(
      motion: const ScrollMotion(),
      extentRatio: 0.01,
      dismissible: DismissiblePane(
        confirmDismiss: () async {
          widget.haptic();
          widget.onRescue();
          return false;
        },
        onDismissed: () {},
      ),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: g.rescueSoft),
          child: Padding(
            padding: EdgeInsets.only(left: compact ? GSpace.s4 : GSpace.s6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FaIcon(TideIcons.surface, color: g.rescue, size: 20),
            ),
          ),
        ),
      ],
    ),
    endActionPane: actions.isEmpty
        ? null
        : ActionPane(motion: const ScrollMotion(), children: actions),
    child: interactive,
  ),
);
```

The `startActionPane`'s `children` reproduce today's exact `Dismissible` background (`rescueSoft` fill, left-aligned `TideIcons.surface`) — check the installed `flutter_slidable` version's actual rendering contract for an `ActionPane` that combines `dismissible` with `children` (whether `children` renders as the background behind the reveal, as it does in the version this plan was written against, or needs a different composition) and adjust if it differs, but the background must remain visually identical to today's `Dismissible` while dragging, not blank.

`FontAwesomeIcons`' `.icon` extension (already available via the `font_awesome_flutter` package this codebase uses elsewhere) turns a `TideIcons` glyph constant into an `IconData`-compatible value for `SlidableAction.icon`, which expects `IconData` — if the installed `flutter_slidable` version's `SlidableAction.icon` type or the icon-conversion step differs from this, adapt to whatever the installed package actually requires while keeping every action's icon sourced from `TideIcons` (never a new, unrelated icon set).

Remove the now-dead `if (widget.busy || !widget.rescueEnabled) { return KeyedSubtree(...); }` early-return's interaction with the old background-only `Dismissible` — keep that early-return as is (it still applies before reaching the `Slidable`), since a busy or non-rescuable row (the top-of-stream note) still shouldn't offer swipe interactions of any kind, matching today's behavior.

- [ ] **Step 7: Wire the four callbacks through `NoteStream`**

`NoteStream` is currently a plain `StatelessWidget` (no depth-fade or editing-state tracking exists yet — this task only adds the four new callbacks to its existing shape, nothing else about its structure changes). In `lib/presentation/widgets/note_stream.dart`, add the four new optional callback parameters:

```dart
class NoteStream extends StatelessWidget {
  const NoteStream({
    super.key,
    required this.notes,
    required this.busyNoteIds,
    required this.onChanged,
    required this.onRescue,
    this.onArchive,
    this.onDelete,
    this.onShare,
    this.onCopy,
    this.undoNoteId,
    this.onUndo,
    this.showNoSearchResults = false,
    this.haptic = defaultTideHaptic,
    this.now = defaultNoteNow,
  });

  final List<Note> notes;
  final Set<String> busyNoteIds;
  final ValueChanged<NoteEdit> onChanged;
  final ValueChanged<String> onRescue;
  final ValueChanged<String>? onArchive;
  final ValueChanged<String>? onDelete;
  final ValueChanged<String>? onShare;
  final ValueChanged<String>? onCopy;
  final String? undoNoteId;
  final VoidCallback? onUndo;
  final bool showNoSearchResults;
  final VoidCallback haptic;
  final DateTime Function() now;
```

Update the `NoteCard` construction inside `build`'s `ListView.builder`'s `itemBuilder` (a top-level method on the `StatelessWidget`, so plain parameter names, not `widget.`-prefixed):

```dart
return NoteCard(
  key: ValueKey(note.id),
  note: note,
  index: index,
  busy: busyNoteIds.contains(note.id),
  rescueEnabled: index > 0,
  onChanged: (content) => onChanged(NoteEdit(note.id, content)),
  onRescue: () => onRescue(note.id),
  onArchive: onArchive == null ? null : () => onArchive!(note.id),
  onDelete: onDelete == null ? null : () => onDelete!(note.id),
  onShare: onShare == null ? null : () => onShare!(note.id),
  onCopy: onCopy == null ? null : () => onCopy!(note.id),
  onUndo: note.id == undoNoteId ? onUndo : null,
  haptic: haptic,
  now: now,
);
```

Do not add `onEditingChanged` here — `NoteCard` already accepts that optional callback today, but nothing in `NoteStream` currently supplies it, and wiring it up is outside this task's scope (it belongs to a future viewport/editing-state feature, not this plan).

- [ ] **Step 8: Wire archive/delete/share/copy from `TidePage`**

In `lib/presentation/pages/tide_page.dart`, add a single-note share helper and wire the four new callbacks on `NoteStream`. Add this import:

```dart
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
```

Add a method on `_TidePageState`:

```dart
Future<void> _shareNote(String id, TideState state) async {
  final note = [...state.notes, ...state.archivedNotes]
      .where((note) => note.id == id)
      .firstOrNull;
  if (note == null) return;
  await SharePlus.instance.share(ShareParams(text: note.content));
}

Future<void> _copyNote(String id, TideState state, BuildContext context) async {
  final note = [...state.notes, ...state.archivedNotes]
      .where((note) => note.id == id)
      .firstOrNull;
  if (note == null) return;
  await Clipboard.setData(ClipboardData(text: note.content));
  if (!context.mounted) return;
  context.read<TideBloc>().add(const TideMessageAcknowledged());
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(TideLocalizations.of(context).noteCopied)),
    );
}
```

In the `BlocConsumer`'s `listener`, extend the `'Rescued'`-only special case added in Task 3 to also skip the snackbar for `'Archived'`/`'Deleted'` (their own undo affordance is the feedback, matching rescue):

```dart
listener: (context, state) {
  final l10n = TideLocalizations.of(context);
  final message = state.message;
  if (message == null) return;
  if (message == 'Rescued' || message == 'Archived' || message == 'Deleted') {
    context.read<TideBloc>().add(const TideMessageAcknowledged());
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.message(message))));
  context.read<TideBloc>().add(const TideMessageAcknowledged());
},
```

Wire the `NoteStream` construction inside `build`:

```dart
stream: NoteStream(
  notes: visibleNotes,
  showNoSearchResults: showNoSearchResults,
  busyNoteIds: state.busyNoteIds,
  haptic: widget.haptic,
  now: widget.now,
  undoNoteId:
      state.rescueReceipt?.noteId ??
      state.archiveReceipt?.noteId ??
      state.deleteReceipt?.noteId,
  onUndo: () {
    final bloc = context.read<TideBloc>();
    if (state.rescueReceipt != null) {
      bloc.add(const RescueUndoRequested());
    } else if (state.archiveReceipt != null) {
      bloc.add(const ArchiveUndoRequested());
    } else if (state.deleteReceipt != null) {
      bloc.add(const DeleteUndoRequested());
    }
  },
  onChanged: (edit) => context.read<TideBloc>().add(
    NoteEditRequested(edit.id, edit.content),
  ),
  onRescue: (id) =>
      context.read<TideBloc>().add(NoteRescueRequested(id)),
  onArchive: (id) =>
      context.read<TideBloc>().add(NoteArchiveRequested(id)),
  onDelete: (id) =>
      context.read<TideBloc>().add(NoteDeleteRequested(id)),
  onShare: (id) => _shareNote(id, state),
  onCopy: (id) => _copyNote(id, state, context),
),
```

- [ ] **Step 9: Run tests, format, analyze, commit**

```bash
flutter test test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart test/presentation/pages/rescue_flow_test.dart
dart format pubspec.yaml lib/design/tide_icons.dart lib/l10n/tide_localizations.dart lib/presentation/widgets/note_card.dart lib/presentation/widgets/note_stream.dart lib/presentation/pages/tide_page.dart test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart
flutter analyze
git add pubspec.yaml pubspec.lock lib/design/tide_icons.dart lib/l10n/tide_localizations.dart lib/presentation/widgets/note_card.dart lib/presentation/widgets/note_stream.dart lib/presentation/pages/tide_page.dart test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart
git commit -m "feat: add swipe-left action panel (archive, delete, share, copy)"
```

---

### Task 7: Long-Press Full-Screen Edit Page

**Files:**
- Create: `lib/presentation/pages/note_edit_page.dart`
- Create: `test/presentation/pages/note_edit_page_test.dart`
- Modify: `lib/presentation/widgets/note_card.dart`
- Modify: `test/presentation/widgets/note_card_test.dart`
- Modify: `lib/l10n/tide_localizations.dart`

This is additive: tapping a note still begins Tide's existing inline edit-in-place (unchanged). Long-pressing opens a new full-screen route with a plain-text field and a live markdown preview underneath, using the style sheet from Task 5.

- [ ] **Step 1: Write failing tests for `NoteEditPage`**

Create `test/presentation/pages/note_edit_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/presentation/pages/note_edit_page.dart';

void main() {
  testWidgets('shows the note content and a live markdown preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: NoteEditPage(content: 'idea: title\n**bold**', onSave: (_) {}),
      ),
    );

    expect(find.text('idea: title\n**bold**'), findsOneWidget);
    final bold = tester.widget<Text>(find.text('bold'));
    expect(bold.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('confirming calls onSave with the edited text', (tester) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: NoteEditPage(content: 'original', onSave: (value) => saved = value),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('edit-page-input')), 'changed');
    await tester.tap(find.byKey(const ValueKey('edit-page-confirm')));
    await tester.pumpAndSettle();

    expect(saved, 'changed');
  });

  testWidgets('closing does not call onSave', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: NoteEditPage(content: 'original', onSave: (_) => called = true),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('edit-page-input')), 'changed');
    await tester.tap(find.byKey(const ValueKey('edit-page-close')));
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });
}
```

- [ ] **Step 2: Run red tests**

```bash
flutter test test/presentation/pages/note_edit_page_test.dart
```

Expected: compile failure — `NoteEditPage` doesn't exist.

- [ ] **Step 3: Implement `NoteEditPage`**

```dart
import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../design/tide_markdown.dart';
import '../../l10n/tide_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NoteEditPage extends StatefulWidget {
  const NoteEditPage({super.key, required this.content, required this.onSave});

  final String content;
  final ValueChanged<String> onSave;

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    final g = tideColorsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GSpace.s4,
                vertical: GSpace.s2,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('edit-page-close'),
                    tooltip: l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const FaIcon(TideIcons.clearSearch, size: 20),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const ValueKey('edit-page-confirm'),
                    tooltip: l10n.saveNote,
                    onPressed: () {
                      widget.onSave(_controller.text);
                      Navigator.of(context).pop();
                    },
                    icon: const FaIcon(TideIcons.check, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: GSpace.s4),
                child: TextField(
                  key: const ValueKey('edit-page-input'),
                  controller: _controller,
                  maxLines: null,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GSpace.s4),
                child: _controller.text.trim().isEmpty
                    ? Text(
                        l10n.editPreviewEmpty,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: g.textMuted),
                      )
                    : MarkdownBody(
                        data: _controller.text,
                        styleSheet: tideMarkdownStyleSheet(context),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add the localized preview placeholder string**

```dart
String get editPreviewEmpty =>
    isItalian ? 'L\'anteprima apparirà qui.' : 'Preview appears here.';
```

- [ ] **Step 5: Run `NoteEditPage` tests to verify they pass**

```bash
flutter test test/presentation/pages/note_edit_page_test.dart
```

Expected: PASS.

- [ ] **Step 6: Open `NoteEditPage` on long-press from `NoteCard`**

In `lib/presentation/widgets/note_card.dart`, wrap the existing `InkWell` (which currently only has `onTap: _beginEditing`) with an `onLongPress` handler that pushes the new page:

```dart
final rowInteraction = MouseRegion(
  cursor: widget.busy ? SystemMouseCursors.basic : SystemMouseCursors.click,
  onEnter: (_) => setState(() => _hovered = true),
  onExit: (_) => setState(() => _hovered = false),
  child: InkWell(
    onTap: widget.busy ? null : _beginEditing,
    onLongPress: widget.busy
        ? null
        : () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => NoteEditPage(
                content: widget.note.content,
                onSave: widget.onChanged,
              ),
            ),
          ),
    child: child,
  ),
);
```

Add the import: `import 'note_edit_page.dart';` — since `note_card.dart` lives in `lib/presentation/widgets/` and `note_edit_page.dart` lives in `lib/presentation/pages/`, the import path is `import '../pages/note_edit_page.dart';`.

- [ ] **Step 7: Write a failing widget test for the long-press integration**

Add to `test/presentation/widgets/note_card_test.dart`:

```dart
testWidgets('long-press opens the full-screen edit page', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: Scaffold(
        body: NoteCard(
          note: note('idea: long press me'),
          index: 1,
          onChanged: (_) {},
          onRescue: () {},
        ),
      ),
    ),
  );

  await tester.longPress(find.byKey(const ValueKey('note-row')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('edit-page-input')), findsOneWidget);
  expect(find.text('idea: long press me'), findsOneWidget);
});
```

- [ ] **Step 8: Run tests, format, analyze, commit**

```bash
flutter test test/presentation/pages/note_edit_page_test.dart test/presentation/widgets/note_card_test.dart
dart format lib/presentation/pages/note_edit_page.dart lib/presentation/widgets/note_card.dart lib/l10n/tide_localizations.dart test/presentation/pages/note_edit_page_test.dart test/presentation/widgets/note_card_test.dart
flutter analyze
git add lib/presentation/pages/note_edit_page.dart lib/presentation/widgets/note_card.dart lib/l10n/tide_localizations.dart test/presentation/pages/note_edit_page_test.dart test/presentation/widgets/note_card_test.dart
git commit -m "feat: add long-press full-screen note editing"
```

---

### Task 8: Archive Screen

**Files:**
- Create: `lib/design/tide_illustrations.dart`
- Create: `lib/presentation/pages/archive_page.dart`
- Create: `test/support/stub_tide_bloc.dart`
- Create: `test/presentation/pages/archive_page_test.dart`
- Modify: `lib/l10n/tide_localizations.dart`

- [ ] **Step 1: Create a shared stub `TideBloc` for page tests**

Tasks 8–11 each need a widget test that renders a page bound to a specific `TideState` and asserts which event it dispatches, without a working repository underneath. Create this once as a shared helper, `test/support/stub_tide_bloc.dart`:

```dart
import 'package:tide/domain/entities/archive_receipt.dart';
import 'package:tide/domain/entities/delete_receipt.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/domain/entities/rescue_receipt.dart';
import 'package:tide/domain/repositories/note_repository.dart';
import 'package:tide/domain/usecases/append_note.dart';
import 'package:tide/domain/usecases/archive_note.dart';
import 'package:tide/domain/usecases/delete_all_notes.dart';
import 'package:tide/domain/usecases/delete_note.dart';
import 'package:tide/domain/usecases/edit_note.dart';
import 'package:tide/domain/usecases/empty_trash.dart';
import 'package:tide/domain/usecases/permanently_delete_note.dart';
import 'package:tide/domain/usecases/rescue_note.dart';
import 'package:tide/domain/usecases/restore_from_archive.dart';
import 'package:tide/domain/usecases/restore_from_trash.dart';
import 'package:tide/domain/usecases/undo_rescue.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/blocs/tide_state.dart';

/// A [TideBloc] for widget tests that renders a specific [TideState] without
/// a working repository underneath. `add` only records the dispatched event
/// instead of running it, so a page under test can assert "the right event
/// was dispatched" while a real `TideBloc` would otherwise immediately try
/// (and fail) to hit `_InertNoteRepository`'s empty/no-op implementation.
final class StubTideBloc extends TideBloc {
  StubTideBloc(TideState initial)
    : super(
        watchNotes: WatchNotes(_repository),
        appendNote: AppendNote(_repository, now: DateTime.now, newId: () => 'id'),
        editNote: EditNote(_repository, now: DateTime.now),
        rescueNote: RescueNote(_repository, now: DateTime.now),
        undoRescue: UndoRescue(_repository),
        archiveNote: ArchiveNote(_repository, now: DateTime.now),
        restoreFromArchive: RestoreFromArchive(_repository),
        deleteNote: DeleteNote(_repository, now: DateTime.now),
        restoreFromTrash: RestoreFromTrash(_repository),
        permanentlyDeleteNote: PermanentlyDeleteNote(_repository),
        emptyTrash: EmptyTrash(_repository),
        deleteAllNotes: DeleteAllNotes(_repository),
      ) {
    emit(initial);
  }

  static final _repository = _InertNoteRepository();

  final List<TideEvent> events = [];

  @override
  void add(TideEvent event) {
    events.add(event);
  }
}

final class _InertNoteRepository implements NoteRepository {
  @override
  Stream<List<Note>> watchNotes() => const Stream.empty();

  @override
  Stream<List<Note>> watchArchivedNotes() => const Stream.empty();

  @override
  Stream<List<Note>> watchDeletedNotes() => const Stream.empty();

  @override
  Future<void> createNote(Note note) async {}

  @override
  Future<int> importNotes(List<Note> notes) async => 0;

  @override
  Future<void> deleteAll() async {}

  @override
  Future<void> updateContent(
    String id,
    String content,
    DateTime updatedAt,
  ) async {}

  @override
  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt) async => null;

  @override
  Future<void> undoRescue(RescueReceipt receipt) async {}

  @override
  Future<ArchiveReceipt?> archive(String id, DateTime archivedAt) async => null;

  @override
  Future<void> restoreFromArchive(String id) async {}

  @override
  Future<DeleteReceipt?> softDelete(String id, DateTime deletedAt) async =>
      null;

  @override
  Future<void> restoreFromTrash(String id) async {}

  @override
  Future<void> permanentlyDelete(String id) async {}

  @override
  Future<void> emptyTrash() async {}
}
```

- [ ] **Step 2: Write failing tests for `ArchivePage`**

Create `test/presentation/pages/archive_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/blocs/tide_state.dart';
import 'package:tide/presentation/pages/archive_page.dart';

import '../../support/stub_tide_bloc.dart';

void main() {
  testWidgets('shows an illustrated empty state with no archived notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: BlocProvider<TideBloc>(
          create: (_) => StubTideBloc(const TideState()),
          child: const ArchivePage(),
        ),
      ),
    );

    expect(find.text('Archive is empty.'), findsOneWidget);
    expect(find.byKey(const ValueKey('archive-empty-icon')), findsOneWidget);
  });

  testWidgets('lists archived notes and restores on swipe-right', (
    tester,
  ) async {
    final note = Note(
      id: 'a1',
      content: 'idea: archived one',
      createdAt: DateTime(2026, 7, 18),
      updatedAt: DateTime(2026, 7, 18),
      surfacedAt: DateTime(2026, 7, 18),
      rescueCount: 0,
      archivedAt: DateTime(2026, 7, 18),
    );
    final bloc = StubTideBloc(TideState(archivedNotes: [note]));
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: BlocProvider<TideBloc>.value(value: bloc, child: const ArchivePage()),
      ),
    );

    expect(find.textContaining('archived one'), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('note-row')), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(bloc.events, contains(isA<NoteRestoreFromArchiveRequested>()));
  });
}
```

- [ ] **Step 3: Run red tests**

```bash
flutter test test/presentation/pages/archive_page_test.dart
```

Expected: compile failure — `ArchivePage` doesn't exist.

- [ ] **Step 4: Create the shared empty-state icon**

Create `lib/design/tide_illustrations.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'design_helpers.dart';

/// A single, restrained line-art glyph used for the Archive and Deleted
/// Notes empty states — Tide's own water motif, not a decorative brand
/// asset, rendered at low opacity in the current theme's muted tone.
class TideEmptyIllustration extends StatelessWidget {
  const TideEmptyIllustration({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final g = tideColorsOf(context);
    return FaIcon(icon, size: 40, color: g.lineStrong);
  }
}
```

- [ ] **Step 5: Implement `ArchivePage`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../design/tide_illustrations.dart';
import '../../l10n/tide_localizations.dart';
import '../blocs/tide_bloc.dart';
import '../blocs/tide_event.dart';
import '../blocs/tide_state.dart';
import '../widgets/note_card.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    final g = tideColorsOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.archiveTitle)),
      body: BlocBuilder<TideBloc, TideState>(
        builder: (context, state) {
          if (state.archivedNotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(GSpace.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TideEmptyIllustration(
                      key: ValueKey('archive-empty-icon'),
                      icon: TideIcons.archive,
                    ),
                    const SizedBox(height: GSpace.s3),
                    Text(
                      l10n.archiveEmptyTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: GSpace.s2),
                    Text(
                      l10n.archiveEmptyBody,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: g.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: state.archivedNotes.length,
            itemBuilder: (context, index) {
              final note = state.archivedNotes[index];
              return Slidable(
                key: ValueKey(note.id),
                startActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.01,
                  dismissible: DismissiblePane(
                    confirmDismiss: () async {
                      context.read<TideBloc>().add(
                        NoteRestoreFromArchiveRequested(note.id),
                      );
                      return false;
                    },
                    onDismissed: () {},
                  ),
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: g.rescueSoft),
                      child: Padding(
                        padding: const EdgeInsets.only(left: GSpace.s4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FaIcon(TideIcons.surface, color: g.rescue, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => context.read<TideBloc>().add(
                        NoteDeleteRequested(note.id),
                      ),
                      backgroundColor: g.dangerSoft,
                      foregroundColor: g.danger,
                      icon: TideIcons.deleteAll.icon,
                      label: l10n.deleteNote,
                    ),
                  ],
                ),
                child: KeyedSubtree(
                  key: const ValueKey('note-row'),
                  child: NoteCard(
                    note: note,
                    index: index,
                    rescueEnabled: false,
                    onChanged: (_) {},
                    onRescue: () {},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

`rescueEnabled: false` disables `NoteCard`'s own built-in swipe handling (it already early-returns to a plain `KeyedSubtree` when `rescueEnabled` is false, per Task 6 Step 6) so the outer `Slidable` added here is the only swipe surface — this avoids the exact nested-gesture-recognizer conflict Task 6 already had to design around inside `NoteCard` itself.

- [ ] **Step 6: Add the localized strings**

```dart
String get archiveTitle => isItalian ? 'Archivio' : 'Archive';
String get archiveEmptyTitle =>
    isItalian ? 'L\'archivio è vuoto.' : 'Archive is empty.';
String get archiveEmptyBody => isItalian
    ? 'Le note che archivi appariranno qui.'
    : 'Notes you archive will appear here.';
```

- [ ] **Step 7: Run tests, format, analyze, commit**

```bash
flutter test test/presentation/pages/archive_page_test.dart
flutter analyze
dart format lib/design/tide_illustrations.dart lib/presentation/pages/archive_page.dart lib/l10n/tide_localizations.dart test/support/stub_tide_bloc.dart test/presentation/pages/archive_page_test.dart
git add lib/design/tide_illustrations.dart lib/presentation/pages/archive_page.dart lib/l10n/tide_localizations.dart test/support/stub_tide_bloc.dart test/presentation/pages/archive_page_test.dart
git commit -m "feat: add the Archive screen"
```

---

### Task 9: Deleted Notes (Trash) Screen

**Files:**
- Create: `lib/presentation/pages/deleted_notes_page.dart`
- Create: `test/presentation/pages/deleted_notes_page_test.dart`
- Modify: `lib/l10n/tide_localizations.dart`

Mirrors Task 8's structure closely: reuse `TideEmptyIllustration` and the `StubTideBloc` test helper created in Task 8 Step 1, and the same `Slidable`-wrapped `NoteCard` pattern. The differences: swipe-left here is a single **permanent delete** action (not Archive/Delete/Share/Copy), and the screen has a top-level "Delete All Permanently" action with a confirmation dialog.

- [ ] **Step 1: Write failing tests**

Create `test/presentation/pages/deleted_notes_page_test.dart` with the same imports as `test/presentation/pages/archive_page_test.dart` from Task 8 Step 2, substituting `deleted_notes_page.dart` for `archive_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/blocs/tide_state.dart';
import 'package:tide/presentation/pages/deleted_notes_page.dart';

import '../../support/stub_tide_bloc.dart';

void main() {
  testWidgets('shows an illustrated empty state with nothing deleted', (
  tester,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: BlocProvider<TideBloc>(
        create: (_) => StubTideBloc(const TideState()),
        child: const DeletedNotesPage(),
      ),
    ),
  );

  expect(find.text('Deleted Notes is empty.'), findsOneWidget);
});

testWidgets('swipe-left permanently deletes a single note', (tester) async {
  final note = Note(
    id: 'd1',
    content: 'idea: trashed',
    createdAt: DateTime(2026, 7, 18),
    updatedAt: DateTime(2026, 7, 18),
    surfacedAt: DateTime(2026, 7, 18),
    rescueCount: 0,
    deletedAt: DateTime(2026, 7, 18),
  );
  final bloc = StubTideBloc(TideState(deletedNotes: [note]));
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: BlocProvider<TideBloc>.value(
        value: bloc,
        child: const DeletedNotesPage(),
      ),
    ),
  );

  await tester.drag(find.byKey(const ValueKey('note-row')), const Offset(-400, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  expect(bloc.events, contains(isA<NotePermanentlyDeleteRequested>()));
});

testWidgets('Delete All Permanently asks for confirmation before emptying', (
  tester,
) async {
  final note = Note(
    id: 'd1',
    content: 'idea: trashed',
    createdAt: DateTime(2026, 7, 18),
    updatedAt: DateTime(2026, 7, 18),
    surfacedAt: DateTime(2026, 7, 18),
    rescueCount: 0,
    deletedAt: DateTime(2026, 7, 18),
  );
  final bloc = StubTideBloc(TideState(deletedNotes: [note]));
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: BlocProvider<TideBloc>.value(
        value: bloc,
        child: const DeletedNotesPage(),
      ),
    ),
  );

  await tester.tap(find.byKey(const ValueKey('empty-trash')));
  await tester.pumpAndSettle();
  expect(bloc.events, isNot(contains(isA<TrashEmptyRequested>())));

  await tester.tap(find.text('Delete all'));
  await tester.pumpAndSettle();

  expect(bloc.events, contains(isA<TrashEmptyRequested>()));
});
}
```

- [ ] **Step 2: Run red tests**

```bash
flutter test test/presentation/pages/deleted_notes_page_test.dart
```

Expected: compile failure — `DeletedNotesPage` doesn't exist.

- [ ] **Step 3: Implement `DeletedNotesPage`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../design/tide_illustrations.dart';
import '../../l10n/tide_localizations.dart';
import '../blocs/tide_bloc.dart';
import '../blocs/tide_event.dart';
import '../blocs/tide_state.dart';
import '../widgets/note_card.dart';

class DeletedNotesPage extends StatelessWidget {
  const DeletedNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    final g = tideColorsOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deletedNotesTitle),
        actions: [
          BlocBuilder<TideBloc, TideState>(
            builder: (context, state) => IconButton(
              key: const ValueKey('empty-trash'),
              tooltip: l10n.emptyTrash,
              onPressed: state.deletedNotes.isEmpty
                  ? null
                  : () => _confirmEmptyTrash(context, l10n),
              icon: FaIcon(TideIcons.deleteAll, color: g.danger),
            ),
          ),
        ],
      ),
      body: BlocBuilder<TideBloc, TideState>(
        builder: (context, state) {
          if (state.deletedNotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(GSpace.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TideEmptyIllustration(icon: TideIcons.deleteAll),
                    const SizedBox(height: GSpace.s3),
                    Text(
                      l10n.deletedNotesEmptyTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: GSpace.s2),
                    Text(
                      l10n.deletedNotesEmptyBody,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: g.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: state.deletedNotes.length,
            itemBuilder: (context, index) {
              final note = state.deletedNotes[index];
              return Slidable(
                key: ValueKey(note.id),
                startActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.01,
                  dismissible: DismissiblePane(
                    confirmDismiss: () async {
                      context.read<TideBloc>().add(
                        NoteRestoreFromTrashRequested(note.id),
                      );
                      return false;
                    },
                    onDismissed: () {},
                  ),
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: g.rescueSoft),
                      child: Padding(
                        padding: const EdgeInsets.only(left: GSpace.s4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FaIcon(TideIcons.surface, color: g.rescue, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => context.read<TideBloc>().add(
                        NotePermanentlyDeleteRequested(note.id),
                      ),
                      backgroundColor: g.dangerSoft,
                      foregroundColor: g.danger,
                      icon: TideIcons.deleteAll.icon,
                      label: l10n.deleteNote,
                    ),
                  ],
                ),
                child: KeyedSubtree(
                  key: const ValueKey('note-row'),
                  child: NoteCard(
                    note: note,
                    index: index,
                    rescueEnabled: false,
                    onChanged: (_) {},
                    onRescue: () {},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    TideLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.emptyTrashTitle),
        content: Text(l10n.emptyTrashBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteAll),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TideBloc>().add(const TrashEmptyRequested());
    }
  }
}
```

- [ ] **Step 4: Add the localized strings**

```dart
String get deletedNotesTitle => isItalian ? 'Cestino' : 'Deleted Notes';
String get deletedNotesEmptyTitle =>
    isItalian ? 'Il cestino è vuoto.' : 'Deleted Notes is empty.';
String get deletedNotesEmptyBody => isItalian
    ? 'Le note che elimini appariranno qui.'
    : 'Notes you delete will appear here.';
String get emptyTrash => isItalian ? 'Svuota cestino' : 'Empty trash';
String get emptyTrashTitle =>
    isItalian ? 'Svuotare il cestino?' : 'Empty the trash?';
String get emptyTrashBody => isItalian
    ? 'Questa azione eliminerà definitivamente tutte le note nel cestino.'
    : 'This will permanently delete every note in the trash.';
```

- [ ] **Step 5: Run tests, format, analyze, commit**

```bash
flutter test test/presentation/pages/deleted_notes_page_test.dart
dart format lib/presentation/pages/deleted_notes_page.dart lib/l10n/tide_localizations.dart test/presentation/pages/deleted_notes_page_test.dart
flutter analyze
git add lib/presentation/pages/deleted_notes_page.dart lib/l10n/tide_localizations.dart test/presentation/pages/deleted_notes_page_test.dart
git commit -m "feat: add the Deleted Notes (trash) screen"
```

---

### Task 10: Tide Stats Screen

**Files:**
- Create: `lib/core/utils/note_stats.dart`
- Create: `test/core/utils/note_stats_test.dart`
- Create: `lib/presentation/pages/tide_stats_page.dart`
- Create: `test/presentation/pages/tide_stats_page_test.dart`
- Modify: `lib/l10n/tide_localizations.dart`

All figures are computed client-side from notes already in `TideState` (`notes` + `archivedNotes`; `deletedNotes` are excluded). No new queries.

- [ ] **Step 1: Write failing tests for the pure aggregation function**

Create `test/core/utils/note_stats_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/core/utils/note_stats.dart';
import 'package:tide/domain/entities/note.dart';

void main() {
  Note note(String id, String content, {int rescueCount = 0, DateTime? createdAt}) =>
      Note(
        id: id,
        content: content,
        createdAt: createdAt ?? DateTime(2026, 7, 10),
        updatedAt: DateTime(2026, 7, 10),
        surfacedAt: DateTime(2026, 7, 10),
        rescueCount: rescueCount,
      );

  test('computes totals, averages, and the longest/most-rescued note', () {
    final notes = [
      note('1', 'short', rescueCount: 4, createdAt: DateTime(2026, 7, 10)),
      note('2', 'a somewhat longer note body here', rescueCount: 1),
    ];

    final stats = NoteStats.compute(notes, now: DateTime(2026, 7, 20));

    expect(stats.totalNotes, 2);
    expect(stats.totalCharacters, 'short'.length + 'a somewhat longer note body here'.length);
    expect(stats.longestNoteCharacters, 'a somewhat longer note body here'.length);
    expect(stats.mostRescuedCount, 4);
    expect(stats.firstNoteAt, DateTime(2026, 7, 10));
    expect(stats.notesPerDay, closeTo(2 / 10, 0.001));
    expect(stats.averageRescues, closeTo((4 + 1) / 2, 0.001));
    expect(stats.rescuesPerDay, closeTo(5 / 10, 0.001));
  });

  test('handles an empty note list without dividing by zero', () {
    final stats = NoteStats.compute(const [], now: DateTime(2026, 7, 20));

    expect(stats.totalNotes, 0);
    expect(stats.notesPerDay, 0);
    expect(stats.averageRescues, 0);
    expect(stats.firstNoteAt, isNull);
  });

  test('buckets word counts into four ranges', () {
    Note withWords(String id, int wordCount) =>
        note(id, List.filled(wordCount, 'w').join(' '));

    final notes = [
      withWords('1', 5),
      withWords('2', 25),
      withWords('3', 45),
      withWords('4', 70),
    ];

    final stats = NoteStats.compute(notes, now: DateTime(2026, 7, 20));

    expect(stats.wordCountBuckets, [1, 1, 1, 1]);
  });
}
```

- [ ] **Step 2: Run red test**

```bash
flutter test test/core/utils/note_stats_test.dart
```

Expected: compile failure — `NoteStats` doesn't exist.

- [ ] **Step 3: Implement the pure aggregation**

```dart
import '../../domain/entities/note.dart';

final class NoteStats {
  const NoteStats({
    required this.totalNotes,
    required this.totalCharacters,
    required this.longestNoteCharacters,
    required this.mostRescuedCount,
    required this.firstNoteAt,
    required this.notesPerDay,
    required this.averageRescues,
    required this.rescuesPerDay,
    required this.wordCountBuckets,
  });

  final int totalNotes;
  final int totalCharacters;
  final int longestNoteCharacters;
  final int mostRescuedCount;
  final DateTime? firstNoteAt;
  final double notesPerDay;
  final double averageRescues;
  final double rescuesPerDay;
  final List<int> wordCountBuckets;

  static NoteStats compute(List<Note> notes, {required DateTime now}) {
    if (notes.isEmpty) {
      return const NoteStats(
        totalNotes: 0,
        totalCharacters: 0,
        longestNoteCharacters: 0,
        mostRescuedCount: 0,
        firstNoteAt: null,
        notesPerDay: 0,
        averageRescues: 0,
        rescuesPerDay: 0,
        wordCountBuckets: [0, 0, 0, 0],
      );
    }

    final totalCharacters = notes.fold<int>(
      0,
      (sum, note) => sum + note.content.length,
    );
    final longestNoteCharacters = notes
        .map((note) => note.content.length)
        .reduce((a, b) => a > b ? a : b);
    final mostRescuedCount = notes
        .map((note) => note.rescueCount)
        .reduce((a, b) => a > b ? a : b);
    final firstNoteAt = notes
        .map((note) => note.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final totalRescues = notes.fold<int>(
      0,
      (sum, note) => sum + note.rescueCount,
    );
    final ageInDays = now.difference(firstNoteAt).inDays.clamp(1, 1 << 30);

    final buckets = List<int>.filled(4, 0);
    for (final note in notes) {
      final words = note.content
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
      final bucket = words <= 21
          ? 0
          : words <= 41
          ? 1
          : words <= 61
          ? 2
          : 3;
      buckets[bucket]++;
    }

    return NoteStats(
      totalNotes: notes.length,
      totalCharacters: totalCharacters,
      longestNoteCharacters: longestNoteCharacters,
      mostRescuedCount: mostRescuedCount,
      firstNoteAt: firstNoteAt,
      notesPerDay: notes.length / ageInDays,
      averageRescues: totalRescues / notes.length,
      rescuesPerDay: totalRescues / ageInDays,
      wordCountBuckets: buckets,
    );
  }
}
```

- [ ] **Step 4: Run the pure test to verify it passes**

```bash
flutter test test/core/utils/note_stats_test.dart
```

Expected: PASS. If the bucket boundaries don't match the third test's expectation exactly (5/25/45/70 words landing one-per-bucket), adjust the bucket cutoffs above until they do — the exact boundary values are a display-only detail, not a contract anything else depends on.

- [ ] **Step 5: Write a failing widget test for `TideStatsPage`**

Create `test/presentation/pages/tide_stats_page_test.dart`, importing the `StubTideBloc` helper created in Task 8 Step 1:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_state.dart';
import 'package:tide/presentation/pages/tide_stats_page.dart';

import '../../support/stub_tide_bloc.dart';

void main() {
  testWidgets('shows totals computed from active and archived notes', (
  tester,
) async {
  final active = Note(
    id: '1',
    content: 'idea: alive',
    createdAt: DateTime(2026, 7, 10),
    updatedAt: DateTime(2026, 7, 10),
    surfacedAt: DateTime(2026, 7, 10),
    rescueCount: 2,
  );
  final archived = Note(
    id: '2',
    content: 'idea: archived too',
    createdAt: DateTime(2026, 7, 11),
    updatedAt: DateTime(2026, 7, 11),
    surfacedAt: DateTime(2026, 7, 11),
    rescueCount: 0,
    archivedAt: DateTime(2026, 7, 12),
  );
  final bloc = StubTideBloc(
    TideState(notes: [active], archivedNotes: [archived]),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: BlocProvider<TideBloc>.value(
        value: bloc,
        child: TideStatsPage(now: () => DateTime(2026, 7, 20)),
      ),
    ),
  );

  expect(find.text('2'), findsWidgets);
});
}
```

- [ ] **Step 6: Run red test**

```bash
flutter test test/presentation/pages/tide_stats_page_test.dart
```

Expected: compile failure — `TideStatsPage` doesn't exist.

- [ ] **Step 7: Implement `TideStatsPage`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/note_stats.dart';
import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../l10n/tide_localizations.dart';
import '../blocs/tide_bloc.dart';
import '../blocs/tide_state.dart';

class TideStatsPage extends StatelessWidget {
  const TideStatsPage({super.key, this.now = DateTime.now});

  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    final g = tideColorsOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: BlocBuilder<TideBloc, TideState>(
        builder: (context, state) {
          final stats = NoteStats.compute([
            ...state.notes,
            ...state.archivedNotes,
          ], now: now());

          return ListView(
            padding: const EdgeInsets.all(GSpace.s4),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: GSpace.s2,
                crossAxisSpacing: GSpace.s2,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(value: '${stats.totalNotes}', label: l10n.statsTotalNotes),
                  _StatCard(
                    value: stats.notesPerDay.toStringAsFixed(1),
                    label: l10n.statsNotesPerDay,
                  ),
                  _StatCard(
                    value: stats.averageRescues.toStringAsFixed(1),
                    label: l10n.statsAverageRescues,
                  ),
                  _StatCard(
                    value: stats.rescuesPerDay.toStringAsFixed(1),
                    label: l10n.statsRescuesPerDay,
                  ),
                ],
              ),
              const SizedBox(height: GSpace.s4),
              _DetailRow(label: l10n.statsLongestNote, value: '${stats.longestNoteCharacters}'),
              _DetailRow(label: l10n.statsMostRescued, value: '${stats.mostRescuedCount}'),
              _DetailRow(
                label: l10n.statsFirstNote,
                value: stats.firstNoteAt == null
                    ? '—'
                    : MaterialLocalizations.of(context).formatMediumDate(stats.firstNoteAt!),
              ),
              _DetailRow(label: l10n.statsTotalCharacters, value: '${stats.totalCharacters}'),
              const SizedBox(height: GSpace.s4),
              Text(l10n.statsWordDistribution, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: GSpace.s2),
              SizedBox(
                height: 96,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final count in stats.wordCountBuckets)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: GSpace.s1),
                          child: FractionallySizedBox(
                            heightFactor: stats.wordCountBuckets.reduce(
                                  (a, b) => a > b ? a : b,
                                ) ==
                                0
                                ? 0
                                : count /
                                    stats.wordCountBuckets.reduce(
                                      (a, b) => a > b ? a : b,
                                    ),
                            alignment: Alignment.bottomCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: g.accent),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: GSpace.s4),
              Text(
                l10n.statsComputedLocally,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: g.textMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final g = tideColorsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: g.surfaceElevated,
        border: Border.all(color: g.lineSubtle),
        borderRadius: GShapes.control,
      ),
      child: Padding(
        padding: const EdgeInsets.all(GSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: g.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: GSpace.s1),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}
```

- [ ] **Step 8: Add the localized strings**

```dart
String get statsTitle => isItalian ? 'Statistiche Tide' : 'Tide Stats';
String get statsTotalNotes => isItalian ? 'Note totali' : 'Total notes';
String get statsNotesPerDay => isItalian ? 'Note al giorno' : 'Notes per day';
String get statsAverageRescues =>
    isItalian ? 'Emersioni medie' : 'Average rescues';
String get statsRescuesPerDay =>
    isItalian ? 'Emersioni al giorno' : 'Rescues per day';
String get statsLongestNote =>
    isItalian ? 'Nota più lunga (caratteri)' : 'Longest note (characters)';
String get statsMostRescued =>
    isItalian ? 'Più riportata a galla' : 'Most rescued';
String get statsFirstNote => isItalian ? 'Prima nota' : 'First note';
String get statsTotalCharacters =>
    isItalian ? 'Caratteri totali' : 'Total characters';
String get statsWordDistribution =>
    isItalian ? 'Distribuzione lunghezza parole' : 'Word count distribution';
String get statsComputedLocally => isItalian
    ? 'Statistiche calcolate localmente.'
    : 'Stats are computed locally.';
```

- [ ] **Step 9: Run tests, format, analyze, commit**

```bash
flutter test test/core/utils/note_stats_test.dart test/presentation/pages/tide_stats_page_test.dart
dart format lib/core/utils/note_stats.dart lib/presentation/pages/tide_stats_page.dart lib/l10n/tide_localizations.dart test/core/utils/note_stats_test.dart test/presentation/pages/tide_stats_page_test.dart
flutter analyze
git add lib/core/utils/note_stats.dart lib/presentation/pages/tide_stats_page.dart lib/l10n/tide_localizations.dart test/core/utils/note_stats_test.dart test/presentation/pages/tide_stats_page_test.dart
git commit -m "feat: add the Tide Stats screen"
```

---

### Task 11: Interactive Tutorial Screen

**Files:**
- Create: `lib/presentation/pages/tide_tutorial_page.dart`
- Create: `test/presentation/pages/tide_tutorial_page_test.dart`
- Modify: `lib/l10n/tide_localizations.dart`

The tutorial uses static, in-memory demo notes — never the real repository or `TideBloc` — so swiping or long-pressing in it can never touch the user's actual data.

- [ ] **Step 1: Write failing tests**

Create `test/presentation/pages/tide_tutorial_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/presentation/pages/tide_tutorial_page.dart';

void main() {
  testWidgets('shows demo notes that can be swiped without side effects', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(theme: null, home: TideTutorialPage()),
    );
    await tester.pumpWidget(
      MaterialApp(theme: TideAppTheme.foam, home: const TideTutorialPage()),
    );

    expect(find.byKey(const ValueKey('tutorial-note-0')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('tutorial-note-0')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tutorial-note-0')), findsOneWidget);
  });

  testWidgets('long-press opens the edit page against demo content only', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: TideAppTheme.foam, home: const TideTutorialPage()),
    );

    await tester.longPress(find.byKey(const ValueKey('tutorial-note-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-page-input')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run red test**

```bash
flutter test test/presentation/pages/tide_tutorial_page_test.dart
```

Expected: compile failure — `TideTutorialPage` doesn't exist.

- [ ] **Step 3: Implement `TideTutorialPage`**

```dart
import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../domain/entities/note.dart';
import '../../l10n/tide_localizations.dart';
import '../widgets/note_card.dart';

class TideTutorialPage extends StatefulWidget {
  const TideTutorialPage({super.key});

  @override
  State<TideTutorialPage> createState() => _TideTutorialPageState();
}

class _TideTutorialPageState extends State<TideTutorialPage> {
  late List<Note> _demoNotes;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _demoNotes = [
      Note(
        id: 'tutorial-swipe-right',
        content: 'tip: Swipe right to rescue a note — it floats back to the top.',
        createdAt: now,
        updatedAt: now,
        surfacedAt: now,
        rescueCount: 0,
      ),
      Note(
        id: 'tutorial-swipe-left',
        content:
            'tip: Swipe left to reveal Archive, Delete, Share, and Copy.',
        createdAt: now,
        updatedAt: now,
        surfacedAt: now,
        rescueCount: 0,
      ),
      Note(
        id: 'tutorial-long-press',
        content: 'tip: Long-press any note to open full-screen editing.',
        createdAt: now,
        updatedAt: now,
        surfacedAt: now,
        rescueCount: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tutorialTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.all(GSpace.s4),
        itemCount: _demoNotes.length,
        itemBuilder: (context, index) => KeyedSubtree(
          key: ValueKey('tutorial-note-$index'),
          child: NoteCard(
            note: _demoNotes[index],
            index: index + 1,
            rescueEnabled: true,
            onArchive: () {},
            onDelete: () {},
            onShare: () {},
            onCopy: () {},
            onChanged: (content) => setState(() {
              _demoNotes[index] = _demoNotes[index].copyWith(content: content);
            }),
            onRescue: () {},
          ),
        ),
      ),
    );
  }
}
```

`onArchive`/`onDelete`/`onShare`/`onCopy`/`onRescue` are all deliberate no-ops here — they exist only so the panel/gesture renders and can be interacted with; nothing they do reaches `TideBloc` or the repository. `index: index + 1` (never `0`) keeps `rescueEnabled` meaningfully demonstrable for every row without relying on `NoteStream`'s "index 0 can't rescue" rule, which doesn't apply to this static demo list.

- [ ] **Step 4: Add the localized title**

```dart
String get tutorialTitle => isItalian ? 'Come funziona Tide' : 'How Tide Works';
String get howTideWorks => isItalian ? 'Come funziona Tide' : 'How Tide Works';
```

- [ ] **Step 5: Run tests, format, analyze, commit**

```bash
flutter test test/presentation/pages/tide_tutorial_page_test.dart
dart format lib/presentation/pages/tide_tutorial_page.dart lib/l10n/tide_localizations.dart test/presentation/pages/tide_tutorial_page_test.dart
flutter analyze
git add lib/presentation/pages/tide_tutorial_page.dart lib/l10n/tide_localizations.dart test/presentation/pages/tide_tutorial_page_test.dart
git commit -m "feat: add the interactive tutorial screen"
```

---

### Task 12: Settings Reorganization and New Destinations

**Files:**
- Modify: `lib/design/tide_icons.dart`
- Modify: `lib/presentation/widgets/tide_settings.dart`
- Modify: `lib/design/appearance_controller.dart`
- Modify: `lib/presentation/pages/tide_page.dart`
- Modify: `lib/l10n/tide_localizations.dart`
- Modify: `test/design/appearance_controller_test.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`

Restructures `TideSettingsButton`'s mobile sheet and macOS popover into Content / Data / Editor / Appearance / Search sections, keeping every existing entry (Theme, Language, quick submit, Import, Export, Delete All) and adding: Archive, Deleted Notes, Tide Stats, How Tide Works, and an "Include archived notes in search" toggle.

- [ ] **Step 1: Write a failing test for the new persisted toggle**

Add to `test/design/appearance_controller_test.dart`, following the existing `submitOnEnter` test's exact shape:

```dart
test('appearance restores and persists includeArchivedInSearch', () async {
  SharedPreferences.setMockInitialValues({});
  final controller = await AppearanceController.load();
  expect(controller.includeArchivedInSearch, isTrue);

  await controller.setIncludeArchivedInSearch(false);
  expect(
    (await AppearanceController.load()).includeArchivedInSearch,
    isFalse,
  );
});
```

- [ ] **Step 2: Run red test**

```bash
flutter test test/design/appearance_controller_test.dart
```

Expected: compile failure — `includeArchivedInSearch` doesn't exist.

- [ ] **Step 3: Add the setting to `AppearanceController`**

In `lib/design/appearance_controller.dart`, add the field (default `true`, matching Gravity's default), its persistence key, getter, setter, and thread it through the private constructor and both factories:

```dart
class AppearanceController extends ChangeNotifier {
  AppearanceController._(
    this._preferences,
    this._selection,
    this._submitOnEnter,
    this._language,
    this._includeArchivedInSearch,
  );

  static const _themeKey = 'tide_theme';
  static const _submitOnEnterKey = 'tide_submit_on_enter';
  static const _languageKey = 'tide_language';
  static const _includeArchivedInSearchKey = 'tide_include_archived_in_search';
  final SharedPreferences? _preferences;
  TideThemeSelection _selection;
  bool _submitOnEnter;
  TideLanguageSelection _language;
  bool _includeArchivedInSearch;

  TideThemeSelection get selection => _selection;
  bool get submitOnEnter => _submitOnEnter;
  TideLanguageSelection get language => _language;
  bool get includeArchivedInSearch => _includeArchivedInSearch;
  Locale? get locale => switch (_language) {
    TideLanguageSelection.system => null,
    TideLanguageSelection.italian => const Locale('it'),
    TideLanguageSelection.english => const Locale('en'),
  };

  static Future<AppearanceController> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_themeKey);
      final submitOnEnter = preferences.getBool(_submitOnEnterKey) ?? false;
      final includeArchivedInSearch =
          preferences.getBool(_includeArchivedInSearchKey) ?? true;
      final storedLanguage = preferences.getString(_languageKey);
      final language = TideLanguageSelection.values.firstWhere(
        (value) => value.name == storedLanguage,
        orElse: () => TideLanguageSelection.system,
      );
      final selection = TideThemeSelection.values.firstWhere(
        (value) => value.name == stored,
        orElse: () => TideThemeSelection.system,
      );
      return AppearanceController._(
        preferences,
        selection,
        submitOnEnter,
        language,
        includeArchivedInSearch,
      );
    } catch (_) {
      return AppearanceController.inMemory();
    }
  }

  factory AppearanceController.inMemory({
    TideThemeSelection selection = TideThemeSelection.system,
    bool submitOnEnter = false,
    TideLanguageSelection language = TideLanguageSelection.system,
    bool includeArchivedInSearch = true,
  }) => AppearanceController._(
    null,
    selection,
    submitOnEnter,
    language,
    includeArchivedInSearch,
  );

  Future<void> setIncludeArchivedInSearch(bool value) async {
    if (_includeArchivedInSearch == value) return;
    _includeArchivedInSearch = value;
    notifyListeners();
    try {
      await _preferences?.setBool(_includeArchivedInSearchKey, value);
    } catch (_) {}
  }

  // setSelection / setSubmitOnEnter / setLanguage unchanged below.
```

- [ ] **Step 4: Run the appearance test to verify it passes**

```bash
flutter test test/design/appearance_controller_test.dart
```

Expected: PASS.

- [ ] **Step 5: Add the two remaining icon roles**

`archive`/`share`/`copy` were already added to `TideIcons` in Task 6. This task's new settings entries need two more, for Tide Stats and the tutorial. In `lib/design/tide_icons.dart`:

```dart
static const stats = FontAwesomeIcons.chartSimple;
static const tutorial = FontAwesomeIcons.circleQuestion;
```

- [ ] **Step 6: Add the new settings entries and section labels**

In `lib/l10n/tide_localizations.dart`:

```dart
String get settingsContent => isItalian ? 'Contenuti' : 'Content';
String get settingsData => isItalian ? 'Dati' : 'Data';
String get settingsEditor => isItalian ? 'Editor' : 'Editor';
String get settingsAppearance => isItalian ? 'Aspetto' : 'Appearance';
String get settingsSearch => isItalian ? 'Ricerca' : 'Search';
String get includeArchivedInSearch =>
    isItalian ? 'Includi archiviate nella ricerca' : 'Include archived notes in search';
```

- [ ] **Step 7: Restructure `TideSettingsButton`'s mobile sheet**

In `lib/presentation/widgets/tide_settings.dart`, `TideSettingsButton` currently takes `onExport`/`onImport`/`onDeleteAll`. Add three navigation callbacks (`onOpenArchive`, `onOpenDeletedNotes`, `onOpenStats`, `onOpenTutorial`) and thread them into both `_showSettingsSheet` and `_MacSettingsMenu`. Replace the flat `Column` of `ListTile`s in `_showSettingsSheet` with section-grouped content:

```dart
Future<void> _showSettingsSheet(
  BuildContext context,
  AppearanceController appearance,
  VoidCallback onExport,
  VoidCallback onImport,
  VoidCallback onDeleteAll,
  VoidCallback onOpenArchive,
  VoidCallback onOpenDeletedNotes,
  VoidCallback onOpenStats,
  VoidCallback onOpenTutorial,
) => showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) => SafeArea(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              final l10n = TideLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(l10n.settingsContent),
                  ListTile(
                    leading: FaIcon(TideIcons.archive, size: 18),
                    title: Text(l10n.archiveTitle),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onOpenArchive();
                    },
                  ),
                  ListTile(
                    leading: FaIcon(TideIcons.deleteAll, size: 18),
                    title: Text(l10n.deletedNotesTitle),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onOpenDeletedNotes();
                    },
                  ),
                  ListTile(
                    leading: FaIcon(TideIcons.stats, size: 18),
                    title: Text(l10n.statsTitle),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onOpenStats();
                    },
                  ),
                  ListTile(
                    leading: FaIcon(TideIcons.tutorial, size: 18),
                    title: Text(l10n.howTideWorks),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onOpenTutorial();
                    },
                  ),
                  _SectionHeader(l10n.settingsData),
                  ListTile(
                    leading: FaIcon(TideIcons.import, size: 18),
                    title: Text(l10n.importNotes),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onImport();
                    },
                  ),
                  ListTile(
                    leading: FaIcon(TideIcons.export, size: 18),
                    title: Text(l10n.exportNotes),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onExport();
                    },
                  ),
                  _SectionHeader(l10n.settingsEditor),
                  SwitchListTile(
                    secondary: FaIcon(TideIcons.insert, size: 18),
                    title: Text(l10n.quickSubmit),
                    value: appearance.submitOnEnter,
                    onChanged: appearance.setSubmitOnEnter,
                  ),
                  _SectionHeader(l10n.settingsAppearance),
                  ListTile(
                    leading: FaIcon(TideIcons.theme, size: 18),
                    title: Text(l10n.theme),
                    trailing: FaIcon(TideIcons.next, size: 14),
                    onTap: () => _showThemeSheet(sheetContext, appearance),
                  ),
                  ListTile(
                    leading: FaIcon(TideIcons.language, size: 18),
                    title: Text(l10n.language),
                    trailing: Text(languageLabel(appearance.language, l10n)),
                    onTap: () => _showLanguageSheet(sheetContext, appearance),
                  ),
                  _SectionHeader(l10n.settingsSearch),
                  SwitchListTile(
                    title: Text(l10n.includeArchivedInSearch),
                    value: appearance.includeArchivedInSearch,
                    onChanged: appearance.setIncludeArchivedInSearch,
                  ),
                  const Divider(),
                  ListTile(
                    leading: FaIcon(
                      TideIcons.deleteAll,
                      color: Theme.of(context).colorScheme.error,
                      size: 18,
                    ),
                    title: Text(
                      l10n.deleteAllNotes,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _confirmDelete(context, onDeleteAll);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: Text(
                      '${l10n.versionLabel} $appVersion',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  ),
);

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ),
  );
}
```

Update `TideSettingsButton.build` and `_showSettingsSheet`'s callers to pass the four new callbacks through, and update `_MacSettingsMenu` the same way: add four `PopupMenuItem`s (Archive, Deleted Notes, Tide Stats, How Tide Works) under a new `_MenuAction` enum entry each, a `PopupMenuDivider()` before the Search toggle entry, and a `PopupMenuItem` wrapping a switch-styled row for `includeArchivedInSearch` (mirror the existing `submitOnEnter` popup item's checkmark-on-the-right pattern rather than introducing an actual `Switch` widget inside a `PopupMenuItem`, which is unusual on macOS menus).

- [ ] **Step 8: Wire the four navigation callbacks from `TidePage`**

In `lib/presentation/widgets/tide_header.dart`, thread the four new `VoidCallback`s through to `TideSettingsButton` at both call sites (compact and expanded layouts), matching how `onExport`/`onImport`/`onDeleteAll` are already threaded.

In `lib/presentation/pages/tide_page.dart`, supply them by pushing the corresponding page:

```dart
onOpenArchive: () => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const ArchivePage()),
),
onOpenDeletedNotes: () => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const DeletedNotesPage()),
),
onOpenStats: () => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => TideStatsPage(now: widget.now)),
),
onOpenTutorial: () => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const TideTutorialPage()),
),
```

Add the four imports (`archive_page.dart`, `deleted_notes_page.dart`, `tide_stats_page.dart`, `tide_tutorial_page.dart`). `ArchivePage`/`DeletedNotesPage`/`TideStatsPage` all read `TideBloc` via `BlocBuilder<TideBloc, TideState>`; this already works with no further changes, since `lib/main.dart`'s `BlocProvider<TideBloc>` wraps `TideApp`/`MaterialApp` itself (confirmed by reading `lib/main.dart`), well above wherever `Navigator.push` mounts a new route — pushed pages inherit it via `context.read`/`BlocBuilder` like any other descendant.

- [ ] **Step 9: Run tests, format, analyze, commit**

```bash
flutter test test/design/appearance_controller_test.dart test/presentation/pages/tide_page_test.dart test/app_test.dart
flutter analyze
dart format lib/design/tide_icons.dart lib/design/appearance_controller.dart lib/presentation/widgets/tide_settings.dart lib/presentation/widgets/tide_header.dart lib/presentation/pages/tide_page.dart lib/l10n/tide_localizations.dart test/design/appearance_controller_test.dart test/presentation/pages/tide_page_test.dart
git add lib/design/tide_icons.dart lib/design/appearance_controller.dart lib/presentation/widgets/tide_settings.dart lib/presentation/widgets/tide_header.dart lib/presentation/pages/tide_page.dart lib/l10n/tide_localizations.dart test/design/appearance_controller_test.dart test/presentation/pages/tide_page_test.dart
git commit -m "feat: reorganize settings and wire new destinations"
```

---

### Task 13: Search Results Count and Inline Highlight

**Files:**
- Modify: `lib/presentation/search/note_search.dart`
- Modify: `lib/presentation/widgets/tide_search_header.dart`
- Modify: `lib/presentation/pages/tide_page.dart`
- Modify: `lib/presentation/widgets/note_card.dart`
- Modify: `lib/l10n/tide_localizations.dart`
- Modify: `test/presentation/search/note_search_test.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`
- Modify: `test/presentation/widgets/note_card_test.dart`

No BLoC involvement, matching the existing search feature's presentation-only architecture.

- [ ] **Step 1: Write a failing test for the results-count string**

Add to `test/presentation/pages/tide_page_test.dart` (search for the existing search-related tests in this file first and place the new one alongside them):

```dart
testWidgets('shows a results count while searching', (tester) async {
  await pumpPage(
    tester,
    notes: [makeNote('alpha'), makeNote('beta')],
  );
  await tester.tap(find.byKey(const ValueKey('open-search')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('search-input')), 'alpha');
  await tester.pumpAndSettle();

  expect(find.text('1 note found'), findsOneWidget);
});
```

(Adapt `pumpPage`/`makeNote` to this test file's actual existing helper names.)

- [ ] **Step 2: Run red test**

```bash
flutter test test/presentation/pages/tide_page_test.dart
```

Expected: FAIL — no results-count text exists yet.

- [ ] **Step 3: Add the localized count string**

```dart
String searchResultsCount(int count) {
  if (isItalian) {
    return count == 1 ? '1 nota trovata' : '$count note trovate';
  }
  return count == 1 ? '1 note found' : '$count notes found';
}
```

- [ ] **Step 4: Render the count above the results in `TidePage`**

In `lib/presentation/pages/tide_page.dart`'s `build`, where `visibleNotes`/`showNoSearchResults` are already computed, wrap the `NoteStream` passed to `TideShell` with a count line when searching and there's a non-empty query:

```dart
final showResultsCount =
    _searching && _searchController.text.trim().isNotEmpty;
```

```dart
stream: Column(
  children: [
    if (showResultsCount)
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sizeClassOf(context) == GSizeClass.compact
              ? GSpace.s4
              : GSpace.s6,
          vertical: GSpace.s1,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            TideLocalizations.of(context).searchResultsCount(visibleNotes.length),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tideColorsOf(context).textMuted),
          ),
        ),
      ),
    Expanded(
      child: NoteStream(/* unchanged constructor call from Task 6 Step 8 */),
    ),
  ],
),
```

Only wrap `NoteStream` in this `Column`/`Expanded` structure when `showResultsCount` is true — pass the bare `NoteStream` (no `Column` wrapper) when not searching, keeping the non-search layout byte-for-byte identical to today. Reconcile this with `TideShell`'s existing `stream:` parameter type (it may currently type this parameter as `Widget`, in which case wrapping conditionally is a simple ternary at the call site: `stream: showResultsCount ? Column(...) : NoteStream(...)`.

- [ ] **Step 5: Write a failing test for inline highlighting**

Add to `test/presentation/widgets/note_card_test.dart`:

```dart
testWidgets('highlights the search term when a query is provided', (
  tester,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: Scaffold(
        body: NoteCard(
          note: note('idea: find this word'),
          index: 1,
          onChanged: (_) {},
          onRescue: () {},
          highlightQuery: 'this',
        ),
      ),
    ),
  );

  final rendered = tester.widget<RichText>(find.byType(RichText).first);
  final matchSpan = (rendered.text as TextSpan).children!.firstWhere(
    (span) => (span as TextSpan).text == 'this',
  ) as TextSpan;
  expect(matchSpan.style?.backgroundColor, isNotNull);
});
```

- [ ] **Step 6: Run red test**

```bash
flutter test test/presentation/widgets/note_card_test.dart
```

Expected: compile failure — `NoteCard` has no `highlightQuery` parameter.

- [ ] **Step 7: Add highlight support to `NoteCard` and `PrefixText`**

Add `highlightQuery` as a new optional `String?` field on `NoteCard` (default `null`) and pass it through to `PrefixText` as a new optional parameter. In `lib/presentation/widgets/prefix_text.dart`, when `highlightQuery` is non-null and non-empty, split the rendered remainder into segments around case-insensitive matches of the query and wrap matched segments in a `TextSpan` styled with a background tint:

```dart
class PrefixText extends StatelessWidget {
  const PrefixText({
    super.key,
    required this.content,
    required this.index,
    this.highlightQuery,
  });

  final String content;
  final int index;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final prefix = parsePrefix(content);
    final bodyStyle = Theme.of(context).textTheme.bodyMedium!;
    final prefixColor = _prefixColor(context, prefix ?? '');
    final remainder = prefix == null ? content : content.substring(prefix.length);
    final rendered = RichText(
      text: TextSpan(
        style: bodyStyle,
        children: [
          if (prefix != null)
            TextSpan(
              text: prefix,
              style: bodyStyle.copyWith(
                color: prefixColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ..._highlightedSpans(context, remainder, bodyStyle),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: content,
      child: ExcludeSemantics(child: rendered),
    );
  }

  List<TextSpan> _highlightedSpans(
    BuildContext context,
    String text,
    TextStyle bodyStyle,
  ) {
    final query = highlightQuery?.trim();
    if (query == null || query.isEmpty) return [TextSpan(text: text)];

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: bodyStyle.copyWith(
            backgroundColor: tideColorsOf(context).accentSubtle,
          ),
        ),
      );
      start = index + query.length;
    }
    return spans;
  }

  Color _prefixColor(BuildContext context, String prefix) {
    final g = tideColorsOf(context);
    final palette = [g.accent, g.rescue, g.textSecondary];
    return palette[prefixPaletteIndex(prefix, palette.length)];
  }
}
```

Add the `design_helpers.dart` import for `tideColorsOf` (replacing the existing `Theme.of(context).extension<TideColors>()!` call in `_prefixColor` with the same null-safe helper while touching this method, consistent with every other widget in the codebase).

In `lib/presentation/widgets/note_card.dart`, add `this.highlightQuery` to the constructor and pass it through: `PrefixText(content: widget.note.content, index: widget.index, highlightQuery: widget.highlightQuery)`.

- [ ] **Step 8: Thread the query from `TidePage` through `NoteStream` to `NoteCard`**

In `lib/presentation/widgets/note_stream.dart`, add an optional `highlightQuery` field to `NoteStream` and pass it to every `NoteCard` built in `itemBuilder`. In `lib/presentation/pages/tide_page.dart`, pass `highlightQuery: _searching ? _searchController.text : null` into the `NoteStream` constructor.

- [ ] **Step 9: Run tests, format, analyze, commit**

```bash
flutter test test/presentation/search/note_search_test.dart test/presentation/pages/tide_page_test.dart test/presentation/widgets/note_card_test.dart test/presentation/widgets/prefix_text_test.dart
dart format lib/presentation/search lib/presentation/widgets/tide_search_header.dart lib/presentation/pages/tide_page.dart lib/presentation/widgets/note_card.dart lib/presentation/widgets/note_stream.dart lib/presentation/widgets/prefix_text.dart lib/l10n/tide_localizations.dart test/presentation/search test/presentation/pages/tide_page_test.dart test/presentation/widgets/note_card_test.dart
flutter analyze
git add lib/presentation/search/note_search.dart lib/presentation/widgets/tide_search_header.dart lib/presentation/pages/tide_page.dart lib/presentation/widgets/note_card.dart lib/presentation/widgets/note_stream.dart lib/presentation/widgets/prefix_text.dart lib/l10n/tide_localizations.dart test/presentation/search/note_search_test.dart test/presentation/pages/tide_page_test.dart test/presentation/widgets/note_card_test.dart test/presentation/widgets/prefix_text_test.dart
git commit -m "feat: add search result count and inline term highlighting"
```

---

### Task 14: Final Verification, Terminology Audit, and Documentation

**Files:**
- Modify: `audit-styles.md`

- [ ] **Step 1: Run the complete automated gate**

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
tool/design_token_lint.sh
flutter analyze
flutter test
flutter build macos
flutter build apk --debug
```

Expected: all commands exit 0.

- [ ] **Step 2: Audit for stray Gravity terminology and confirm no illustration reuse**

```bash
rg -n -i "gravity|bump|stats for nerds|feather" lib test audit-styles.md
```

Expected: no matches in application code, tests, or `audit-styles.md` (the term "Gravity" may legitimately remain only in `docs/superpowers/`, which is out of scope for this grep).

- [ ] **Step 3: Update `audit-styles.md`**

Add a section documenting the interaction-parity additions: the archive/trash lifecycle, the swipe-left action panel via `flutter_slidable`, long-press full-screen editing, the Tide Stats and tutorial screens, the sectioned settings menu, search's results count and inline highlight, and markdown rendering via `flutter_markdown_plus` — mirroring the existing document's factual, no-marketing tone. State plainly that no Gravity color, typography, icon asset, or illustration was reused; only interaction structure and information architecture were.

- [ ] **Step 4: Commit**

```bash
git add audit-styles.md
git commit -m "docs: record interaction parity additions in the style audit"
```
