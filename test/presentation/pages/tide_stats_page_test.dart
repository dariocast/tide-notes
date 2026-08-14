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
