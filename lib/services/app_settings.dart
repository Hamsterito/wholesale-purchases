import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  AppSettings._();

  static const _darkModeKey = 'dark_mode';

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  // Инициализация настроек приложения
  // Вызывается в main() ДО runApp для предотвращения ошибок зоны
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_darkModeKey) ?? false;
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      // В случае ошибки инициализации используем значение по умолчанию
      themeMode.value = ThemeMode.light;
      rethrow;
    }
  }

  static bool get isDark => themeMode.value == ThemeMode.dark;

  static Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }
}
