import 'package:flutter/material.dart';

class TideHeader extends StatelessWidget {
  const TideHeader({super.key, required this.noteCount, required this.now});

  final int noteCount;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final countLabel = noteCount == 1
        ? '1 note captured'
        : '$noteCount notes captured';
    final date = MaterialLocalizations.of(context).formatMediumDate(now);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tide',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$countLabel • $date',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
