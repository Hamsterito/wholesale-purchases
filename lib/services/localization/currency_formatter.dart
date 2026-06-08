import 'package:intl/intl.dart';

import '../store/app_settings.dart';
import '../../models/currency.dart';
import '../../models/language.dart';

/// Сервис для форматирования денежных сумм с поддержкой разных валют и языков
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Форматирует сумму в строку с символом валюты
  /// Пример: formatAmount(1234.56, CurrencyCode.rub) -> "1 234,56 ₽"
  static String formatAmount(
    double amount,
    CurrencyCode currency, {
    int decimalDigits = 2,
    LanguageCode? language,
  }) {
    final lang = language ?? _getCurrentLanguageCode();
    final currencyModel = Currency.supported
        .firstWhere((c) => c.code == currency, orElse: () => Currency.supported.first);

    // Выбираем локаль для форматирования чисел
    final locale = _getLocaleString(lang);
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: decimalDigits,
    );

    final formattedNumber = formatter.format(amount);

    // Добавляем символ валюты в нужное место
    if (currencyModel.symbolBeforeValue) {
      return '${currencyModel.symbol} $formattedNumber';
    } else {
      return '$formattedNumber ${currencyModel.symbol}';
    }
  }

  /// Форматирует сумму без символа валюты
  /// Пример: formatNumber(1234.56) -> "1 234,56"
  static String formatNumber(
    double amount, {
    int decimalDigits = 2,
    LanguageCode? language,
  }) {
    final lang = language ?? _getCurrentLanguageCode();
    final locale = _getLocaleString(lang);
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: decimalDigits,
    );

    return formatter.format(amount);
  }

  /// Форматирует целое число с разделителями тысяч
  /// Пример: formatInteger(1234567) -> "1 234 567"
  static String formatInteger(
    int number, {
    LanguageCode? language,
  }) {
    final lang = language ?? _getCurrentLanguageCode();
    final locale = _getLocaleString(lang);
    final formatter = NumberFormat.decimalPattern(locale);
    return formatter.format(number);
  }

  /// Форматирует процент
  /// Пример: formatPercent(0.1234) -> "12,34%"
  static String formatPercent(
    double percent, {
    int decimalDigits = 2,
    LanguageCode? language,
  }) {
    final lang = language ?? _getCurrentLanguageCode();
    final locale = _getLocaleString(lang);
    final formatter = NumberFormat.percentPattern(locale);
    return formatter.format(percent);
  }

  /// Конвертирует сумму из одной валюты в другую и форматирует
  /// Пример: convertAndFormat(100, CurrencyCode.kzt, CurrencyCode.rub) -> "10,00 ₽"
  static String convertAndFormat(
    double amount,
    CurrencyCode fromCurrency,
    CurrencyCode toCurrency, {
    int decimalDigits = 2,
    LanguageCode? language,
  }) {
    final lang = language ?? _getCurrentLanguageCode();
    final convertedAmount = Currency.convert(amount, fromCurrency, toCurrency);
    return formatAmount(convertedAmount, toCurrency, decimalDigits: decimalDigits, language: lang);
  }

  /// Получает локаль для форматирования на основе языка
  static String _getLocaleString(LanguageCode language) {
    switch (language) {
      case LanguageCode.russian:
        return 'ru_RU';
      case LanguageCode.kazakh:
        return 'kk_KZ';
    }
  }

  /// Получает текущий язык из настроек
  static LanguageCode _getCurrentLanguageCode() {
    return AppSettings.language.value.code;
  }

  /// Парсит строку с суммой в число
  /// Пример: parseAmount("1 234,56") -> 1234.56
  static double? parseAmount(
    String input, {
    LanguageCode? language,
  }) {
    try {
      final lang = language ?? _getCurrentLanguageCode();
      final locale = _getLocaleString(lang);
      final formatter = NumberFormat.currency(
        locale: locale,
        symbol: '',
      );

      // Удаляем символы валют и пробелы
      String cleaned = input.replaceAll(RegExp(r'[₽₸\s]'), '');

      return formatter.parse(cleaned).toDouble();
    } catch (e) {
      return null;
    }
  }
}
