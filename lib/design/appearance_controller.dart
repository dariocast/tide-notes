import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceController extends ChangeNotifier {
  AppearanceController._(
    this._preferences,
    this._themeMode,
    this._motionEnabled,
  );

  static const _themeKey = 'theme_mode';
  static const _motionKey = 'motion_enabled';
  final SharedPreferences? _preferences;
  ThemeMode _themeMode;
  bool _motionEnabled;

  static Future<AppearanceController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final theme = switch (preferences.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return AppearanceController._(
      preferences,
      theme,
      preferences.getBool(_motionKey) ?? true,
    );
  }

  factory AppearanceController.inMemory() =>
      AppearanceController._(null, ThemeMode.system, true);
  ThemeMode get themeMode => _themeMode;
  bool get motionEnabled => _motionEnabled;

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    await _preferences?.setString(_themeKey, value.name);
  }

  Future<void> setMotionEnabled(bool value) async {
    if (_motionEnabled == value) return;
    _motionEnabled = value;
    notifyListeners();
    await _preferences?.setBool(_motionKey, value);
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
