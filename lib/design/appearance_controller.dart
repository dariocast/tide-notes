import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user-facing Tide appearance choices. `system` follows the OS
/// brightness with Foam/Deep Tide; the others force a specific palette,
/// including the OLED-oriented `abyss` theme that has no `ThemeMode`
/// equivalent.
enum TideThemeSelection { system, foam, deepTide, abyss }

class AppearanceController extends ChangeNotifier {
  AppearanceController._(
    this._preferences,
    this._selection,
    this._submitOnEnter,
  );

  static const _themeKey = 'tide_theme';
  static const _submitOnEnterKey = 'tide_submit_on_enter';
  final SharedPreferences? _preferences;
  TideThemeSelection _selection;
  bool _submitOnEnter;

  TideThemeSelection get selection => _selection;
  bool get submitOnEnter => _submitOnEnter;

  static Future<AppearanceController> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_themeKey);
      final submitOnEnter = preferences.getBool(_submitOnEnterKey) ?? false;
      final selection = TideThemeSelection.values.firstWhere(
        (value) => value.name == stored,
        orElse: () => TideThemeSelection.system,
      );
      return AppearanceController._(preferences, selection, submitOnEnter);
    } catch (_) {
      return AppearanceController.inMemory();
    }
  }

  factory AppearanceController.inMemory({
    TideThemeSelection selection = TideThemeSelection.system,
    bool submitOnEnter = false,
  }) => AppearanceController._(null, selection, submitOnEnter);

  Future<void> setSelection(TideThemeSelection value) async {
    if (_selection == value) return;
    _selection = value;
    notifyListeners();
    try {
      await _preferences?.setString(_themeKey, value.name);
    } catch (_) {}
  }

  Future<void> setSubmitOnEnter(bool value) async {
    if (_submitOnEnter == value) return;
    _submitOnEnter = value;
    notifyListeners();
    try {
      await _preferences?.setBool(_submitOnEnterKey, value);
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
