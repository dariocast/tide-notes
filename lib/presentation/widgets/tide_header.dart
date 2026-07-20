import 'package:flutter/material.dart';

import '../../design/appearance_controller.dart';
import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';

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
    final g = Theme.of(context).extension<GravityTheme>()!;
    final compact = sizeClassOf(context) == GSizeClass.compact;
    final appearance = AppearanceScope.maybeOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s5,
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const TideGlyph(size: 18),
                    const SizedBox(width: GSpace.s3),
                    Text('Tide', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: GSpace.s2),
                Text(
                  '$countLabel • $date',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: g.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          if (appearance != null)
            Semantics(
              label: 'Appearance settings',
              button: true,
              child: PopupMenuButton<_AppearanceOption>(
                tooltip: 'Appearance settings',
                icon: const Icon(Icons.tune_rounded),
                onSelected: (option) => switch (option) {
                  _AppearanceOption.system => appearance.setThemeMode(
                    ThemeMode.system,
                  ),
                  _AppearanceOption.light => appearance.setThemeMode(
                    ThemeMode.light,
                  ),
                  _AppearanceOption.dark => appearance.setThemeMode(
                    ThemeMode.dark,
                  ),
                  _AppearanceOption.motion => appearance.setMotionEnabled(
                    !appearance.motionEnabled,
                  ),
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _AppearanceOption.system,
                    child: Text('Use system theme'),
                  ),
                  const PopupMenuItem(
                    value: _AppearanceOption.light,
                    child: Text('Use light theme'),
                  ),
                  const PopupMenuItem(
                    value: _AppearanceOption.dark,
                    child: Text('Use dark theme'),
                  ),
                  PopupMenuItem(
                    value: _AppearanceOption.motion,
                    child: Text(
                      appearance.motionEnabled
                          ? 'Reduce motion'
                          : 'Enable motion',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _AppearanceOption { system, light, dark, motion }
