import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_helpers.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/presentation/widgets/note_composer.dart';
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
          theme: TideAppTheme.foam,
          home: Scaffold(
            body: TideShell(
              platform: platform,
              header: Column(
                children: [
                  const Text('header'),
                  Builder(
                    builder: (context) => Text(
                      sizeClassOf(context).name,
                      key: const ValueKey('size-class-probe'),
                    ),
                  ),
                ],
              ),
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
      expect(
        tester
            .getSize(find.byKey(const ValueKey('desktop-split-layout')))
            .width,
        GLayout.desktopMax,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('size-class-probe')))
            .data,
        GSizeClass.expanded.name,
      );
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('desktop-split-layout')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ConstrainedBox &&
                widget.constraints.maxWidth == GLayout.desktopMax,
          ),
        ),
        findsOneWidget,
      );

      final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
      for (final label in ['header', 'composer', 'undo']) {
        expect(
          find.descendant(of: sidebar, matching: find.text(label)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: sidebar, matching: find.text('stream')),
        findsNothing,
      );
    });

    testWidgets('vertical layouts fill the viewport and use compact sizing', (
      tester,
    ) async {
      for (final (:platform, :width) in [
        (platform: TargetPlatform.iOS, width: 1200.0),
        (platform: TargetPlatform.android, width: 1200.0),
        (platform: TargetPlatform.macOS, width: GLayout.bpExpanded - 1),
      ]) {
        await pumpShell(tester, platform: platform, width: width);

        expect(find.byKey(const ValueKey('vertical-layout')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('desktop-split-layout')),
          findsNothing,
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('vertical-layout'))).width,
          width,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('size-class-probe')))
              .data,
          GSizeClass.compact.name,
        );

        final vertical = find.byKey(const ValueKey('vertical-layout'));
        for (final label in ['header', 'composer', 'undo', 'stream']) {
          expect(
            find.descendant(of: vertical, matching: find.text(label)),
            findsOneWidget,
          );
        }
        expect(
          tester.getTopLeft(find.text('header')).dy,
          lessThan(tester.getTopLeft(find.text('composer')).dy),
        );
        expect(
          tester.getTopLeft(find.text('composer')).dy,
          lessThan(tester.getTopLeft(find.text('undo')).dy),
        );
        expect(
          tester.getTopLeft(find.text('undo')).dy,
          lessThan(tester.getTopLeft(find.text('stream')).dy),
        );
      }
    });

    testWidgets('composer draft and focus survive a live breakpoint change', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(GLayout.bpExpanded - 1, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: TideAppTheme.foam,
          home: Scaffold(
            body: TideShell(
              platform: TargetPlatform.macOS,
              header: const Text('header'),
              composer: NoteComposer(onSubmit: (_) {}, appendCompleted: 0),
              undoAction: const Text('undo'),
              stream: const Text('stream'),
            ),
          ),
        ),
      );

      final input = find.byKey(const ValueKey('composer-input'));
      await tester.tap(input);
      await tester.enterText(input, 'unfinished draft');
      expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);

      tester.view.physicalSize = const Size(1200, 800);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('desktop-split-layout')),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(input).controller!.text,
        'unfinished draft',
      );
      expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);
    });

    testWidgets('compact height keeps the composer and stream visible', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 180);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: TideAppTheme.foam,
          home: Scaffold(
            body: TideShell(
              platform: TargetPlatform.android,
              header: const Text('header'),
              composer: const Text('composer'),
              undoAction: const SizedBox.shrink(),
              stream: const Text('stream'),
            ),
          ),
        ),
      );

      expect(find.text('header'), findsNothing);
      expect(find.text('composer'), findsOneWidget);
      expect(find.text('stream'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
