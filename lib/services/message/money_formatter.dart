import '../../models/currency.dart';
import 'message_localization.dart';

/// Сервис форматирования денег с поддержкой валют и языков
class MoneyFormatter {
  /// Форматирует сумму денег с символом валюты
  /// Пример: formatMoney(1234.56, CurrencyCode.kzt, 'ru') → "1 234,56 ₸"
  static String formatMoney(
    double amount, {
    required CurrencyCode currencyCode,
    String? language,
  }) {
    final lang = language ?? MessageLocalizationManager.getCurrentLanguage();
    final currency = Currency.supported.firstWhere(
      (c) => c.code == currencyCode,
    );

    final formatted = MessageLocalizationManager.formatNumber(
      amount.toDouble(),
      decimals: 2,
      language: lang,
    );

    if (currency.symbolBeforeValue) {
      return '${currency.symbol} $formatted';
    } else {
      return '$formatted ${currency.symbol}';
    }
  }

  /// Форматирует сумму денег с опциональным преобразованием валюты
  /// Пример: convertAndFormat(100, CurrencyCode.kzt, CurrencyCode.rub, 'ru')
  static String convertAndFormat(
    double amount,
    CurrencyCode fromCurrency,
    CurrencyCode toCurrency, {
    String? language,
  }) {
    final lang = language ?? MessageLocalizationManager.getCurrentLanguage();
    final converted = Currency.convert(amount, fromCurrency, toCurrency);
    return formatMoney(converted, currencyCode: toCurrency, language: lang);
  }

  /// Форматирует сумму без символа валюты (только число)
  static String formatAmount(
    double amount, {
    String? language,
  }) {
    final lang = language ?? MessageLocalizationManager.getCurrentLanguage();
    return MessageLocalizationManager.formatNumber(
      amount.toDouble(),
      decimals: 2,
      language: lang,
    );
  }
}
