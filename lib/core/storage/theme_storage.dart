import 'package:shared_preferences/shared_preferences.dart';

class ThemeStorage {
  static const _themeKey = 'theme_mode';

  Future<String?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
  }
}
