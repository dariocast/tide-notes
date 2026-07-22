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

  test('application text roles use the platform font', () {
    for (final theme in [GravityAppTheme.light, GravityAppTheme.dark]) {
      final textTheme = theme.textTheme;
      final roles = [
        textTheme.displaySmall,
        textTheme.headlineMedium,
        textTheme.headlineSmall,
        textTheme.titleLarge,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
        textTheme.labelLarge,
        textTheme.labelSmall,
      ];

      for (final role in roles) {
        expect(role?.fontFamily, isNull);
      }
    }
  });
}
