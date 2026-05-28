part of '../backend.dart';

// Общие пользовательские роуты: обновление профиля и смена пароля.
// Доступны для всех ролей (buyer/supplier/moderator/super_admin).

void _registerSharedUserProfileRoutes(Router router, Connection connection) {  router.patch('/users/<id>', (Request request, String id) async {
    try {
      final userId = int.tryParse(id);
      if (userId == null) {
        return Response.badRequest(body: 'Неверный ID пользователя');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Expected JSON object');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final hasName = payload.containsKey('name');
      final hasEmail = payload.containsKey('email');
      final hasPhone = payload.containsKey('phone');
      final hasSupplierName =
          payload.containsKey('supplierName') ||
          payload.containsKey('supplier_name');

      if (!hasName && !hasEmail && !hasPhone && !hasSupplierName) {
        return Response.badRequest(body: 'Nothing to update');
      }

      final userResult = await connection.execute(
        Sql.named(
          'SELECT id, name, email, role, supplier_name, phone FROM users WHERE id = @id',
        ),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound('User not found');
      }
      final user = userResult.first.toColumnMap();

      var nextName = (user['name'] ?? '').toString().trim();
      var nextEmail = (user['email'] ?? '').toString().trim();
      var nextRole = (user['role'] ?? _defaultRole).toString();
      var nextSupplierName = (user['supplier_name'] ?? '').toString().trim();
      String? nextPhone = user['phone']?.toString().trim();
      if (nextPhone != null && nextPhone.isEmpty) {
        nextPhone = null;
      }

      if (hasName) {
        nextName = (payload['name'] ?? '').toString().trim();
        if (nextName.isEmpty) {
          return Response.badRequest(body: 'Name is required');
        }
      }

      if (hasEmail) {
        nextEmail = (payload['email'] ?? '').toString().trim();
        if (nextEmail.isEmpty) {
          return Response.badRequest(body: 'Email is required');
        }
        final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        if (!emailPattern.hasMatch(nextEmail)) {
          return Response.badRequest(body: 'Неверный формат email');
        }

        final duplicate = await connection.execute(
          Sql.named('''
            SELECT id
            FROM users
            WHERE email = @email
              AND id <> @id
            LIMIT 1;
            '''),
          parameters: {'email': nextEmail, 'id': userId},
        );
        if (duplicate.isNotEmpty) {
          return Response(409, body: 'Email already in use');
        }
      }

      if (hasPhone) {
        final rawPhone = (payload['phone'] ?? '').toString();
        final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) {
          nextPhone = null;
        } else {
          if (digits.length != 11 || !digits.startsWith('7')) {
            return Response.badRequest(body: 'Неверный формат телефона');
          }
          nextPhone = digits;
        }
      }

      if (hasSupplierName) {
        final supplierNameRaw = payload.containsKey('supplierName')
            ? payload['supplierName']
            : payload['supplier_name'];
        nextSupplierName = (supplierNameRaw ?? '').toString().trim();
      }

      final normalizedRole = _normalizeRole(nextRole);
      if (normalizedRole != 'supplier') {
        nextSupplierName = '';
      } else if (hasSupplierName && nextSupplierName.isEmpty) {
        return Response.badRequest(body: 'Supplier name is required');
      }

      // Сначала пробуем UPDATE с RETURNING avatar_url. Если столбца нет
      // (миграция ещё не применилась) - откатываемся к запросу без него
      // и отдаём avatarUrl: null, чтобы PATCH остальных полей не падал.
      Map<String, dynamic>? updatedUser;
      Object? rawAvatarUrl;
      try {
        final updated = await connection.execute(
          Sql.named('''
            UPDATE users
            SET name = @name,
                email = @email,
                phone = @phone,
                supplier_name = @supplier_name
            WHERE id = @id
            RETURNING id, name, email, role, supplier_name, phone, avatar_url;
            '''),
          parameters: {
            'id': userId,
            'name': nextName,
            'email': nextEmail,
            'phone': nextPhone,
            'supplier_name': nextSupplierName,
          },
        );
        if (updated.isEmpty) {
          return Response.notFound('User not found');
        }
        updatedUser = updated.first.toColumnMap();
        rawAvatarUrl = updatedUser['avatar_url'];
      } catch (_) {
        final updated = await connection.execute(
          Sql.named('''
            UPDATE users
            SET name = @name,
                email = @email,
                phone = @phone,
                supplier_name = @supplier_name
            WHERE id = @id
            RETURNING id, name, email, role, supplier_name, phone;
            '''),
          parameters: {
            'id': userId,
            'name': nextName,
            'email': nextEmail,
            'phone': nextPhone,
            'supplier_name': nextSupplierName,
          },
        );
        if (updated.isEmpty) {
          return Response.notFound('User not found');
        }
        updatedUser = updated.first.toColumnMap();
        rawAvatarUrl = null;
      }

      nextRole = (updatedUser['role'] ?? nextRole).toString();

      return Response.ok(
        jsonEncode({
          'id': updatedUser['id'],
          'name': updatedUser['name'] ?? '',
          'email': updatedUser['email'] ?? '',
          'role': nextRole,
          'supplierName': _supplierNameForRole(
            nextRole,
            updatedUser['supplier_name'],
          ),
          'phone': updatedUser['phone'] ?? '',
          'avatarUrl': _avatarUrlOrNull(request, rawAvatarUrl),
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Error updating user profile: $e\n$st');
      return Response.internalServerError(body: 'Server error: $e');
    }
  });

  router.patch('/users/<id>/password', (Request request, String id) async {
    try {
      final userId = int.tryParse(id);
      if (userId == null || userId <= 0) {
        return Response.badRequest(
          body: 'Некорректный id пользователя',
          headers: _utf8TextHeaders,
        );
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(
          body: 'Ожидается JSON объект',
          headers: _utf8TextHeaders,
        );
      }
      final payload = Map<String, dynamic>.from(decoded);

      final currentPasswordRaw = payload.containsKey('currentPassword')
          ? payload['currentPassword']
          : payload['current_password'];
      final newPasswordRaw = payload.containsKey('newPassword')
          ? payload['newPassword']
          : payload['new_password'];
      final confirmPasswordRaw = payload.containsKey('confirmPassword')
          ? payload['confirmPassword']
          : payload['confirm_password'];

      final currentPassword = currentPasswordRaw?.toString().trim() ?? '';
      final newPassword = newPasswordRaw?.toString().trim() ?? '';
      final confirmPassword = confirmPasswordRaw?.toString().trim();

      if (currentPassword.isEmpty || newPassword.isEmpty) {
        return Response.badRequest(
          body: 'Текущий и новый пароль обязательны',
          headers: _utf8TextHeaders,
        );
      }

      if (currentPassword.length < 6 || newPassword.length < 6) {
        return Response.badRequest(
          body: 'Пароль должен содержать минимум 6 символов',
          headers: _utf8TextHeaders,
        );
      }

      if (newPassword == currentPassword) {
        return Response.badRequest(
          body: 'Новый пароль должен отличаться от текущего',
          headers: _utf8TextHeaders,
        );
      }

      if (confirmPassword != null && confirmPassword != newPassword) {
        return Response.badRequest(
          body: 'Подтверждение пароля не совпадает',
          headers: _utf8TextHeaders,
        );
      }

      final userResult = await connection.execute(
        Sql.named('SELECT id, password FROM users WHERE id = @id LIMIT 1;'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound(
          'Пользователь не найден',
          headers: _utf8TextHeaders,
        );
      }

      final user = userResult.first.toColumnMap();
      final persistedPassword = (user['password'] ?? '').toString().trim();
      if (persistedPassword != currentPassword) {
        return Response(
          401,
          body: 'Текущий пароль указан неверно',
          headers: _utf8TextHeaders,
        );
      }

      await connection.execute(
        Sql.named('''
          UPDATE users
          SET password = @password
          WHERE id = @id;
          '''),
        parameters: {'id': userId, 'password': newPassword},
      );

      return Response.ok(
        jsonEncode({'updated': true}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(
        body: 'Неверный JSON',
        headers: _utf8TextHeaders,
      );
    } catch (e, st) {
      print('Ошибка при смене пароля: $e\n$st');
      return Response.internalServerError(
        body: 'Ошибка сервера: $e',
        headers: _utf8TextHeaders,
      );
    }
  });

}
