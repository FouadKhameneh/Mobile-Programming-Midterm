import 'package:material_ui/material_ui.dart';

import '../core/storage/preferences_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs)
      : _themeMode = _prefs.themeMode,
        _onboardingSeen = _prefs.onboardingSeen;

  final PreferencesService _prefs;
  ThemeMode _themeMode;
  bool _onboardingSeen;

  ThemeMode get themeMode => _themeMode;
  bool get onboardingSeen => _onboardingSeen;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> completeOnboarding() async {
    if (_onboardingSeen) return;
    _onboardingSeen = true;
    await _prefs.setOnboardingSeen(true);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setThemeMode(mode);
  }

  Future<void> toggleTheme() => setThemeMode(
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );

  void resetOnboardingForPreview() {
    _onboardingSeen = false;
    _prefs.setOnboardingSeen(false);
    notifyListeners();
  }
}
