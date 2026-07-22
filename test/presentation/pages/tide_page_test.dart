import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/app.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/domain/entities/rescue_receipt.dart';
import 'package:tide/domain/repositories/note_repository.dart';
import 'package:tide/domain/usecases/append_note.dart';
import 'package:tide/domain/usecases/edit_note.dart';
import 'package:tide/domain/usecases/rescue_note.dart';
import 'package:tide/domain/usecases/undo_rescue.dart';
import 'package:tide/domain/usecases/watch_notes.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/pages/tide_page.dart';
import 'package:tide/presentation/widgets/note_card.dart';
import 'package:tide/presentation/widgets/tide_empty_state.dart';
import 'package:tide/presentation/widgets/tide_header.dart';
import 'package:tide/presentation/widgets/tide_shell.dart';

void main() {
  final timestamp = DateTime(2026, 7, 18, 12);

  Future<(TideBloc, PageRepository)> pumpPage(
    WidgetTester tester, {
    List<Note> notes = const [],
    MediaQueryData? mediaQuery,
    ThemeData? theme,
    DateTime Function()? now,
  }) async {
    final repository = PageRepository();
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
    );
    addTearDown(() async {
      await bloc.close();
      await repository.dispose();
    });

    Widget page = BlocProvider.value(
      value: bloc,
      child: now == null ? const TidePage() : TidePage(now: now),
    );
    if (theme != null) page = Theme(data: theme, child: page);
    if (mediaQuery != null) {
      page = MediaQuery(data: mediaQuery, child: page);
    }
    await tester.pumpWidget(
      theme == null
          ? TideApp(home: page)
          : MaterialApp(theme: theme, home: page),
    );
    if (notes.isNotEmpty) {
      bloc.add(const TideStarted());
      await tester.pump();
      repository.emit(notes);
      await tester.pump();
    }
    return (bloc, repository);
  }

  Note makeNote(String id) => Note(
    id: id,
    content: id,
    createdAt: timestamp,
    updatedAt: timestamp,
    surfacedAt: timestamp,
    rescueCount: 0,
  );

  testWidgets(
    'composer stays above stream and blank submit dispatches nothing',
    (tester) async {
      await pumpPage(tester);

      expect(find.byKey(const ValueKey('composer')), findsOneWidget);
      expect(find.byKey(const ValueKey('note-list')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(find.byType(NoteCard), findsNothing);
    },
  );

  testWidgets('button submission clears composer after successful append', (
    tester,
  ) async {
    final (_, repository) = await pumpPage(tester);
    final composer = find.byKey(const ValueKey('composer-input'));
    await tester.enterText(composer, 'capture thought');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(repository.created.single.content, 'capture thought');
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
  });

  testWidgets('Enter inserts newline while Meta+Enter submits', (tester) async {
    final (_, repository) = await pumpPage(tester);
    final composer = find.byKey(const ValueKey('composer-input'));
    await tester.tap(composer);
    await tester.enterText(composer, 'line one');
    await tester.enterText(composer, 'line one\n');
    expect(tester.widget<TextField>(composer).controller!.text, 'line one\n');

    await tester.enterText(composer, 'command submit');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    expect(repository.created.single.content, 'command submit');
  });

  testWidgets('empty state explains Append, Review, Rescue', (tester) async {
    await pumpPage(tester);

    expect(find.textContaining('Append'), findsOneWidget);
    expect(find.textContaining('review'), findsOneWidget);
    expect(find.textContaining('rescue'), findsOneWidget);
  });

  testWidgets('lean shell shows Tide count and localized date', (tester) async {
    await pumpPage(
      tester,
      notes: [makeNote('one'), makeNote('two')],
      now: () => DateTime(2026, 7, 19, 12),
    );
    await tester.pump();

    expect(find.byType(TideShell), findsOneWidget);
    expect(find.byKey(const ValueKey('vertical-layout')), findsOneWidget);
    expect(find.text('Tide'), findsOneWidget);
    expect(find.textContaining('2 notes captured'), findsOneWidget);
    expect(find.textContaining('Jul 19'), findsOneWidget);
  });

  testWidgets('wide macOS puts controls beside note stream', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    try {
      await pumpPage(tester, notes: [makeNote('one')]);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('desktop-split-layout')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('desktop-sidebar')), findsOneWidget);
      expect(find.byType(NoteCard), findsOneWidget);
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('wide macOS supports large text without accessibility issues', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    try {
      await pumpPage(
        tester,
        notes: [makeNote('top'), makeNote('middle'), makeNote('bottom')],
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        theme: GravityAppTheme.light,
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('desktop-split-layout')),
        findsOneWidget,
      );
      expect(
        _contrast(GLight.textGhost, GLight.bgBottom),
        greaterThanOrEqualTo(4.6),
      );
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('note stream keeps its scroll position across a breakpoint', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 800);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    try {
      final notes = List.generate(100, (index) => makeNote('$index'));
      await pumpPage(tester, notes: notes);
      await tester.pump();

      final noteList = find.byKey(const ValueKey('note-list'));
      await tester.drag(noteList, const Offset(0, -600));
      await tester.pumpAndSettle();
      final beforeResize = tester
          .state<ScrollableState>(
            find.descendant(of: noteList, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      expect(beforeResize, greaterThan(0));

      tester.view.physicalSize = const Size(1200, 800);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('desktop-split-layout')),
        findsOneWidget,
      );
      expect(
        tester
            .state<ScrollableState>(
              find.descendant(of: noteList, matching: find.byType(Scrollable)),
            )
            .position
            .pixels,
        closeTo(beforeResize, 0.01),
      );
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('composer uses the tokenized capture field', (tester) async {
    await pumpPage(tester);

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('composer-input')),
    );
    expect(field.minLines, 2);
    expect(
      tester.getSize(find.byKey(const ValueKey('composer'))).height,
      lessThan(110),
    );
  });

  testWidgets('empty stream guidance is left aligned', (tester) async {
    await pumpPage(tester);

    final guidance = tester.widget<Text>(
      find.textContaining('Capture anything'),
    );
    expect(guidance.textAlign, TextAlign.left);
  });

  testWidgets('header and empty state use text without decorations', (
    tester,
  ) async {
    await pumpPage(tester, theme: GravityAppTheme.light);

    for (final type in [TideHeader, TideEmptyState]) {
      expect(
        find.descendant(
          of: find.byType(type),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    }
    final shell = find.byType(TideShell);
    expect(shell, findsOneWidget);
    expect(
      find.descendant(
        of: shell,
        matching: find.ancestor(
          of: find.byType(TideHeader),
          matching: find.byType(CustomPaint),
        ),
      ),
      findsNothing,
    );
    expect(find.text('⌘'), findsNothing);
    expect(find.text('↵'), findsNothing);
  });

  testWidgets('tapping note opens inline editor and focus loss flushes edit', (
    tester,
  ) async {
    final (_, repository) = await pumpPage(tester, notes: [makeNote('one')]);
    await tester.pump();
    await tester.tap(find.byType(NoteCard));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));

    final editors = find.byType(TextField);
    await tester.enterText(editors.last, 'changed');
    await tester.tap(find.byKey(const ValueKey('composer-input')));
    await tester.pump(const Duration(milliseconds: 450));

    expect(repository.updatedContents, contains('changed'));
  });

  testWidgets('10,000 notes use bounded lazy card construction', (
    tester,
  ) async {
    final notes = List.generate(10000, (index) => makeNote('$index'));
    await pumpPage(tester, notes: notes);
    await tester.pump();

    expect(find.byType(NoteCard).evaluate().length, lessThan(100));
  });

  testWidgets('save and rescue controls expose semantic labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpPage(tester, notes: [makeNote('top'), makeNote('second')]);
    await tester.pump();

    final labels = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((semantics) => semantics.properties.label);
    expect(labels, contains('Save note'));
    expect(labels, contains('Rescue note'));
    semantics.dispose();
  });

  testWidgets('large text and theme modes meet accessibility guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpPage(
      tester,
      mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
      theme: GravityAppTheme.light,
    );
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await pumpPage(
      tester,
      mediaQuery: const MediaQueryData(
        textScaler: TextScaler.linear(1.3),
        platformBrightness: Brightness.dark,
      ),
      theme: GravityAppTheme.dark,
    );
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}

double _contrast(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

final class PageRepository implements NoteRepository {
  final StreamController<List<Note>> controller =
      StreamController<List<Note>>.broadcast();
  final List<Note> created = [];
  final List<String> updatedContents = [];

  @override
  Stream<List<Note>> watchNotes() => controller.stream;

  @override
  Future<void> createNote(Note note) async {
    created.add(note);
    controller.add([...created]);
  }

  @override
  Future<void> updateContent(
    String id,
    String content,
    DateTime updatedAt,
  ) async {
    updatedContents.add(content);
  }

  @override
  Future<RescueReceipt?> rescue(String id, DateTime surfacedAt) async => null;

  @override
  Future<void> undoRescue(RescueReceipt receipt) async {}

  void emit(List<Note> notes) => controller.add(notes);

  Future<void> dispose() => controller.close();
}
