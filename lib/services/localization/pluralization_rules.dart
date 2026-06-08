/// Правила плюрализации для разных языков
///
/// Реализует правила выбора формы слова в зависимости от числа
/// для казахского и русского языков.
class PluralizationRules {
  /// Применяет правила плюрализации для казахского языка
  ///
  /// Правила:
  /// - 1, 21, 31, 41, ... (count % 10 == 1 && count % 100 != 11) → one
  /// - 2-4, 12-14, 22-24, ... → few
  /// - 0, 5-20, 25-30, ... → many
  ///
  /// Примеры:
  /// - 1 өнім (one)
  /// - 2 өнім (few)
  /// - 5 өнім (many)
  /// - 21 өнім (one)
  static String pluralizeKazakh(
    int count,
    String one,
    String few,
    String many,
  ) {
    if (count == 1) return one;
    if (count % 10 == 1 && count % 100 != 11) return one;
    if ((count % 10 >= 2 && count % 10 <= 4) ||
        (count % 100 >= 12 && count % 100 <= 14)) {
      return few;
    }
    return many;
  }

  /// Применяет правила плюрализации для русского языка
  ///
  /// Правила:
  /// - 1, 21, 31, 41, ... (count % 10 == 1 && count % 100 != 11) → one
  /// - 2-4, 22-24, 32-34, ... (count % 10 in 2..4 && count % 100 not in 10..19) → few
  /// - 0, 5-20, 25-30, ... → many
  ///
  /// Примеры:
  /// - 1 товар (one)
  /// - 2 товара (few)
  /// - 5 товаров (many)
  /// - 21 товар (one)
  static String pluralizeRussian(
    int count,
    String one,
    String few,
    String many,
  ) {
    if (count % 10 == 1 && count % 100 != 11) return one;
    if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return few;
    }
    return many;
  }

  /// Универсальная функция плюрализации с выбором языка
  ///
  /// [count] - число, для которого выбирается форма
  /// [one] - форма для единственного числа
  /// [few] - форма для малого множественного числа
  /// [many] - форма для большого множественного числа
  /// [language] - код языка ('ru' или 'kk')
  ///
  /// Примеры:
  /// ```dart
  /// pluralize(1, 'товар', 'товара', 'товаров', language: 'ru'); // 'товар'
  /// pluralize(2, 'товар', 'товара', 'товаров', language: 'ru'); // 'товара'
  /// pluralize(5, 'товар', 'товара', 'товаров', language: 'ru'); // 'товаров'
  /// pluralize(1, 'өнім', 'өнім', 'өнім', language: 'kk'); // 'өнім'
  /// ```
  static String pluralize(
    int count,
    String one,
    String few,
    String many, {
    required String language,
  }) {
    switch (language) {
      case 'kk':
        return pluralizeKazakh(count, one, few, many);
      case 'ru':
        return pluralizeRussian(count, one, few, many);
      default:
        return pluralizeRussian(count, one, few, many);
    }
  }
}
