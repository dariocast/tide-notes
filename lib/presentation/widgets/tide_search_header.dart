import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../l10n/tide_localizations.dart';

class TideSearchHeader extends StatelessWidget {
  const TideSearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final compact = sizeClassOf(context) == GSizeClass.compact;
    final colors = tideColorsOf(context);
    final l10n = TideLocalizations.of(context);

    return Padding(
      key: const ValueKey('search-header'),
      padding: EdgeInsets.fromLTRB(
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s3,
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: FocusRing(
              borderRadius: GShapes.control,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  border: Border.all(color: colors.lineSubtle),
                  borderRadius: GShapes.control,
                ),
                child: TextField(
                  key: const ValueKey('search-input'),
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  textAlignVertical: TextAlignVertical.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixIcon: const Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: FaIcon(TideIcons.search, size: 16),
                    ),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey('clear-search'),
                            tooltip: l10n.clearSearch,
                            onPressed: onClear,
                            icon: const FaIcon(TideIcons.clearSearch, size: 18),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: GSpace.s2),
          TextButton(
            key: const ValueKey('close-search'),
            onPressed: onClose,
            child: Text(l10n.closeSearch),
          ),
        ],
      ),
    );
  }
}
