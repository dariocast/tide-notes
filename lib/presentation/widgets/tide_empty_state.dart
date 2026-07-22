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
            Text(
              'Your stream is quiet.',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: GSpace.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: GLayout.contentNarrow,
              ),
              child: Text(
                'Capture anything above. Append freely, review what sinks, rescue what still matters.',
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
