import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';

void main() {
  test('Tide themes expose Foam, Deep Tide, and true-black Abyss', () {
    expect(TideColors.foam.bgTop, const Color(0xFFF7FBFC));
    expect(TideColors.deepTide.bgBottom, const Color(0xFF041319));
    expect(TideColors.abyss.bgTop, Colors.black);
    expect(TideColors.abyss.bgMid, Colors.black);
    expect(TideColors.abyss.bgBottom, Colors.black);
    expect(TideAppTheme.abyss.scaffoldBackgroundColor, Colors.black);
  });

  test('Tide type roles use only Quicksand and Nunito', () {
    for (final theme in [
      TideAppTheme.foam,
      TideAppTheme.deepTide,
      TideAppTheme.abyss,
    ]) {
      expect(theme.textTheme.titleLarge?.fontFamily, 'Quicksand');
      expect(theme.textTheme.headlineMedium?.fontFamily, 'Quicksand');
      for (final style in [
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
        theme.textTheme.labelSmall,
      ]) {
        expect(style?.fontFamily, 'Nunito');
      }
    }
  });
}
