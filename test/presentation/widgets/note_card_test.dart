import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
      expect(find.byType(Dismissible), findsOneWidget);

      await tester.tap(find.byType(PrefixText));
      await tester.pump();

      expect(find.byTooltip('Rescue note'), findsOneWidget);
      expect(find.byType(Dismissible), findsOneWidget);
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
}
