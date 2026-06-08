/// Поддерживаемые валюты в приложении
enum CurrencyCode {
  kzt, // Казахский тенге
  rub, // Российский рубль
}

extension CurrencyCodeExtension on CurrencyCode {
  String get code {
    switch (this) {
      case CurrencyCode.kzt:
        return 'KZT';
      case CurrencyCode.rub:
        return 'RUB';
    }
  }

  String get symbol {
    switch (this) {
      case CurrencyCode.kzt:
        return '₸';
      case CurrencyCode.rub:
        return '₽';
    }
  }

  /// Позиция символа: true - перед числом, false - после
  bool get symbolBeforeValue {
    switch (this) {
      case CurrencyCode.kzt:
        return false; // 100 ₸
      case CurrencyCode.rub:
        return false; // 100 ₽
    }
  }
}

class Currency {
  final CurrencyCode code;
  final String name;
  final String symbol;
  final bool symbolBeforeValue;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.symbolBeforeValue,
  });

  static final List<Currency> supported = [
    Currency(
      code: CurrencyCode.kzt,
      name: 'Казахский тенге',
      symbol: '₸',
      symbolBeforeValue: false,
    ),
    Currency(
      code: CurrencyCode.rub,
      name: 'Российский рубль',
      symbol: '₽',
      symbolBeforeValue: false,
    ),
  ];

  static Currency? fromCode(String code) {
    try {
      return supported.firstWhere((curr) => curr.code.code == code);
    } catch (e) {
      return null;
    }
  }

  static Currency get defaultCurrency => supported.first;

  /// Курсы обмена относительно базовой валюты (KZT = 1.0)
  /// Статические курсы. 1 KZT = 0.1 RUB примерно
  static const Map<String, double> exchangeRates = {
    'KZT': 1.0,
    'RUB': 0.1, // 1 KZT ≈ 0.1 RUB
  };

  /// Конвертирует сумму из одной валюты в другую
  static double convert(
    double amount,
    CurrencyCode from,
    CurrencyCode to,
  ) {
    if (from == to) return amount;

    final fromRate = exchangeRates[from.code] ?? 1.0;
    final toRate = exchangeRates[to.code] ?? 1.0;

    return (amount / fromRate) * toRate;
  }
}
