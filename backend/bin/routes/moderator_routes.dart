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
      final normalizedReason = reason.replaceAll(RegExp(r'\s+'), ' ').trim();
      final moderationComment = 'Удалено модератором: $normalizedReason';

      Future<bool> hideFromCatalog() async {
        final updated = await connection.execute(
          Sql.named('''
            UPDATE products
            SET moderation_status = 'rejected',
                moderation_comment = @comment,
                stock_quantity = 0
            WHERE id = @id
            RETURNING id;
          '''),
          parameters: {'id': productId, 'comment': moderationComment},
        );
        return updated.isNotEmpty;
      }

      final linkedOrders = await connection.execute(
        Sql.named('''
          SELECT o.status
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          WHERE oi.product_id = @id;
        '''),
        parameters: {'id': productId},
      );
      final hasUnacceptedOrders = linkedOrders.any((row) {
        final status = row.toColumnMap()['status'];
        return !_isAcceptedOrderStatus(status) &&
            !_isCancelledOrderStatus(status);
      });

      var action = 'hard_deleted';
      if (hasUnacceptedOrders) {
        final hidden = await hideFromCatalog();
        if (!hidden) {
          return Response.notFound('Товар не найден');
        }
        action = 'hidden_from_catalog';
      } else {
        try {
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
        } catch (e) {
          final constraintError = _supplierProductDeleteConstraintMessage(e);
          if (constraintError == null) {
            rethrow;
          }
          final hidden = await hideFromCatalog();
          if (!hidden) {
            return Response.notFound('Товар не найден');
          }
          action = 'hidden_from_catalog';
        }
      }

      final supplierUserId = _toPositiveInt(productMap['supplier_user_id']);
      var supplierNotified = false;
      if (supplierUserId > 0) {
        var chatMap = await _loadPreferredSupportChatForUser(
          connection,
          supplierUserId,
        );
        final hasOpenChat =
            chatMap != null &&
            _normalizeSupportChatStatus(chatMap['status']) == 'open';
        if (!hasOpenChat) {
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
              'user_id': supplierUserId,
              'category': 'Модерация товаров',
              'subject': 'Действие по товару за нарушение',
            },
          );
          if (createdChat.isNotEmpty) {
            chatMap = createdChat.first.toColumnMap();
          }
        }

        final chatId = chatMap == null ? 0 : _toPositiveInt(chatMap['id']);
        if (chatId > 0) {
          final resolvedChatMap = chatMap!;
          final category =
              _normalizeOptionalText(resolvedChatMap['category']) ??
              'Модерация товаров';
          final subject =
              _normalizeOptionalText(resolvedChatMap['subject']) ??
              'Действие по товару за нарушение';
          final notificationText = action == 'hidden_from_catalog'
              ? 'Товар "$productName" снят с публикации модератором за нарушение. '
                    'Причина: $normalizedReason'
              : 'Товар "$productName" удален модератором за нарушение. '
                    'Причина: $normalizedReason';

          final insertedMessage = await connection.execute(
            Sql.named('''
              WITH inserted AS (
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
                  'moderator',
                  @sender_user_id,
                  @category,
                  @subject,
                  @message_text
                )
                RETURNING *
              )
              SELECT i.*, u.avatar_url AS sender_avatar_url
              FROM inserted i
              LEFT JOIN public.users u ON u.id = i.sender_user_id;
            '''),
            parameters: {
              'chat_id': chatId,
              'user_id': supplierUserId,
              'sender_user_id': moderatorId,
              'category': category,
              'subject': subject,
              'message_text': notificationText,
            },
          );
          if (insertedMessage.isNotEmpty) {
            await connection.execute(
              Sql.named('''
                UPDATE support_chats
                SET
                  updated_at = NOW(),
                  category = COALESCE(category, @category),
                  subject = COALESCE(subject, @subject)
                WHERE id = @chat_id;
              '''),
              parameters: {
                'chat_id': chatId,
                'category': category,
                'subject': subject,
              },
            );

            final messageDto = _supportMessageRowToDto(
              insertedMessage.first.toColumnMap(),
              request,
            );
            _emitSupportEvent(
              kind: 'message',
              userId: supplierUserId,
              chatId: chatId,
              messageId: _toPositiveInt(messageDto['id']),
              senderRole: messageDto['senderRole']?.toString(),
            );
            supplierNotified = true;
          }
        }
      }

      return Response.ok(
        jsonEncode({
          'deleted': true,
          'id': productId.toString(),
          'action': action,
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

void _registerModeratorCategoryRoutes(Router router, Connection connection) {
  router.post('/moderation/categories', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);
      final name = _normalizeCategoryName(payload['name']?.toString() ?? '');
      if (name.isEmpty) {
        return Response.badRequest(body: 'Название категории обязательно');
      }

      final parentId = _toNullablePositiveInt(payload['parentId']);
      if (parentId != null) {
        final parentResult = await connection.execute(
          Sql.named('SELECT id FROM public.categories WHERE id = @id'),
          parameters: {'id': parentId},
        );
        if (parentResult.isEmpty) {
          return Response.badRequest(body: 'Родительская категория не найдена');
        }
      }

      final subtitle = _normalizeOptionalText(payload['subtitle']);
      final imagePath = _normalizeOptionalText(payload['imagePath']);
      final keywords = _normalizeCategoryKeywordsPayload(payload['keywords']);
      final sortOrder = _toPositiveInt(payload['sortOrder'], fallback: 0);
      final isActive = payload['isActive'] == null
          ? true
          : payload['isActive'] == true;

      final inserted = await connection.execute(
        Sql.named('''
          INSERT INTO public.categories (
            name,
            parent_id,
            subtitle,
            image_path,
            keywords,
            sort_order,
            is_active
          )
          VALUES (
            @name::varchar(120),
            @parent_id::integer,
            @subtitle::varchar(255),
            @image_path::varchar(255),
            @keywords::text,
            @sort_order::integer,
            @is_active::boolean
          )
          ON CONFLICT ((COALESCE(parent_id, 0)), (LOWER(name))) DO UPDATE
          SET parent_id = EXCLUDED.parent_id,
              subtitle = EXCLUDED.subtitle,
              image_path = EXCLUDED.image_path,
              keywords = EXCLUDED.keywords,
              sort_order = EXCLUDED.sort_order,
              is_active = EXCLUDED.is_active,
              updated_at = NOW()
          RETURNING
            id,
            name,
            parent_id,
            subtitle,
            image_path,
            keywords,
            sort_order,
            is_active;
        '''),
        parameters: {
          'name': name,
          'parent_id': parentId,
          'subtitle': subtitle,
          'image_path': imagePath,
          'keywords': keywords,
          'sort_order': sortOrder,
          'is_active': isActive,
        },
      );

      return Response(
        201,
        body: jsonEncode(_categoryRowToDto(inserted.first.toColumnMap())),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при создании категории: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.put('/moderation/categories/<id>', (Request request, String id) async {
    try {
      final categoryId = int.tryParse(id);
      if (categoryId == null) {
        return Response.badRequest(body: 'Неверный id категории');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final hasName = payload.containsKey('name');
      final hasSortOrder = payload.containsKey('sortOrder');
      final hasIsActive = payload.containsKey('isActive');
      final hasParentId = payload.containsKey('parentId');
      final hasSubtitle = payload.containsKey('subtitle');
      final hasImagePath = payload.containsKey('imagePath');
      final hasKeywords = payload.containsKey('keywords');
      if (!hasName &&
          !hasSortOrder &&
          !hasIsActive &&
          !hasParentId &&
          !hasSubtitle &&
          !hasImagePath &&
          !hasKeywords) {
        return Response.badRequest(body: 'Нет данных для обновления');
      }

      final existingResult = await connection.execute(
        Sql.named('''
          SELECT
            id,
            name,
            parent_id,
            subtitle,
            image_path,
            keywords,
            sort_order,
            is_active
          FROM public.categories
          WHERE id = @id
        '''),
        parameters: {'id': categoryId},
      );
      if (existingResult.isEmpty) {
        return Response.notFound('Категория не найдена');
      }
      final existing = existingResult.first.toColumnMap();

      final nextName = hasName
          ? _normalizeCategoryName(payload['name']?.toString() ?? '')
          : (existing['name'] ?? '').toString();
      if (nextName.isEmpty) {
        return Response.badRequest(body: 'Название категории обязательно');
      }

      final nextParentId = hasParentId
          ? _toNullablePositiveInt(payload['parentId'])
          : _toNullablePositiveInt(existing['parent_id']);
      if (nextParentId != null) {
        if (nextParentId == categoryId) {
          return Response.badRequest(
            body: 'Категория не может быть родителем самой себе',
          );
        }
        final parentResult = await connection.execute(
          Sql.named('SELECT id FROM public.categories WHERE id = @id'),
          parameters: {'id': nextParentId},
        );
        if (parentResult.isEmpty) {
          return Response.badRequest(body: 'Родительская категория не найдена');
        }
      }

      final nextSubtitle = hasSubtitle
          ? _normalizeOptionalText(payload['subtitle'])
          : _normalizeOptionalText(existing['subtitle']);
      final nextImagePath = hasImagePath
          ? _normalizeOptionalText(payload['imagePath'])
          : _normalizeOptionalText(existing['image_path']);
      final nextKeywords = hasKeywords
          ? _normalizeCategoryKeywordsPayload(payload['keywords'])
          : _normalizeCategoryKeywordsPayload(existing['keywords']);
      final nextSortOrder = hasSortOrder
          ? _toPositiveInt(payload['sortOrder'], fallback: 0)
          : _toPositiveInt(existing['sort_order'], fallback: 0);
      final nextIsActive = hasIsActive
          ? payload['isActive'] == true
          : (existing['is_active'] == true);

      final updated = await connection.execute(
        Sql.named('''
          UPDATE public.categories
          SET name = @name::varchar(120),
              parent_id = @parent_id::integer,
              subtitle = @subtitle::varchar(255),
              image_path = @image_path::varchar(255),
              keywords = @keywords::text,
              sort_order = @sort_order::integer,
              is_active = @is_active::boolean,
              updated_at = NOW()
          WHERE id = @id
          RETURNING
            id,
            name,
            parent_id,
            subtitle,
            image_path,
            keywords,
            sort_order,
            is_active;
        '''),
        parameters: {
          'id': categoryId,
          'name': nextName,
          'parent_id': nextParentId,
          'subtitle': nextSubtitle,
          'image_path': nextImagePath,
          'keywords': nextKeywords,
          'sort_order': nextSortOrder,
          'is_active': nextIsActive,
        },
      );

      return Response.ok(
        jsonEncode(_categoryRowToDto(updated.first.toColumnMap())),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при обновлении категории: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.delete('/moderation/categories/<id>', (
    Request request,
    String id,
  ) async {
    try {
      final categoryId = int.tryParse(id);
      if (categoryId == null) {
        return Response.badRequest(body: 'Неверный id категории');
      }

      final deleted = await connection.execute(
        Sql.named('DELETE FROM public.categories WHERE id = @id RETURNING id;'),
        parameters: {'id': categoryId},
      );
      if (deleted.isEmpty) {
        return Response.notFound('Категория не найдена');
      }

      return Response.ok(
        jsonEncode({'deleted': true}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при удалении категории: $e\n$st');
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

  router.get('/moderation/categories', (Request request) async {
    try {
      final includeInactive =
          request.url.queryParameters['includeInactive'] == 'true';
      final result = includeInactive
          ? await connection.execute('''
              SELECT
                id,
                name,
                parent_id,
                subtitle,
                image_path,
                keywords,
                sort_order,
                is_active
              FROM public.categories
              ORDER BY parent_id NULLS FIRST, sort_order ASC, id ASC;
            ''')
          : await connection.execute('''
              SELECT
                id,
                name,
                parent_id,
                subtitle,
                image_path,
                keywords,
                sort_order,
                is_active
              FROM public.categories
              WHERE is_active = true
              ORDER BY parent_id NULLS FIRST, sort_order ASC, id ASC;
            ''');

      final categories = result
          .map((row) => _categoryRowToDto(row.toColumnMap()))
          .toList();

      return Response.ok(
        jsonEncode(categories),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });
}
