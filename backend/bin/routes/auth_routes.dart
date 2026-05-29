part of '../backend.dart';

// Роуты аутентификации и регистрации:
// проверка email, регистрация, подтверждение, восстановление пароля.

void _registerAuthRoutes(Router router, Connection connection) {
  router.get('/register/check-email', (Request request) async {
    try {
      final email = _normalizeEmail(request.url.queryParameters['email'] ?? '');
      if (email.isEmpty) {
        return _jsonError('Email is required', 400);
      }

      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат email', 400);
      }

      final existing = await connection.execute(
        Sql.named('''
          SELECT id, is_verified
          FROM users
          WHERE email = @email
          LIMIT 1;
        '''),
        parameters: {'email': email},
      );

      final available =
          existing.isEmpty ||
          existing.first.toColumnMap()['is_verified'] != true;
      final requiresVerification =
          existing.isNotEmpty &&
          existing.first.toColumnMap()['is_verified'] != true;

      return _jsonSuccess('Email checked', {
        'available': available,
        'requiresVerification': requiresVerification,
      });
    } catch (e, st) {
      print('Error while checking email availability: $e\n$st');
      return _jsonError('Server error', 500);
    }
  });

  router.post('/register', (Request request) async {
    try {
      final body = await request.readAsString();

      final data = Uri.splitQueryString(body);

      final name = data['name']?.trim() ?? '';
      final email = _normalizeEmail(data['email'] ?? '');
      final password = data['password']?.trim() ?? '';
      final role = _normalizeRole(data['role']);

      // Запрещаем самостоятельную регистрацию ролей, которые выдаёт только Super_Admin
      if (_selfRegistrationDeniedRoles.contains(role)) {
        return _jsonError('Регистрация с такой ролью запрещена', 400);
      }

      final supplierName = data['supplier_name']?.trim();
      final persistedSupplierName = role == 'supplier' ? supplierName : null;
      final rawPhone = data['phone'];
      final phoneDigits = rawPhone == null
          ? ''
          : rawPhone.replaceAll(RegExp(r'\D'), '');
      final phone = phoneDigits.isEmpty ? null : phoneDigits;

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        return _jsonError('Не заполнены обязательные поля', 400);
      }

      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат email', 400);
      }

      if (role == 'supplier' &&
          (supplierName == null || supplierName.isEmpty)) {
        return _jsonError('Для поставщика требуется название', 400);
      }

      final existing = await connection.execute(
        Sql.named(
          'SELECT id, is_verified FROM users WHERE LOWER(email) = @email LIMIT 1',
        ),
        parameters: {'email': email},
      );

      // Хешируем пароль перед сохранением
      final hashedPassword = _hashPassword(password);
      final otp = _generateOtpCode();
      final otpHash = _hashOtp(otp);
      final expiresAt = DateTime.now().toUtc().add(_emailVerificationOtpTtl);
      late final int userId;
      var message =
          'Регистрация успешна. Проверьте почту для подтверждения.';

      if (existing.isNotEmpty) {
        final user = existing.first.toColumnMap();
        final isVerified = user['is_verified'] == true;

        if (isVerified) {
          return _jsonError('Account already exists', 409);
        }

        userId = user['id'] as int;
        await connection.runTx((session) async {
          await session.execute(
            Sql.named('''
              UPDATE users
              SET name = @name,
                  email = @email,
                  password = @password,
                  role = @role,
                  supplier_name = @supplier_name,
                  phone = @phone,
                  is_verified = false
              WHERE id = @id;
            '''),
            parameters: {
              'id': userId,
              'name': name,
              'email': email,
              'password': hashedPassword,
              'role': role,
              'supplier_name': persistedSupplierName,
              'phone': phone,
            },
          );

          await _replacePendingEmailVerificationCode(
            session,
            userId: userId,
            codeHash: otpHash,
            expiresAt: expiresAt,
            purpose: null,
          );
        });

        message =
            'Аккаунт не подтверждён. Новый код подтверждения отправлен на почту.';
      } else {
        await connection.runTx((session) async {
          final created = await session.execute(
            Sql.named('''
              INSERT INTO users (name, email, password, role, supplier_name, phone, is_verified, created_at)
              VALUES (@name, @email, @password, @role, @supplier_name, @phone, false, NOW())
              RETURNING id;
            '''),
            parameters: {
              'name': name,
              'email': email,
              'password': hashedPassword,
              'role': role,
              'supplier_name': persistedSupplierName,
              'phone': phone,
            },
          );

          final createdMap = created.first.toColumnMap();
          userId = createdMap['id'] as int;

          await _replacePendingEmailVerificationCode(
            session,
            userId: userId,
            codeHash: otpHash,
            expiresAt: expiresAt,
            purpose: null,
          );
        });
      }

      // Отправляем email асинхронно (не блокируем ответ)
      Future.microtask(() => _sendVerificationEmail(email, otp));

      return _jsonSuccess(message);
    } on UniqueViolationException catch (e, st) {
      print('Email conflict while registering: $e\n$st');
      return _jsonError('Account already exists', 409);
    } catch (e, st) {
      print('Ошибка при регистрации: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/confirm-email', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);

      final email = _normalizeEmail(data['email'] ?? '');
      final code = data['code']?.trim();

      if (email.isEmpty || code == null || code.isEmpty) {
        return _jsonError('Email и код обязательны', 400);
      }

      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат email', 400);
      }

      final userResult = await connection.execute(
        Sql.named(
          'SELECT id, is_verified FROM users WHERE LOWER(email) = @email LIMIT 1',
        ),
        parameters: {'email': email},
      );

      if (userResult.isEmpty) {
        return _jsonError('Пользователь не найден', 404);
      }

      final user = userResult.first.toColumnMap();
      final userId = user['id'] as int;
      final isVerified = user['is_verified'] == true;
      if (isVerified) {
        return _jsonSuccess('Email уже подтверждён');
      }

      final verResult = await connection.execute(
        Sql.named('''
          SELECT id, code_hash, expires_at, used
          FROM public.email_verifications
          WHERE user_id = @user_id AND used = false AND expires_at > NOW()
            AND purpose IS NULL
          ORDER BY created_at DESC
          LIMIT 1
        '''),
        parameters: {'user_id': userId},
      );

      if (verResult.isEmpty) {
        return _jsonError('Код не найден или истёк', 400);
      }

      final ver = verResult.first.toColumnMap();
      final verId = ver['id'] as int;
      final codeHash = ver['code_hash']?.toString() ?? '';
      final ok = _checkOtp(code, codeHash);
      if (!ok) {
        return _jsonError('Неверный код', 400);
      }

      await connection.runTx((session) async {
        await session.execute(
          Sql.named('UPDATE users SET is_verified = true WHERE id = @id'),
          parameters: {'id': userId},
        );

        await session.execute(
          Sql.named(
            'UPDATE public.email_verifications SET used = true WHERE id = @id',
          ),
          parameters: {'id': verId},
        );
      });

      return _jsonSuccess('Email подтверждён');
    } catch (e, st) {
      print('Ошибка подтверждения email: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/resend-verification', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final email = _normalizeEmail(data['email'] ?? '');
      if (email.isEmpty) {
        return _jsonError('Email обязателен', 400);
      }

      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат email', 400);
      }

      final userResult = await connection.execute(
        Sql.named(
          'SELECT id, is_verified FROM users WHERE LOWER(email) = @email LIMIT 1',
        ),
        parameters: {'email': email},
      );
      if (userResult.isEmpty) {
        return _jsonError('Пользователь не найден', 404);
      }
      final user = userResult.first.toColumnMap();
      final userId = user['id'] as int;
      final isVerified = user['is_verified'] == true;
      if (isVerified) {
        return _jsonError('Email уже подтверждён', 400);
      }

      final otp = _generateOtpCode();
      final otpHash = _hashOtp(otp);
      final expiresAt = DateTime.now().toUtc().add(_emailVerificationOtpTtl);

      await connection.runTx((session) async {
        await _replacePendingEmailVerificationCode(
          session,
          userId: userId,
          codeHash: otpHash,
          expiresAt: expiresAt,
          purpose: null,
        );
      });

      Future.microtask(() => _sendVerificationEmail(email, otp));

      return _jsonSuccess('Код отправлен');
    } catch (e, st) {
      print('Ошибка при повторной отправке кода: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  // Эндпоинт для отправки кода сброса пароля
  router.post('/forgot-password/send-code', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final email = _normalizeEmail(data['email'] ?? '');

      if (email.isEmpty) {
        return _jsonError('Email обязателен', 400);
      }

      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат email', 400);
      }

      // Проверяем существование пользователя
      final userResult = await connection.execute(
        Sql.named('SELECT id FROM users WHERE LOWER(email) = @email LIMIT 1'),
        parameters: {'email': email},
      );

      if (userResult.isEmpty) {
        return _jsonError('Пользователь с таким email не найден', 404);
      }

      // Очищаем истекшие коды
      await connection.execute(
        Sql.named('DELETE FROM password_resets WHERE expires_at < NOW()'),
      );

      // Проверяем, есть ли активный код для этого email
      final activeResult = await connection.execute(
        Sql.named('''
          SELECT expires_at FROM password_resets
          WHERE email = @email AND used = false AND expires_at > NOW()
          ORDER BY created_at DESC
          LIMIT 1
        '''),
        parameters: {'email': email},
      );

      if (activeResult.isNotEmpty) {
        // Возвращаем оставшееся время без отправки нового кода
        final expiresAt =
            activeResult.first.toColumnMap()['expires_at'] as DateTime;
        final remainingSeconds = expiresAt
            .difference(DateTime.now().toUtc())
            .inSeconds;
        return _jsonSuccess('Код уже был отправлен', {
          'expires_in': remainingSeconds > 0 ? remainingSeconds : 0,
        });
      }

      // Ограничение частоты: проверяем, отправлялся ли код недавно (последняя 1 минута)
      final recentResult = await connection.execute(
        Sql.named('''
          SELECT id FROM password_resets
          WHERE email = @email AND created_at > NOW() - INTERVAL '1 minute'
          LIMIT 1
        '''),
        parameters: {'email': email},
      );

      if (recentResult.isNotEmpty) {
        return _jsonError(
          'Код уже был отправлен недавно. Попробуйте позже.',
          429,
        );
      }

      final otp = _generateOtpCode();
      final otpHash = _hashOtp(otp);
      final expiresAt = DateTime.now().toUtc().add(_emailVerificationOtpTtl);

      await connection.execute(
        Sql.named('''
          INSERT INTO password_resets (email, code_hash, expires_at, used, created_at)
          VALUES (@email, @code_hash, @expires_at, false, NOW())
        '''),
        parameters: {
          'email': email,
          'code_hash': otpHash,
          'expires_at': expiresAt,
        },
      );

      // Отправляем email асинхронно
      Future.microtask(() => _sendVerificationEmail(email, otp));

      return _jsonSuccess('Код отправлен на вашу почту', {
        'expires_in': _emailVerificationOtpTtl.inSeconds,
      });
    } catch (e, st) {
      print('Ошибка отправки кода восстановления: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  // Эндпоинт для повторной отправки кода сброса пароля
  router.post('/forgot-password/resend-code', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final email = _normalizeEmail(data['email'] ?? '');

      if (email.isEmpty) {
        return _jsonError('Email обязателен', 400);
      }

      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат email', 400);
      }

      // Проверяем существование пользователя
      final userResult = await connection.execute(
        Sql.named('SELECT id FROM users WHERE LOWER(email) = @email LIMIT 1'),
        parameters: {'email': email},
      );

      if (userResult.isEmpty) {
        return _jsonError('Пользователь с таким email не найден', 404);
      }

      // Очищаем истекшие коды
      await connection.execute(
        Sql.named('DELETE FROM password_resets WHERE expires_at < NOW()'),
      );

      // Повторную отправку ограничиваем только окном в 1 минуту, а не сроком
      // жизни кода: код валиден 5 минут, но перезапросить новый можно уже через
      // минуту, если письмо не дошло. Старый код при этом гасится ниже.
      final recentResult = await connection.execute(
        Sql.named('''
          SELECT id FROM password_resets
          WHERE email = @email AND created_at > NOW() - INTERVAL '1 minute'
          LIMIT 1
        '''),
        parameters: {'email': email},
      );

      if (recentResult.isNotEmpty) {
        return _jsonError(
          'Код уже был отправлен недавно. Попробуйте позже.',
          429,
        );
      }

      final otp = _generateOtpCode();
      final otpHash = _hashOtp(otp);
      final expiresAt = DateTime.now().toUtc().add(_emailVerificationOtpTtl);

      // Деактивируем старые неиспользованные коды
      await connection.execute(
        Sql.named('''
          UPDATE password_resets
          SET used = true
          WHERE email = @email AND used = false;
        '''),
        parameters: {'email': email},
      );

      await connection.execute(
        Sql.named('''
          INSERT INTO password_resets (email, code_hash, expires_at, used, created_at)
          VALUES (@email, @code_hash, @expires_at, false, NOW())
        '''),
        parameters: {
          'email': email,
          'code_hash': otpHash,
          'expires_at': expiresAt,
        },
      );

      // Отправляем email асинхронно
      Future.microtask(() => _sendVerificationEmail(email, otp));

      return _jsonSuccess('Код отправлен повторно', {
        'expires_in': _emailVerificationOtpTtl.inSeconds,
      });
    } catch (e, st) {
      print('Ошибка повторной отправки кода восстановления: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  // Эндпоинт для верификации кода сброса пароля
  router.post('/forgot-password/verify-code', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final email = _normalizeEmail(data['email'] ?? '');
      final code = data['code']?.trim();

      if (email.isEmpty || code == null || code.isEmpty) {
        return _jsonError('Email и код обязательны', 400);
      }

      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат email', 400);
      }

      final result = await connection.execute(
        Sql.named('''
          SELECT id, code_hash, expires_at, used
          FROM password_resets
          WHERE email = @email AND used = false AND expires_at > NOW()
          ORDER BY created_at DESC
          LIMIT 1
        '''),
        parameters: {'email': email},
      );

      if (result.isEmpty) {
        return _jsonError('Код не найден или истёк', 400);
      }

      final reset = result.first.toColumnMap();
      final resetId = reset['id'] as int;
      final codeHash = reset['code_hash']?.toString() ?? '';
      final ok = _checkOtp(code, codeHash);

      if (!ok) {
        return _jsonError('Неверный код', 400);
      }

      // Помечаем код как использованный
      await connection.execute(
        Sql.named('UPDATE password_resets SET used = true WHERE id = @id'),
        parameters: {'id': resetId},
      );

      return _jsonSuccess('Код подтверждён');
    } catch (e, st) {
      print('Ошибка верификации кода восстановления: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  // Эндпоинт для сброса пароля
  router.post('/forgot-password/reset-password', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final email = _normalizeEmail(data['email'] ?? '');
      final code = data['code']?.trim();
      final newPassword = data['newPassword']?.trim();

      if (email.isEmpty ||
          code == null ||
          code.isEmpty ||
          newPassword == null ||
          newPassword.isEmpty) {
        return _jsonError('Все поля обязательны', 400);
      }

      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат email', 400);
      }

      if (newPassword.length < 6) {
        return _jsonError('Пароль должен содержать минимум 6 символов', 400);
      }

      // Сначала проверяем код
      final result = await connection.execute(
        Sql.named('''
          SELECT id, used
          FROM password_resets
          WHERE email = @email AND used = true AND expires_at > NOW() - INTERVAL '5 minutes'
          ORDER BY created_at DESC
          LIMIT 1
        '''),
        parameters: {'email': email},
      );

      if (result.isEmpty) {
        return _jsonError('Код не найден или истёк. Запросите новый код.', 400);
      }

      final reset = result.first.toColumnMap();
      final resetId = reset['id'] as int;

      // Проверяем, был ли код использован недавно (в течение 5 минут)
      final codeHashResult = await connection.execute(
        Sql.named('''
          SELECT code_hash FROM password_resets WHERE id = @id
        '''),
        parameters: {'id': resetId},
      );

      if (codeHashResult.isEmpty) {
        return _jsonError('Код не найден', 400);
      }

      final codeHash =
          codeHashResult.first.toColumnMap()['code_hash']?.toString() ?? '';
      final ok = _checkOtp(code, codeHash);

      if (!ok) {
        return _jsonError('Неверный код', 400);
      }

      // Обновляем пароль
      final hashedPassword = _hashPassword(newPassword);
      final ip = _extractClientIp(request);
      await connection.runTx((session) async {
        // RETURNING id нужен, чтобы в той же транзакции отозвать
        // доверенные устройства и записать аудит без отдельного SELECT.
        final updated = await session.execute(
          Sql.named(
            'UPDATE users SET password = @password WHERE LOWER(email) = @email RETURNING id',
          ),
          parameters: {'email': email, 'password': hashedPassword},
        );

        // Помечаем все коды сброса для этого email как использованные
        await session.execute(
          Sql.named(
            'UPDATE password_resets SET used = true WHERE email = @email',
          ),
          parameters: {'email': email},
        );

        // После смены пароля все доверенные устройства теряют силу,
        // даже если 2FA не была включена. two_factor_enabled и
        // backup-коды не трогаем - сброс пароля не отключает 2FA.
        if (updated.isNotEmpty) {
          final userId = updated.first.toColumnMap()['id'] as int;
          await _revokeAllDeviceTokens(session, userId);
          await _writeTwoFactorAudit(
            session,
            actorUserId: userId,
            targetUserId: userId,
            action: 'trusted_devices_revoked',
            context: 'password_reset',
            ipAddress: ip,
          );
        }
      });

      return _jsonSuccess('Пароль успешно изменён');
    } catch (e, st) {
      print('Ошибка сброса пароля: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });
}

void _registerLoginRoute(Router router, Connection connection) {
  router.post('/login', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);

      final email = _normalizeEmail(data['email'] ?? '');
      final password = data['password']?.trim();

      if (email.isEmpty || password == null || password.isEmpty) {
        return _jsonError('Введите почту и пароль', 400);
      }

      if (!_isValidEmail(email)) {
        return _jsonError('Неверный формат электронной почты', 400);
      }

      final result = await connection.execute(
        Sql.named(
          'SELECT id, name, email, password, role, supplier_name, avatar_url, is_verified, two_factor_enabled FROM users WHERE LOWER(email) = @email LIMIT 1',
        ),
        parameters: {'email': email},
      );

      if (result.isEmpty) {
        return _jsonError('Неверная почта или пароль', 401);
      }

      final user = result.first.toColumnMap();
      final storedHash = user['password']?.toString() ?? '';
      if (!_checkPassword(password, storedHash)) {
        return _jsonError('Неверная почта или пароль', 401);
      }

      final isVerified = user['is_verified'] == true;
      if (!isVerified) {
        return Response(
          403,
          body: jsonEncode({
            'success': false,
            'message': 'Email не подтверждён',
            'requiresVerification': true,
            'email': email,
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final role = user['role'] ?? _defaultRole;
      final userId = user['id'] as int;
      final twoFactorEnabled = (user['two_factor_enabled'] as bool?) ?? false;

      // 2FA включена - проверяем доверенное устройство; если токен валиден,
      // пропускаем челлендж и сразу выдаём обычный логин-ответ.
      if (twoFactorEnabled) {
        final deviceToken = request.headers['x-device-token']?.trim() ?? '';
        final trusted =
            deviceToken.isNotEmpty &&
            await _validateDeviceToken(
              connection,
              userId: userId,
              token: deviceToken,
            );

        if (!trusted) {
          // Создаём pending-сессию, отправляем OTP, возвращаем challenge.
          // Сам user в ответе НЕ возвращаем - клиент получит его после
          // успешной проверки кода через /auth/2fa/verify.
          final otp = _generateOtpCode();
          final otpHash = _hashOtp(otp);
          final expiresAt = DateTime.now().toUtc().add(
            _emailVerificationOtpTtl,
          );

          late String challengeId;
          await connection.runTx((session) async {
            challengeId = await _createTwoFactorPendingSession(
              session,
              userId: userId,
              codeHash: otpHash,
              expiresAt: expiresAt,
            );
          });

          final emailForOtp = user['email']?.toString() ?? email;
          Future.microtask(() async {
            try {
              await _sendVerificationEmail(emailForOtp, otp);
            } catch (e) {
              print('Не удалось отправить OTP для 2FA-челленджа: $e');
            }
          });

          return _jsonSuccess('Введите код из почты', {
            'requiresTwoFactor': true,
            'challengeId': challengeId,
          });
        }
      }

      return _jsonSuccess('Login successful', {
        'user': {
          'id': userId,
          'name': user['name'] ?? '',
          'email': user['email'] ?? '',
          'role': role,
          'supplierName': _supplierNameForRole(role, user['supplier_name']),
          'avatarUrl': _avatarUrlOrNull(request, user['avatar_url']),
        },
      });
    } on FormatException {
      return _jsonError('Доступ запрещен', 400);
    } catch (e, st) {
      print('Ошибка сервера при входе: $e\n$st');
      return _jsonError('Не удалось выполнить вход. Попробуйте позже.', 500);
    }
  });
}
