part of '../backend.dart';

/// Роуты управления модераторами для Super_Admin. Все эндпоинты защищены
/// через _requireSuperAdmin.
void _registerAdminModeratorRoutes(Router router, Connection connection) {
  router.get('/admin/moderators', (Request request) async {
    try {
      final auth = await _requireSuperAdmin(request, connection);
      if (auth is Response) return auth;

      final result = await connection.execute(
        Sql.named('''
          SELECT id, name, email, phone, role
          FROM public.users
          WHERE role = 'moderator'
          ORDER BY name ASC, id ASC;
        '''),
      );

      final list = result.map((r) {
        final m = r.toColumnMap();
        return {
          'id': m['id'],
          'name': m['name'] ?? '',
          'email': m['email'] ?? '',
          'phone': m['phone'] ?? '',
          'role': 'moderator',
        };
      }).toList();

      return Response.ok(
        jsonEncode(list),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при получении списка модераторов: $e\n$st');
      return _jsonError('Server error', 500);
    }
  });

  router.post('/admin/moderators', (Request request) async {
    try {
      final auth = await _requireSuperAdmin(request, connection);
      if (auth is Response) return auth;

      final raw = await request.readAsString();
      final dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return _jsonError('Неверный JSON', 400);
      }
      if (decoded is! Map) {
        return _jsonError('Ожидается JSON объект', 400);
      }
      final data = Map<String, dynamic>.from(decoded);

      final name = data['name']?.toString().trim() ?? '';
      final email = _normalizeEmail(data['email'] ?? '');
      final password = data['password']?.toString().trim() ?? '';
      final phoneDigits =
          data['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
      final phone = phoneDigits.isEmpty ? null : phoneDigits;

      if (name.isEmpty) {
        return _jsonError('Введите имя', 400);
      }
      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат email', 400);
      }
      if (password.length < 6) {
        return _jsonError('Пароль должен быть не короче 6 символов', 400);
      }

      // Проверка уникальности email без учёта регистра
      final existing = await connection.execute(
        Sql.named(
          'SELECT id FROM public.users WHERE LOWER(email) = @email LIMIT 1;',
        ),
        parameters: {'email': email},
      );
      if (existing.isNotEmpty) {
        return _jsonError('Email уже зарегистрирован', 409);
      }

      final hashedPassword = _hashPassword(password);

      final created = await connection.execute(
        Sql.named('''
          INSERT INTO public.users (
            name, email, password, role, phone, is_verified, created_at
          )
          VALUES (
            @name, @email, @password, 'moderator', @phone, true, NOW()
          )
          RETURNING id, name, email, phone, role;
        '''),
        parameters: {
          'name': name,
          'email': email,
          'password': hashedPassword,
          'phone': phone,
        },
      );

      final row = created.first.toColumnMap();
      final body = {
        'id': row['id'],
        'name': row['name'] ?? '',
        'email': row['email'] ?? '',
        'phone': row['phone'] ?? '',
        'role': 'moderator',
      };

      return Response(
        201,
        body: jsonEncode(body),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on UniqueViolationException catch (e, st) {
      print('Конфликт email при создании модератора: $e\n$st');
      return _jsonError('Email уже зарегистрирован', 409);
    } catch (e, st) {
      print('Ошибка при создании модератора: $e\n$st');
      return _jsonError('Server error', 500);
    }
  });

  router.delete('/admin/moderators/<id>', (Request request, String id) async {
    try {
      final auth = await _requireSuperAdmin(request, connection);
      if (auth is Response) return auth;

      final moderatorId = int.tryParse(id);
      if (moderatorId == null || moderatorId <= 0) {
        return _jsonError('Модератор не найден', 404);
      }

      final existing = await connection.execute(
        Sql.named(
          'SELECT email, role FROM public.users WHERE id = @id LIMIT 1;',
        ),
        parameters: {'id': moderatorId},
      );
      if (existing.isEmpty) {
        return _jsonError('Модератор не найден', 404);
      }

      final row = existing.first.toColumnMap();
      final role = row['role']?.toString().trim().toLowerCase() ?? '';
      if (role != 'moderator') {
        return _jsonError('Модератор не найден', 404);
      }

      final email = row['email']?.toString().trim().toLowerCase() ?? '';
      if (email == _superAdminEmail) {
        // Защита от удаления Super_Admin даже если кто-то вручную поправил роль в БД
        return _jsonError('Главного администратора удалить нельзя', 400);
      }

      await connection.execute(
        Sql.named('DELETE FROM public.users WHERE id = @id;'),
        parameters: {'id': moderatorId},
      );

      return Response.ok(
        jsonEncode({'success': true, 'message': 'Модератор удалён'}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при удалении модератора: $e\n$st');
      return _jsonError('Server error', 500);
    }
  });
}

// Каталог поставщиков и find-or-create support-чата.
// Сейчас это обычный support_chat: модератор находит поставщика в каталоге,
