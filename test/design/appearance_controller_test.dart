import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide/design/appearance_controller.dart';

void main() {
  test('appearance preferences restore and persist theme and motion', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'motion_enabled': false,
    });

    final controller = await AppearanceController.load();

    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.motionEnabled, isFalse);
    await controller.setThemeMode(ThemeMode.light);
    await controller.setMotionEnabled(true);

    final restored = await AppearanceController.load();
    expect(restored.themeMode, ThemeMode.light);
    expect(restored.motionEnabled, isTrue);
  });
}
