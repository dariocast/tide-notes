import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';

class TideEmptyState extends StatelessWidget {
  const TideEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final g = gravityOf(context);
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
            TideGlyph(size: 40, color: g.accentMuted),
            const SizedBox(height: GSpace.s5),
            Text(
              'Your stream is quiet.',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: GSpace.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: GLayout.contentNarrow),
              child: Text(
                'Capture anything above. Append freely, Review what sinks, Rescue what still matters.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: g.textMuted),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: GSpace.s6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Kbd('⌘'),
                const SizedBox(width: GSpace.s1),
                const _Kbd('↵'),
                const SizedBox(width: GSpace.s3),
                Text(
                  'to capture',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: g.textGhost),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A minimal keycap chip used in onboarding hints.
class _Kbd extends StatelessWidget {
  const _Kbd(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final g = gravityOf(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(
        horizontal: GSpace.s2,
        vertical: GSpace.s1,
      ),
      decoration: BoxDecoration(
        color: g.surfaceElevated,
        border: Border.all(color: g.lineSubtle),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: g.textMuted, letterSpacing: 0),
      ),
    );
  }
}
