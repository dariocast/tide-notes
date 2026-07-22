import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import 'tide_settings.dart';

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
    final g = Theme.of(context).extension<TideColors>()!;
    final compact = sizeClassOf(context) == GSizeClass.compact;

    final title = Text(
      'Tide',
      key: const ValueKey('tide-title'),
      style: Theme.of(context).textTheme.titleLarge,
    );
    final metadata = Text(
      '$countLabel • $date',
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: g.textMuted, letterSpacing: 0.6),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s5,
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s2,
      ),
      child: compact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const TideSettingsButton(),
                Expanded(
                  child: Column(
                    children: [
                      title,
                      const SizedBox(height: GSpace.s2),
                      metadata,
                    ],
                  ),
                ),
                const SizedBox.square(dimension: GLayout.minTouchTarget),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: GSpace.s2),
                      metadata,
                    ],
                  ),
                ),
                const TideSettingsButton(),
              ],
            ),
    );
  }
}
