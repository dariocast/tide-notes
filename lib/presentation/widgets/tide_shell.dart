import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';

enum TideShellLayout { vertical, desktopSplit }

TideShellLayout tideShellLayoutFor(TargetPlatform platform, double width) =>
    platform == TargetPlatform.macOS && width >= GLayout.bpExpanded
    ? TideShellLayout.desktopSplit
    : TideShellLayout.vertical;

/// Responsive full-viewport composition for Tide's primary regions.
///
/// The parent must provide a bounded height because both layouts use flex
/// children that fill the remaining viewport space.
class TideShell extends StatefulWidget {
  const TideShell({
    super.key,
    required this.header,
    required this.composer,
    required this.undoAction,
    required this.stream,
    this.platform,
  });

  final Widget header;
  final Widget composer;
  final Widget undoAction;
  final Widget stream;
  final TargetPlatform? platform;

  @override
  State<TideShell> createState() => _TideShellState();
}

class _TideShellState extends State<TideShell> {
  final _headerKey = GlobalKey(debugLabel: 'TideShell header');
  final _composerKey = GlobalKey(debugLabel: 'TideShell composer');
  final _undoActionKey = GlobalKey(debugLabel: 'TideShell undo action');
  final _streamKey = GlobalKey(debugLabel: 'TideShell stream');

  Widget _region(GlobalKey key, Widget child) =>
      KeyedSubtree(key: key, child: child);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      assert(
        constraints.hasBoundedHeight,
        'TideShell requires a bounded height from a full-viewport parent.',
      );
      final layout = tideShellLayoutFor(
        widget.platform ?? defaultTargetPlatform,
        constraints.maxWidth,
      );
      return switch (layout) {
        TideShellLayout.vertical => _buildVertical(),
        TideShellLayout.desktopSplit => _buildDesktop(context),
      };
    },
  );

  Widget _buildVertical() => GSizeClassScope(
    sizeClass: GSizeClass.compact,
    child: SizedBox(
      width: double.infinity,
      child: FocusTraversalGroup(
        child: Column(
          key: const ValueKey('vertical-layout'),
          children: [
            _region(_headerKey, widget.header),
            _region(_composerKey, widget.composer),
            _region(_undoActionKey, widget.undoAction),
            Expanded(child: _region(_streamKey, widget.stream)),
          ],
        ),
      ),
    ),
  );

  Widget _buildDesktop(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: GLayout.desktopMax),
      child: FocusTraversalGroup(
        child: Row(
          key: const ValueKey('desktop-split-layout'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const ValueKey('desktop-sidebar'),
              width: GLayout.desktopSidebar,
              child: Column(
                children: [
                  _region(_headerKey, widget.header),
                  _region(_composerKey, widget.composer),
                  _region(_undoActionKey, widget.undoAction),
                ],
              ),
            ),
            SizedBox(
              key: const ValueKey('desktop-divider'),
              width: GDecor.hairline,
              child: ColoredBox(color: tideColorsOf(context).lineSubtle),
            ),
            Expanded(child: _region(_streamKey, widget.stream)),
          ],
        ),
      ),
    ),
  );
}
