import 'package:flutter/material.dart';

class TideEmptyState extends StatelessWidget {
  const TideEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'A quiet stream starts here.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Append a thought, Review what sinks, Rescue what still matters.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
