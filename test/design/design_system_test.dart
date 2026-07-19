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
}
