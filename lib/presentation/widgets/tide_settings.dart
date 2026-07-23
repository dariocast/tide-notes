import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/appearance_controller.dart';
import '../../design/tide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const themeLabels = {
  TideThemeSelection.system: 'System',
  TideThemeSelection.foam: 'Foam',
  TideThemeSelection.deepTide: 'Deep Tide',
  TideThemeSelection.abyss: 'Abyss',
};

class TideSettingsButton extends StatelessWidget {
  const TideSettingsButton({
    super.key,
    required this.onExport,
    required this.onDeleteAll,
  });

  final VoidCallback onExport;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance == null) return const SizedBox.shrink();

    return Semantics(
      label: 'Appearance settings',
      button: true,
      child: defaultTargetPlatform == TargetPlatform.macOS
          ? _MacSettingsMenu(
              appearance: appearance,
              onExport: onExport,
              onDeleteAll: onDeleteAll,
            )
          : IconButton(
              tooltip: 'Menu',
              icon: const FaIcon(TideIcons.menu, size: 20),
              onPressed: () => _showSettingsSheet(
                context,
                appearance,
                onExport,
                onDeleteAll,
              ),
            ),
    );
  }
}

enum _MenuAction { theme, submitOnEnter, export, deleteAll }

Future<void> _showSettingsSheet(
  BuildContext context,
  AppearanceController appearance,
  VoidCallback onExport,
  VoidCallback onDeleteAll,
) => showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: FaIcon(
            TideIcons.theme,
            color: Theme.of(sheetContext).iconTheme.color,
            size: 18,
          ),
          title: const Text('Tema'),
          trailing: FaIcon(
            TideIcons.next,
            color: Theme.of(sheetContext).iconTheme.color,
            size: 14,
          ),
          onTap: () => _showThemeSheet(sheetContext, appearance),
        ),
        ListTile(
          leading: FaIcon(
            TideIcons.export,
            color: Theme.of(sheetContext).iconTheme.color,
            size: 18,
          ),
          title: const Text('Esporta note'),
          onTap: () {
            Navigator.of(sheetContext).pop();
            onExport();
          },
        ),
        SwitchListTile(
          secondary: FaIcon(
            TideIcons.insert,
            color: Theme.of(sheetContext).iconTheme.color,
            size: 18,
          ),
          title: const Text('Invio rapido'),
          value: appearance.submitOnEnter,
          onChanged: appearance.setSubmitOnEnter,
        ),
        ListTile(
          leading: FaIcon(
            TideIcons.deleteAll,
            color: Theme.of(sheetContext).colorScheme.error,
            size: 18,
          ),
          title: Text(
            'Elimina tutte le note',
            style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
          ),
          onTap: () {
            Navigator.of(sheetContext).pop();
            _confirmDelete(context, onDeleteAll);
          },
        ),
      ],
    ),
  ),
);

Future<void> _showThemeSheet(
  BuildContext context,
  AppearanceController appearance,
) => showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(title: Text('Tema')),
        for (final selection in TideThemeSelection.values)
          ListTile(
            title: Text(themeLabels[selection]!),
            trailing: appearance.selection == selection
                ? FaIcon(
                    TideIcons.check,
                    color: Theme.of(sheetContext).iconTheme.color,
                    size: 14,
                  )
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

Future<void> _confirmDelete(
  BuildContext context,
  VoidCallback onDeleteAll,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminare tutte le note?'),
      content: const Text(
        'Questa azione eliminerà definitivamente tutte le note.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Elimina tutto'),
        ),
      ],
    ),
  );
  if (confirmed == true) onDeleteAll();
}

class _MacSettingsMenu extends StatelessWidget {
  const _MacSettingsMenu({
    required this.appearance,
    required this.onExport,
    required this.onDeleteAll,
  });

  final AppearanceController appearance;
  final VoidCallback onExport;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_MenuAction>(
    tooltip: 'Menu',
    icon: const FaIcon(TideIcons.menu, size: 20),
    onSelected: (action) {
      switch (action) {
        case _MenuAction.theme:
          _showThemeSheet(context, appearance);
        case _MenuAction.submitOnEnter:
          appearance.setSubmitOnEnter(!appearance.submitOnEnter);
        case _MenuAction.export:
          onExport();
        case _MenuAction.deleteAll:
          _confirmDelete(context, onDeleteAll);
      }
    },
    itemBuilder: (context) => [
      PopupMenuItem(
        value: _MenuAction.theme,
        child: Row(
          children: [
            Expanded(child: Text('Tema')),
            FaIcon(
              TideIcons.next,
              color: Theme.of(context).iconTheme.color,
              size: 14,
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: _MenuAction.submitOnEnter,
        child: Row(
          children: [
            const Expanded(child: Text('Invio rapido')),
            if (appearance.submitOnEnter)
              FaIcon(
                TideIcons.check,
                color: Theme.of(context).iconTheme.color,
                size: 14,
              ),
          ],
        ),
      ),
      const PopupMenuItem(
        value: _MenuAction.export,
        child: Text('Esporta note'),
      ),
      PopupMenuItem(
        value: _MenuAction.deleteAll,
        child: Text(
          'Elimina tutte le note',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    ],
  );
}
