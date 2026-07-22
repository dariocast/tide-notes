import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';

enum TideShellLayout { vertical, desktopSplit }

TideShellLayout tideShellLayoutFor(TargetPlatform platform, double width) =>
    platform == TargetPlatform.macOS && width >= GLayout.bpExpanded
    ? TideShellLayout.desktopSplit
    : TideShellLayout.vertical;

class TideShell extends StatelessWidget {
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = tideShellLayoutFor(
        platform ?? defaultTargetPlatform,
        constraints.maxWidth,
      );
      return switch (layout) {
        TideShellLayout.vertical => _buildVertical(),
        TideShellLayout.desktopSplit => _buildDesktop(context),
      };
    },
  );

  Widget _buildVertical() => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: GLayout.contentMax),
      child: FocusTraversalGroup(
        child: Column(
          key: const ValueKey('vertical-layout'),
          children: [
            header,
            composer,
            undoAction,
            const Hairline(indent: GSpace.s4),
            Expanded(child: stream),
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
              child: Column(children: [header, composer, undoAction]),
            ),
            SizedBox(
              width: GDecor.hairline,
              child: ColoredBox(color: gravityOf(context).lineSubtle),
            ),
            Expanded(child: stream),
          ],
        ),
      ),
    ),
  );
}
