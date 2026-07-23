import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../l10n/tide_localizations.dart';

class TideEmptyState extends StatelessWidget {
  const TideEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final g = tideColorsOf(context);
    final compact = sizeClassOf(context) == GSizeClass.compact;
    final l10n = TideLocalizations.of(context);
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
              l10n.emptyTitle,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: GSpace.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: GLayout.contentNarrow,
              ),
              child: Text(
                l10n.emptyBody,
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
