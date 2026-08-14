import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tide/domain/entities/archive_receipt.dart';
import 'package:tide/domain/entities/delete_receipt.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/domain/entities/rescue_receipt.dart';
import 'package:tide/domain/repositories/note_repository.dart';
import 'package:tide/domain/usecases/append_note.dart';
import 'package:tide/domain/usecases/archive_note.dart';
import 'package:tide/domain/usecases/delete_note.dart';
import 'package:tide/domain/usecases/edit_note.dart';
import 'package:tide/domain/usecases/empty_trash.dart';
import 'package:tide/domain/usecases/permanently_delete_note.dart';
import 'package:tide/domain/usecases/rescue_note.dart';
import 'package:tide/domain/usecases/restore_from_archive.dart';
import 'package:tide/domain/usecases/restore_from_trash.dart';
import 'package:tide/domain/usecases/undo_rescue.dart';

void main() {
  late FakeNoteRepository repository;
  late DateTime now;
  late AppendNote append;
  late EditNote edit;
  late RescueNote rescue;
  late UndoRescue undo;
  late ArchiveNote archiveNote;
  late RestoreFromArchive restoreFromArchive;
  late DeleteNote deleteNote;
  late RestoreFromTrash restoreFromTrash;
  late PermanentlyDeleteNote permanentlyDeleteNote;
  late EmptyTrash emptyTrash;

  setUp(() {
    repository = FakeNoteRepository();
    now = DateTime(2026, 7, 18, 12);
    repository.seed(
      Note(
        id: 'n1',
        content: 'first',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        surfacedAt: now.subtract(const Duration(hours: 1)),
        rescueCount: 0,
      ),
    );
    append = AppendNote(repository, now: () => now, newId: () => 'new');
    edit = EditNote(repository, now: () => now);
    rescue = RescueNote(repository, now: () => now);
    undo = UndoRescue(repository);
    archiveNote = ArchiveNote(repository, now: () => now);
    restoreFromArchive = RestoreFromArchive(repository);
    deleteNote = DeleteNote(repository, now: () => now);
    restoreFromTrash = RestoreFromTrash(repository);
    permanentlyDeleteNote = PermanentlyDeleteNote(repository);
    emptyTrash = EmptyTrash(repository);
  });

  tearDown(() => repository.dispose());

  test('append rejects whitespace-only content', () async {
    expect(append('  \n '), throwsA(isA<ArgumentError>()));
  });

  test(
    'append trims trailing whitespace and preserves leading/internal text',
    () async {
      await append('  idea: keep\nshape   ');

      expect(repository.created.single.content, '  idea: keep\nshape');
    },
  );

  test('edit changes content but not surfacedAt', () async {
    final before = repository.seeded.single;

    await edit(id: before.id, content: 'changed');

    expect(repository.seeded.single.content, 'changed');
    expect(repository.seeded.single.updatedAt, now);
    expect(repository.seeded.single.surfacedAt, before.surfacedAt);
  });

  test('rescue returns receipt and undo restores old values', () async {
    final before = repository.seeded.single;

    final receipt = await rescue('n1');

    expect(receipt, isNotNull);
    expect(repository.seeded.single.rescueCount, 1);
    expect(repository.seeded.single.surfacedAt, now);

    await undo(receipt!);

    expect(repository.seeded.single.rescueCount, 0);
    expect(repository.seeded.single.surfacedAt, before.surfacedAt);
  });

  test(
    'archiveNote returns a receipt and restoreFromArchive clears it',
    () async {
      final receipt = await archiveNote('n1');

      expect(receipt!.noteId, 'n1');
      expect(repository.seeded.single.archivedAt, now);

      await restoreFromArchive('n1');

      expect(repository.seeded.single.archivedAt, isNull);
    },
  );

  test('deleteNote returns a receipt and restoreFromTrash clears it', () async {
    final receipt = await deleteNote('n1');

    expect(receipt!.noteId, 'n1');
    expect(repository.seeded.single.deletedAt, now);

    await restoreFromTrash('n1');

    expect(repository.seeded.single.deletedAt, isNull);
  });

  test(
    'permanentlyDeleteNote and emptyTrash call through to the repository',
    () async {
      await permanentlyDeleteNote('n1');
      await emptyTrash();
    },
  );
}

final class FakeNoteRepository implements NoteRepository {
  final StreamController<List<Note>> _controller =
      StreamController<List<Note>>.broadcast();
  final List<Note> seeded = [];
  final List<Note> created = [];

  void seed(Note note) => seeded.add(note);

  @override
  Stream<List<Note>> watchNotes() => _controller.stream;

  @override
  Future<void> createNote(Note note) async {
    created.add(note);
    seeded.add(note);
    _emit();
  }

  @override
  Future<int> importNotes(List<Note> notes) async => 0;

  @override
  Future<void> deleteAll() async {}

  @override
  Future<void> updateContent(
    String id,
    String content,
    DateTime updatedAt,
  ) async {
    final index = seeded.indexWhere((note) => note.id == id);
    seeded[index] = seeded[index].copyWith(
      content: content,
      updatedAt: updatedAt,
    );
    _emit();
  }

  @override
  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt) async {
    final index = seeded.indexWhere((note) => note.id == id);
    if (index == -1) return null;
    final note = seeded[index];
    final receipt = RescueReceipt(
      noteId: note.id,
      previousSurfacedAt: note.surfacedAt,
      previousRescueCount: note.rescueCount,
      rescuedSurfacedAt: surfacedAt,
    );
    seeded[index] = note.copyWith(
      surfacedAt: surfacedAt,
      rescueCount: note.rescueCount + 1,
    );
    _emit();
    return receipt;
  }

  @override
  Future<void> undoRescue(RescueReceipt receipt) async {
    final index = seeded.indexWhere(
      (note) =>
          note.id == receipt.noteId &&
          note.surfacedAt == receipt.rescuedSurfacedAt,
    );
    if (index == -1) return;
    seeded[index] = seeded[index].copyWith(
      surfacedAt: receipt.previousSurfacedAt,
      rescueCount: receipt.previousRescueCount,
    );
    _emit();
  }

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
  Future<void> restoreFromArchive(String id) async {
    final index = seeded.indexWhere((note) => note.id == id);
    if (index == -1) return;
    seeded[index] = Note(
      id: seeded[index].id,
      content: seeded[index].content,
      createdAt: seeded[index].createdAt,
      updatedAt: seeded[index].updatedAt,
      surfacedAt: seeded[index].surfacedAt,
      rescueCount: seeded[index].rescueCount,
    );
  }

  @override
  Future<DeleteReceipt?> softDelete(String id, DateTime deletedAt) async {
    final index = seeded.indexWhere((note) => note.id == id);
    if (index == -1) return null;
    seeded[index] = Note(
      id: seeded[index].id,
      content: seeded[index].content,
      createdAt: seeded[index].createdAt,
      updatedAt: seeded[index].updatedAt,
      surfacedAt: seeded[index].surfacedAt,
      rescueCount: seeded[index].rescueCount,
      deletedAt: deletedAt,
    );
    return DeleteReceipt(noteId: id, deletedAt: deletedAt);
  }

  @override
  Future<void> restoreFromTrash(String id) async {
    final index = seeded.indexWhere((note) => note.id == id);
    if (index == -1) return;
    seeded[index] = Note(
      id: seeded[index].id,
      content: seeded[index].content,
      createdAt: seeded[index].createdAt,
      updatedAt: seeded[index].updatedAt,
      surfacedAt: seeded[index].surfacedAt,
      rescueCount: seeded[index].rescueCount,
    );
  }

  @override
  Future<void> permanentlyDelete(String id) async {}

  @override
  Future<void> emptyTrash() async {}

  void _emit() {
    final sorted = [...seeded]
      ..sort((a, b) {
        final surfaced = b.surfacedAt.compareTo(a.surfacedAt);
        return surfaced == 0 ? b.id.compareTo(a.id) : surfaced;
      });
    _controller.add(sorted);
  }

  Future<void> dispose() => _controller.close();
}
