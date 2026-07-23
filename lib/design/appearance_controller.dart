import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user-facing Tide appearance choices. `system` follows the OS
/// brightness with Foam/Deep Tide; the others force a specific palette,
/// including the OLED-oriented `abyss` theme that has no `ThemeMode`
/// equivalent.
enum TideThemeSelection { system, foam, deepTide, abyss }

enum TideLanguageSelection { system, italian, english }

class AppearanceController extends ChangeNotifier {
  AppearanceController._(
    this._preferences,
    this._selection,
    this._submitOnEnter,
    this._language,
  );

  static const _themeKey = 'tide_theme';
  static const _submitOnEnterKey = 'tide_submit_on_enter';
  static const _languageKey = 'tide_language';
  final SharedPreferences? _preferences;
  TideThemeSelection _selection;
  bool _submitOnEnter;
  TideLanguageSelection _language;

  TideThemeSelection get selection => _selection;
  bool get submitOnEnter => _submitOnEnter;
  TideLanguageSelection get language => _language;
  Locale? get locale => switch (_language) {
    TideLanguageSelection.system => null,
    TideLanguageSelection.italian => const Locale('it'),
    TideLanguageSelection.english => const Locale('en'),
  };

  static Future<AppearanceController> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_themeKey);
      final submitOnEnter = preferences.getBool(_submitOnEnterKey) ?? false;
      final storedLanguage = preferences.getString(_languageKey);
      final language = TideLanguageSelection.values.firstWhere(
        (value) => value.name == storedLanguage,
        orElse: () => TideLanguageSelection.system,
      );
      final selection = TideThemeSelection.values.firstWhere(
        (value) => value.name == stored,
        orElse: () => TideThemeSelection.system,
      );
      return AppearanceController._(
        preferences,
        selection,
        submitOnEnter,
        language,
      );
    } catch (_) {
      return AppearanceController.inMemory();
    }
  }

  factory AppearanceController.inMemory({
    TideThemeSelection selection = TideThemeSelection.system,
    bool submitOnEnter = false,
    TideLanguageSelection language = TideLanguageSelection.system,
  }) => AppearanceController._(null, selection, submitOnEnter, language);

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

  Future<void> setLanguage(TideLanguageSelection value) async {
    if (_language == value) return;
    _language = value;
    notifyListeners();
    try {
      await _preferences?.setString(_languageKey, value.name);
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
