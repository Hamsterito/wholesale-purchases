part of '../backend.dart';

// Роут отправки сообщений в поддержку.
// Доступен для всех ролей.

void _registerSupportMessageRoute(Router router, Connection connection) {
  router.post('/support/messages', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final userId = _toPositiveInt(payload['userId']);
      if (userId <= 0) {
        return Response.badRequest(body: 'Требуется корректный userId');
      }

      final text = payload['text']?.toString().trim() ?? '';
      if (text.isEmpty) {
        return Response.badRequest(body: 'Текст сообщения обязателен');
      }

      final senderRole = _normalizeSupportSenderRole(payload['senderRole']);
      var senderUserId = _toNullablePositiveInt(payload['senderUserId']);
      if (senderRole == 'user') {
        senderUserId = userId;
      }

      final userCheck = await connection.execute(
        Sql.named('SELECT id FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userCheck.isEmpty) {
        return Response.notFound('Пользователь не найден');
      }

      if (senderRole == 'moderator') {
        if (senderUserId == null || senderUserId <= 0) {
          return Response.badRequest(
            body: 'Для сообщения модератора требуется senderUserId',
          );
        }
        final moderatorCheck = await connection.execute(
          Sql.named('SELECT role FROM users WHERE id = @id'),
          parameters: {'id': senderUserId},
        );
        if (moderatorCheck.isEmpty) {
          return Response.notFound('Модератор не найден');
        }
        final moderatorRole = _normalizeRole(
          moderatorCheck.first.toColumnMap()['role'],
        );
        if (!_isModerationActor(moderatorRole)) {
          return Response.badRequest(
            body: 'Пользователь senderUserId не является модератором',
          );
        }
      }

      final providedChatId = _toNullablePositiveInt(payload['chatId']);
      final categoryRaw = payload['category']?.toString().trim();
      final subjectRaw = payload['subject']?.toString().trim();
      final category = (categoryRaw == null || categoryRaw.isEmpty)
          ? null
          : categoryRaw;
      final subject = (subjectRaw == null || subjectRaw.isEmpty)
          ? null
          : subjectRaw;

      Map<String, dynamic>? chatMap;
      if (providedChatId != null && providedChatId > 0) {
        final chatResult = await connection.execute(
          Sql.named('''
            SELECT *
            FROM support_chats
            WHERE id = @chat_id
              AND user_id = @user_id
            LIMIT 1;
          '''),
          parameters: {'chat_id': providedChatId, 'user_id': userId},
        );
        if (chatResult.isEmpty) {
          return Response.badRequest(
            body: 'Чат не найден или не принадлежит пользователю',
          );
        }
        chatMap = chatResult.first.toColumnMap();
      } else {
        final openChatResult = await connection.execute(
          Sql.named('''
            SELECT *
            FROM support_chats
            WHERE user_id = @user_id
              AND status = 'open'
            ORDER BY id DESC
            LIMIT 1;
          '''),
          parameters: {'user_id': userId},
        );
        if (openChatResult.isNotEmpty) {
          chatMap = openChatResult.first.toColumnMap();
        }
      }

      if (chatMap != null &&
          _normalizeSupportChatStatus(chatMap['status']) == 'closed') {
        if (senderRole == 'moderator') {
          return Response.badRequest(body: 'Чат закрыт. Отправка невозможна');
        }
        chatMap = null;
      }

      if (chatMap == null) {
        if (senderRole == 'moderator') {
          return Response.badRequest(
            body: 'Для ответа модератора требуется открытый чат',
          );
        }
        // category и subject опциональны - если переданы, проставляем,
        // иначе сохраняем NULL.
        final createdChat = await connection.execute(
          Sql.named('''
            INSERT INTO support_chats (
              user_id,
              status,
              category,
              subject
            )
            VALUES (
              @user_id,
              'open',
              @category,
              @subject
            )
            RETURNING *;
          '''),
          parameters: {
            'user_id': userId,
            'category': category,
            'subject': subject,
          },
        );
        if (createdChat.isEmpty) {
          return Response.internalServerError(
            body: 'Не удалось создать чат поддержки',
          );
        }
        chatMap = createdChat.first.toColumnMap();
      }

      final chatId = _toPositiveInt(chatMap['id']);
      if (chatId <= 0) {
        return Response.internalServerError(body: 'Некорректный chatId');
      }

      // category и subject опциональны: если пришли - используем, иначе
      // наследуем из чата. NULL валиден.
      final effectiveCategory =
          category ?? _normalizeOptionalText(chatMap['category']);
      final effectiveSubject =
          subject ?? _normalizeOptionalText(chatMap['subject']);

      final inserted = await connection.execute(
        Sql.named('''
          INSERT INTO support_messages (
            chat_id,
            user_id,
            sender_role,
            sender_user_id,
            category,
            subject,
            message_text
          )
          VALUES (
            @chat_id,
            @user_id,
            @sender_role,
            @sender_user_id,
            @category,
            @subject,
            @message_text
          )
          RETURNING *;
        '''),
        parameters: {
          'chat_id': chatId,
          'user_id': userId,
          'sender_role': senderRole,
          'sender_user_id': senderUserId,
          'category': effectiveCategory,
          'subject': effectiveSubject,
          'message_text': text,
        },
      );

      if (inserted.isEmpty) {
        return Response.internalServerError(
          body: 'Не удалось создать сообщение',
        );
      }

      await connection.execute(
        Sql.named('''
          UPDATE support_chats
          SET
            category = COALESCE(category, @category),
            subject = COALESCE(subject, @subject),
            updated_at = NOW()
          WHERE id = @chat_id;
        '''),
        parameters: {
          'chat_id': chatId,
          'category': effectiveCategory,
          'subject': effectiveSubject,
        },
      );

      final insertedDto = _supportMessageRowToDto(inserted.first.toColumnMap());
      _emitSupportEvent(
        kind: 'message',
        userId: _toPositiveInt(insertedDto['userId']),
        chatId: _toPositiveInt(insertedDto['chatId']),
        messageId: _toPositiveInt(insertedDto['id']),
        senderRole: insertedDto['senderRole']?.toString(),
      );

      return Response(
        201,
        body: jsonEncode(insertedDto),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка создания сообщения поддержки: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });
}

// GET-роуты поддержки: thread/events/messages для пользователя и модератора.

void _registerSupportReadRoutes(Router router, Connection connection) {
  router.get('/support/thread', (Request request) async {
    try {
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(
          body: 'Идентификатор пользователя указан некорректно',
        );
      }

      final chatIdRaw = request.url.queryParameters['chatId'];
      final chatId = chatIdRaw == null ? null : int.tryParse(chatIdRaw);
      if (chatIdRaw != null && (chatId == null || chatId <= 0)) {
        return Response.badRequest(body: 'chatId обязателен');
      }

      final thread = await _loadSupportThreadForUser(
        connection,
        userId,
        chatId: chatId,
      );
      return Response.ok(
        jsonEncode(thread),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/support/events', (Request request) async {
    final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
    if (userId == null || userId <= 0) {
      return Response.badRequest(
        body: 'Идентификатор пользователя указан некорректно',
      );
    }

    final chatIdRaw = request.url.queryParameters['chatId'];
    final chatId = chatIdRaw == null ? null : int.tryParse(chatIdRaw);
    if (chatIdRaw != null && (chatId == null || chatId <= 0)) {
      return Response.badRequest(body: 'chatId обязателен');
    }

    return _buildSupportEventsResponse(
      scope: 'user',
      filter: (event) {
        if (_toPositiveInt(event['userId']) != userId) return false;
        if (chatId != null && _toPositiveInt(event['chatId']) != chatId) {
          return false;
        }
        return true;
      },
    );
  });

  router.get('/support/messages', (Request request) async {
    try {
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(
          body: 'Идентификатор пользователя указан некорректно',
        );
      }

      final chatIdRaw = request.url.queryParameters['chatId'];
      final chatId = chatIdRaw == null ? null : int.tryParse(chatIdRaw);
      if (chatIdRaw != null && (chatId == null || chatId <= 0)) {
        return Response.badRequest(body: 'chatId обязателен');
      }

      final chat = await _loadPreferredSupportChatForUser(
        connection,
        userId,
        chatId: chatId,
      );
      final messages = chat == null
          ? <Map<String, dynamic>>[]
          : await _loadSupportMessagesByChat(
              connection,
              _toPositiveInt(chat['id']),
            );
      return Response.ok(
        jsonEncode(messages),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/moderation/support/chats', (Request request) async {
    try {
      final result = await connection.execute('''
        SELECT
          sc.id AS chat_id,
          sc.user_id,
          sc.status,
          sc.category AS chat_category,
          sc.subject AS chat_subject,
          sc.close_reason,
          sc.created_at AS chat_created_at,
          sc.updated_at AS chat_updated_at,
          sc.closed_at,
          sc.closed_by_user_id,
          lm.message_text AS last_message,
          lm.sender_role AS last_sender_role,
          lm.created_at AS last_message_at,
          u.name AS user_name,
          u.email AS user_email,
          u.role AS user_role,
          u.supplier_name
        FROM support_chats sc
        JOIN users u ON u.id = sc.user_id
        LEFT JOIN LATERAL (
          SELECT
            message_text,
            sender_role,
            created_at
          FROM support_messages sm
          WHERE sm.chat_id = sc.id
          ORDER BY sm.id DESC
          LIMIT 1
        ) lm ON TRUE
        ORDER BY
          CASE WHEN sc.status = 'open' THEN 0 ELSE 1 END ASC,
          COALESCE(lm.created_at, sc.updated_at, sc.created_at) DESC,
          sc.id DESC;
      ''');

      final chats = result.map((row) {
        final map = row.toColumnMap();
        final lastMessageAtRaw =
            map['last_message_at'] ??
            map['chat_updated_at'] ??
            map['chat_created_at'];
        String? lastMessageAtIso;
        if (lastMessageAtRaw is DateTime) {
          lastMessageAtIso = lastMessageAtRaw.toIso8601String();
        }

        final chatDto = _supportChatRowToDto({
          'id': map['chat_id'],
          'user_id': map['user_id'],
          'status': map['status'],
          'category': map['chat_category'],
          'subject': map['chat_subject'],
          'close_reason': map['close_reason'],
          'created_at': map['chat_created_at'],
          'updated_at': map['chat_updated_at'],
          'closed_at': map['closed_at'],
          'closed_by_user_id': map['closed_by_user_id'],
        });

        final createdAtIso = chatDto['createdAt']?.toString();
        final closedAtIso = chatDto['closedAt']?.toString();

        return {
          'chatId': _toPositiveInt(map['chat_id']),
          'userId': _toPositiveInt(map['user_id']),
          'status': chatDto['status'] ?? 'open',
          'category': chatDto['category'] ?? '',
          'subject': chatDto['subject'] ?? '',
          'closeReason': chatDto['closeReason'] ?? '',
          'userName': map['user_name'] ?? '',
          'userEmail': map['user_email'] ?? '',
          'userRole': map['user_role'] ?? _defaultRole,
          'supplierName': map['supplier_name'] ?? '',
          'lastMessage': map['last_message'] ?? '',
          'lastSenderRole': _normalizeSupportSenderRole(
            map['last_sender_role'],
          ),
          if (createdAtIso != null) 'createdAt': createdAtIso,
          if (lastMessageAtIso != null) 'lastMessageAt': lastMessageAtIso,
          if (closedAtIso != null) 'closedAt': closedAtIso,
        };
      }).toList();

      return Response.ok(
        jsonEncode(chats),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/moderation/support/events', (Request request) async {
    final chatIdRaw = request.url.queryParameters['chatId'];
    final chatId = chatIdRaw == null ? null : int.tryParse(chatIdRaw);
    if (chatIdRaw != null && (chatId == null || chatId <= 0)) {
      return Response.badRequest(body: 'chatId обязателен');
    }

    return _buildSupportEventsResponse(
      scope: 'moderator',
      filter: (event) {
        if (chatId != null && _toPositiveInt(event['chatId']) != chatId) {
          return false;
        }
        return true;
      },
    );
  });

  router.get('/moderation/support/messages/<id>', (
    Request request,
    String id,
  ) async {
    try {
      final parsedId = int.tryParse(id);
      if (parsedId == null || parsedId <= 0) {
        return Response.badRequest(body: 'Некорректный идентификатор');
      }

      final directChat = await _loadSupportChatById(connection, parsedId);
      final chat =
          directChat ??
          await _loadPreferredSupportChatForUser(connection, parsedId);
      if (chat == null) {
        return Response.ok(
          jsonEncode(<Map<String, dynamic>>[]),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final chatId = _toPositiveInt(chat['id']);
      final messages = chatId <= 0
          ? <Map<String, dynamic>>[]
          : await _loadSupportMessagesByChat(connection, chatId);
      return Response.ok(
        jsonEncode(messages),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/moderation/support/thread/<id>', (
    Request request,
    String id,
  ) async {
    try {
      final chatId = int.tryParse(id);
      if (chatId == null || chatId <= 0) {
        return Response.badRequest(body: 'chatId обязателен');
      }

      final chat = await _loadSupportChatById(connection, chatId);
      if (chat == null) {
        return Response.notFound('chatId обязателен');
      }

      final messages = await _loadSupportMessagesByChat(connection, chatId);
      return Response.ok(
        jsonEncode({'chat': _supportChatRowToDto(chat), 'messages': messages}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });
}
