import 'package:flutter/material.dart';

import '../../models/language.dart';
import '../../models/currency.dart';
import '../storage/shared_prefs_provider.dart';
import '../localization/app_localizations.dart';
import '../message/message_localization.dart';
import '../api/api_service.dart';

class AppSettings {
  AppSettings._();

  static const _darkModeKey = 'dark_mode';
  static const _languageKey = 'language_code';
  static const _currencyKey = 'currency_code';

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static final ValueNotifier<Language> language =
      ValueNotifier<Language>(Language.defaultLanguage);

  static final ValueNotifier<Currency> currency =
      ValueNotifier<Currency>(Currency.defaultCurrency);

  // Инициализация настроек приложения
  // Вызывается в main() ДО runApp для предотвращения ошибок зоны
  static Future<void> init() async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();

      // Тема
      final isDark = prefs.getBool(_darkModeKey) ?? false;
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;

      // Язык
      final langCode = prefs.getString(_languageKey);
      final selectedLang =
          langCode != null ? Language.fromCode(langCode) : null;
      language.value = selectedLang ?? Language.defaultLanguage;

      // Загружаем локализацию для выбранного языка
      await AppLocalizations.loadLocale(language.value.code.code);

      // Предзагружаем шаблоны сообщений из ARB, чтобы getTemplate был синхронным
      await MessageLocalizationManager.loadTemplates(language.value.code.code);

      // Валюта
      final currCode = prefs.getString(_currencyKey);
      final selectedCurr =
          currCode != null ? Currency.fromCode(currCode) : null;
      currency.value = selectedCurr ?? Currency.defaultCurrency;

      // Загрузка актуального курса валют
      try {
        final rates = await ApiService.getExchangeRates();
        Currency.updateRates(rates);
      } catch (e) {
        // При ошибке ловим исключение и продолжаем инициализацию приложения с дефолтными курсами
        debugPrint('Не удалось обновить курсы валют: $e');
      }
    } catch (e) {
      // В случае ошибки инициализации используем значения по умолчанию
      themeMode.value = ThemeMode.light;
      language.value = Language.defaultLanguage;
      currency.value = Currency.defaultCurrency;

      // Пытаемся загрузить дефолтную локализацию
      try {
        await AppLocalizations.loadLocale(Language.defaultLanguage.code.code);
      } catch (_) {
        // Игнорируем ошибку загрузки локализации при инициализации
      }

      rethrow;
    }
  }

  static bool get isDark => themeMode.value == ThemeMode.dark;

  static String get languageCode => language.value.code.code;

  static String get currencyCode => currency.value.code.code;

  static Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPrefsProvider.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  static Future<void> setLanguage(Language lang) async {
    // Загружаем новую локализацию перед обновлением ValueNotifier
    await AppLocalizations.loadLocale(lang.code.code);
    await MessageLocalizationManager.loadTemplates(lang.code.code);

    // Обновляем ValueNotifier - это триггерит перестройку UI
    language.value = lang;

    // Сохраняем выбор в SharedPreferences
    final prefs = await SharedPrefsProvider.getInstance();
    await prefs.setString(_languageKey, lang.code.code);
  }

  static Future<void> setCurrency(Currency curr) async {
    currency.value = curr;
    final prefs = await SharedPrefsProvider.getInstance();
    await prefs.setString(_currencyKey, curr.code.code);
  }
}
