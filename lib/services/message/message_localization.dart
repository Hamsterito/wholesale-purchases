/// Шаблоны системных сообщений и русская типографика. Только русский.
class MessageLocalizationManager {
  static const String defaultLanguage = 'ru';
  static const List<String> supportedLanguages = <String>['ru'];

  static String getCurrentLanguage() => defaultLanguage;

  static const Map<String, String> messageTemplates = <String, String>{
    'ORDER_NOT_FOUND': 'Заказ с ID {orderId} не найден',
    'ORDER_CONFIRMED': 'Ваш заказ #{orderId} подтверждён',
    'ORDER_DELIVERED': 'Заказ #{orderId} доставлен',
    'PRODUCT_NOT_FOUND': 'Товар с ID {productId} не найден',
    'NETWORK_ERROR': 'Ошибка сети. Проверьте подключение и попробуйте снова',
    'TIMEOUT_ERROR': 'Превышено время ожидания ответа сервера',
    'VALIDATION_ERROR': 'Ошибка валидации: {details}',
    'AUTH_REQUIRED': 'Требуется авторизация',
    'PARSE_ERROR': 'Не удалось разобрать сообщение',
    'AI_GENERATION_FAILED': 'Не удалось сгенерировать ответ AI: {reason}',
  };

  /// Пустая строка вместо null - упрощает конкатенацию и не ломает валидацию body.
  static String getTemplate(String code) {
    return messageTemplates[code] ?? '';
  }

  static String renderTemplate(String code, Map<String, dynamic> values) {
    final template = getTemplate(code);
    if (template.isEmpty) return '';
    return replacePlaceholders(template, values);
  }

  static final RegExp _placeholderPattern = RegExp(
    r'\{([A-Za-z_][A-Za-z0-9_]*)\}',
  );

  /// Отсутствующие ключи остаются в тексте - так заметнее опечатки в шаблонах.
  static String replacePlaceholders(
    String template,
    Map<String, dynamic> values,
  ) {
    if (template.isEmpty || values.isEmpty) return template;

    return template.replaceAllMapped(_placeholderPattern, (match) {
      final key = match.group(1);
      if (key == null || !values.containsKey(key)) {
        return match.group(0) ?? '';
      }
      final value = values[key];
      if (value == null) return '';
      return value.toString();
    });
  }

  static final RegExp _spaceBeforePunct = RegExp(r'\s+([,.;:!?])');
  static final RegExp _spaceAfterPunct = RegExp(
    r'([,.;:!?])[ \t]*([A-Za-zА-Яа-яЁё])',
  );
  static final RegExp _pairedQuotes = RegExp(r'"([^"]*)"');

  /// Применяет русские правила: убирает пробелы перед пунктуацией,
  /// ставит ровно один пробел после, заменяет парные "..." на «ёлочки».
  /// Числа вроде 12.5 не трогает - там после точки идёт цифра.
  /// Параметр language зарезервирован под будущие языки.
  static String formatForLanguage(String text, String language) {
    if (text.isEmpty) return text;

    var result = text.replaceFirst(RegExp(r'\s+$'), '');
    result = result.replaceAllMapped(
      _spaceBeforePunct,
      (m) => m.group(1) ?? '',
    );
    result = result.replaceAllMapped(
      _spaceAfterPunct,
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    result = result.replaceAllMapped(
      _pairedQuotes,
      (m) => '«${m.group(1) ?? ''}»',
    );

    return result;
  }

  /// DD.MM.YYYY HH:mm.
  static String formatDateRu(DateTime dt) {
    final day = _pad2(dt.day);
    final month = _pad2(dt.month);
    final year = dt.year.toString().padLeft(4, '0');
    final hour = _pad2(dt.hour);
    final minute = _pad2(dt.minute);
    return '$day.$month.$year $hour:$minute';
  }

  /// Запятая как разделитель дробной части, узкий неразрывный пробел (U+202F)
  /// между разрядами. Пример: 1234567.89 → 1 234 567,89.
  static String formatNumberRu(num value, {int decimals = 2}) {
    final effectiveDecimals = decimals < 0 ? 0 : decimals;

    final isNegative = value < 0;
    final absValue = isNegative ? -value : value;

    final fixed = absValue.toStringAsFixed(effectiveDecimals);
    final dotIndex = fixed.indexOf('.');
    final intPart = dotIndex >= 0 ? fixed.substring(0, dotIndex) : fixed;
    final decPart = dotIndex >= 0 ? fixed.substring(dotIndex + 1) : '';

    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write('\u202F');
      }
      buffer.write(intPart[i]);
    }

    var result = buffer.toString();
    if (decPart.isNotEmpty) {
      result = '$result,$decPart';
    }
    if (isNegative) {
      result = '-$result';
    }
    return result;
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
}
