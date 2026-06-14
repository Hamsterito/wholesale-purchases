import 'package:flutter_project/services/localization/app_localizations.dart';
import '../../services/store/app_settings.dart';
import '../../models/language.dart';
import '../localization/arb_loader.dart';
import '../app_logger.dart';

/// Мультиязычный менеджер сообщений и форматирования
class MessageLocalizationManager {
  static const String defaultLanguage = 'ru';
  static const List<String> supportedLanguages = <String>['ru', 'kk'];

  // Кэш загруженных шаблонов сообщений из ARB: locale -> Map<String, String>
  static final Map<String, Map<String, String>> _messageTemplatesCache = {};

  // Маппинг старых кодов на новые ключи ARB
  static final Map<String, String> _codeToArbKey = {
    'ORDER_NOT_FOUND': 'message_order_not_found',
    'ORDER_CONFIRMED': 'message_order_confirmed',
    'ORDER_DELIVERED': 'message_order_delivered',
    'PRODUCT_NOT_FOUND': 'message_product_not_found',
    'NETWORK_ERROR': 'message_network_error',
    'TIMEOUT_ERROR': 'message_timeout_error',
    'VALIDATION_ERROR': 'message_validation_error',
    'AUTH_REQUIRED': 'message_auth_required',
    'PARSE_ERROR': 'message_parse_error',
    'AI_GENERATION_FAILED': 'message_ai_generation_failed',
  };

  // Хардкод-фолбэк по исходным кодам - используется, если ARB ещё не загружен
  // (старт до init, тесты) или нужного ключа в ARB нет. Так getTemplate
  // остаётся синхронным и никогда не отдаёт пустоту для известных кодов.
  static final Map<String, String> _fallbackTemplates = <String, String>{
    'ORDER_NOT_FOUND': 'Заказ с ID {orderId} не найден',
    'ORDER_CONFIRMED': 'Ваш заказ #{orderId} подтверждён',
    'ORDER_DELIVERED': 'Заказ #{orderId} доставлен',
    'PRODUCT_NOT_FOUND': 'Товар с ID {productId} не найден',
    'NETWORK_ERROR': AppLocalizations.current.getString('auto_oshibka_seti_proverte_podklyuchenie'),
    'TIMEOUT_ERROR': AppLocalizations.current.getString('auto_prevysheno_vremya_ozhidaniya_otveta'),
    'VALIDATION_ERROR': 'Ошибка валидации: {details}',
    'AUTH_REQUIRED': AppLocalizations.current.getString('auto_trebuetsya_avtorizatsiya'),
    'PARSE_ERROR': AppLocalizations.current.getString('auto_ne_udalos_razobrat_soobschenie'),
    'AI_GENERATION_FAILED': 'Не удалось сгенерировать ответ AI: {reason}',
  };

  /// Возвращает текущий язык из AppSettings.
  /// Если язык не поддерживается — падает на 'ru'.
  static String getCurrentLanguage() {
    final code = AppSettings.language.value.code;
    switch (code) {
      case LanguageCode.kazakh:
        return 'kk';
      case LanguageCode.russian:
        return 'ru';
    }
  }

  /// Предзагружает шаблоны сообщений из ARB в кэш.
  /// Вызывать при старте приложения и при смене языка - тогда getTemplate
  /// может оставаться синхронным и читать из готового кэша.
  static Future<void> loadTemplates(String language) async {
    if (_messageTemplatesCache.containsKey(language)) return;

    try {
      final arbTranslations = await ArbLoader.loadArbFile(language);

      // Из всего ARB берём только message_* ключи
      final templates = <String, String>{};
      for (final entry in arbTranslations.entries) {
        if (entry.key.startsWith('message_')) {
          templates[entry.key] = entry.value;
        }
      }

      _messageTemplatesCache[language] = templates;
      AppLogger.info(
        'Loaded ${templates.length} message templates for language: $language',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load message templates for language: $language',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Сбрасывает кэш шаблонов - нужно для тестов и принудительной перезагрузки.
  static void clearTemplatesCache() {
    _messageTemplatesCache.clear();
  }

  /// Возвращает шаблон сообщения по коду.
  ///
  /// Поддерживает старые коды (ORDER_NOT_FOUND) и новые ключи ARB
  /// (message_order_not_found). Источник - предзагруженные ARB-шаблоны,
  /// при их отсутствии берём хардкод-фолбэк по исходному коду.
  static String getTemplate(String code, {String? language}) {
    final lang = language ?? getCurrentLanguage();
    final arbKey = _codeToArbKey[code] ?? code;

    final fromArb = _messageTemplatesCache[lang]?[arbKey];
    if (fromArb != null && fromArb.isNotEmpty) {
      return fromArb;
    }

    final fallback = _fallbackTemplates[code];
    if (fallback != null) {
      return fallback;
    }

    AppLogger.warning(
      'Message template not found: $code (ARB key: $arbKey) for language: $lang',
    );
    return '';
  }

  /// Рендерит шаблон сообщения с подстановкой значений.
  static String renderTemplate(
    String code,
    Map<String, dynamic> values, {
    String? language,
  }) {
    final template = getTemplate(code, language: language);
    if (template.isEmpty) return '';
    return replacePlaceholders(template, values);
  }

  static final RegExp _placeholderPattern = RegExp(
    r'\{([A-Za-z_][A-Za-z0-9_]*)\}',
  );

  /// Отсутствующие ключи остаются в тексте - так заметнее опечатки в шаблонах
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
    r'([,.;:!?])[ \t]*([A-Za-zА-Яа-яЁёҚқҒғҮүҰұІіӘәҺһҢң])',
  );
  static final RegExp _pairedQuotes = RegExp(r'"([^"]*)"');

  /// Применяет правила типографики: убирает пробелы перед пунктуацией,
  /// ставит один пробел после, заменяет парные кавычки на ёлочки.
  /// Работает одинаково для 'ru' и 'kk'.
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

  /// DD.MM.YYYY HH:mm
  static String formatDate(DateTime dt, {String? language}) {
    final day = _pad2(dt.day);
    final month = _pad2(dt.month);
    final year = dt.year.toString().padLeft(4, '0');
    final hour = _pad2(dt.hour);
    final minute = _pad2(dt.minute);
    return '$day.$month.$year $hour:$minute';
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');

  /// Форматирует число с запятой как разделитель дробной части
  /// и узким неразрывным пробелом между разрядами
  static String formatNumber(
    num value, {
    int decimals = 2,
    String? language,
  }) {
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

  /// Казахский плюрал: 1 → one, 2-10/21/101 → few, остальное → many
  static String pluralizeKk(
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

  /// Русский плюрал: 1/21/101 → one, 2-4/22-24 → few, остальное → many
  static String pluralizeRu(
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

  static String pluralize(
    int count,
    String one,
    String few,
    String many, {
    String? language,
  }) {
    final lang = language ?? getCurrentLanguage();
    if (lang == 'kk') {
      return pluralizeKk(count, one, few, many);
    } else {
      return pluralizeRu(count, one, few, many);
    }
  }
}

String formatNumberRu(num value, {int decimals = 2}) =>
    MessageLocalizationManager.formatNumber(
      value,
      decimals: decimals,
      language: 'ru',
    );

String formatDateRu(DateTime dt) =>
    MessageLocalizationManager.formatDate(dt, language: 'ru');
