import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';

class TideEmptyState extends StatelessWidget {
  const TideEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        sizeClassOf(context) == GSizeClass.compact ? GSpace.s4 : GSpace.s6,
        GSpace.s7,
        sizeClassOf(context) == GSizeClass.compact ? GSpace.s4 : GSpace.s6,
        GSpace.s5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your stream is quiet.',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: GSpace.s2),
          Text(
            'Capture anything above. Append freely, Review what sinks, Rescue what still matters.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    ),
  );
}
