import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive preferences. Tokens deliberately live elsewhere.
class PreferencesService {
  static const _onboardingKey = 'soundify_onboarding_seen';
  static const _themeKey = 'soundify_theme_mode';
  static const _lastEmailKey = 'soundify_last_email';
  static const _recentSearchesKey = 'soundify_recent_searches';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _requirePrefs {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('PreferencesService.init() must be called first.');
    }
    return prefs;
  }

  bool get onboardingSeen => _requirePrefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingSeen(bool value) =>
      _requirePrefs.setBool(_onboardingKey, value);

  ThemeMode get themeMode {
    final raw = _requirePrefs.getString(_themeKey);
    if (raw == 'light') return ThemeMode.light;
    if (raw == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _requirePrefs.setString(_themeKey, mode.name);

  String? get lastEmail => _requirePrefs.getString(_lastEmailKey);

  Future<void> setLastEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _requirePrefs.remove(_lastEmailKey);
    } else {
      await _requirePrefs.setString(_lastEmailKey, email);
    }
  }

  List<String> get recentSearches =>
      _requirePrefs.getStringList(_recentSearchesKey) ?? const <String>[];

  Future<void> setRecentSearches(List<String> values) =>
      _requirePrefs.setStringList(_recentSearchesKey, values.take(8).toList());
}
