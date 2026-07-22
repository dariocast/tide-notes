import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/appearance_controller.dart';

/// User-facing labels for each Tide theme selection. Never expose
/// implementation names such as `ThemeMode.dark` in the UI.
const themeLabels = {
  TideThemeSelection.system: 'System',
  TideThemeSelection.foam: 'Foam',
  TideThemeSelection.deepTide: 'Deep Tide',
  TideThemeSelection.abyss: 'Abyss',
};

/// Platform-adaptive appearance control: a modal bottom sheet on touch
/// platforms, a popover-style menu on macOS. Reads and updates the
/// [AppearanceScope] controller in context.
class TideSettingsButton extends StatelessWidget {
  const TideSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance == null) return const SizedBox.shrink();

    return Semantics(
      label: 'Appearance settings',
      button: true,
      child: defaultTargetPlatform == TargetPlatform.macOS
          ? _MacSettingsMenu(appearance: appearance)
          : IconButton(
              tooltip: 'Appearance settings',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _showSettingsSheet(context, appearance),
            ),
    );
  }
}

Future<void> _showSettingsSheet(
  BuildContext context,
  AppearanceController appearance,
) => showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final selection in TideThemeSelection.values)
          ListTile(
            title: Text(themeLabels[selection]!),
            trailing: appearance.selection == selection
                ? const Icon(Icons.check_rounded)
                : null,
            selected: appearance.selection == selection,
            onTap: () {
              appearance.setSelection(selection);
              Navigator.of(sheetContext).pop();
            },
          ),
      ],
    ),
  ),
);

class _MacSettingsMenu extends StatelessWidget {
  const _MacSettingsMenu({required this.appearance});

  final AppearanceController appearance;

  @override
  Widget build(BuildContext context) => PopupMenuButton<TideThemeSelection>(
    tooltip: 'Appearance settings',
    icon: const Icon(Icons.tune_rounded),
    onSelected: appearance.setSelection,
    itemBuilder: (context) => [
      for (final selection in TideThemeSelection.values)
        CheckedPopupMenuItem(
          value: selection,
          checked: appearance.selection == selection,
          child: Text(themeLabels[selection]!),
        ),
    ],
  );
}
