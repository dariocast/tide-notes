import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/presentation/widgets/tide_shell.dart';

void main() {
  group('tideShellLayoutFor', () {
    test('uses desktop split on expanded macOS', () {
      expect(
        tideShellLayoutFor(TargetPlatform.macOS, GLayout.bpExpanded),
        TideShellLayout.desktopSplit,
      );
    });

    test('uses vertical layout below the macOS breakpoint', () {
      expect(
        tideShellLayoutFor(TargetPlatform.macOS, GLayout.bpExpanded - 1),
        TideShellLayout.vertical,
      );
    });

    test('uses vertical layout on wide iOS', () {
      expect(
        tideShellLayoutFor(TargetPlatform.iOS, 1200),
        TideShellLayout.vertical,
      );
    });

    test('uses vertical layout on wide Android', () {
      expect(
        tideShellLayoutFor(TargetPlatform.android, 1200),
        TideShellLayout.vertical,
      );
    });
  });

  group('TideShell', () {
    Future<void> pumpShell(
      WidgetTester tester, {
      required TargetPlatform platform,
      required double width,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: GravityAppTheme.light,
          home: Scaffold(
            body: TideShell(
              platform: platform,
              header: const Text('header'),
              composer: const Text('composer'),
              undoAction: const Text('undo'),
              stream: const Text('stream'),
            ),
          ),
        ),
      );
    }

    testWidgets('wide macOS renders the desktop split', (tester) async {
      await pumpShell(tester, platform: TargetPlatform.macOS, width: 1200);

      expect(
        find.byKey(const ValueKey('desktop-split-layout')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('vertical-layout')), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('desktop-sidebar'))).width,
        GLayout.desktopSidebar,
      );
    });

    testWidgets('narrow macOS renders vertically', (tester) async {
      await pumpShell(
        tester,
        platform: TargetPlatform.macOS,
        width: GLayout.bpExpanded - 1,
      );

      expect(find.byKey(const ValueKey('vertical-layout')), findsOneWidget);
      expect(find.byKey(const ValueKey('desktop-split-layout')), findsNothing);
    });

    testWidgets('wide iOS renders vertically', (tester) async {
      await pumpShell(tester, platform: TargetPlatform.iOS, width: 1200);

      expect(find.byKey(const ValueKey('vertical-layout')), findsOneWidget);
      expect(find.byKey(const ValueKey('desktop-split-layout')), findsNothing);
    });
  });
}
