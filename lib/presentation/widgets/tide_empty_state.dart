import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../l10n/tide_localizations.dart';

class TideEmptyState extends StatelessWidget {
  const TideEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    return _TideEmptyContent(title: l10n.emptyTitle, body: l10n.emptyBody);
  }
}

class TideNoSearchResults extends StatelessWidget {
  const TideNoSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    return _TideEmptyContent(
      key: const ValueKey('search-empty-state'),
      title: l10n.noSearchResultsTitle,
      body: l10n.noSearchResultsBody,
    );
  }
}

class _TideEmptyContent extends StatelessWidget {
  const _TideEmptyContent({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final g = tideColorsOf(context);
    final compact = sizeClassOf(context) == GSizeClass.compact;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? GSpace.s4 : GSpace.s6,
          GSpace.s7,
          compact ? GSpace.s4 : GSpace.s6,
          GSpace.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: GSpace.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: GLayout.contentNarrow,
              ),
              child: Text(
                body,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: g.textMuted),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
