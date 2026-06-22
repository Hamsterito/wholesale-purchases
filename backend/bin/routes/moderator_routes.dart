part of '../backend.dart';

// Роуты для роли moderator (модератор):
// модерация товаров, управление категориями, закрытие чатов поддержки,
// каталог поставщиков и open-chat helper.

void _registerModeratorProductRoutes(Router router, Connection connection) {
  router.patch('/moderation/products/<id>', (Request request, String id) async {
    try {
      final productId = int.tryParse(id);
      if (productId == null) {
        return Response.badRequest(body: 'Неверный id товара');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final status = _normalizeModerationStatus(payload['status']);
      final comment = payload['comment']?.toString();

      final updated = await connection.execute(
        Sql.named('''
          UPDATE products
          SET moderation_status = @status,
              moderation_comment = @comment
          WHERE id = @id
          RETURNING *;
        '''),
        parameters: {'id': productId, 'status': status, 'comment': comment},
      );

      if (updated.isEmpty) {
        return Response.notFound('Товар не найден');
      }

      final updatedMap = updated.first.toColumnMap();
      return Response.ok(
        jsonEncode(_productRowToModerationDto(updatedMap)),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при модерации товара: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.delete('/moderation/products/<id>', (
    Request request,
    String id,
  ) async {
    try {
      final productId = int.tryParse(id);
      if (productId == null || productId <= 0) {
        return Response.badRequest(body: 'Неверный id товара');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return Response.badRequest(
          body: 'Требуются moderatorId и reason',
          headers: _utf8TextHeaders,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final moderatorId = _toPositiveInt(payload['moderatorId']);
      if (moderatorId <= 0) {
        return Response.badRequest(
          body: 'Требуется корректный moderatorId',
          headers: _utf8TextHeaders,
        );
      }

      final reason = payload['reason']?.toString().trim() ?? '';
      if (reason.isEmpty) {
        return Response.badRequest(
          body: 'Укажите причину удаления товара',
          headers: _utf8TextHeaders,
        );
      }

      final moderatorCheck = await connection.execute(
        Sql.named('SELECT role FROM users WHERE id = @id'),
        parameters: {'id': moderatorId},
      );
      if (moderatorCheck.isEmpty) {
        return Response.notFound('Модератор не найден');
      }
      final moderatorRole = _normalizeRole(
        moderatorCheck.first.toColumnMap()['role'],
      );
      if (!_isModerationActor(moderatorRole)) {
        return Response.badRequest(
          body: 'Пользователь не является модератором',
          headers: _utf8TextHeaders,
        );
      }

      final productResult = await connection.execute(
        Sql.named('SELECT * FROM products WHERE id = @id LIMIT 1'),
        parameters: {'id': productId},
      );
      if (productResult.isEmpty) {
        return Response.notFound('Товар не найден');
      }
      final productMap = productResult.first.toColumnMap();
      final productName = (productMap['name'] ?? 'Товар').toString().trim();
      final productNameKk = (productMap['name_kk'] ?? '').toString().trim();
      final normalizedReason = reason.replaceAll(RegExp(r'\s+'), ' ').trim();

      final deleted = await connection.execute(
        Sql.named('''
          DELETE FROM products
          WHERE id = @id
          RETURNING id;
        '''),
        parameters: {'id': productId},
      );
      if (deleted.isEmpty) {
        return Response.notFound('Товар не найден');
      }

      final supplierUserId = _toPositiveInt(productMap['supplier_user_id']);
      var supplierNotified = false;
      if (supplierUserId > 0) {
        // Записываем уведомление в moderation_deletions -
        // поставщик увидит баннер. Чат откроется только если он
        // сам нажмет "Обратиться в поддержку".
        await connection.execute(
          Sql.named('''
            INSERT INTO moderation_deletions (
              supplier_user_id,
              product_name,
              product_name_kk,
              reason,
              moderator_id
            )
            VALUES (
              @supplier_user_id,
              @product_name,
              @product_name_kk,
              @reason,
              @moderator_id
            );
          '''),
          parameters: {
            'supplier_user_id': supplierUserId,
            'product_name': productName,
            'product_name_kk': productNameKk,
            'reason': normalizedReason,
            'moderator_id': moderatorId,
          },
        );
        supplierNotified = true;
      }

      return Response.ok(
        jsonEncode({
          'deleted': true,
          'id': productId.toString(),
          'supplierUserId': supplierUserId > 0 ? supplierUserId : null,
          'supplierNotified': supplierNotified,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      final constraintError = _supplierProductDeleteConstraintMessage(e);
      if (constraintError != null) {
        return Response(409, body: constraintError, headers: _utf8TextHeaders);
      }
      print('Ошибка удаления товара модератором: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });
}



void _registerModeratorSupportCloseRoute(Router router, Connection connection) {
  router.patch('/moderation/support/chats/<id>/close', (
    Request request,
    String id,
  ) async {
    try {
      final chatId = int.tryParse(id);
      if (chatId == null || chatId <= 0) {
        return Response.badRequest(body: 'Неверный id чата');
      }

      final body = await request.readAsString();
      Map<String, dynamic> payload = <String, dynamic>{};
      if (body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is! Map) {
          return Response.badRequest(body: 'Ожидается JSON объект');
        }
        payload = Map<String, dynamic>.from(decoded);
      }

      final moderatorId = _toPositiveInt(payload['moderatorId']);
      if (moderatorId <= 0) {
        return Response.badRequest(body: 'Требуется корректный moderatorId');
      }

      final moderatorCheck = await connection.execute(
        Sql.named('SELECT role FROM users WHERE id = @id'),
        parameters: {'id': moderatorId},
      );
      if (moderatorCheck.isEmpty) {
        return Response.notFound('Модератор не найден');
      }
      final moderatorRole = _normalizeRole(
        moderatorCheck.first.toColumnMap()['role'],
      );
      if (!_isModerationActor(moderatorRole)) {
        return Response.badRequest(
          body: 'Пользователь не является модератором',
        );
      }

      final existing = await connection.execute(
        Sql.named('SELECT * FROM support_chats WHERE id = @id LIMIT 1'),
        parameters: {'id': chatId},
      );
      if (existing.isEmpty) {
        return Response.notFound('Чат не найден');
      }

      final current = existing.first.toColumnMap();
      if (_normalizeSupportChatStatus(current['status']) == 'closed') {
        return Response.ok(
          jsonEncode(_supportChatRowToDto(current)),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final reasonRaw = payload['reason']?.toString().trim();
      final reason = (reasonRaw == null || reasonRaw.isEmpty)
          ? null
          : reasonRaw;

      final updated = await connection.execute(
        Sql.named('''
          UPDATE support_chats
          SET
            status = 'closed',
            close_reason = COALESCE(@reason, close_reason),
            closed_at = NOW(),
            closed_by_user_id = @closed_by_user_id,
            updated_at = NOW()
          WHERE id = @id
          RETURNING *;
        '''),
        parameters: {
          'id': chatId,
          'reason': reason,
          'closed_by_user_id': moderatorId,
        },
      );
      if (updated.isEmpty) {
        return Response.internalServerError(body: 'Не удалось закрыть чат');
      }

      final updatedMap = updated.first.toColumnMap();
      _emitSupportEvent(
        kind: 'chat_closed',
        userId: _toPositiveInt(updatedMap['user_id']),
        chatId: _toPositiveInt(updatedMap['id']),
        reason: updatedMap['close_reason']?.toString(),
        actorUserId: moderatorId,
      );

      return Response.ok(
        jsonEncode(_supportChatRowToDto(updatedMap)),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка закрытия чата поддержки: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });
}

void _registerSupplierDirectoryRoute(Router router, Connection connection) {
  // GET /moderation/suppliers - каталог верифицированных поставщиков.
  // Доступ только moderator/super_admin (userId из query или X-User-Id).
  router.get('/moderation/suppliers', (Request request) async {
    final actor = await _resolveModerationActor(request, connection);
    if (actor is Response) return actor;

    final params = request.url.queryParameters;
    final offset = _toPositiveInt(params['offset']);
    final limitRaw = _toPositiveInt(params['limit'], fallback: 50);
    final limit = limitRaw <= 0 ? 50 : (limitRaw > 200 ? 200 : limitRaw);
    final query = params['query']?.trim() ?? '';

    try {
      final whereParts = <String>[
        "u.role = 'supplier'",
        "COALESCE(u.is_verified, FALSE) = TRUE",
      ];
      final args = <String, Object?>{'limit': limit, 'offset': offset};
      if (query.isNotEmpty) {
        whereParts.add(
          '(LOWER(COALESCE(u.supplier_name, \'\')) LIKE @q '
          'OR LOWER(COALESCE(u.name, \'\')) LIKE @q)',
        );
        args['q'] = '%${query.toLowerCase()}%';
      }
      final whereSql = whereParts.join(' AND ');

      final itemsResult = await connection.execute(
        Sql.named('''
          SELECT u.id, u.name, u.email, u.supplier_name, u.avatar_url
          FROM public.users u
          WHERE $whereSql
          ORDER BY
            COALESCE(NULLIF(u.supplier_name, ''), u.name) ASC,
            u.id ASC
          LIMIT @limit OFFSET @offset
        '''),
        parameters: args,
      );

      final countArgs = Map<String, Object?>.from(args)
        ..remove('limit')
        ..remove('offset');
      final countResult = await connection.execute(
        Sql.named(
          'SELECT COUNT(*) AS total FROM public.users u WHERE $whereSql',
        ),
        parameters: countArgs,
      );
      final total = _toPositiveInt(countResult.first.toColumnMap()['total']);

      final items = itemsResult.map((row) {
        final m = row.toColumnMap();
        final id = _toPositiveInt(m['id']);
        final name = m['name']?.toString() ?? '';
        final email = m['email']?.toString() ?? '';
        final supplierName = m['supplier_name']?.toString() ?? '';
        final companyName = supplierName.isNotEmpty ? supplierName : name;
        return <String, dynamic>{
          'supplierId': id,
          'displayName': name,
          'companyName': companyName,
          if (email.isNotEmpty) 'email': email,
          'avatarUrl': _avatarUrlOrNull(request, m['avatar_url']),
        };
      }).toList();

      return Response.ok(
        jsonEncode({
          'items': items,
          'total': total,
          'offset': offset,
          'limit': limit,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при получении каталога поставщиков: $e\n$st');
      return _jsonError('Не удалось получить каталог поставщиков', 500);
    }
  });

  // POST /moderation/support/chats/find-or-create - открывает support_chat.
  // Тело: {moderatorId, userId, peek?}.
  //
  // peek != true: возвращает существующий открытый чат или создаёт новый.
  // peek == true: только проверка - отдаёт открытый чат или 404
  // {code: "no_open_chat"}. Нужно UI для диалога подтверждения создания.
  router.post('/moderation/support/chats/find-or-create', (
    Request request,
  ) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидался JSON-объект');
      }
      final payload = Map<String, dynamic>.from(decoded);
      final moderatorId = _toPositiveInt(payload['moderatorId']);
      final targetUserId = _toPositiveInt(payload['userId']);
      final peek = payload['peek'] == true;
      if (moderatorId <= 0 || targetUserId <= 0) {
        return Response.badRequest(body: 'moderatorId и userId обязательны');
      }

      final moderatorRole = await _resolveUserRoleById(connection, moderatorId);
      if (moderatorRole != 'moderator' && moderatorRole != 'super_admin') {
        return Response(
          403,
          body: jsonEncode({
            'code': 'FORBIDDEN',
            'message': 'Доступ только для модератора',
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final targetRow = await connection.execute(
        Sql.named(
          'SELECT id, role, is_verified FROM public.users WHERE id = @id LIMIT 1;',
        ),
        parameters: {'id': targetUserId},
      );
      if (targetRow.isEmpty) {
        return Response.notFound('Пользователь не найден');
      }

      // Ищем уже открытый чат пользователя - частичный уникальный индекс
      // uq_support_chats_open_user гарантирует не больше одного.
      final existingRow = await connection.execute(
        Sql.named('''
          SELECT * FROM public.support_chats
          WHERE user_id = @uid AND status = 'open'
          LIMIT 1
        '''),
        parameters: {'uid': targetUserId},
      );

      if (existingRow.isNotEmpty) {
        return Response.ok(
          jsonEncode(_supportChatRowToDto(existingRow.first.toColumnMap())),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      // peek-режим: открытого чата нет - отдаём 404, не создавая.
      if (peek) {
        return Response(
          404,
          body: jsonEncode({
            'code': 'no_open_chat',
            'message': 'Открытого чата нет',
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final created = await connection.execute(
        Sql.named('''
          INSERT INTO public.support_chats (user_id, status)
          VALUES (@uid, 'open')
          RETURNING *
        '''),
        parameters: {'uid': targetUserId},
      );
      final chat = created.first.toColumnMap();

      return Response.ok(
        jsonEncode(_supportChatRowToDto(chat)),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Некорректный JSON');
    } catch (e, st) {
      print('Ошибка при find-or-create support_chat: $e\n$st');
      return _jsonError('Не удалось открыть чат с пользователем', 500);
    }
  });
}

// Берёт роль пользователя по id. Используется в каталоге поставщиков и

// GET-роуты модерации: список товаров и категорий.

void _registerModeratorReadRoutes(Router router, Connection connection) {
  router.get('/moderation/products', (Request request) async {
    try {
      final status = request.url.queryParameters['status'];
      final normalized = status == null || status == 'all'
          ? 'all'
          : _normalizeModerationStatus(status, fallback: 'pending');

      final result = normalized == 'all'
          ? await connection.execute('SELECT * FROM products ORDER BY id DESC;')
          : await connection.execute(
              Sql.named(
                'SELECT * FROM products WHERE moderation_status = @status ORDER BY id DESC;',
              ),
              parameters: {'status': normalized},
            );

      final products = result
          .map((row) => _productRowToModerationDto(row.toColumnMap()))
          .toList();

      return Response.ok(
        jsonEncode(products),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });


}
