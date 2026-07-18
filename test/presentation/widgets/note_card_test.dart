import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/core/theme/tide_colors.dart';
import 'package:tide/core/theme/tide_theme.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/widgets/note_card.dart';

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
        theme: TideTheme.light,
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

    final richText = tester.widget<RichText>(find.byType(RichText));
    final span = richText.text as TextSpan;
    final color = span.style!.color!;
    expect(_contrast(color, TideColors.pearl), greaterThanOrEqualTo(4.5));
  });

  testWidgets('busy card cannot dispatch rescue', (tester) async {
    var rescueCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: TideTheme.light,
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
