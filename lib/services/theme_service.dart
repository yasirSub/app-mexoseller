import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _key = 'theme_mode';
  static late SharedPreferences _prefs;
  // Default to light so text is visible on light backgrounds by default
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier(
    ThemeMode.light,
  );

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Load saved theme preference
    final savedTheme = _prefs.getString(_key);
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          notifier.value = ThemeMode.light;
          break;
        case 'dark':
          notifier.value = ThemeMode.dark;
          break;
        case 'system':
          notifier.value = ThemeMode.system;
          break;
        default:
          notifier.value = ThemeMode.light;
      }
    } else {
      // Default to light theme if no preference is saved
      notifier.value = ThemeMode.light;
      await _prefs.setString(_key, 'light');
    }
  }

  static ThemeMode get current => notifier.value;

  static Future<void> setMode(ThemeMode mode) async {
    notifier.value = mode;
    final s = mode == ThemeMode.light
        ? 'light'
        : (mode == ThemeMode.system ? 'system' : 'dark');
    await _prefs.setString(_key, s);
  }
}
