import 'package:http/http.dart' as http;

import '../../models/message.dart';
import '../../models/support_message.dart';
import 'message_parser.dart';

/// Обёртка над HTTP-ответами и ошибками `ApiService`.
class ApiServiceAdapter {
  static Message wrapApiResponse(
    http.Response response,
    String language, {
    String? endpoint,
    String? method,
  }) {
    return MessageParser.parseApiResponse(
      response,
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
    if (endpoint == null && method == null) return base;

    final mergedMetadata = <String, dynamic>{
      ...base.metadata,
      if (endpoint != null) 'endpoint': endpoint,
      if (method != null) 'method': method,
    };
    return base.copyWith(metadata: mergedMetadata);
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
