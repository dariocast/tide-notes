import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user-facing Tide appearance choices. `system` follows the OS
/// brightness with Foam/Deep Tide; the others force a specific palette,
/// including the OLED-oriented `abyss` theme that has no `ThemeMode`
/// equivalent.
enum TideThemeSelection { system, foam, deepTide, abyss }

class AppearanceController extends ChangeNotifier {
  AppearanceController._(this._preferences, this._selection);

  static const _themeKey = 'tide_theme';
  final SharedPreferences? _preferences;
  TideThemeSelection _selection;

  TideThemeSelection get selection => _selection;

  static Future<AppearanceController> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_themeKey);
      final selection = TideThemeSelection.values.firstWhere(
        (value) => value.name == stored,
        orElse: () => TideThemeSelection.system,
      );
      return AppearanceController._(preferences, selection);
    } catch (_) {
      return AppearanceController.inMemory();
    }
  }

  factory AppearanceController.inMemory({
    TideThemeSelection selection = TideThemeSelection.system,
  }) => AppearanceController._(null, selection);

  Future<void> setSelection(TideThemeSelection value) async {
    if (_selection == value) return;
    _selection = value;
    notifyListeners();
    try {
      await _preferences?.setString(_themeKey, value.name);
    } catch (_) {}
  }
}

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppearanceController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;
}
