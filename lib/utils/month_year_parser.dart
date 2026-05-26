import 'package:flutter/foundation.dart';

/// Парсер для преобразования различных форматов месяца/года в DateTime.
///
/// Поддерживаемые форматы:
/// - Числовой: "05.2026", "5.2026" (MM.YYYY или M.YYYY)
/// - Текстовый: "май 2026", "май", "Май 2026"
/// - Аббревиатуры: "янв 2026", "янв.", "янв", "Янв", "ЯНВ"
/// - С лишними пробелами: "май  2026"
/// - Капитализированные: "Май", "Май 2026"
class MonthYearParser {
  // RegExp в static final, чтобы не пересоздавать на каждый ввод даты
  static final RegExp _whitespaceRegExp = RegExp(r'\s+');

  // Объединённый словарь для быстрого поиска
  static const Map<String, int> _russianMonths = {
    // Полные названия
    'январь': 1,
    'февраль': 2,
    'март': 3,
    'апрель': 4,
    'май': 5,
    'июнь': 6,
    'июль': 7,
    'август': 8,
    'сентябрь': 9,
    'октябрь': 10,
    'ноябрь': 11,
    'декабрь': 12,
    // Аббревиатуры (3 буквы)
    'янв': 1,
    'фев': 2,
    'мар': 3,
    'апр': 4,
    'июн': 6,
    'июл': 7,
    'авг': 8,
    'сен': 9,
    'окт': 10,
    'ноя': 11,
    'дек': 12,
    // Аббревиатуры с точкой
    'янв.': 1,
    'фев.': 2,
    'мар.': 3,
    'апр.': 4,
    'май.': 5,
    'июн.': 6,
    'июл.': 7,
    'авг.': 8,
    'сен.': 9,
    'окт.': 10,
    'ноя.': 11,
    'дек.': 12,
  };

  /// Парсит строку месяца/года в DateTime.
  /// Возвращает null если парсинг не удался.
  ///
  /// Поддерживает:
  /// - Числовой формат: "05.2026", "5.2026", "05.26", "5.26"
  /// - Текстовый формат: "май 2026", "май", "Май", "Май 2026"
  /// - Аббревиатуры: "янв", "Янв", "янв.", "Янв."
  static DateTime? parse(String monthYear) {
    if (monthYear.isEmpty) return null;

    try {
      final input = monthYear.trim();

      // Попытка 1: Числовой формат MM.YYYY или M.YYYY или MM.YY или M.YY
      if (input.contains('.')) {
        final parts = input.split('.');
        // Проверяем, что это формат MM.YYYY или MM.YY (2 части)
        if (parts.length == 2) {
          final result = _parseNumericFormat(input);
          if (result != null) return result;
        }
      }

      // Попытка 2: Текстовый формат с русскими месяцами
      final result = _parseTextFormat(input);
      return result;
    } catch (e) {
      debugPrint('⚠️ Ошибка парсинга даты: "$monthYear" - $e');
      return null;
    }
  }

  /// Парсит числовой формат MM.YYYY или M.YYYY
  static DateTime? _parseNumericFormat(String input) {
    final parts = input.split('.');
    if (parts.length != 2) return null;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return null;
    if (month < 1 || month > 12) return null;

    final fullYear = year < 100 ? year + 2000 : year;
    if (fullYear < 1900 || fullYear > 2100) return null;

    return DateTime(fullYear, month);
  }

  /// Парсит текстовый формат с русскими месяцами
  /// Поддерживает: "май", "Май", "май 2026", "Май 2026", "янв", "Янв", "янв 2026"
  static DateTime? _parseTextFormat(String input) {
    // Нормализуем: убираем лишние пробелы, но сохраняем регистр для проверки
    final normalized = input.replaceAll(_whitespaceRegExp, ' ').trim();
    final lowerNormalized = normalized.toLowerCase();

    final parts = lowerNormalized.split(' ');
    if (parts.isEmpty) return null;

    // Ищем месяц в словаре (ищем в нижнем регистре)
    final month = _russianMonths[parts[0]];
    if (month == null) return null;

    int year;
    if (parts.length == 1) {
      // Только месяц - используем текущий год
      year = DateTime.now().year;
    } else if (parts.length == 2) {
      // Месяц и год
      year = int.tryParse(parts[1]) ?? 0;
      if (year == 0) return null;

      // Обрабатываем 2-значные годы
      if (year < 100) year += 2000;
    } else {
      return null;
    }

    // Валидация года
    if (year < 1900 || year > 2100) return null;

    return DateTime(year, month);
  }

  /// Форматирует DateTime в строку "MM.YYYY" для отправки на бэкенд
  static String formatForBackend(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Форматирует DateTime в читаемый формат "май 2026"
  static String formatForDisplay(DateTime date) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
