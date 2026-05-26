part of '../backend.dart';

// Хелперы для поддержки: SSE-стрим событий, нормализация ролей и статусов
// чатов, DTO-мапперы и загрузка чатов/сообщений по ключу.

void _emitSupportEvent({
  required String kind,
  required int userId,
  int? chatId,
  int? messageId,
  String? senderRole,
  String? reason,
  int? actorUserId,
}) {
  if (_supportEventsController.isClosed) return;

  final event = <String, dynamic>{
    'kind': kind,
    'userId': userId,
    if (chatId != null && chatId > 0) 'chatId': chatId,
    if (messageId != null && messageId > 0) 'messageId': messageId,
    if (senderRole != null && senderRole.isNotEmpty) 'senderRole': senderRole,
    if (reason != null && reason.isNotEmpty) 'reason': reason,
    if (actorUserId != null && actorUserId > 0) 'actorUserId': actorUserId,
    'timestamp': DateTime.now().toIso8601String(),
  };
  _supportEventsController.add(event);
}

Response _buildSupportEventsResponse({
  required String scope,
  required bool Function(Map<String, dynamic>) filter,
}) {
  final controller = StreamController<List<int>>();
  StreamSubscription<Map<String, dynamic>>? subscription;
  Timer? keepAlive;
  var closed = false;

  void pushFrame(String payload, {String event = 'support'}) {
    if (closed) return;
    final buffer = StringBuffer();
    if (event.isNotEmpty) {
      buffer.writeln('event: $event');
    }
    for (final line in payload.split('\n')) {
      buffer.writeln('data: $line');
    }
    buffer.writeln();
    controller.add(utf8.encode(buffer.toString()));
  }

  Future<void> shutdown() async {
    if (closed) return;
    closed = true;
    keepAlive?.cancel();
    await subscription?.cancel();
    await controller.close();
  }

  controller.onListen = () {
    pushFrame(
      jsonEncode({
        'kind': 'connected',
        'scope': scope,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      event: 'connected',
    );

    subscription = _supportEventsController.stream.listen(
      (event) {
        if (!filter(event)) return;
        pushFrame(jsonEncode(event));
      },
      onError: (_) {
        if (!closed) {
          controller.add(utf8.encode(': stream-error\n\n'));
        }
      },
    );

    keepAlive = Timer.periodic(const Duration(seconds: 20), (_) {
      if (closed) return;
      controller.add(utf8.encode(': keep-alive\n\n'));
    });
  };

  controller.onCancel = shutdown;

  return Response.ok(
    controller.stream,
    headers: {
      'content-type': 'text/event-stream; charset=utf-8',
      'cache-control': 'no-cache',
      'connection': 'keep-alive',
      'x-accel-buffering': 'no',
    },
  );
}

String _normalizeSupportSenderRole(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == 'moderator') {
    return 'moderator';
  }
  return 'user';
}

String _normalizeSupportChatStatus(Object? value, {String fallback = 'open'}) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return fallback;
  if (_allowedSupportChatStatuses.contains(raw)) return raw;
  return fallback;
}

Map<String, dynamic> _supportChatRowToDto(Map<String, dynamic> map) {
  String? createdAtIso;
  String? updatedAtIso;
  String? closedAtIso;

  final createdAt = map['created_at'];
  if (createdAt is DateTime) {
    createdAtIso = createdAt.toIso8601String();
  }

  final updatedAt = map['updated_at'];
  if (updatedAt is DateTime) {
    updatedAtIso = updatedAt.toIso8601String();
  }

  final closedAt = map['closed_at'];
  if (closedAt is DateTime) {
    closedAtIso = closedAt.toIso8601String();
  }

  return {
    'id': _toPositiveInt(map['id']),
    'userId': _toPositiveInt(map['user_id']),
    'status': _normalizeSupportChatStatus(map['status']),
    'category': map['category'] ?? '',
    'subject': map['subject'] ?? '',
    'closeReason': map['close_reason'] ?? '',
    'closedByUserId': _toNullablePositiveInt(map['closed_by_user_id']),
    if (createdAtIso != null) 'createdAt': createdAtIso,
    if (updatedAtIso != null) 'updatedAt': updatedAtIso,
    if (closedAtIso != null) 'closedAt': closedAtIso,
  };
}

Map<String, dynamic> _supportMessageRowToDto(Map<String, dynamic> map) {
  String? createdAtIso;
  final createdAt = map['created_at'];
  if (createdAt is DateTime) {
    createdAtIso = createdAt.toIso8601String();
  }

  return {
    'id': map['id']?.toString() ?? '',
    'chatId': _toPositiveInt(map['chat_id']),
    'userId': _toPositiveInt(map['user_id']),
    'senderRole': _normalizeSupportSenderRole(map['sender_role']),
    'senderUserId': _toNullablePositiveInt(map['sender_user_id']),
    'category': map['category'] ?? '',
    'subject': map['subject'] ?? '',
    'text': map['message_text'] ?? '',
    if (createdAtIso != null) 'createdAt': createdAtIso,
  };
}

Future<List<Map<String, dynamic>>> _loadSupportMessagesByChat(
  Connection connection,
  int chatId,
) async {
  final result = await connection.execute(
    Sql.named('''
      SELECT *
      FROM support_messages
      WHERE chat_id = @chat_id
      ORDER BY id ASC;
    '''),
    parameters: {'chat_id': chatId},
  );
  return result
      .map((row) => _supportMessageRowToDto(row.toColumnMap()))
      .toList();
}

Future<Map<String, dynamic>?> _loadSupportChatById(
  Connection connection,
  int chatId, {
  int? userId,
}) async {
  final result = userId == null
      ? await connection.execute(
          Sql.named('''
            SELECT *
            FROM support_chats
            WHERE id = @chat_id
            LIMIT 1;
          '''),
          parameters: {'chat_id': chatId},
        )
      : await connection.execute(
          Sql.named('''
            SELECT *
            FROM support_chats
            WHERE id = @chat_id
              AND user_id = @user_id
            LIMIT 1;
          '''),
          parameters: {'chat_id': chatId, 'user_id': userId},
        );
  if (result.isEmpty) return null;
  return result.first.toColumnMap();
}

Future<Map<String, dynamic>?> _loadPreferredSupportChatForUser(
  Connection connection,
  int userId, {
  int? chatId,
}) async {
  if (chatId != null && chatId > 0) {
    return _loadSupportChatById(connection, chatId, userId: userId);
  }

  final result = await connection.execute(
    Sql.named('''
      SELECT *
      FROM support_chats
      WHERE user_id = @user_id
      ORDER BY
        CASE WHEN status = 'open' THEN 0 ELSE 1 END ASC,
        updated_at DESC,
        id DESC
      LIMIT 1;
    '''),
    parameters: {'user_id': userId},
  );
  if (result.isEmpty) return null;
  return result.first.toColumnMap();
}

Future<Map<String, dynamic>> _loadSupportThreadForUser(
  Connection connection,
  int userId, {
  int? chatId,
}) async {
  final chatMap = await _loadPreferredSupportChatForUser(
    connection,
    userId,
    chatId: chatId,
  );
  if (chatMap == null) {
    return {'chat': null, 'messages': <Map<String, dynamic>>[]};
  }

  final resolvedChatId = _toPositiveInt(chatMap['id']);
  final messages = resolvedChatId > 0
      ? await _loadSupportMessagesByChat(connection, resolvedChatId)
      : <Map<String, dynamic>>[];

  return {'chat': _supportChatRowToDto(chatMap), 'messages': messages};
}
