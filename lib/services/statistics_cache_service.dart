// ignore_for_file: unnecessary_brace_in_string_interps
import 'dart:convert';
import '../models/supplier_stats.dart';
import 'app_logger.dart';
import 'shared_prefs_provider.dart';

/// Сервис кэширования статистики поставщика
/// Хранит данные локально для быстрого доступа и оффлайн режима
class StatisticsCacheService {
  StatisticsCacheService._();

  static const String _cacheKeyPrefix = 'supplier_stats_';
  static const String _aiSummaryKeyPrefix = 'ai_summary_';
  static const String _cacheTimestampKeyPrefix = 'stats_timestamp_';
  static const Duration _cacheExpiration = Duration(hours: 1);

  /// Сохраняет сводку статистики в кэш
  static Future<void> cacheStatsSummary(
    int userId,
    SupplierStatsSummary summary,
  ) async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final key = '${_cacheKeyPrefix}summary_$userId';
      final json = jsonEncode(summary.toJson());
      await prefs.setString(key, json);
      await prefs.setInt(
        '${_cacheTimestampKeyPrefix}summary_$userId',
        DateTime.now().millisecondsSinceEpoch,
      );
      AppLogger.info('Сводка статистики закэширована', scope: 'cache');
    } catch (e) {
      AppLogger.error(
        'Ошибка при кэшировании сводки',
        scope: 'cache',
        error: e,
      );
    }
  }

  /// Получает сводку статистики из кэша
  static Future<SupplierStatsSummary?> getStatsSummary(int userId) async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final key = '${_cacheKeyPrefix}summary_$userId';
      final timestampKey = '${_cacheTimestampKeyPrefix}summary_$userId';

      if (!prefs.containsKey(key)) {
        return null;
      }

      // Проверяем, не истёк ли кэш
      final timestamp = prefs.getInt(timestampKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheExpiration.inMilliseconds) {
        await prefs.remove(key);
        await prefs.remove(timestampKey);
        return null;
      }

      final json = prefs.getString(key);
      if (json == null) return null;

      final data = jsonDecode(json) as Map<String, dynamic>;
      return SupplierStatsSummary.fromJson(data);
    } catch (e) {
      AppLogger.error(
        'Ошибка при получении кэша сводки',
        scope: 'cache',
        error: e,
      );
      return null;
    }
  }

  /// Сохраняет AI резюме в кэш
  static Future<void> cacheAiSummary(int userId, String summary) async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final key = '${_aiSummaryKeyPrefix}$userId';
      await prefs.setString(key, summary);
      await prefs.setInt(
        '${_cacheTimestampKeyPrefix}ai_summary_$userId',
        DateTime.now().millisecondsSinceEpoch,
      );
      AppLogger.info('AI резюме закэшировано', scope: 'cache');
    } catch (e) {
      AppLogger.error(
        'Ошибка при кэшировании AI резюме',
        scope: 'cache',
        error: e,
      );
    }
  }

  /// Получает AI резюме из кэша
  static Future<String?> getAiSummary(int userId) async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final key = '${_aiSummaryKeyPrefix}$userId';
      final timestampKey = '${_cacheTimestampKeyPrefix}ai_summary_$userId';

      if (!prefs.containsKey(key)) {
        return null;
      }

      // Проверяем, не истёк ли кэш
      final timestamp = prefs.getInt(timestampKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheExpiration.inMilliseconds) {
        await prefs.remove(key);
        await prefs.remove(timestampKey);
        return null;
      }

      return prefs.getString(key);
    } catch (e) {
      AppLogger.error(
        'Ошибка при получении кэша AI резюме',
        scope: 'cache',
        error: e,
      );
      return null;
    }
  }

  /// Очищает весь кэш для пользователя
  static Future<void> clearCache(int userId) async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final keysToRemove = <String>[];

      // Собираем все ключи для этого пользователя
      for (final key in prefs.getKeys()) {
        if (key.contains('_$userId') || key.contains('stats_timestamp_')) {
          keysToRemove.add(key);
        }
      }

      // Удаляем все ключи
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      AppLogger.info('Кэш статистики очищен', scope: 'cache');
    } catch (e) {
      AppLogger.error('Ошибка при очистке кэша', scope: 'cache', error: e);
    }
  }

  /// Проверяет, есть ли валидный кэш для пользователя
  static Future<bool> hasCachedData(int userId) async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final key = '${_cacheKeyPrefix}summary_$userId';
      final timestampKey = '${_cacheTimestampKeyPrefix}summary_$userId';

      if (!prefs.containsKey(key)) {
        return false;
      }

      final timestamp = prefs.getInt(timestampKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      return cacheAge <= _cacheExpiration.inMilliseconds;
    } catch (e) {
      return false;
    }
  }
}
