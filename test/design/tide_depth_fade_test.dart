import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/design/tide_depth_fade.dart';

import '../support/contrast.dart';

void main() {
  test('depth is full through 65 percent then fades to theme floor', () {
    expect(TideDepthModel.opacityAt(0.0, floor: 0.8), 1);
    expect(TideDepthModel.opacityAt(0.65, floor: 0.8), 1);
    expect(TideDepthModel.opacityAt(0.825, floor: 0.8), closeTo(0.9, 0.001));
    expect(TideDepthModel.opacityAt(1.0, floor: 0.8), 0.8);
  });

  test('a note rising above the fade threshold recovers full presence', () {
    const floor = 0.8;
    final sinking = TideDepthModel.opacityAt(0.9, floor: floor);
    final risen = TideDepthModel.opacityAt(0.5, floor: floor);

    expect(sinking, lessThan(1));
    expect(risen, 1);
    expect(risen, greaterThan(sinking));
  });

  for (final (:name, :colors) in [
    (name: 'Foam', colors: TideColors.foam),
    (name: 'Deep Tide', colors: TideColors.deepTide),
    (name: 'Abyss', colors: TideColors.abyss),
  ]) {
    test('$name deepest metadata stays readable', () {
      final faded = Color.alphaBlend(
        colors.textMuted.withValues(alpha: colors.depthFloor),
        colors.bgBottom,
      );
      expect(contrast(faded, colors.bgBottom), greaterThanOrEqualTo(4.5));
    });
  }

  test('depth gradient is anchored top-to-bottom with the right stops', () {
    final gradient = TideDepthFade.buildGradient(TideColors.foam);

    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(gradient.stops, const [0, TideDepthModel.fullPresenceEnd, 1]);
  });

  testWidgets('contains a bottom-only ShaderMask when enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: const TideDepthFade(enabled: true, child: Text('note')),
      ),
    );

    expect(find.byKey(const ValueKey('tide-depth-mask')), findsOneWidget);
    final mask = tester.widget<ShaderMask>(
      find.byKey(const ValueKey('tide-depth-mask')),
    );
    expect(mask.blendMode, BlendMode.dstIn);
  });

  testWidgets('disabled fade renders the child without a ShaderMask', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: const TideDepthFade(enabled: false, child: Text('note')),
      ),
    );

    expect(find.byKey(const ValueKey('tide-depth-mask')), findsNothing);
    expect(find.text('note'), findsOneWidget);
  });

  testWidgets('high-contrast mode bypasses the shader', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TideAppTheme.foam,
        home: const MediaQuery(
          data: MediaQueryData(highContrast: true),
          child: TideDepthFade(enabled: true, child: Text('note')),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('tide-depth-mask')), findsNothing);
    expect(find.text('note'), findsOneWidget);
  });
}
