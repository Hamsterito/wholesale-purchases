import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_logger.dart';
import 'arb_loader.dart';
import 'pluralization_rules.dart';

/// Централизованная система локализации приложения
class AppLocalizations {
  static AppLocalizations? _instance;

  final String _locale;
  final Map<String, String> _translations;

  AppLocalizations._(this._locale, this._translations);

  /// Возвращает текущий экземпляр из InheritedWidget или создаёт с дефолтной локалью
  static AppLocalizations of(BuildContext context) {
    // Пытаемся получить из InheritedWidget
    final inherited = context.dependOnInheritedWidgetOfExactType<AppLocalizationsProvider>();
    if (inherited != null) {
      return inherited.localizations;
    }

    // Fallback: если InheritedWidget не найден, используем синглтон
    if (_instance != null) {
      return _instance!;
    }

    // Иначе создаём новый с локалью по умолчанию
    AppLogger.warning('AppLocalizations not initialized, using default locale');
    return AppLocalizations._('ru', {});
  }

  /// Инициализировать AppLocalizations с указанной локалью
  static Future<void> loadLocale(String locale) async {
    try {
      AppLogger.info('Loading locale: $locale');

      // Загружаем ARB-файл через ArbLoader
      final translations = await ArbLoader.loadArbFile(locale);

      // Создаём новый экземпляр
      _instance = AppLocalizations._(locale, translations);

      AppLogger.info(
          'Locale $locale loaded successfully with ${translations.length} translations');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load locale $locale',
        error: e,
        stackTrace: stackTrace,
      );

      // Fallback к русскому языку
      if (locale != 'ru') {
        AppLogger.warning('Falling back to Russian locale');
        await loadLocale('ru');
      } else {
        // Если даже русский не загрузился, создаём пустой экземпляр
        _instance = AppLocalizations._('ru', {});
      }
    }
  }

  /// Получить текущий экземпляр (для использования в InheritedWidget)
  static AppLocalizations get current {
    return _instance ?? AppLocalizations._('ru', {});
  }

  /// Получить текущую локаль
  String get locale => _locale;

  /// Получить переведённую строку по ключу
  ///
  /// [key] - ключ перевода из ARB-файла
  /// [params] - параметры для интерполяции в строку
  ///
  /// Если ключ не найден, возвращает сам ключ и логирует предупреждение.
  ///
  /// Примеры:
  /// ```dart
  /// getString('common_ok') // 'ОК'
  /// getString('order_total', {'count': 5}) // 'Итого: 5 товаров'
  /// ```
  String getString(String key, {Map<String, dynamic>? params}) {
    // Проверяем наличие ключа
    if (!_translations.containsKey(key)) {
      AppLogger.warning(
        'Missing translation key: $key for locale: $_locale',
      );
      return key; // Fallback - возвращаем сам ключ
    }

    String translation = _translations[key]!;

    // Если есть параметры, выполняем интерполяцию
    if (params != null && params.isNotEmpty) {
      translation = _interpolate(translation, params);
    }

    return translation;
  }

  /// Интерполяция параметров в строку
  ///
  /// Заменяет плейсхолдеры вида {paramName} на значения из params.
  String _interpolate(String template, Map<String, dynamic> params) {
    try {
      return template.replaceAllMapped(
        RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}'),
        (match) {
          final key = match.group(1);
          if (key == null || !params.containsKey(key)) {
            AppLogger.warning(
              'Missing parameter: $key in template: $template',
            );
            return match.group(0) ?? '';
          }
          return params[key].toString();
        },
      );
    } catch (e) {
      AppLogger.error(
        'Interpolation failed for template: $template',
        error: e,
      );
      return template;
    }
  }

  /// Получить плюрализованную строку
  ///
  /// [key] - ключ перевода из ARB-файла
  /// [count] - число для определения формы
  ///
  /// Применяет правила плюрализации для текущего языка.
  ///
  /// Примеры:
  /// ```dart
  /// pluralize('item_count', 1) // '1 товар'
  /// pluralize('item_count', 2) // '2 товара'
  /// pluralize('item_count', 5) // '5 товаров'
  /// ```
  String pluralize(String key, int count) {
    // Получаем базовый ключ для плюрализации
    final oneKey = '${key}_one';
    final fewKey = '${key}_few';
    final manyKey = '${key}_many';

    // Получаем формы из ARB-файла
    final one = _translations[oneKey] ?? '';
    final few = _translations[fewKey] ?? '';
    final many = _translations[manyKey] ?? '';

    // Если формы не найдены, возвращаем ключ
    if (one.isEmpty && few.isEmpty && many.isEmpty) {
      AppLogger.warning(
        'Missing pluralization forms for key: $key in locale: $_locale',
      );
      return key;
    }

    // Применяем правила плюрализации
    final form = PluralizationRules.pluralize(
      count,
      one,
      few,
      many,
      language: _locale,
    );

    // Заменяем {count} на фактическое число
    return form.replaceAll('{count}', count.toString());
  }

  /// Форматировать дату в формате DD.MM.YYYY HH:mm
  ///
  /// Примеры:
  /// ```dart
  /// formatDate(DateTime(2024, 1, 15, 14, 30)) // '15.01.2024 14:30'
  /// ```
  String formatDate(DateTime dateTime) {
    try {
      final formatter = DateFormat('dd.MM.yyyy HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      AppLogger.error('Date formatting failed', error: e);
      return dateTime.toString();
    }
  }

  /// Форматировать число с разделителями тысяч и десятичной запятой
  ///
  /// [value] - число для форматирования
  /// [decimals] - количество знаков после запятой (по умолчанию 2)
  ///
  /// Использует узкий неразрывный пробел (U+202F) как разделитель тысяч
  /// и запятую как десятичный разделитель.
  ///
  /// Примеры:
  /// ```dart
  /// formatNumber(1234.56) // '1 234,56'
  /// formatNumber(1000000.99, decimals: 2) // '1 000 000,99'
  /// formatNumber(123.5, decimals: 1) // '123,5'
  /// ```
  String formatNumber(num value, {int decimals = 2}) {
    try {
      // Форматируем число с нужным количеством десятичных знаков
      final formatter = NumberFormat('#,##0.${'0' * decimals}', 'ru_RU');
      String formatted = formatter.format(value);

      // Заменяем обычный пробел на узкий неразрывный пробел (U+202F)
      formatted = formatted.replaceAll(' ', '\u202F');

      // Заменяем точку на запятую (если используется точка)
      formatted = formatted.replaceAll('.', ',');

      return formatted;
    } catch (e) {
      AppLogger.error('Number formatting failed', error: e);
      return value.toString();
    }
  }

  /// Проверить наличие ключа в переводах
  ///
  /// Примеры:
  /// ```dart
  /// hasKey('common_ok') // true
  /// hasKey('nonexistent_key') // false
  /// ```
  bool hasKey(String key) {
    return _translations.containsKey(key);
  }
}


/// InheritedWidget для передачи локализации вниз по дереву виджетов
class AppLocalizationsProvider extends InheritedWidget {
  const AppLocalizationsProvider({
    required this.localizations,
    required super.child,
    super.key,
  });

  final AppLocalizations localizations;

  @override
  bool updateShouldNotify(AppLocalizationsProvider oldWidget) {
    return localizations._locale != oldWidget.localizations._locale;
  }
}
