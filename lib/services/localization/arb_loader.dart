import 'dart:convert';
import 'package:flutter/services.dart';
import '../app_logger.dart';

/// Загрузчик ARB-файлов с кэшированием
class ArbLoader {
  // Кэш загруженных ARB-файлов: locale -> Map<String, String>
  static final Map<String, Map<String, String>> _cache = {};

  /// Загружает ARB-файл для указанной локали
  ///
  /// Возвращает Map с переводами.
  /// При ошибке возвращает пустую Map и логирует предупреждение.
  static Future<Map<String, String>> loadArbFile(String locale) async {
    // Проверяем кэш
    if (_cache.containsKey(locale)) {
      AppLogger.info('ARB file for locale $locale loaded from cache');
      return _cache[locale]!;
    }

    try {
      // Формируем путь к ARB-файлу
      final path = 'lib/l10n/app_$locale.arb';

      AppLogger.info('Loading ARB file: $path');

      // Загружаем содержимое файла
      final String content = await rootBundle.loadString(path);

      // Парсим JSON
      final Map<String, dynamic> jsonData = json.decode(content);

      // Фильтруем только строковые значения (исключаем метаданные вроде @@locale)
      final Map<String, String> translations = {};

      for (final entry in jsonData.entries) {
        final key = entry.key;
        final value = entry.value;

        // Пропускаем метаданные (ключи, начинающиеся с @)
        if (key.startsWith('@')) {
          continue;
        }

        // Добавляем только строковые значения
        if (value is String) {
          translations[key] = value;
        }
      }

      // Кэшируем результат
      _cache[locale] = translations;

      AppLogger.info('ARB file for locale $locale loaded successfully: ${translations.length} translations');

      return translations;
    } catch (e, stackTrace) {
      // Файл не найден или ошибка парсинга
      if (e.toString().contains('Unable to load asset')) {
        AppLogger.warning('ARB file not found for locale $locale: $e');
      } else {
        // Ошибка парсинга или другая ошибка
        AppLogger.error(
          'Failed to load ARB file for locale $locale',
          error: e,
          stackTrace: stackTrace,
        );
      }
      return {};
    }
  }

  /// Очищает кэш загруженных ARB-файлов
  static void clearCache() {
    _cache.clear();
    AppLogger.info('ARB cache cleared');
  }

  /// Проверяет, загружен ли ARB-файл для указанной локали
  static bool isCached(String locale) {
    return _cache.containsKey(locale);
  }

  /// Возвращает количество загруженных локалей в кэше
  static int get cacheSize => _cache.length;
}
