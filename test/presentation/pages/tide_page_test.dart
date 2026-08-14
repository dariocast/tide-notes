import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/app.dart';
import 'package:tide/design/appearance_controller.dart';
import 'package:tide/design/tide_icons.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/archive_receipt.dart';
import 'package:tide/domain/entities/delete_receipt.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/domain/entities/rescue_receipt.dart';
import 'package:tide/domain/repositories/note_repository.dart';
import 'package:tide/domain/usecases/append_note.dart';
import 'package:tide/domain/usecases/archive_note.dart';
import 'package:tide/domain/usecases/edit_note.dart';
import 'package:tide/domain/usecases/delete_all_notes.dart';
import 'package:tide/domain/usecases/delete_note.dart';
import 'package:tide/domain/usecases/empty_trash.dart';
import 'package:tide/domain/usecases/permanently_delete_note.dart';
import 'package:tide/domain/usecases/rescue_note.dart';
import 'package:tide/domain/usecases/restore_from_archive.dart';
import 'package:tide/domain/usecases/restore_from_trash.dart';
import 'package:tide/domain/usecases/undo_rescue.dart';
import 'package:tide/domain/usecases/watch_notes.dart';
import 'package:tide/presentation/blocs/tide_bloc.dart';
import 'package:tide/presentation/blocs/tide_event.dart';
import 'package:tide/presentation/pages/archive_page.dart';
import 'package:tide/presentation/pages/tide_page.dart';
import 'package:tide/presentation/widgets/note_card.dart';
import 'package:tide/presentation/widgets/note_composer.dart';
import 'package:tide/presentation/widgets/tide_shell.dart';

void main() {
  final timestamp = DateTime(2026, 7, 18, 12);

  Future<(TideBloc, PageRepository)> pumpPage(
    WidgetTester tester, {
    List<Note> notes = const [],
    MediaQueryData? mediaQuery,
    ThemeData? theme,
    DateTime Function()? now,
    AppearanceController? appearance,
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
      archiveNote: ArchiveNote(repository, now: () => timestamp),
      restoreFromArchive: RestoreFromArchive(repository),
      deleteNote: DeleteNote(repository, now: () => timestamp),
      restoreFromTrash: RestoreFromTrash(repository),
      permanentlyDeleteNote: PermanentlyDeleteNote(repository),
      emptyTrash: EmptyTrash(repository),
      deleteAllNotes: DeleteAllNotes(repository),
    );
    addTearDown(() async {
      await bloc.close();
      await repository.dispose();
    });

    Widget page = now == null ? const TidePage() : TidePage(now: now);
    if (theme != null) page = Theme(data: theme, child: page);
    if (mediaQuery != null) {
      page = MediaQuery(data: mediaQuery, child: page);
    }
    // BlocProvider wraps TideApp (not just the home page) so that pages
    // pushed via Navigator.push — which mount as siblings of the initial
    // route under the Navigator's Overlay, not as descendants of it — can
    // still find TideBloc via context.read/BlocBuilder. This mirrors
    // main.dart's TideBootstrap, where BlocProvider wraps TideApp itself.
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: theme == null
            ? TideApp(home: page, appearance: appearance)
            : MaterialApp(theme: theme, home: page),
      ),
    );
    if (notes.isNotEmpty) {
      bloc.add(const TideStarted());
      await tester.pump();
      repository.emit(notes);
      await tester.pump();
    }
    return (bloc, repository);
  }

  Note makeNote(String id, {String? content}) => Note(
    id: id,
    content: content ?? id,
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
      await tester.tap(find.byIcon(TideIcons.insert.data));
      await tester.pump();

      expect(find.byType(NoteCard), findsNothing);
    },
  );

  testWidgets('search action replaces the regular header and focuses input', (
    tester,
  ) async {
    await pumpPage(tester, notes: [makeNote('one')]);
    await tester.pump();

    final search = find.byKey(const ValueKey('open-search'));
    final settings = find.bySemanticsLabel('Appearance settings');
    expect(find.byKey(const ValueKey('open-search')), findsOneWidget);
    expect(
      tester.getCenter(search).dx,
      greaterThan(tester.getCenter(settings).dx),
    );

    await tester.tap(search);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('search-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('tide-title')), findsNothing);
    expect(settings, findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('search-input')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('composer-transition'))).height,
      0,
    );
  });

  testWidgets('closing search resets query and preserves composer draft', (
    tester,
  ) async {
    await pumpPage(tester, notes: [makeNote('one')]);
    final composer = find.byKey(const ValueKey('composer-input'));
    await tester.enterText(composer, 'unfinished draft');

    await tester.tap(find.byKey(const ValueKey('open-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('search-input')), 'one');
    await tester.tap(find.byKey(const ValueKey('close-search')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('search-input')), findsNothing);
    expect(find.byKey(const ValueKey('tide-title')), findsOneWidget);
    expect(
      tester.widget<TextField>(composer).controller!.text,
      'unfinished draft',
    );

    await tester.tap(find.byKey(const ValueKey('open-search')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('search-input')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('search filters content immediately and preserves note order', (
    tester,
  ) async {
    Finder noteCard(String id) => find.byWidgetPredicate(
      (widget) => widget is NoteCard && widget.note.id == id,
    );
    await pumpPage(
      tester,
      notes: [
        makeNote('first', content: 'TODO: Buy Milk'),
        makeNote('second', content: 'Call Alice'),
        makeNote('third', content: 'todo: buy train tickets'),
      ],
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('open-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('search-input')),
      '  ToDo: BuY  ',
    );
    await tester.pump();

    expect(noteCard('first'), findsOneWidget);
    expect(noteCard('second'), findsNothing);
    expect(noteCard('third'), findsOneWidget);
    expect(
      tester.getTopLeft(noteCard('first')).dy,
      lessThan(tester.getTopLeft(noteCard('third')).dy),
    );
  });

  testWidgets('clear restores all notes without closing search', (
    tester,
  ) async {
    Finder noteCard(String id) => find.byWidgetPredicate(
      (widget) => widget is NoteCard && widget.note.id == id,
    );
    await pumpPage(
      tester,
      notes: [
        makeNote('first', content: 'alpha'),
        makeNote('second', content: 'beta'),
      ],
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('open-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('search-input')), 'alpha');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('clear-search')));
    await tester.pump();

    expect(find.byKey(const ValueKey('search-input')), findsOneWidget);
    expect(noteCard('first'), findsOneWidget);
    expect(noteCard('second'), findsOneWidget);
  });

  testWidgets('unmatched query shows dedicated feedback', (tester) async {
    await pumpPage(tester, notes: [makeNote('one', content: 'alpha')]);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('open-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('search-input')),
      'missing',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('search-empty-state')), findsOneWidget);
    expect(find.text('No notes found.'), findsOneWidget);
    expect(find.textContaining('stream is quiet'), findsNothing);
  });

  testWidgets(
    'Italian search localizes field, close, and no-results feedback',
    (tester) async {
      final appearance = AppearanceController.inMemory(
        language: TideLanguageSelection.italian,
      );
      await pumpPage(
        tester,
        notes: [makeNote('one', content: 'alpha')],
        appearance: appearance,
      );
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Cerca note'));
      await tester.pumpAndSettle();
      expect(find.text('Cerca nelle note…'), findsOneWidget);
      expect(find.text('Cancella'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('search-input')),
        'assente',
      );
      await tester.pump();
      expect(find.text('Nessuna nota trovata.'), findsOneWidget);
    },
  );

  testWidgets('search remains usable in the wide macOS sidebar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    try {
      await pumpPage(tester, notes: [makeNote('one')]);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('open-search')));
      await tester.pumpAndSettle();

      final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
      expect(
        find.descendant(
          of: sidebar,
          matching: find.byKey(const ValueKey('search-input')),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('reduced motion switches to search in one frame', (tester) async {
    await pumpPage(
      tester,
      mediaQuery: const MediaQueryData(disableAnimations: true),
    );
    await tester.tap(find.byKey(const ValueKey('open-search')));
    await tester.pump();

    expect(find.byKey(const ValueKey('search-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('tide-title')), findsNothing);
  });

  testWidgets('composer receives focus on startup', (tester) async {
    await pumpPage(tester);
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('composer-input')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('submit on enter sends the note when enabled', (tester) async {
    final appearance = AppearanceController.inMemory(submitOnEnter: true);
    final (_, repository) = await pumpPage(tester, appearance: appearance);
    final composer = find.byKey(const ValueKey('composer-input'));

    await tester.enterText(composer, 'quick note');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(repository.created.single.content, 'quick note');
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
  });

  testWidgets('button submission clears composer after successful append', (
    tester,
  ) async {
    final (_, repository) = await pumpPage(tester);
    final composer = find.byKey(const ValueKey('composer-input'));
    await tester.enterText(composer, 'capture thought');
    await tester.tap(find.byIcon(TideIcons.insert.data));
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
      tester
          .widget<TextField>(find.byKey(const ValueKey('composer-input')))
          .controller!
          .text,
      'pasted thought',
    );
  });

  testWidgets(
    'paste appends and places the cursor correctly when selection is invalid',
    (tester) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return {'text': 'pasted'};
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

      final controller = tester
          .widget<TextField>(find.byKey(const ValueKey('composer-input')))
          .controller!;
      controller.text = 'existing';
      // The field must be unfocused before forcing an invalid selection:
      // while focused, EditableText immediately normalizes an invalid
      // selection back to a valid one, which would hide the regression.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: -1);

      await tester.tap(find.byKey(const ValueKey('composer-paste')));
      await tester.pump();

      const expectedText = 'existingpasted';
      expect(controller.text, expectedText);
      expect(controller.selection.baseOffset, expectedText.length);
      expect(controller.selection.extentOffset, expectedText.length);
    },
  );

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

  testWidgets('mobile settings sheet selects Abyss theme', (tester) async {
    final appearance = AppearanceController.inMemory();
    await pumpPage(tester, appearance: appearance);

    await tester.tap(find.bySemanticsLabel('Appearance settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abyss'));
    await tester.pumpAndSettle();

    expect(appearance.selection, TideThemeSelection.abyss);
  });

  testWidgets('tapping Archive in settings pushes the Archive page', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsLabel('Appearance settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.byType(ArchivePage), findsOneWidget);
  });

  testWidgets('language setting switches the app to Italian', (tester) async {
    final appearance = AppearanceController.inMemory();
    await pumpPage(tester, appearance: appearance);

    await tester.tap(find.bySemanticsLabel('Appearance settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🇮🇹  Italiano'));
    await tester.pumpAndSettle();

    expect(find.text('Cattura un pensiero…'), findsOneWidget);
    expect(appearance.language, TideLanguageSelection.italian);
  });

  testWidgets('delete all asks for confirmation before dispatching', (
    tester,
  ) async {
    final (_, repository) = await pumpPage(tester, notes: [makeNote('one')]);

    await tester.tap(find.bySemanticsLabel('Appearance settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete all notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all notes'));
    await tester.pumpAndSettle();

    expect(find.text('Delete all notes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deleteAllCalls, 0);

    await tester.tap(find.bySemanticsLabel('Appearance settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete all notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();
    expect(repository.deleteAllCalls, 1);
  });

  testWidgets('macOS settings popover selects Abyss theme', (tester) async {
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    try {
      final appearance = AppearanceController.inMemory();
      await pumpPage(tester, appearance: appearance);

      await tester.tap(find.bySemanticsLabel('Appearance settings'));
      await tester.pumpAndSettle();

      expect(find.text('Theme'), findsOneWidget);
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abyss'));
      await tester.pumpAndSettle();

      expect(appearance.selection, TideThemeSelection.abyss);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
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
        theme: TideAppTheme.foam,
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('desktop-split-layout')),
        findsOneWidget,
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

  testWidgets('composer surface and note rows use organic shape language', (
    tester,
  ) async {
    await pumpPage(tester, notes: [makeNote('one')]);
    await tester.pump();

    final composerSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('composer-surface')),
    );
    final composerDecoration = composerSurface.decoration as BoxDecoration;
    expect(composerDecoration.borderRadius, GShapes.composer);
    expect(composerDecoration.boxShadow, isNull);

    final noteRow = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('note-row')),
    );
    final noteDecoration = noteRow.decoration as BoxDecoration;
    expect(noteDecoration.border, isNull);
    expect(noteDecoration.borderRadius, isNull);

    final noteContext = tester.element(find.byKey(const ValueKey('note-row')));
    expect(Theme.of(noteContext).textTheme.bodyMedium?.fontFamily, 'Nunito');
    expect(find.text('Tide'), findsOneWidget);
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
      theme: TideAppTheme.foam,
    );
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tester.tap(find.byKey(const ValueKey('open-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('search-input')), 'query');
    await tester.pump();
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tester.tap(find.byKey(const ValueKey('close-search')));
    await tester.pumpAndSettle();

    await pumpPage(
      tester,
      mediaQuery: const MediaQueryData(
        textScaler: TextScaler.linear(1.3),
        platformBrightness: Brightness.dark,
      ),
      theme: TideAppTheme.deepTide,
    );
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}

final class PageRepository implements NoteRepository {
  final StreamController<List<Note>> controller =
      StreamController<List<Note>>.broadcast();
  final List<Note> created = [];
  int deleteAllCalls = 0;
  final List<String> updatedContents = [];

  @override
  Stream<List<Note>> watchNotes() => controller.stream;

  @override
  Future<void> createNote(Note note) async {
    created.add(note);
    controller.add([...created]);
  }

  @override
  Future<int> importNotes(List<Note> notes) async => 0;

  @override
  Future<void> deleteAll() async => deleteAllCalls++;

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
