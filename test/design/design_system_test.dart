import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';

void main() {
  test('Gravity themes expose the specified warm paper palettes', () {
    expect(GravityTheme.light.bgTop, GLight.bgTop);
    expect(GravityTheme.dark.ink, GDark.ink);
    expect(GLayout.contentMax, 720);
  });

  test('application theme neutralizes Material defaults', () {
    final theme = GravityAppTheme.light;

    expect(theme.useMaterial3, isTrue);
    expect(theme.splashFactory, NoSplash.splashFactory);
    expect(theme.extension<GravityTheme>(), GravityTheme.light);
    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve({}),
      const Size(0, GLayout.minTouchTarget),
    );
  });

  for (final (:name, :ink, :textGhost, :bgBottom, :hoverMinimum) in [
    (
      name: 'light',
      ink: GLight.ink,
      textGhost: GLight.textGhost,
      bgBottom: GLight.bgBottom,
      hoverMinimum: 4.55,
    ),
    (
      name: 'dark',
      ink: GDark.ink,
      textGhost: GDark.textGhost,
      bgBottom: GDark.bgBottom,
      hoverMinimum: 4.6,
    ),
  ]) {
    test('$name metadata stays readable on bare and hovered paper', () {
      final hoveredPaper = Color.alphaBlend(
        ink.withValues(alpha: GDecor.hoverAlpha),
        bgBottom,
      );

      expect(_contrast(textGhost, bgBottom), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(textGhost, hoveredPaper),
        greaterThanOrEqualTo(hoverMinimum),
      );
    });
  }

  test('application text roles use the platform font', () {
    for (final theme in [GravityAppTheme.light, GravityAppTheme.dark]) {
      final textTheme = theme.textTheme;
      final roles = [
        textTheme.displayLarge,
        textTheme.displayMedium,
        textTheme.displaySmall,
        textTheme.headlineLarge,
        textTheme.headlineMedium,
        textTheme.headlineSmall,
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.titleSmall,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
        textTheme.labelLarge,
        textTheme.labelMedium,
        textTheme.labelSmall,
      ];

      for (final role in roles) {
        expect(role, isNotNull);
        expect(role!.fontFamily, isNull);
      }
    }
  });
}

double _contrast(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
