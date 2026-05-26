import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../models/message.dart';
import '../../models/support_message.dart';
import 'message_validator.dart';

/// Приводит разнородные источники к единой Message. На любой сбой возвращает
/// Message типа MessageType.error, чтобы вызывающий код не ловил исключений.
class MessageParser {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static final Random _random = Random.secure();

  /// 2xx → apiResponse/info, 4xx → error/error, 5xx → error/critical, иное → error/warning.
  static Message parseApiResponse(
    http.Response response,
    String language, {
    String? endpoint,
    String? method,
  }) {
    final status = response.statusCode;
    final isSuccess = status >= 200 && status < 300;
    final is4xx = status >= 400 && status < 500;
    final is5xx = status >= 500 && status < 600;

    final MessageType type = isSuccess
        ? MessageType.apiResponse
        : MessageType.error;
    final MessageSeverity severity;
    if (isSuccess) {
      severity = MessageSeverity.info;
    } else if (is4xx) {
      severity = MessageSeverity.error;
    } else if (is5xx) {
      severity = MessageSeverity.critical;
    } else {
      severity = MessageSeverity.warning;
    }

    String? extractedBody;
    String? extractedCode;
    Map<String, dynamic>? jsonBody;
    final rawBody = response.body;
    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map) {
          jsonBody = Map<String, dynamic>.from(decoded);
          for (final key in const ['error', 'message', 'detail']) {
            final v = jsonBody[key];
            if (v is String && v.isNotEmpty) {
              extractedBody = v;
              break;
            }
          }
          for (final key in const ['code', 'errorCode']) {
            final v = jsonBody[key];
            if (v != null && v.toString().isNotEmpty) {
              extractedCode = v.toString();
              break;
            }
          }
        }
      } catch (_) {
        // Не JSON - нормально для ряда эндпоинтов.
      }
    }

    final title = isSuccess
        ? 'Запрос выполнен'
        : 'Ошибка запроса (HTTP $status)';

    final body = (extractedBody != null && extractedBody.isNotEmpty)
        ? extractedBody
        : (rawBody.isNotEmpty
              ? rawBody
              : (response.reasonPhrase ?? 'HTTP $status'));

    // Берём только безопасное подмножество заголовков - остальное может быть объёмным
    // или содержать чувствительные значения.
    final headers = response.headers;
    final headersSubset = <String, String>{};
    for (final key in const ['content-type', 'content-length']) {
      final value = headers[key];
      if (value != null) headersSubset[key] = value;
    }

    final metadata = <String, dynamic>{
      if (endpoint != null) 'endpoint': endpoint,
      if (method != null) 'method': method,
      'httpStatus': status,
      'responseHeaders': headersSubset,
    };

    final message = Message(
      id: _generateUuid(),
      type: type,
      severity: severity,
      title: title,
      body: _truncate(body, MessageValidator.maxBodyLength),
      code: extractedCode,
      timestamp: DateTime.now(),
      language: language,
      metadata: metadata,
    );

    final validation = MessageValidator.validate(message);
    if (!validation.isValid) {
      return _genericParseError('некорректный ответ API', <String, dynamic>{
        'httpStatus': status,
        if (endpoint != null) 'endpoint': endpoint,
        if (method != null) 'method': method,
        'validationErrors': validation.errors,
      });
    }

    return message;
  }

  /// Сетевые ошибки и таймауты получают severity=warning, остальные - error.
  static Message parseException(Object e, StackTrace? stack, String language) {
    final runtimeName = e.runtimeType.toString();
    final exceptionString = e.toString();
    final lowerName = runtimeName.toLowerCase();

    final isNetworkLike =
        e is TimeoutException ||
        lowerName.contains('socket') ||
        lowerName.contains('timeout') ||
        lowerName.contains('httpexception') ||
        lowerName.contains('handshake') ||
        lowerName.contains('connection');

    final severity = isNetworkLike
        ? MessageSeverity.warning
        : MessageSeverity.error;

    final body = _describeException(runtimeName, exceptionString);
    final code = 'EXCEPTION_${_sanitizeCode(runtimeName)}';

    final metadata = <String, dynamic>{
      'exceptionType': runtimeName,
      'exceptionMessage': _truncate(exceptionString, 1000),
      if (stack != null) 'stackTrace': _truncate(stack.toString(), 2000),
    };

    final message = Message(
      id: _generateUuid(),
      type: MessageType.error,
      severity: severity,
      title: 'Ошибка приложения',
      body: _truncate(body, MessageValidator.maxBodyLength),
      code: code,
      timestamp: DateTime.now(),
      language: language,
      metadata: metadata,
    );

    final validation = MessageValidator.validate(message);
    if (!validation.isValid) {
      return _genericParseError('не удалось разобрать исключение', metadata);
    }
    return message;
  }

  /// Если исходный id не похож на UUID - генерируем новый, оригинал кладём в metadata.
  static Message parseSupportMessage(SupportMessage msg) {
    final hasValidUuid = msg.id.isNotEmpty && _uuidRegex.hasMatch(msg.id);
    final id = hasValidUuid ? msg.id : _generateUuid();

    final metadata = <String, dynamic>{
      'chatId': msg.chatId,
      'userId': msg.userId,
      'senderRole': msg.senderRole,
      if (msg.senderUserId != null) 'senderUserId': msg.senderUserId,
      'category': msg.category,
      if (!hasValidUuid && msg.id.isNotEmpty) 'originalId': msg.id,
    };

    final message = Message(
      id: id,
      type: MessageType.supportChat,
      severity: MessageSeverity.info,
      title: msg.subject,
      body: _truncate(msg.text, MessageValidator.maxBodyLength),
      timestamp: msg.createdAt,
      language: 'ru',
      metadata: metadata,
    );

    final validation = MessageValidator.validate(message);
    if (!validation.isValid) {
      return _genericParseError(
        'некорректное сообщение поддержки',
        <String, dynamic>{
          'chatId': msg.chatId,
          'userId': msg.userId,
          'validationErrors': validation.errors,
        },
      );
    }
    return message;
  }

  static Message parseJson(Map<String, dynamic> json) {
    try {
      final message = Message.fromJson(json);
      final validation = MessageValidator.validate(message);
      if (!validation.isValid) {
        return _genericParseError('JSON не прошёл валидацию', <String, dynamic>{
          'jsonSnippet': _truncate(json.toString(), 500),
          'validationErrors': validation.errors,
        });
      }
      return message;
    } catch (e) {
      return _genericParseError('не удалось разобрать JSON', <String, dynamic>{
        'jsonSnippet': _truncate(json.toString(), 500),
        'exception': e.toString(),
      });
    }
  }

  /// severity берётся из поля severity, если оно строковое и совпадает с известным значением.
  static Message parseNotification(dynamic notification, String language) {
    String? title;
    String? body;
    String? category;
    MessageSeverity severity = MessageSeverity.info;
    final extra = <String, dynamic>{};

    if (notification is Map) {
      final map = Map<String, dynamic>.from(notification);
      title = map['title']?.toString();
      body = map['body']?.toString();
      category = map['category']?.toString();

      final sevRaw = map['severity'];
      if (sevRaw is String) {
        try {
          severity = MessageSeverity.fromValue(sevRaw);
        } catch (_) {
          // Неизвестное значение - оставляем info.
        }
      }

      // Прочие ключи кладём в metadata, чтобы не терять контекст.
      for (final entry in map.entries) {
        if (const {
          'title',
          'body',
          'category',
          'severity',
        }.contains(entry.key)) {
          continue;
        }
        extra[entry.key] = entry.value;
      }
    } else if (notification != null) {
      // Универсальный путь для объектов-уведомлений: достаём поля динамически.
      try {
        final dynamic n = notification;
        title = n.title?.toString();
      } catch (_) {}
      try {
        final dynamic n = notification;
        body = n.body?.toString();
      } catch (_) {}
      try {
        final dynamic n = notification;
        category = n.category?.toString();
      } catch (_) {}
    }

    final resolvedTitle = (title == null || title.isEmpty)
        ? 'Уведомление'
        : title;
    final resolvedBody = (body == null || body.isEmpty)
        ? (notification?.toString() ?? '')
        : body;

    final metadata = <String, dynamic>{
      if (category != null) 'category': category,
      ...extra,
    };

    final message = Message(
      id: _generateUuid(),
      type: MessageType.notification,
      severity: severity,
      title: _truncate(resolvedTitle, MessageValidator.maxTitleLength),
      body: _truncate(resolvedBody, MessageValidator.maxBodyLength),
      timestamp: DateTime.now(),
      language: language,
      metadata: metadata,
    );

    final validation = MessageValidator.validate(message);
    if (!validation.isValid) {
      return _genericParseError('некорректное уведомление', <String, dynamic>{
        if (category != null) 'category': category,
        'validationErrors': validation.errors,
      });
    }
    return message;
  }

  static Message parseAiResponse(
    String content,
    String model,
    Map<String, dynamic> params,
  ) {
    final metadata = <String, dynamic>{
      'model': model,
      'params': Map<String, dynamic>.from(params),
    };
    if (params.containsKey('temperature')) {
      metadata['temperature'] = params['temperature'];
    }
    if (params.containsKey('maxTokens')) {
      metadata['maxTokens'] = params['maxTokens'];
    }

    final message = Message(
      id: _generateUuid(),
      type: MessageType.aiGenerated,
      severity: MessageSeverity.info,
      title: 'AI-генерация',
      body: _truncate(content, MessageValidator.maxBodyLength),
      timestamp: DateTime.now(),
      language: 'ru',
      metadata: metadata,
    );

    final validation = MessageValidator.validate(message);
    if (!validation.isValid) {
      return _genericParseError('некорректный ответ AI', <String, dynamic>{
        'model': model,
        'validationErrors': validation.errors,
      });
    }
    return message;
  }

  /// UUID v4 без внешних пакетов через Random.secure.
  static String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // версия 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // вариант RFC 4122

    String hex(int start, int end) {
      final sb = StringBuffer();
      for (var i = start; i < end; i++) {
        sb.write(bytes[i].toRadixString(16).padLeft(2, '0'));
      }
      return sb.toString();
    }

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  static Message _genericParseError(
    String reason,
    Map<String, dynamic> metadata,
  ) {
    final enriched = <String, dynamic>{...metadata, 'reason': reason};
    return Message(
      id: _generateUuid(),
      type: MessageType.error,
      severity: MessageSeverity.warning,
      title: 'Ошибка разбора сообщения',
      body: _truncate(
        'Не удалось разобрать сообщение: $reason',
        MessageValidator.maxBodyLength,
      ),
      code: 'PARSE_ERROR',
      timestamp: DateTime.now(),
      language: 'ru',
      metadata: enriched,
    );
  }

  static String _describeException(String runtimeName, String exceptionString) {
    final lower = runtimeName.toLowerCase();
    final trimmed = _truncate(exceptionString, 500);

    if (lower.contains('timeout')) {
      return 'Превышено время ожидания ответа сервера. $trimmed';
    }
    if (lower.contains('socket') ||
        lower.contains('handshake') ||
        lower.contains('connection')) {
      return 'Не удалось установить соединение с сервером. $trimmed';
    }
    if (lower.contains('format')) {
      return 'Неверный формат данных. $trimmed';
    }
    if (lower.contains('http')) {
      return 'Ошибка HTTP-запроса. $trimmed';
    }
    return 'Произошла ошибка ($runtimeName). $trimmed';
  }

  static String _sanitizeCode(String runtimeName) {
    final sb = StringBuffer();
    for (final code in runtimeName.toUpperCase().codeUnits) {
      final isDigit = code >= 0x30 && code <= 0x39;
      final isUpperLatin = code >= 0x41 && code <= 0x5A;
      if (isDigit || isUpperLatin) {
        sb.writeCharCode(code);
      } else {
        sb.write('_');
      }
    }
    final result = sb.toString();
    return result.isEmpty ? 'UNKNOWN' : result;
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    if (maxLength <= 3) return value.substring(0, maxLength);
    return '${value.substring(0, maxLength - 3)}...';
  }
}
