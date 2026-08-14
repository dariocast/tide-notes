import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/widgets/note_card.dart';
import 'package:tide/presentation/widgets/prefix_text.dart';

import '../../support/contrast.dart';

void main() {
  final timestamp = DateTime(2026, 7, 18, 12);
  final note = Note(
    id: 'n1',
    content: 'idea: accessible stream',
    createdAt: timestamp,
    updatedAt: timestamp,
    surfacedAt: timestamp,
    rescueCount: 0,
  );

  testWidgets('busy card cannot dispatch rescue', (tester) async {
    var rescueCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Scaffold(
          body: NoteCard(
            note: note,
            index: 0,
            busy: true,
            onChanged: (_) {},
            onRescue: () => rescueCount++,
          ),
        ),
      ),
    );

    await tester.drag(find.byType(NoteCard), const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(rescueCount, 0);
  });

  testWidgets('row is flat with metadata and no visible separator', (
    tester,
  ) async {
    final rescued = note.copyWith(rescueCount: 2);
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Scaffold(
          body: NoteCard(
            note: rescued,
            index: 1,
            now: () => timestamp.add(const Duration(hours: 2)),
            onChanged: (_) {},
            onRescue: () {},
          ),
        ),
      ),
    );

    final row = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('note-row')),
    );
    final decoration = row.decoration as BoxDecoration;
    expect(decoration.color, isNull);
    expect(decoration.borderRadius, isNull);
    expect(decoration.border, isNull);
    expect(find.textContaining('2h ago'), findsOneWidget);
    expect(find.textContaining('Jul 18'), findsOneWidget);
    expect(find.textContaining('↑ 2'), findsOneWidget);
  });

  for (final (:name, :theme, :colors, :textMuted, :bgBottom) in [
    (
      name: 'foam',
      theme: TideAppTheme.foam,
      colors: TideColors.foam,
      textMuted: GFoam.textMuted,
      bgBottom: GFoam.bgBottom,
    ),
    (
      name: 'deepTide',
      theme: TideAppTheme.deepTide,
      colors: TideColors.deepTide,
      textMuted: GDeepTide.textMuted,
      bgBottom: GDeepTide.bgBottom,
    ),
  ]) {
    testWidgets(
      '$name hovered row shows the soft water wash and keeps metadata readable',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              backgroundColor: bgBottom,
              body: NoteCard(
                note: note,
                index: 1,
                onChanged: (_) {},
                onRescue: () {},
              ),
            ),
          ),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(
          tester.getCenter(find.byKey(const ValueKey('note-row'))),
        );
        await tester.pump();

        final row = tester.widget<AnimatedContainer>(
          find.byKey(const ValueKey('note-row')),
        );
        final hoverColor = (row.decoration as BoxDecoration).color!;
        expect(
          hoverColor,
          colors.accentSubtle.withValues(alpha: GDecor.hoverAlpha),
        );
        final metadata = tester.widget<Text>(find.textContaining('Jul 18'));
        expect(metadata.style?.color, textMuted);
        expect(
          contrast(
            metadata.style!.color!,
            Color.alphaBlend(hoverColor, bgBottom),
          ),
          greaterThanOrEqualTo(4.5),
        );
      },
    );
  }

  testWidgets('highlights the search term when a query is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Scaffold(
          body: NoteCard(
            note: note.copyWith(content: 'idea: find this word'),
            index: 1,
            onChanged: (_) {},
            onRescue: () {},
            highlightQuery: 'this',
          ),
        ),
      ),
    );

    final rendered = tester.widget<RichText>(find.byType(RichText).first);
    final matchSpan =
        (rendered.text as TextSpan).children!.firstWhere(
              (span) => (span as TextSpan).text == 'this',
            )
            as TextSpan;
    expect(matchSpan.style?.backgroundColor, isNotNull);
  });

  testWidgets('inline editor keeps the flat row surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Scaffold(
          body: NoteCard(
            note: note,
            index: 1,
            onChanged: (_) {},
            onRescue: () {},
          ),
        ),
      ),
    );

    final before = tester.getSize(find.byKey(const ValueKey('note-row')));
    await tester.tap(find.byType(PrefixText));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('note-row'))).width,
      before.width,
    );
  });

  testWidgets(
    'rescue icon appears only while editing and swipe remains active',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TideAppTheme.foam,
          home: Scaffold(
            body: NoteCard(
              note: note,
              index: 1,
              onChanged: (_) {},
              onRescue: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Rescue note'), findsNothing);
      expect(find.byType(Slidable), findsOneWidget);

      await tester.tap(find.byType(PrefixText));
      await tester.pump();

      expect(find.byTooltip('Rescue note'), findsOneWidget);
      expect(find.byType(Slidable), findsOneWidget);
    },
  );

  testWidgets('rescue action keeps editing active while keyboard is open', (
    tester,
  ) async {
    var rescueCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Scaffold(
          body: NoteCard(
            note: note,
            index: 1,
            onChanged: (_) {},
            onRescue: () => rescueCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PrefixText));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(
      find.byTooltip('Rescue note'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    expect(rescueCount, 1);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Rescue note'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byTooltip('Rescue note'),
        matching: find.byType(TextFieldTapRegion),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'disposing a mid-edit card without a focus-loss event still reports '
    'editing as ended',
    (tester) async {
      var editing = false;
      var showCard = true;
      late StateSetter setHostState;

      await tester.pumpWidget(
        MaterialApp(
          theme: TideAppTheme.foam,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return showCard
                    ? NoteCard(
                        note: note,
                        index: 0,
                        onChanged: (_) {},
                        onRescue: () {},
                        onEditingChanged: (value) => editing = value,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PrefixText));
      await tester.pump();
      expect(editing, isTrue);
      expect(find.byType(TextField), findsOneWidget);

      // Swap the mid-edit card out for an unrelated widget, tearing down
      // its State via dispose() without ever routing through the focus
      // loss handler (no unfocus/blur happens here).
      setHostState(() => showCard = false);
      await tester.pump();

      expect(editing, isFalse);
    },
  );

  testWidgets('renders lines after the first as markdown', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Scaffold(
          body: NoteCard(
            note: note.copyWith(content: 'idea: title\n**bold body**'),
            index: 1,
            onChanged: (_) {},
            onRescue: () {},
          ),
        ),
      ),
    );

    // flutter_markdown_plus renders inline text via Text.rich, so the
    // resolved style (including the bold weight from the markdown style
    // sheet's `strong` style) lives on the underlying TextSpan rather than
    // on Text.style itself.
    final rendered = tester.widget<Text>(find.text('bold body'));
    expect(rendered.textSpan?.style?.fontWeight, FontWeight.w700);

    // Regression: PrefixText must only ever receive the first line.
    // PrefixText does no markdown parsing of its own -- it renders
    // whatever string it's handed as one continuous plain-text RichText.
    // If it were still handed the full multi-line content, the raw
    // markdown source ("**bold body**") would render a second time,
    // unformatted, via PrefixText's own RichText -- alongside the
    // correctly-rendered MarkdownBody below it. `find.text`/
    // `find.textContaining` only match `Text`/`EditableText` widgets, not
    // a bare `RichText` like PrefixText's, so we inspect PrefixText's
    // widget property and the plain text of every RichText in the tree
    // directly, rather than relying on those finders here.
    final prefixText = tester.widget<PrefixText>(find.byType(PrefixText));
    expect(prefixText.content, 'idea: title');

    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    for (final richText in richTexts) {
      expect(richText.text.toPlainText(), isNot(contains('**bold body**')));
    }

    // The first line (prefix + title) should still render exactly once,
    // via PrefixText.
    expect(find.bySemanticsLabel('idea: title'), findsOneWidget);
  });

  testWidgets('single-line notes render exactly as before, no markdown body', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Scaffold(
          body: NoteCard(
            note: note.copyWith(content: 'idea: single line'),
            index: 1,
            onChanged: (_) {},
            onRescue: () {},
          ),
        ),
      ),
    );

    expect(find.byType(MarkdownBody), findsNothing);
  });

  testWidgets('swipe-left reveals Archive, Delete, Share, and Copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Scaffold(
          body: NoteCard(
            note: note.copyWith(content: 'idea: swipe me'),
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

    await tester.drag(
      find.byKey(const ValueKey('note-row')),
      const Offset(-400, 0),
    );
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
            note: note.copyWith(content: 'idea: swipe me'),
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

    await tester.drag(
      find.byKey(const ValueKey('note-row')),
      const Offset(-400, 0),
    );
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
            note: note.copyWith(content: 'idea: swipe me'),
            index: 1,
            onChanged: (_) {},
            onRescue: () => rescued = true,
          ),
        ),
      ),
    );

    // A timed drag (rather than a plain instantaneous tester.drag) is
    // required here: flutter_slidable only mounts DismissiblePane -- the
    // widget whose initState registers the listener that makes
    // isDismissibleReady true -- once a frame is pumped after the ratio
    // exceeds the pane's extentRatio. A plain tester.drag delivers its
    // whole down/move/up sequence with no frame pumped in between, so
    // isDismissibleReady would still read false at release and the
    // gesture would silently fall back to "open the pane" instead of
    // dismissing -- unlike real, frame-by-frame finger drags.
    await tester.timedDrag(
      find.byKey(const ValueKey('note-row')),
      const Offset(400, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(rescued, isTrue);
  });

  testWidgets('long-press opens the full-screen edit page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: Scaffold(
          body: NoteCard(
            note: note.copyWith(content: 'idea: long press me'),
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
}
