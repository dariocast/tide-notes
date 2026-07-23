import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide/design/appearance_controller.dart';

void main() {
  test('appearance restores and persists all Tide theme selections', () async {
    for (final selection in TideThemeSelection.values) {
      SharedPreferences.setMockInitialValues({'tide_theme': selection.name});
      final controller = await AppearanceController.load();
      expect(controller.selection, selection);
    }

    SharedPreferences.setMockInitialValues({});
    final controller = await AppearanceController.load();
    await controller.setSelection(TideThemeSelection.abyss);
    expect(
      (await AppearanceController.load()).selection,
      TideThemeSelection.abyss,
    );
  });

  test('invalid persisted selection falls back to system', () async {
    SharedPreferences.setMockInitialValues({'tide_theme': 'unknown'});
    expect(
      (await AppearanceController.load()).selection,
      TideThemeSelection.system,
    );
  });

  test('submit on enter defaults off and persists when enabled', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await AppearanceController.load();

    expect(controller.submitOnEnter, isFalse);
    await controller.setSubmitOnEnter(true);

    final restored = await AppearanceController.load();
    expect(restored.submitOnEnter, isTrue);
  });
}
