import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/message.dart';
import '../../models/support_message.dart';
import 'message_parser.dart';

/// Обёртка над HTTP-ответами и ошибками `ApiService`.
class ApiServiceAdapter {
  /// Поля JSON-тела, которые нельзя сохранять в логах для чат-эндпоинтов:
  /// текст сообщения и идентифицирующая контактная информация поставщика.
  static const _chatRedactedFields = {'body', 'email', 'displayName'};

  /// Префикс эндпоинта, при совпадении с которым включается редакция чат-полей.
  static const _chatEndpointPrefix = '/chats/';

  static Message wrapApiResponse(
    http.Response response,
    String language, {
    String? endpoint,
    String? method,
  }) {
    final sanitized = _isChatEndpoint(endpoint)
        ? _redactChatResponseBody(response)
        : response;
    return MessageParser.parseApiResponse(
      sanitized,
      language,
      endpoint: endpoint,
      method: method,
    );
  }

  // Парсер не знает про endpoint/method — добавляем их сами.
  static Message wrapApiError(
    Object e,
    StackTrace? stack,
    String language, {
    String? endpoint,
    String? method,
  }) {
    final base = MessageParser.parseException(e, stack, language);

    final shouldRedact = _isChatEndpoint(endpoint);
    if (endpoint == null && method == null && !shouldRedact) return base;

    final mergedMetadata = <String, dynamic>{
      ...base.metadata,
      if (endpoint != null) 'endpoint': endpoint,
      if (method != null) 'method': method,
    };

    if (shouldRedact) {
      // Затираем возможные упоминания текста сообщения и контактной
      // информации, которые могли просочиться в строку исключения.
      final redactedBody = _redactPlainText(base.body);
      final redactedException = mergedMetadata['exceptionMessage'];
      if (redactedException is String) {
        mergedMetadata['exceptionMessage'] = _redactPlainText(
          redactedException,
        );
      }
      return base.copyWith(body: redactedBody, metadata: mergedMetadata);
    }

    return base.copyWith(metadata: mergedMetadata);
  }

  static bool _isChatEndpoint(String? endpoint) {
    return endpoint != null && endpoint.startsWith(_chatEndpointPrefix);
  }

  /// Возвращает копию ответа с JSON-телом, в котором значения чувствительных
  /// полей заменены на `[redacted]`. Если тело не JSON или пустое — возвращает
  /// исходный ответ как есть.
  static http.Response _redactChatResponseBody(http.Response response) {
    final raw = response.body;
    if (raw.isEmpty) return response;
    try {
      final decoded = jsonDecode(raw);
      final redacted = _redactJsonNode(decoded);
      final rebuilt = jsonEncode(redacted);
      return http.Response(
        rebuilt,
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        request: response.request,
      );
    } catch (_) {
      // Не JSON — на всякий случай прогоняем через текстовую редакцию,
      // чтобы исключить эхо чувствительных значений.
      return http.Response(
        _redactPlainText(raw),
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        request: response.request,
      );
    }
  }

  static dynamic _redactJsonNode(dynamic node) {
    if (node is Map) {
      final result = <String, dynamic>{};
      for (final entry in node.entries) {
        final key = entry.key.toString();
        if (_chatRedactedFields.contains(key)) {
          result[key] = '[redacted]';
        } else {
          result[key] = _redactJsonNode(entry.value);
        }
      }
      return result;
    }
    if (node is List) {
      return node.map(_redactJsonNode).toList();
    }
    return node;
  }

  /// Грубая текстовая редакция для строк, в которых не разобрать JSON
  /// (например, текст исключения с эхом тела запроса). Ищем токены вида
  /// `"body":"..."`, `"email":"..."`, `"displayName":"..."` и обрезаем их.
  static String _redactPlainText(String text) {
    var result = text;
    for (final field in _chatRedactedFields) {
      // Совпадает с JSON-парой "field":"<любые символы, включая \">".
      final pattern = RegExp(
        '"$field"\\s*:\\s*"(?:[^"\\\\]|\\\\.)*"',
        caseSensitive: false,
      );
      result = result.replaceAll(pattern, '"$field":"[redacted]"');
    }
    return result;
  }
}

/// Обёртка над уведомлениями `NotificationService`.
class NotificationServiceAdapter {
  // Категория из самого уведомления имеет приоритет над переданным параметром.
  static Message wrapNotification(
    dynamic notification,
    String language, {
    String? category,
  }) {
    final base = MessageParser.parseNotification(notification, language);
    final hasCategory = base.metadata.containsKey('category');
    if (hasCategory || category == null) return base;

    final mergedMetadata = <String, dynamic>{
      ...base.metadata,
      'category': category,
    };
    return base.copyWith(metadata: mergedMetadata);
  }
}

/// Обёртка над ответами и ошибками AI-моделей.
class AiServiceAdapter {
  static Message wrapAiResponse(
    String content,
    String model,
    Map<String, dynamic> params,
  ) {
    return MessageParser.parseAiResponse(content, model, params);
  }

  static Message wrapAiError(
    Object e,
    StackTrace? stack,
    String language, {
    String? model,
  }) {
    final base = MessageParser.parseException(e, stack, language);
    if (model == null) return base;

    final mergedMetadata = <String, dynamic>{...base.metadata, 'model': model};
    return base.copyWith(metadata: mergedMetadata);
  }
}

/// Двунаправленная конвертация между [SupportMessage] и [Message].
class SupportChatAdapter {
  static Message fromSupportMessage(SupportMessage msg) {
    return MessageParser.parseSupportMessage(msg);
  }

  // originalId в metadata — оригинальный id, если он не подошёл под формат UUID.
  static SupportMessage toSupportMessage(Message msg) {
    final metadata = msg.metadata;

    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value.toString());
    }

    final senderRoleRaw = metadata['senderRole']?.toString().toLowerCase();
    final senderRole = senderRoleRaw == 'moderator' ? 'moderator' : 'user';

    final originalId = metadata['originalId']?.toString();
    final id = (originalId != null && originalId.isNotEmpty)
        ? originalId
        : msg.id;

    return SupportMessage(
      id: id,
      chatId: parseInt(metadata['chatId']),
      userId: parseInt(metadata['userId']),
      senderRole: senderRole,
      senderUserId: parseNullableInt(metadata['senderUserId']),
      category: metadata['category']?.toString() ?? '',
      subject: msg.title,
      text: msg.body,
      createdAt: msg.timestamp,
    );
  }
}
