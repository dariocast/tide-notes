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
                  _StatCard(
                    value: '${stats.totalNotes}',
                    label: l10n.statsTotalNotes,
                  ),
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
              _DetailRow(
                label: l10n.statsLongestNote,
                value: '${stats.longestNoteCharacters}',
              ),
              _DetailRow(
                label: l10n.statsMostRescued,
                value: '${stats.mostRescuedCount}',
              ),
              _DetailRow(
                label: l10n.statsFirstNote,
                value: stats.firstNoteAt == null
                    ? '—'
                    : MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(stats.firstNoteAt!),
              ),
              _DetailRow(
                label: l10n.statsTotalCharacters,
                value: '${stats.totalCharacters}',
              ),
              const SizedBox(height: GSpace.s4),
              Text(
                l10n.statsWordDistribution,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: GSpace.s2),
              SizedBox(
                height: 96,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final count in stats.wordCountBuckets)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GSpace.s1,
                          ),
                          child: FractionallySizedBox(
                            heightFactor:
                                stats.wordCountBuckets.reduce(
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
