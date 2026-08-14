import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tide/app.dart';
import 'package:tide/design/design_helpers.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/tide_icons.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/archive_receipt.dart';
import 'package:tide/domain/entities/delete_receipt.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/domain/entities/rescue_receipt.dart';
import 'package:tide/domain/repositories/note_repository.dart';
import 'package:tide/domain/usecases/append_note.dart';
import 'package:tide/domain/usecases/edit_note.dart';
import 'package:tide/domain/usecases/delete_all_notes.dart';
import 'package:tide/domain/usecases/rescue_note.dart';
import 'package:tide/domain/usecases/undo_rescue.dart';
import 'package:tide/domain/usecases/watch_notes.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/pages/tide_page.dart';

void main() {
  final timestamp = DateTime(2026, 7, 18, 12);

  Note note(String id) => Note(
    id: id,
    content: id,
    createdAt: timestamp,
    updatedAt: timestamp,
    surfacedAt: timestamp,
    rescueCount: 0,
  );

  Future<(TideBloc, RescueRepository)> pumpFlow(
    WidgetTester tester, {
    required VoidCallback haptic,
    RescueReceipt? rescueResult,
  }) async {
    final repository = RescueRepository(rescueResult: rescueResult);
    final bloc = TideBloc(
      watchNotes: WatchNotes(repository),
      appendNote: AppendNote(
        repository,
        now: () => timestamp,
        newId: () => 'new',
      ),
      editNote: EditNote(repository, now: () => timestamp),
      rescueNote: RescueNote(repository, now: () => timestamp),
      undoRescue: UndoRescue(repository),
      deleteAllNotes: DeleteAllNotes(repository),
    );
    addTearDown(() async {
      await bloc.close();
      await repository.dispose();
    });
    await tester.pumpWidget(
      TideApp(
        home: BlocProvider.value(
          value: bloc,
          child: TidePage(haptic: haptic),
        ),
      ),
    );
    bloc.add(const TideStarted());
    await tester.pump();
    repository.emit([note('top'), note('second')]);
    await tester.pump();
    await tester.pump();
    return (bloc, repository);
  }

  testWidgets('only notes below top can be rescued', (tester) async {
    await pumpFlow(tester, haptic: () {});

    expect(find.byType(Dismissible), findsOneWidget);
  });

  testWidgets('haptic and rescue dispatch happen only after swipe threshold', (
    tester,
  ) async {
    var haptics = 0;
    final (_, repository) = await pumpFlow(tester, haptic: () => haptics++);
    final dismissible = find.byType(Dismissible);

    await tester.drag(dismissible, const Offset(40, 0));
    await tester.pump();
    expect(haptics, 0);
    expect(repository.rescueCalls, 0);

    await tester.drag(dismissible, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(haptics, 1);
    expect(repository.rescueCalls, 1);
  });

  testWidgets('successful rescue shows Undo and Undo dispatches rollback', (
    tester,
  ) async {
    final rescuedAt = timestamp.add(const Duration(minutes: 1));
    final (_, repository) = await pumpFlow(
      tester,
      haptic: () {},
      rescueResult: RescueReceipt(
        noteId: 'second',
        previousSurfacedAt: timestamp,
        previousRescueCount: 0,
        rescuedSurfacedAt: rescuedAt,
      ),
    );

    await tester.drag(find.byType(Dismissible), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.byIcon(TideIcons.undo.data), findsOneWidget);

    await tester.tap(find.byIcon(TideIcons.undo.data));
    await tester.pumpAndSettle();
    expect(repository.undoCalls, 1);
  });

  testWidgets('OS reduced motion removes non-essential duration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: _MotionProbe(),
        ),
      ),
    );
    expect(
      tester
          .widget<AnimatedContainer>(find.byKey(const ValueKey('probe')))
          .duration,
      Duration.zero,
    );
  });
}

class _MotionProbe extends StatelessWidget {
  const _MotionProbe();

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const ValueKey('probe'),
    duration: context.motion.duration(GMotion.color),
  );
}

final class RescueRepository implements NoteRepository {
  RescueRepository({this.rescueResult});

  final StreamController<List<Note>> controller =
      StreamController<List<Note>>.broadcast();
  final RescueReceipt? rescueResult;
  int rescueCalls = 0;
  int undoCalls = 0;

  @override
  Stream<List<Note>> watchNotes() => controller.stream;

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
  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt) async {
    rescueCalls++;
    return rescueResult;
  }

  @override
  Future<void> undoRescue(RescueReceipt receipt) async {
    undoCalls++;
  }

  @override
  Stream<List<Note>> watchArchivedNotes() => const Stream.empty();

  @override
  Stream<List<Note>> watchDeletedNotes() => const Stream.empty();

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

  void emit(List<Note> notes) => controller.add(notes);

  Future<void> dispose() => controller.close();
}
