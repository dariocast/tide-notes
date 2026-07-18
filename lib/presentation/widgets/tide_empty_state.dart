import 'package:flutter/material.dart';

class TideEmptyState extends StatelessWidget {
  const TideEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your stream is quiet.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 8),
          Text(
            'Capture anything above. Append freely, Review what sinks, Rescue what still matters.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              height: 1.45,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    ),
  );
}
