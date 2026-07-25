import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import 'tide_settings.dart';
import '../../l10n/tide_localizations.dart';

class TideHeader extends StatelessWidget {
  const TideHeader({
    super.key,
    required this.noteCount,
    required this.now,
    required this.onExport,
    required this.onImport,
    required this.onDeleteAll,
    required this.onSearch,
  });

  final int noteCount;
  final DateTime now;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback onDeleteAll;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    final countLabel = l10n.notesCaptured(noteCount);
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
    final searchButton = Semantics(
      label: l10n.searchNotes,
      button: true,
      child: IconButton(
        key: const ValueKey('open-search'),
        tooltip: l10n.searchNotes,
        onPressed: onSearch,
        icon: const FaIcon(TideIcons.search, size: 18),
      ),
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
                TideSettingsButton(
                  onExport: onExport,
                  onImport: onImport,
                  onDeleteAll: onDeleteAll,
                ),
                Expanded(
                  child: Column(
                    children: [
                      title,
                      const SizedBox(height: GSpace.s2),
                      metadata,
                    ],
                  ),
                ),
                searchButton,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TideSettingsButton(
                      onExport: onExport,
                      onImport: onImport,
                      onDeleteAll: onDeleteAll,
                    ),
                    const SizedBox(width: GSpace.s1),
                    searchButton,
                  ],
                ),
              ],
            ),
    );
  }
}
