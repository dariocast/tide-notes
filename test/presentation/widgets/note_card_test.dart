import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/widgets/note_card.dart';
import 'package:tide/presentation/widgets/prefix_text.dart';

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

  testWidgets('sinking text keeps readable contrast', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GravityAppTheme.light,
        home: Scaffold(
          body: NoteCard(
            note: note,
            index: 30,
            onChanged: (_) {},
            onRescue: () {},
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(PrefixText),
        matching: find.byType(RichText),
      ),
    );
    final span = richText.text as TextSpan;
    final color = span.style!.color!;
    expect(_contrast(color, GLight.surface), greaterThanOrEqualTo(4.5));
  });

  testWidgets('busy card cannot dispatch rescue', (tester) async {
    var rescueCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: GravityAppTheme.light,
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

  testWidgets('row is flat with metadata and a hairline separator', (
    tester,
  ) async {
    final rescued = note.copyWith(rescueCount: 2);
    await tester.pumpWidget(
      MaterialApp(
        theme: GravityAppTheme.light,
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
    expect(decoration.border?.bottom.width, 1);
    expect(find.textContaining('2h ago'), findsOneWidget);
    expect(find.textContaining('Jul 18'), findsOneWidget);
    expect(find.textContaining('↑ 2'), findsOneWidget);
  });

  for (final (:name, :theme, :ink, :textGhost, :bgBottom, :hoverMinimum) in [
    (
      name: 'light',
      theme: GravityAppTheme.light,
      ink: GLight.ink,
      textGhost: GLight.textGhost,
      bgBottom: GLight.bgBottom,
      hoverMinimum: 4.55,
    ),
    (
      name: 'dark',
      theme: GravityAppTheme.dark,
      ink: GDark.ink,
      textGhost: GDark.textGhost,
      bgBottom: GDark.bgBottom,
      hoverMinimum: 4.6,
    ),
  ]) {
    testWidgets('$name hovered row keeps metadata readable on darkest paper', (
      tester,
    ) async {
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
      expect(hoverColor, ink.withValues(alpha: GDecor.hoverAlpha));
      final metadata = tester.widget<Text>(find.textContaining('Jul 18'));
      expect(metadata.style?.color, textGhost);
      expect(
        _contrast(
          metadata.style!.color!,
          Color.alphaBlend(hoverColor, bgBottom),
        ),
        greaterThanOrEqualTo(hoverMinimum),
      );
    });
  }

  testWidgets('inline editor keeps the flat row surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GravityAppTheme.light,
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
