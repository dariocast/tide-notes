import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/appearance_controller.dart';
import '../../design/tide_icons.dart';
import '../../app_version.dart';
import '../../l10n/tide_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

String themeLabel(TideThemeSelection selection, TideLocalizations l10n) =>
    switch (selection) {
      TideThemeSelection.system => l10n.systemLanguage,
      TideThemeSelection.foam => 'Foam',
      TideThemeSelection.deepTide => 'Deep Tide',
      TideThemeSelection.abyss => 'Abyss',
    };

String languageLabel(TideLanguageSelection selection, TideLocalizations l10n) =>
    switch (selection) {
      TideLanguageSelection.system => l10n.systemLanguage,
      TideLanguageSelection.italian => '🇮🇹  ${l10n.italian}',
      TideLanguageSelection.english => '🇬🇧  ${l10n.english}',
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
    final l10n = TideLocalizations.of(context);

    return Semantics(
      label: l10n.appearanceSettings,
      button: true,
      child: defaultTargetPlatform == TargetPlatform.macOS
          ? _MacSettingsMenu(
              appearance: appearance,
              onExport: onExport,
              onDeleteAll: onDeleteAll,
            )
          : IconButton(
              tooltip: l10n.menu,
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

enum _MenuAction { theme, language, submitOnEnter, export, deleteAll }

Future<void> _showSettingsSheet(
  BuildContext context,
  AppearanceController appearance,
  VoidCallback onExport,
  VoidCallback onDeleteAll,
) => showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) => SafeArea(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              final l10n = TideLocalizations.of(context);
              return ListTile(
                leading: FaIcon(
                  TideIcons.theme,
                  color: Theme.of(context).iconTheme.color,
                  size: 18,
                ),
                title: Text(l10n.theme),
                trailing: FaIcon(
                  TideIcons.next,
                  color: Theme.of(context).iconTheme.color,
                  size: 14,
                ),
                onTap: () => _showThemeSheet(sheetContext, appearance),
              );
            },
          ),
          ListTile(
            leading: FaIcon(
              TideIcons.language,
              color: Theme.of(sheetContext).iconTheme.color,
              size: 18,
            ),
            title: Text(TideLocalizations.of(sheetContext).language),
            trailing: Text(
              languageLabel(
                appearance.language,
                TideLocalizations.of(sheetContext),
              ),
            ),
            onTap: () => _showLanguageSheet(sheetContext, appearance),
          ),
          ListTile(
            leading: FaIcon(
              TideIcons.export,
              color: Theme.of(sheetContext).iconTheme.color,
              size: 18,
            ),
            title: Text(TideLocalizations.of(sheetContext).exportNotes),
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
            title: Text(TideLocalizations.of(sheetContext).quickSubmit),
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
              TideLocalizations.of(sheetContext).deleteAllNotes,
              style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _confirmDelete(context, onDeleteAll);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              '${TideLocalizations.of(sheetContext).versionLabel} $appVersion',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
  ),
);

Future<void> _showThemeSheet(
  BuildContext context,
  AppearanceController appearance,
) => showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) => SafeArea(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(TideLocalizations.of(sheetContext).theme)),
          for (final selection in TideThemeSelection.values)
            ListTile(
              title: Text(
                themeLabel(selection, TideLocalizations.of(sheetContext)),
              ),
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
  ),
);

Future<void> _showLanguageSheet(
  BuildContext context,
  AppearanceController appearance,
) => showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) {
    final l10n = TideLocalizations.of(sheetContext);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.language)),
            for (final selection in TideLanguageSelection.values)
              ListTile(
                title: Text(languageLabel(selection, l10n)),
                trailing: appearance.language == selection
                    ? FaIcon(
                        TideIcons.check,
                        color: Theme.of(sheetContext).iconTheme.color,
                        size: 14,
                      )
                    : null,
                selected: appearance.language == selection,
                onTap: () {
                  appearance.setLanguage(selection);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  },
);

Future<void> _confirmDelete(
  BuildContext context,
  VoidCallback onDeleteAll,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(TideLocalizations.of(dialogContext).deleteAllTitle),
      content: Text(TideLocalizations.of(dialogContext).deleteAllBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(TideLocalizations.of(dialogContext).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(TideLocalizations.of(dialogContext).deleteAll),
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
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    return PopupMenuButton<_MenuAction>(
      tooltip: l10n.menu,
      icon: const FaIcon(TideIcons.menu, size: 20),
      onSelected: (action) {
        switch (action) {
          case _MenuAction.theme:
            _showThemeSheet(context, appearance);
          case _MenuAction.language:
            _showLanguageSheet(context, appearance);
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
              Expanded(child: Text(l10n.theme)),
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
          value: _MenuAction.language,
          child: Row(
            children: [
              Expanded(child: Text(l10n.language)),
              Text(languageLabel(appearance.language, l10n)),
            ],
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.submitOnEnter,
          child: Row(
            children: [
              Expanded(child: Text(l10n.quickSubmit)),
              if (appearance.submitOnEnter)
                FaIcon(
                  TideIcons.check,
                  color: Theme.of(context).iconTheme.color,
                  size: 14,
                ),
            ],
          ),
        ),
        PopupMenuItem(value: _MenuAction.export, child: Text(l10n.exportNotes)),
        PopupMenuItem(
          value: _MenuAction.deleteAll,
          child: Text(
            l10n.deleteAllNotes,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        PopupMenuItem<_MenuAction>(
          enabled: false,
          child: Text('${l10n.versionLabel} $appVersion'),
        ),
      ],
    );
  }
}
