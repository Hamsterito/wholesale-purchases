import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../theme/app_color_palette.dart';

/// Готовый комплект параметров стилизации сообщения для UI.
class MessageColors {
  const MessageColors({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    this.icon,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final IconData? icon;
}

/// Подстановка плейсхолдеров, экранирование и подбор стилей по severity.
class MessageFormatter {
  // Имя плейсхолдера должно начинаться с буквы или подчёркивания,
  // чтобы не цеплять случайные `{...}` в обычном тексте.
  static final RegExp _placeholderPattern = RegExp(
    r'\{([A-Za-z_][A-Za-z0-9_]*)\}',
  );

  static String format(Message message, BuildContext context) {
    final raw = message.body;
    if (raw.isEmpty) return '';

    final withValues = replacePlaceholders(raw, message.metadata);
    return _sanitize(withValues);
  }

  /// Возвращает только размер и вес шрифта. Цвет берётся через [getColors].
  static TextStyle getStyle(MessageSeverity severity) {
    switch (severity) {
      case MessageSeverity.info:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
      case MessageSeverity.warning:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
      case MessageSeverity.error:
        return const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
      case MessageSeverity.critical:
        return const TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
    }
  }

  static MessageColors getColors(
    MessageSeverity severity,
    BuildContext context,
  ) {
    final palette = AppColorPalette.of(context);

    switch (severity) {
      case MessageSeverity.info:
        return MessageColors(
          backgroundColor: palette.info.withValues(alpha: 0.12),
          textColor: palette.ink,
          borderColor: palette.info,
          icon: Icons.info_outline,
        );
      case MessageSeverity.warning:
        return MessageColors(
          backgroundColor: palette.warning.withValues(alpha: 0.15),
          textColor: palette.ink,
          borderColor: palette.warning,
          icon: Icons.warning_amber_rounded,
        );
      case MessageSeverity.error:
        return MessageColors(
          backgroundColor: palette.error.withValues(alpha: 0.15),
          textColor: palette.ink,
          borderColor: palette.error,
          icon: Icons.error_outline,
        );
      case MessageSeverity.critical:
        // Белый текст на цветном фоне — задокументированное исключение из color-system-usage.md
        // ради контраста при сплошном красном фоне.
        return MessageColors(
          backgroundColor: palette.error,
          textColor: Colors.white,
          borderColor: palette.error,
          icon: Icons.dangerous_outlined,
        );
    }
  }

  /// Заглушка под мультиязычность: пока поддерживается только русский,
  /// любой запрос отдаёт оригинальный body.
  static String translate(Message message, String targetLanguage) {
    return message.body;
  }

  /// Отсутствующие ключи остаются в тексте — так заметнее опечатки в шаблонах.
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

  // Сохраняем переносы и табуляции, остальные управляющие символы выкидываем.
  // Не полноценная защита от XSS, но безопасный минимум для Text-виджетов и логов.
  static String _sanitize(String input) {
    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);

      if (ch == '\n' || ch == '\r' || ch == '\t') {
        buffer.write(ch);
        continue;
      }

      if (rune < 0x20 || rune == 0x7F) {
        continue;
      }

      switch (ch) {
        case '&':
          buffer.write('&amp;');
          break;
        case '<':
          buffer.write('&lt;');
          break;
        case '>':
          buffer.write('&gt;');
          break;
        default:
          buffer.write(ch);
      }
    }

    return buffer.toString();
  }
}
