import 'dart:convert';

import '../../models/message.dart';
import 'message_validator.dart';

/// Форматирование сообщений для логов и багрепортов.
class MessagePrettyPrinter {
  static const int _bodyTruncateLimit = 200;

  /// detailed = true - многострочный отчёт, false - однострочная сводка.
  static String prettyPrint(Message message, {bool detailed = true}) {
    if (!detailed) {
      return _compactSummary(message);
    }
    return _detailedReport(message);
  }

  /// При ошибке кодирования возвращаем toString() - лучше что-то читаемое, чем падение лога.
  static String prettyPrintJson(Map<String, dynamic> json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return json.toString();
    }
  }

  static String prettyPrintValidationResult(ValidationResult result) {
    final buffer = StringBuffer();
    buffer.writeln('ValidationResult: ${result.isValid}');

    if (result.errors.isNotEmpty) {
      buffer.writeln('Ошибки (${result.errors.length}):');
      for (final err in result.errors) {
        buffer.writeln('  - $err');
      }
    }

    if (result.warnings.isNotEmpty) {
      buffer.writeln('Предупреждения (${result.warnings.length}):');
      for (final warn in result.warnings) {
        buffer.writeln('  - $warn');
      }
    }

    final out = buffer.toString();
    return out.endsWith('\n') ? out.substring(0, out.length - 1) : out;
  }

  static String _compactSummary(Message message) {
    final title = message.title.isEmpty ? '(без заголовка)' : message.title;
    final body = _truncate(message.body, _bodyTruncateLimit);
    return '[${message.severity.value}][${message.type.value}] '
        '${message.displayId} | $title — $body';
  }

  static String _detailedReport(Message message) {
    final buffer = StringBuffer();

    buffer.writeln('Message');
    buffer.writeln('  id: ${message.id} (${message.displayId})');
    buffer.writeln('  type: ${message.type.value}');
    buffer.writeln('  severity: ${message.severity.value}');
    buffer.writeln('  title: ${message.title}');
    buffer.writeln('  body: ${_truncate(message.body, _bodyTruncateLimit)}');
    buffer.writeln('  code: ${message.code ?? '-'}');
    buffer.writeln('  timestamp: ${_formatTimestamp(message.timestamp)}');
    buffer.writeln('  language: ${message.language}');

    if (message.metadata.isEmpty) {
      buffer.writeln('  metadata: {}');
    } else {
      buffer.writeln('  metadata:');
      buffer.write(_formatMetadata(message.metadata, indent: '    '));
    }

    final out = buffer.toString();
    return out.endsWith('\n') ? out.substring(0, out.length - 1) : out;
  }

  // Локально-нейтральный формат YYYY-MM-DD HH:mm:ss без зависимости от часового пояса.
  static String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  static String _truncate(String s, int max) {
    if (max <= 0) return '...';
    if (s.length <= max) return s;
    return '${s.substring(0, max)}...';
  }

  // Вложенные структуры сериализуем через jsonEncode, остальное - toString.
  static String _formatMetadata(
    Map<String, dynamic> metadata, {
    String indent = '  ',
  }) {
    final buffer = StringBuffer();
    for (final entry in metadata.entries) {
      final value = entry.value;
      String rendered;
      if (value == null) {
        rendered = 'null';
      } else if (value is Map || value is List) {
        try {
          rendered = jsonEncode(value);
        } catch (_) {
          rendered = value.toString();
        }
      } else {
        rendered = value.toString();
      }
      buffer.writeln('$indent${entry.key}: $rendered');
    }
    return buffer.toString();
  }
}
