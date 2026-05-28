part of '../backend.dart';

// Роуты 2FA: настройки, логин-челлендж, admin-disable.

// 32 символа без визуально похожих 0/O/1/I, ~50 бит энтропии на 10 знаков.
const String _twoFactorBackupCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

const int _twoFactorBackupCodeLength = 10;
const int _twoFactorBackupCodeCount = 10;

const Duration _trustedDeviceTtl = Duration(days: 30);

const int _twoFactorMaxVerifyAttempts = 5;
const Duration _twoFactorEnableLockoutWindow = Duration(minutes: 5);
const Duration _twoFactorEnableLockoutDuration = Duration(minutes: 15);

const Duration _twoFactorResendCooldown = Duration(minutes: 1);

List<String> _generateBackupCodes({
  int count = _twoFactorBackupCodeCount,
  int length = _twoFactorBackupCodeLength,
}) {
  final rnd = Random.secure();
  final alphabet = _twoFactorBackupCodeAlphabet;
  final codes = <String>{};
  // Гарантируем уникальность - коллизии в партии маловероятны, но дешевле явно.
  while (codes.length < count) {
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      buf.writeCharCode(alphabet.codeUnitAt(rnd.nextInt(alphabet.length)));
    }
    codes.add(buf.toString());
  }
  return codes.toList(growable: false);
}

// Backup-код хранится в bcrypt-хеше; перед хешем приводим к верхнему регистру.
String _hashBackupCode(String code) => _hashOtp(code.toUpperCase());

// Публичные обёртки для тестов - доступ к приватным генераторам из test/.
List<String> debugGenerateBackupCodes({
  int count = _twoFactorBackupCodeCount,
  int length = _twoFactorBackupCodeLength,
}) => _generateBackupCodes(count: count, length: length);

const String debugTwoFactorBackupCodeAlphabet = _twoFactorBackupCodeAlphabet;
const int debugTwoFactorBackupCodeLength = _twoFactorBackupCodeLength;
const int debugTwoFactorBackupCodeCount = _twoFactorBackupCodeCount;

const int debugTwoFactorMaxVerifyAttempts = _twoFactorMaxVerifyAttempts;
const Duration debugTwoFactorEnableLockoutWindow =
    _twoFactorEnableLockoutWindow;
const Duration debugTwoFactorEnableLockoutDuration =
    _twoFactorEnableLockoutDuration;

const Duration debugTwoFactorResendCooldown = _twoFactorResendCooldown;
const Duration debugTrustedDeviceTtl = _trustedDeviceTtl;

// Чистый предикат lockout для /auth/2fa/enable/request - тот же код, что в проде.
bool _isEnableLockedOut(int recentFailedAttempts) =>
    recentFailedAttempts >= _twoFactorMaxVerifyAttempts;

bool debugIsEnableLockedOut(int recentFailedAttempts) =>
    _isEnableLockedOut(recentFailedAttempts);

// Если у пользователя уже есть активный (used=false, expires_at>NOW()) OTP
// для указанного purpose, возвращает остаток секунд до его истечения.
// Иначе - null. Используется чтобы не плодить письма при повторном открытии
// или отмене экранов 2FA: эндпоинт молча возвращает success с этим
// expires_in, не выпуская новый код. Старый OTP в почте остаётся валидным.
Future<int?> _activeOtpRemainingSeconds(
  Connection connection, {
  required int userId,
  required String purpose,
}) async {
  final rows = await connection.execute(
    Sql.named('''
      SELECT expires_at
      FROM public.email_verifications
      WHERE user_id = @user_id
        AND purpose = @purpose
        AND used = false
        AND expires_at > NOW()
      ORDER BY created_at DESC
      LIMIT 1;
    '''),
    parameters: {'user_id': userId, 'purpose': purpose},
  );
  if (rows.isEmpty) return null;
  final expiresAtRaw = rows.first.toColumnMap()['expires_at'];
  final expiresAt = expiresAtRaw is DateTime
      ? expiresAtRaw
      : DateTime.tryParse(expiresAtRaw?.toString() ?? '');
  if (expiresAt == null) return null;
  final remaining = expiresAt
      .toUtc()
      .difference(DateTime.now().toUtc())
      .inSeconds;
  if (remaining <= 0) return null;
  return remaining;
}

// Возвращает 429-ответ, если за окно _twoFactorEnableLockoutWindow для пользователя
// накопилось >= _twoFactorMaxVerifyAttempts записей verify_failure с указанным
// context. Иначе - null. Используется в sensitive-эндпоинтах disable/regenerate/revoke.
Future<Response?> _checkSensitiveLockout(
  Connection connection, {
  required int userId,
  required String context,
}) async {
  final windowMinutes = _twoFactorEnableLockoutWindow.inMinutes;
  final failedRows = await connection.execute(
    Sql.named('''
      SELECT COUNT(*) AS failed
      FROM public.two_factor_audit
      WHERE target_user_id = @user_id
        AND action = 'verify_failure'
        AND context = @ctx
        AND created_at > NOW() - INTERVAL '$windowMinutes minutes';
    '''),
    parameters: {'user_id': userId, 'ctx': context},
  );
  final failed = _toPositiveInt(
    failedRows.isEmpty ? 0 : failedRows.first.toColumnMap()['failed'],
  );
  if (_isEnableLockedOut(failed)) {
    final lockoutMinutes = _twoFactorEnableLockoutDuration.inMinutes;
    return _jsonError(
      'Слишком много попыток. Попробуйте через $lockoutMinutes минут',
      429,
    );
  }
  return null;
}

// 32 байта (256 бит) base64url без padding; в БД хранится только bcrypt-хеш.
String _generateDeviceToken() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
  final encoded = base64Url.encode(bytes);
  return encoded.replaceAll('=', '');
}

String debugGenerateDeviceToken() => _generateDeviceToken();

String? debugExtractClientIp(Request request) => _extractClientIp(request);

// Берёт первый валидный токен из X-Forwarded-For, иначе адрес TCP-соединения.
// Возвращает null - аудит должен записаться с ip_address=NULL, не валить действие.
String? _extractClientIp(Request request) {
  final forwarded = request.headers['x-forwarded-for'];
  if (forwarded != null && forwarded.isNotEmpty) {
    for (final raw in forwarded.split(',')) {
      final candidate = raw.trim();
      if (candidate.isEmpty) continue;
      if (InternetAddress.tryParse(candidate) != null) {
        return candidate;
      }
    }
  }

  final info = request.context['shelf.io.connection_info'];
  if (info is HttpConnectionInfo) {
    final address = info.remoteAddress.address;
    if (InternetAddress.tryParse(address) != null) {
      return address;
    }
  }

  return null;
}

// Запись действия в журнал 2FA. Сбой INSERT не пробрасываем - аудит не должен
// ронять основной флоу.
Future<void> _writeTwoFactorAudit(
  Session session, {
  required int? actorUserId,
  required int targetUserId,
  required String action,
  required String? context,
  required String? ipAddress,
}) async {
  try {
    await session.execute(
      Sql.named('''
        INSERT INTO public.two_factor_audit
          (actor_user_id, target_user_id, action, context, ip_address)
        VALUES (@actor_user_id, @target_user_id, @action, @context, @ip_address);
      '''),
      parameters: {
        'actor_user_id': actorUserId,
        'target_user_id': targetUserId,
        'action': action,
        'context': context,
        'ip_address': ipAddress,
      },
    );
  } catch (e, st) {
    print('Не удалось записать 2FA-аудит ($action / $targetUserId): $e\n$st');
  }
}

// Авторизация владельца по X-User-Id. Возвращает Map строки пользователя
// либо готовый Response 401.
Future<Object> _resolveAuthenticatedUser(
  Request request,
  Connection connection,
) async {
  final raw = request.headers['x-user-id']?.trim();
  if (raw == null || raw.isEmpty) {
    return _jsonError('Требуется авторизация', 401);
  }
  final userId = int.tryParse(raw);
  if (userId == null || userId <= 0) {
    return _jsonError('Требуется авторизация', 401);
  }
  final result = await connection.execute(
    Sql.named('''
      SELECT id, email, role, name, supplier_name, two_factor_enabled
      FROM public.users
      WHERE id = @id
      LIMIT 1;
    '''),
    parameters: {'id': userId},
  );
  if (result.isEmpty) {
    return _jsonError('Требуется авторизация', 401);
  }
  return result.first.toColumnMap();
}

// Перебирает активные trusted-устройства пользователя и сверяет bcrypt-хеши.
// Активных обычно единицы - перебор дешёвый.
Future<bool> _validateDeviceToken(
  Connection connection, {
  required int userId,
  required String token,
}) async {
  if (userId <= 0 || token.isEmpty) return false;
  final rows = await connection.execute(
    Sql.named('''
      SELECT id, token_hash
      FROM public.two_factor_trusted_devices
      WHERE user_id = @user_id
        AND revoked = false
        AND expires_at > NOW();
    '''),
    parameters: {'user_id': userId},
  );
  for (final row in rows) {
    final map = row.toColumnMap();
    final hash = map['token_hash']?.toString() ?? '';
    if (hash.isEmpty) continue;
    if (_checkOtp(token, hash)) {
      return true;
    }
  }
  return false;
}

// Помечает все активные trusted-устройства пользователя как revoked.
// Идемпотентно. Исключения наружу не глотаем - вызывающий управляет транзакцией.
Future<void> _revokeAllDeviceTokens(Session session, int userId) async {
  if (userId <= 0) return;
  await session.execute(
    Sql.named('''
      UPDATE public.two_factor_trusted_devices
      SET revoked = true
      WHERE user_id = @user_id AND revoked = false;
    '''),
    parameters: {'user_id': userId},
  );
}

// UUID v4 на Random.secure без внешнего пакета.
String _generateUuidV4() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  // Версия 4 в старшей тетраде 7-го байта.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Variant 10xx в старших битах 9-го байта.
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final s = bytes.map(hex).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-'
      '${s.substring(16, 20)}-${s.substring(20, 32)}';
}

String debugGenerateUuidV4() => _generateUuidV4();

// Грубая проверка формата UUID - отсекает мусор до каста @id::uuid (иначе 500).
final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
bool _isUuid(String value) => _uuidPattern.hasMatch(value);

// Исход проверки кода в pending-сессии 2FA-челленджа.
enum _TwoFactorVerifyOutcome { success, invalidCode, expired, sessionInvalid }

// Результат _consumeTwoFactorPendingSession.
class _TwoFactorVerifyResult {
  const _TwoFactorVerifyResult({
    required this.outcome,
    this.userId,
    this.attempts = 0,
    this.remainingAttempts = 0,
  });

  final _TwoFactorVerifyOutcome outcome;
  final int? userId;

  // Текущее значение attempts после операции.
  final int attempts;

  // Сколько попыток осталось до инвалидации сессии (не меньше нуля).
  final int remainingAttempts;
}

// Создаёт pending-сессию 2FA-челленджа и возвращает challengeId (UUID v4).
Future<String> _createTwoFactorPendingSession(
  Session session, {
  required int userId,
  required String codeHash,
  required DateTime expiresAt,
}) async {
  final challengeId = _generateUuidV4();
  await session.execute(
    Sql.named('''
      INSERT INTO public.two_factor_pending_sessions
        (id, user_id, code_hash, attempts, expires_at, used, created_at)
      VALUES
        (@id::uuid, @user_id, @code_hash, 0, @expires_at, false, NOW());
    '''),
    parameters: {
      'id': challengeId,
      'user_id': userId,
      'code_hash': codeHash,
      'expires_at': expiresAt.toUtc(),
    },
  );
  return challengeId;
}

// Атомарная проверка OTP из pending-сессии под SELECT ... FOR UPDATE.
// Backup-коды обрабатываются отдельно в /auth/2fa/verify.
Future<_TwoFactorVerifyResult> _consumeTwoFactorPendingSession(
  Session session, {
  required String challengeId,
  required String code,
}) async {
  if (challengeId.isEmpty) {
    return const _TwoFactorVerifyResult(
      outcome: _TwoFactorVerifyOutcome.sessionInvalid,
    );
  }

  final rows = await session.execute(
    Sql.named('''
      SELECT id, user_id, code_hash, attempts, expires_at, used
      FROM public.two_factor_pending_sessions
      WHERE id = @id::uuid
      FOR UPDATE;
    '''),
    parameters: {'id': challengeId},
  );

  if (rows.isEmpty) {
    return const _TwoFactorVerifyResult(
      outcome: _TwoFactorVerifyOutcome.sessionInvalid,
    );
  }

  final row = rows.first.toColumnMap();
  final userId = row['user_id'] as int;
  final codeHash = row['code_hash']?.toString() ?? '';
  final attempts = (row['attempts'] as int?) ?? 0;
  final used = (row['used'] as bool?) ?? false;
  final expiresAtRaw = row['expires_at'];
  final expiresAt = expiresAtRaw is DateTime
      ? expiresAtRaw
      : DateTime.tryParse(expiresAtRaw?.toString() ?? '') ?? DateTime.now();
  final nowUtc = DateTime.now().toUtc();
  final expiresUtc = expiresAt.toUtc();

  if (used ||
      expiresUtc.isBefore(nowUtc) ||
      attempts >= _twoFactorMaxVerifyAttempts) {
    return _TwoFactorVerifyResult(
      outcome: _TwoFactorVerifyOutcome.expired,
      userId: userId,
      attempts: attempts,
    );
  }

  final ok = codeHash.isNotEmpty && _checkOtp(code, codeHash);
  if (ok) {
    await session.execute(
      Sql.named('''
        UPDATE public.two_factor_pending_sessions
        SET used = true
        WHERE id = @id::uuid;
      '''),
      parameters: {'id': challengeId},
    );
    final remaining = _twoFactorMaxVerifyAttempts - attempts;
    return _TwoFactorVerifyResult(
      outcome: _TwoFactorVerifyOutcome.success,
      userId: userId,
      attempts: attempts,
      remainingAttempts: remaining < 0 ? 0 : remaining,
    );
  }

  final newAttempts = attempts + 1;
  await session.execute(
    Sql.named('''
      UPDATE public.two_factor_pending_sessions
      SET attempts = @attempts
      WHERE id = @id::uuid;
    '''),
    parameters: {'id': challengeId, 'attempts': newAttempts},
  );
  final remaining = _twoFactorMaxVerifyAttempts - newAttempts;
  return _TwoFactorVerifyResult(
    outcome: _TwoFactorVerifyOutcome.invalidCode,
    userId: userId,
    attempts: newAttempts,
    remainingAttempts: remaining < 0 ? 0 : remaining,
  );
}

// /auth/2fa/verify по backup-коду. Всё в одной транзакции - при сбое COMMIT
// никаких частичных изменений в БД не остаётся.
Future<Response> _handleTwoFactorBackupVerify(
  Connection connection, {
  required String challengeId,
  required String backupCode,
  required bool rememberDevice,
  required String? ipAddress,
}) async {
  var matched = false;
  var sessionInvalid = false;
  var attemptsAfter = 0;
  var lockedOut = false;
  Map<String, dynamic>? userRow;
  String? deviceTokenRaw;

  await connection.runTx((session) async {
    final sessionRows = await session.execute(
      Sql.named('''
        SELECT id, user_id, attempts, expires_at, used
        FROM public.two_factor_pending_sessions
        WHERE id = @id::uuid
        FOR UPDATE;
      '''),
      parameters: {'id': challengeId},
    );

    if (sessionRows.isEmpty) {
      sessionInvalid = true;
      return;
    }

    final sessionMap = sessionRows.first.toColumnMap();
    final userId = sessionMap['user_id'] as int;
    final attempts = (sessionMap['attempts'] as int?) ?? 0;
    final used = (sessionMap['used'] as bool?) ?? false;
    final expiresAtRaw = sessionMap['expires_at'];
    final expiresAt = expiresAtRaw is DateTime
        ? expiresAtRaw
        : DateTime.tryParse(expiresAtRaw?.toString() ?? '') ?? DateTime.now();
    final nowUtc = DateTime.now().toUtc();
    final expiresUtc = expiresAt.toUtc();

    if (used ||
        expiresUtc.isBefore(nowUtc) ||
        attempts >= _twoFactorMaxVerifyAttempts) {
      sessionInvalid = true;
      return;
    }

    final candidate = backupCode.toUpperCase();

    final codeRows = await session.execute(
      Sql.named('''
        SELECT id, code_hash
        FROM public.two_factor_backup_codes
        WHERE user_id = @user_id AND used = false
        FOR UPDATE;
      '''),
      parameters: {'user_id': userId},
    );

    int? matchedCodeId;
    for (final row in codeRows) {
      final map = row.toColumnMap();
      final hash = map['code_hash']?.toString() ?? '';
      if (hash.isEmpty) continue;
      if (_checkOtp(candidate, hash)) {
        matchedCodeId = map['id'] as int;
        break;
      }
    }

    if (matchedCodeId == null) {
      // Неудача: инкремент счётчика той же сессии (как для OTP-ветки).
      await session.execute(
        Sql.named('''
          UPDATE public.two_factor_pending_sessions
          SET attempts = attempts + 1
          WHERE id = @id::uuid;
        '''),
        parameters: {'id': challengeId},
      );
      attemptsAfter = attempts + 1;
      if (attemptsAfter >= _twoFactorMaxVerifyAttempts) {
        lockedOut = true;
      }
      await _writeTwoFactorAudit(
        session,
        actorUserId: userId,
        targetUserId: userId,
        action: 'verify_failure',
        context: 'login',
        ipAddress: ipAddress,
      );
      return;
    }

    // Успех: помечаем код использованным внутри той же транзакции.
    await session.execute(
      Sql.named('''
        UPDATE public.two_factor_backup_codes
        SET used = true, used_at = NOW()
        WHERE id = @id;
      '''),
      parameters: {'id': matchedCodeId},
    );

    await session.execute(
      Sql.named('''
        UPDATE public.two_factor_pending_sessions
        SET used = true
        WHERE id = @id::uuid;
      '''),
      parameters: {'id': challengeId},
    );

    final rows = await session.execute(
      Sql.named('''
        SELECT id, name, email, role, supplier_name, two_factor_enabled
        FROM public.users
        WHERE id = @id
        LIMIT 1;
      '''),
      parameters: {'id': userId},
    );
    if (rows.isNotEmpty) {
      userRow = rows.first.toColumnMap();
    }

    await _writeTwoFactorAudit(
      session,
      actorUserId: userId,
      targetUserId: userId,
      action: 'backup_code_used',
      context: 'login',
      ipAddress: ipAddress,
    );

    await _writeTwoFactorAudit(
      session,
      actorUserId: userId,
      targetUserId: userId,
      action: 'verify_success',
      context: 'login',
      ipAddress: ipAddress,
    );

    if (rememberDevice) {
      final token = _generateDeviceToken();
      final tokenHash = _hashOtp(token);
      final expiresAtTrusted = DateTime.now().toUtc().add(_trustedDeviceTtl);
      await session.execute(
        Sql.named('''
          INSERT INTO public.two_factor_trusted_devices
            (user_id, token_hash, expires_at, revoked, created_at)
          VALUES (@user_id, @token_hash, @expires_at, false, NOW());
        '''),
        parameters: {
          'user_id': userId,
          'token_hash': tokenHash,
          'expires_at': expiresAtTrusted,
        },
      );
      await _writeTwoFactorAudit(
        session,
        actorUserId: userId,
        targetUserId: userId,
        action: 'trusted_device_added',
        context: 'login',
        ipAddress: ipAddress,
      );
      deviceTokenRaw = token;
    }

    matched = true;
  });

  if (sessionInvalid || lockedOut) {
    return _jsonError('Срок действия кода истёк, повторите вход', 410);
  }
  if (!matched) {
    return _jsonError('Неверный код', 400);
  }
  if (userRow == null) {
    return _jsonError('Пользователь не найден', 404);
  }

  final user = userRow!;
  final userId = user['id'] as int;
  final role = user['role']?.toString() ?? _defaultRole;

  // Считаем оставшиеся коды вне транзакции - значение ровное на момент COMMIT.
  final remRows = await connection.execute(
    Sql.named('''
      SELECT COUNT(*) AS remaining
      FROM public.two_factor_backup_codes
      WHERE user_id = @id AND used = false;
    '''),
    parameters: {'id': userId},
  );
  final remaining = _toPositiveInt(
    remRows.isEmpty ? 0 : remRows.first.toColumnMap()['remaining'],
  );

  return _jsonSuccess('Login successful', {
    'data': {
      'user': {
        'id': userId,
        'name': user['name'] ?? '',
        'email': user['email'] ?? '',
        'role': role,
        'supplierName': _supplierNameForRole(role, user['supplier_name']),
      },
      'deviceToken': deviceTokenRaw,
      'backupCodesRemaining': remaining,
    },
  });
}

// Периодическая очистка просроченных pending-сессий 2FA. Ошибки SQL глушим.
Future<void> _cleanupExpiredTwoFactorPendingSessions(
  Connection connection,
) async {
  print('Запуск очистки истекших pending-сессий 2FA...');
  try {
    final result = await connection.execute(
      Sql.named('''
        DELETE FROM public.two_factor_pending_sessions
        WHERE expires_at < NOW();
      '''),
    );
    print(
      'Очистка завершена. Удалено ${result.affectedRows} истекших pending-сессий 2FA.',
    );
    if (result.affectedRows > 0) {
      print(
        'Успешно очищено ${result.affectedRows} истекших pending-сессий 2FA',
      );
    }
  } catch (e, st) {
    print('Ошибка при очистке истекших pending-сессий 2FA: $e\n$st');
  }
}

// Периодическая очистка просроченных trusted-устройств 2FA.
Future<void> _cleanupExpiredTrustedDevices(Connection connection) async {
  print('Запуск очистки истекших доверенных устройств 2FA...');
  try {
    final result = await connection.execute(
      Sql.named('''
        DELETE FROM public.two_factor_trusted_devices
        WHERE expires_at < NOW();
      '''),
    );
    print(
      'Очистка завершена. Удалено ${result.affectedRows} истекших доверенных устройств 2FA.',
    );
    if (result.affectedRows > 0) {
      print(
        'Успешно очищено ${result.affectedRows} истекших доверенных устройств 2FA',
      );
    }
  } catch (e, st) {
    print('Ошибка при очистке истекших доверенных устройств 2FA: $e\n$st');
  }
}

void _registerTwoFactorRoutes(Router router, Connection connection) {
  router.get('/auth/2fa/status', (Request request) async {
    // targetUserId - модераторский путь к чужому статусу. Пустые/невалидные
    // значения трактуем как self-запрос.
    final targetRaw = request.url.queryParameters['targetUserId']?.trim();
    int? targetUserId;
    if (targetRaw != null && targetRaw.isNotEmpty) {
      final parsed = int.tryParse(targetRaw);
      if (parsed != null && parsed > 0) {
        targetUserId = parsed;
      }
    }

    int userId;
    if (targetUserId != null) {
      final actor = await _resolveModerationActor(request, connection);
      if (actor is Response) return actor;
      userId = targetUserId;
    } else {
      final caller = await _resolveAuthenticatedUser(request, connection);
      if (caller is Response) return caller;
      final callerMap = caller as Map<String, dynamic>;
      final id = callerMap['id'];
      if (id is! int || id <= 0) {
        return _jsonError('Требуется авторизация', 401);
      }
      userId = id;
    }

    final userRows = await connection.execute(
      Sql.named('''
        SELECT two_factor_enabled
        FROM public.users
        WHERE id = @id
        LIMIT 1;
      '''),
      parameters: {'id': userId},
    );
    if (userRows.isEmpty) {
      return _jsonError('Пользователь не найден', 404);
    }
    final enabled =
        (userRows.first.toColumnMap()['two_factor_enabled'] as bool?) ?? false;

    final countRows = await connection.execute(
      Sql.named('''
        SELECT COUNT(*) AS remaining
        FROM public.two_factor_backup_codes
        WHERE user_id = @id AND used = false;
      '''),
      parameters: {'id': userId},
    );
    final remaining = _toPositiveInt(
      countRows.isEmpty ? 0 : countRows.first.toColumnMap()['remaining'],
    );

    return _jsonSuccess('ok', {
      'data': {'enabled': enabled, 'backupCodesRemaining': remaining},
    });
  });

  router.post('/auth/2fa/enable/request', (Request request) async {
    try {
      final caller = await _resolveAuthenticatedUser(request, connection);
      if (caller is Response) return caller;
      final user = caller as Map<String, dynamic>;

      final userId = user['id'] as int;
      final email = (user['email']?.toString() ?? '').trim();
      final alreadyEnabled = (user['two_factor_enabled'] as bool?) ?? false;

      if (alreadyEnabled) {
        return _jsonError('Двухфакторная аутентификация уже включена', 400);
      }
      if (email.isEmpty) {
        return _jsonError('У пользователя не указан email', 400);
      }

      final activeRemaining = await _activeOtpRemainingSeconds(
        connection,
        userId: userId,
        purpose: 'enable',
      );
      if (activeRemaining != null) {
        return _jsonSuccess('Код уже отправлен на ваш email', {
          'expires_in': activeRemaining,
        });
      }

      // INTERVAL интерполируем литералом - в Sql.named интервал не биндится.
      final windowMinutes = _twoFactorEnableLockoutWindow.inMinutes;
      final failedRows = await connection.execute(
        Sql.named('''
          SELECT COUNT(*) AS failed
          FROM public.two_factor_audit
          WHERE target_user_id = @user_id
            AND action = 'verify_failure'
            AND context = 'enable'
            AND created_at > NOW() - INTERVAL '$windowMinutes minutes';
        '''),
        parameters: {'user_id': userId},
      );
      final failed = _toPositiveInt(
        failedRows.isEmpty ? 0 : failedRows.first.toColumnMap()['failed'],
      );
      if (_isEnableLockedOut(failed)) {
        final lockoutMinutes = _twoFactorEnableLockoutDuration.inMinutes;
        return _jsonError(
          'Слишком много попыток. Попробуйте через $lockoutMinutes минут',
          429,
        );
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
          purpose: 'enable',
        );
      });

      Future.microtask(() async {
        try {
          await _sendVerificationEmail(email, otp);
        } catch (e) {
          print('Не удалось отправить OTP для включения 2FA: $e');
        }
      });

      return _jsonSuccess('Код отправлен на ваш email', {
        'expires_in': _emailVerificationOtpTtl.inSeconds,
      });
    } catch (e, st) {
      print('Ошибка отправки кода для включения 2FA: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/enable/verify', (Request request) async {
    try {
      final caller = await _resolveAuthenticatedUser(request, connection);
      if (caller is Response) return caller;
      final user = caller as Map<String, dynamic>;

      final userId = user['id'] as int;
      final alreadyEnabled = (user['two_factor_enabled'] as bool?) ?? false;
      if (alreadyEnabled) {
        return _jsonError('Двухфакторная аутентификация уже включена', 400);
      }

      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final code = data['code']?.trim() ?? '';
      if (code.isEmpty) {
        return _jsonError('Код обязателен', 400);
      }

      final ip = _extractClientIp(request);

      List<String>? generatedBackupCodes;
      var otpInvalid = false;

      await connection.runTx((session) async {
        final verRows = await session.execute(
          Sql.named('''
            SELECT id, code_hash
            FROM public.email_verifications
            WHERE user_id = @user_id AND used = false AND expires_at > NOW()
              AND purpose = 'enable'
            ORDER BY created_at DESC
            LIMIT 1
            FOR UPDATE;
          '''),
          parameters: {'user_id': userId},
        );

        if (verRows.isEmpty) {
          otpInvalid = true;
          return;
        }

        final ver = verRows.first.toColumnMap();
        final verId = ver['id'] as int;
        final codeHash = ver['code_hash']?.toString() ?? '';
        if (codeHash.isEmpty || !_checkOtp(code, codeHash)) {
          otpInvalid = true;
          return;
        }

        await session.execute(
          Sql.named('''
            UPDATE public.email_verifications
            SET used = true
            WHERE id = @id;
          '''),
          parameters: {'id': verId},
        );

        await session.execute(
          Sql.named('''
            UPDATE public.users
            SET two_factor_enabled = true
            WHERE id = @id;
          '''),
          parameters: {'id': userId},
        );

        final codes = _generateBackupCodes();
        for (final c in codes) {
          await session.execute(
            Sql.named('''
              INSERT INTO public.two_factor_backup_codes
                (user_id, code_hash, used, created_at)
              VALUES (@user_id, @code_hash, false, NOW());
            '''),
            parameters: {'user_id': userId, 'code_hash': _hashBackupCode(c)},
          );
        }

        await _writeTwoFactorAudit(
          session,
          actorUserId: userId,
          targetUserId: userId,
          action: 'enable',
          context: null,
          ipAddress: ip,
        );

        generatedBackupCodes = codes;
      });

      if (otpInvalid) {
        // Аудит пишем отдельной транзакцией - основная уже откатилась.
        await connection.runTx((session) async {
          await _writeTwoFactorAudit(
            session,
            actorUserId: userId,
            targetUserId: userId,
            action: 'verify_failure',
            context: 'enable',
            ipAddress: ip,
          );
        });
        return _jsonError('Неверный код или истёк срок действия', 400);
      }

      return _jsonSuccess('Двухфакторная аутентификация включена', {
        'data': {'backupCodes': generatedBackupCodes ?? const <String>[]},
      });
    } catch (e, st) {
      print('Ошибка включения 2FA: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/disable/request', (Request request) async {
    try {
      final caller = await _resolveAuthenticatedUser(request, connection);
      if (caller is Response) return caller;
      final user = caller as Map<String, dynamic>;

      final userId = user['id'] as int;
      final email = (user['email']?.toString() ?? '').trim();
      final enabled = (user['two_factor_enabled'] as bool?) ?? false;

      if (!enabled) {
        return _jsonError('Двухфакторная аутентификация уже выключена', 400);
      }
      if (email.isEmpty) {
        return _jsonError('У пользователя не указан email', 400);
      }

      // Lockout для disable не применяется: пользователь уже владеет аккаунтом.

      final activeRemaining = await _activeOtpRemainingSeconds(
        connection,
        userId: userId,
        purpose: 'disable',
      );
      if (activeRemaining != null) {
        return _jsonSuccess('Код уже отправлен на ваш email', {
          'expires_in': activeRemaining,
        });
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
          purpose: 'disable',
        );
      });

      Future.microtask(() async {
        try {
          await _sendVerificationEmail(email, otp);
        } catch (e) {
          print('Не удалось отправить OTP для выключения 2FA: $e');
        }
      });

      return _jsonSuccess('Код отправлен на ваш email', {
        'expires_in': _emailVerificationOtpTtl.inSeconds,
      });
    } catch (e, st) {
      print('Ошибка отправки кода для выключения 2FA: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/backup-codes/request', (Request request) async {
    try {
      final caller = await _resolveAuthenticatedUser(request, connection);
      if (caller is Response) return caller;
      final user = caller as Map<String, dynamic>;

      final userId = user['id'] as int;
      final email = (user['email']?.toString() ?? '').trim();
      final enabled = (user['two_factor_enabled'] as bool?) ?? false;

      if (!enabled) {
        return _jsonError('Двухфакторная аутентификация выключена', 400);
      }
      if (email.isEmpty) {
        return _jsonError('У пользователя не указан email', 400);
      }

      final activeRemaining = await _activeOtpRemainingSeconds(
        connection,
        userId: userId,
        purpose: 'regenerate',
      );
      if (activeRemaining != null) {
        return _jsonSuccess('Код уже отправлен на ваш email', {
          'expires_in': activeRemaining,
        });
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
          purpose: 'regenerate',
        );
      });

      Future.microtask(() async {
        try {
          await _sendVerificationEmail(email, otp);
        } catch (e) {
          print('Не удалось отправить OTP для регенерации backup-кодов: $e');
        }
      });

      return _jsonSuccess('Код отправлен на ваш email', {
        'expires_in': _emailVerificationOtpTtl.inSeconds,
      });
    } catch (e, st) {
      print('Ошибка отправки кода для регенерации backup-кодов: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/trusted-devices/request', (Request request) async {
    try {
      final caller = await _resolveAuthenticatedUser(request, connection);
      if (caller is Response) return caller;
      final user = caller as Map<String, dynamic>;

      final userId = user['id'] as int;
      final email = (user['email']?.toString() ?? '').trim();
      final enabled = (user['two_factor_enabled'] as bool?) ?? false;

      if (!enabled) {
        return _jsonError('Двухфакторная аутентификация выключена', 400);
      }
      if (email.isEmpty) {
        return _jsonError('У пользователя не указан email', 400);
      }

      final activeRemaining = await _activeOtpRemainingSeconds(
        connection,
        userId: userId,
        purpose: 'revoke',
      );
      if (activeRemaining != null) {
        return _jsonSuccess('Код уже отправлен на ваш email', {
          'expires_in': activeRemaining,
        });
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
          purpose: 'revoke',
        );
      });

      Future.microtask(() async {
        try {
          await _sendVerificationEmail(email, otp);
        } catch (e) {
          print('Не удалось отправить OTP для отзыва доверенных устройств: $e');
        }
      });

      return _jsonSuccess('Код отправлен на ваш email', {
        'expires_in': _emailVerificationOtpTtl.inSeconds,
      });
    } catch (e, st) {
      print('Ошибка отправки кода для отзыва доверенных устройств: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/disable/verify', (Request request) async {
    try {
      final caller = await _resolveAuthenticatedUser(request, connection);
      if (caller is Response) return caller;
      final user = caller as Map<String, dynamic>;

      final userId = user['id'] as int;
      final enabled = (user['two_factor_enabled'] as bool?) ?? false;
      if (!enabled) {
        return _jsonError('Двухфакторная аутентификация уже выключена', 400);
      }

      final lockoutResponse = await _checkSensitiveLockout(
        connection,
        userId: userId,
        context: 'disable',
      );
      if (lockoutResponse != null) return lockoutResponse;

      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final code = data['code']?.trim() ?? '';
      if (code.isEmpty) {
        return _jsonError('Код обязателен', 400);
      }

      final ip = _extractClientIp(request);

      var otpInvalid = false;

      await connection.runTx((session) async {
        final verRows = await session.execute(
          Sql.named('''
            SELECT id, code_hash
            FROM public.email_verifications
            WHERE user_id = @user_id AND used = false AND expires_at > NOW()
              AND purpose = 'disable'
            ORDER BY created_at DESC
            LIMIT 1
            FOR UPDATE;
          '''),
          parameters: {'user_id': userId},
        );

        if (verRows.isEmpty) {
          otpInvalid = true;
          return;
        }

        final ver = verRows.first.toColumnMap();
        final verId = ver['id'] as int;
        final codeHash = ver['code_hash']?.toString() ?? '';
        if (codeHash.isEmpty || !_checkOtp(code, codeHash)) {
          otpInvalid = true;
          return;
        }

        await session.execute(
          Sql.named('''
            UPDATE public.email_verifications
            SET used = true
            WHERE id = @id;
          '''),
          parameters: {'id': verId},
        );

        await session.execute(
          Sql.named('''
            UPDATE public.users
            SET two_factor_enabled = false
            WHERE id = @id;
          '''),
          parameters: {'id': userId},
        );

        await session.execute(
          Sql.named('''
            DELETE FROM public.two_factor_backup_codes
            WHERE user_id = @user_id;
          '''),
          parameters: {'user_id': userId},
        );

        await _revokeAllDeviceTokens(session, userId);

        await _writeTwoFactorAudit(
          session,
          actorUserId: userId,
          targetUserId: userId,
          action: 'disable',
          context: null,
          ipAddress: ip,
        );

        await _writeTwoFactorAudit(
          session,
          actorUserId: userId,
          targetUserId: userId,
          action: 'trusted_devices_revoked',
          context: 'disable',
          ipAddress: ip,
        );
      });

      if (otpInvalid) {
        // Аудит пишем отдельной транзакцией - основная уже откатилась.
        await connection.runTx((session) async {
          await _writeTwoFactorAudit(
            session,
            actorUserId: userId,
            targetUserId: userId,
            action: 'verify_failure',
            context: 'disable',
            ipAddress: ip,
          );
        });
        return _jsonError('Неверный код или истёк срок действия', 400);
      }

      return _jsonSuccess('Двухфакторная аутентификация выключена');
    } catch (e, st) {
      print('Ошибка выключения 2FA: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/verify', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final challengeId = data['challengeId']?.trim() ?? '';
      final code = data['code']?.trim() ?? '';
      final backupCode = data['backupCode']?.trim() ?? '';
      final rememberDevice =
          data['rememberDevice']?.trim().toLowerCase() == 'true';

      if (challengeId.isEmpty) {
        return _jsonError('Не указан идентификатор сессии', 400);
      }

      if (!_isUuid(challengeId)) {
        // Без проверки невалидное значение даёт 500 на касте @id::uuid.
        return _jsonError('Некорректный идентификатор сессии', 400);
      }

      // OTP в приоритете; backup-ветка - только когда OTP пустой.
      if (code.isEmpty && backupCode.isEmpty) {
        return _jsonError('Не указан код подтверждения', 400);
      }

      final ip = _extractClientIp(request);
      final isBackupPath = code.isEmpty && backupCode.isNotEmpty;

      if (isBackupPath) {
        return await _handleTwoFactorBackupVerify(
          connection,
          challengeId: challengeId,
          backupCode: backupCode,
          rememberDevice: rememberDevice,
          ipAddress: ip,
        );
      }

      _TwoFactorVerifyResult? consumeResult;
      Map<String, dynamic>? userRow;
      String? deviceTokenRaw;

      await connection.runTx((session) async {
        final result = await _consumeTwoFactorPendingSession(
          session,
          challengeId: challengeId,
          code: code,
        );
        consumeResult = result;

        switch (result.outcome) {
          case _TwoFactorVerifyOutcome.success:
            final userId = result.userId!;
            final rows = await session.execute(
              Sql.named('''
                SELECT id, name, email, role, supplier_name, two_factor_enabled
                FROM public.users
                WHERE id = @id
                LIMIT 1;
              '''),
              parameters: {'id': userId},
            );
            if (rows.isNotEmpty) {
              userRow = rows.first.toColumnMap();
            }

            await _writeTwoFactorAudit(
              session,
              actorUserId: userId,
              targetUserId: userId,
              action: 'verify_success',
              context: 'login',
              ipAddress: ip,
            );

            if (rememberDevice) {
              final token = _generateDeviceToken();
              final tokenHash = _hashOtp(token);
              final expiresAt = DateTime.now().toUtc().add(_trustedDeviceTtl);
              await session.execute(
                Sql.named('''
                  INSERT INTO public.two_factor_trusted_devices
                    (user_id, token_hash, expires_at, revoked, created_at)
                  VALUES (@user_id, @token_hash, @expires_at, false, NOW());
                '''),
                parameters: {
                  'user_id': userId,
                  'token_hash': tokenHash,
                  'expires_at': expiresAt,
                },
              );
              await _writeTwoFactorAudit(
                session,
                actorUserId: userId,
                targetUserId: userId,
                action: 'trusted_device_added',
                context: 'login',
                ipAddress: ip,
              );
              deviceTokenRaw = token;
            }
            break;

          case _TwoFactorVerifyOutcome.invalidCode:
            // Аудит в той же транзакции - инкремент attempts и запись о
            // неудаче коммитятся вместе.
            if (result.userId != null) {
              await _writeTwoFactorAudit(
                session,
                actorUserId: result.userId,
                targetUserId: result.userId!,
                action: 'verify_failure',
                context: 'login',
                ipAddress: ip,
              );
            }
            break;

          case _TwoFactorVerifyOutcome.expired:
          case _TwoFactorVerifyOutcome.sessionInvalid:
            // Истёкшую/невалидную сессию не аудируем - не действие пользователя.
            break;
        }
      });

      final outcome = consumeResult!.outcome;
      switch (outcome) {
        case _TwoFactorVerifyOutcome.success:
          if (userRow == null) {
            return _jsonError('Пользователь не найден', 404);
          }
          final user = userRow!;
          final userId = user['id'] as int;
          final role = user['role']?.toString() ?? _defaultRole;

          final remRows = await connection.execute(
            Sql.named('''
              SELECT COUNT(*) AS remaining
              FROM public.two_factor_backup_codes
              WHERE user_id = @id AND used = false;
            '''),
            parameters: {'id': userId},
          );
          final remaining = _toPositiveInt(
            remRows.isEmpty ? 0 : remRows.first.toColumnMap()['remaining'],
          );

          return _jsonSuccess('Login successful', {
            'data': {
              'user': {
                'id': userId,
                'name': user['name'] ?? '',
                'email': user['email'] ?? '',
                'role': role,
                'supplierName': _supplierNameForRole(
                  role,
                  user['supplier_name'],
                ),
              },
              'deviceToken': deviceTokenRaw,
              'backupCodesRemaining': remaining,
            },
          });

        case _TwoFactorVerifyOutcome.invalidCode:
          // Попытки исчерпаны - 410 сразу, чтобы клиент не ловил его на следующем verify.
          if ((consumeResult!.remainingAttempts) <= 0) {
            return _jsonError('Срок действия кода истёк, повторите вход', 410);
          }
          return _jsonError('Неверный код', 400);

        case _TwoFactorVerifyOutcome.expired:
        case _TwoFactorVerifyOutcome.sessionInvalid:
          return _jsonError('Срок действия кода истёк, повторите вход', 410);
      }
    } catch (e, st) {
      print('Ошибка проверки 2FA-кода: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/resend', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final challengeId = data['challengeId']?.trim() ?? '';

      if (challengeId.isEmpty) {
        return _jsonError('Не указан идентификатор сессии', 400);
      }
      if (!_isUuid(challengeId)) {
        return _jsonError('Некорректный идентификатор сессии', 400);
      }

      var sessionInvalid = false;
      var cooldownActive = false;
      String? targetEmail;
      String? freshOtp;

      await connection.runTx((session) async {
        final rows = await session.execute(
          Sql.named('''
            SELECT id, user_id, last_resend_at, created_at, expires_at, used
            FROM public.two_factor_pending_sessions
            WHERE id = @id::uuid
            FOR UPDATE;
          '''),
          parameters: {'id': challengeId},
        );

        if (rows.isEmpty) {
          sessionInvalid = true;
          return;
        }

        final row = rows.first.toColumnMap();
        final userId = row['user_id'] as int;
        final used = (row['used'] as bool?) ?? false;
        final expiresAtRaw = row['expires_at'];
        final expiresAt = expiresAtRaw is DateTime
            ? expiresAtRaw
            : DateTime.tryParse(expiresAtRaw?.toString() ?? '') ??
                  DateTime.now();
        final nowUtc = DateTime.now().toUtc();
        final expiresUtc = expiresAt.toUtc();

        if (used || expiresUtc.isBefore(nowUtc)) {
          sessionInvalid = true;
          return;
        }

        // Cooldown - от last_resend_at, иначе от created_at.
        final lastResendRaw = row['last_resend_at'];
        final createdAtRaw = row['created_at'];
        DateTime? lastTime;
        if (lastResendRaw != null) {
          lastTime = lastResendRaw is DateTime
              ? lastResendRaw
              : DateTime.tryParse(lastResendRaw.toString());
        }
        lastTime ??= createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.tryParse(createdAtRaw?.toString() ?? '');

        if (lastTime != null) {
          final elapsed = nowUtc.difference(lastTime.toUtc());
          if (elapsed < _twoFactorResendCooldown) {
            cooldownActive = true;
            return;
          }
        }

        // Если пользователь удалён между логином и resend - сессия мёртвая.
        final userRows = await session.execute(
          Sql.named('''
            SELECT email
            FROM public.users
            WHERE id = @id
            LIMIT 1;
          '''),
          parameters: {'id': userId},
        );
        if (userRows.isEmpty) {
          sessionInvalid = true;
          return;
        }
        final email = userRows.first.toColumnMap()['email']?.toString() ?? '';
        if (email.isEmpty) {
          sessionInvalid = true;
          return;
        }

        final otp = _generateOtpCode();
        final otpHash = _hashOtp(otp);

        await session.execute(
          Sql.named('''
            UPDATE public.two_factor_pending_sessions
            SET code_hash = @code_hash, last_resend_at = NOW()
            WHERE id = @id::uuid;
          '''),
          parameters: {'id': challengeId, 'code_hash': otpHash},
        );

        targetEmail = email;
        freshOtp = otp;
      });

      if (sessionInvalid) {
        return _jsonError('Срок действия кода истёк, повторите вход', 410);
      }
      if (cooldownActive) {
        return _jsonError('Слишком частый запрос кода', 429);
      }

      // SMTP вне транзакции - сбой отправки не должен откатывать новый code_hash.
      final emailToSend = targetEmail;
      final otpToSend = freshOtp;
      if (emailToSend != null && otpToSend != null) {
        Future.microtask(() async {
          try {
            await _sendVerificationEmail(emailToSend, otpToSend);
          } catch (e) {
            print('Не удалось отправить повторный 2FA OTP: $e');
          }
        });
      }

      return _jsonSuccess('Код отправлен повторно', {
        'expires_in': _emailVerificationOtpTtl.inSeconds,
      });
    } catch (e, st) {
      print('Ошибка повторной отправки 2FA-кода: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/backup-codes/regenerate', (Request request) async {
    try {
      final caller = await _resolveAuthenticatedUser(request, connection);
      if (caller is Response) return caller;
      final user = caller as Map<String, dynamic>;

      final userId = user['id'] as int;
      final enabled = (user['two_factor_enabled'] as bool?) ?? false;
      if (!enabled) {
        return _jsonError('Двухфакторная аутентификация выключена', 400);
      }

      final lockoutResponse = await _checkSensitiveLockout(
        connection,
        userId: userId,
        context: 'regenerate',
      );
      if (lockoutResponse != null) return lockoutResponse;

      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final code = data['code']?.trim() ?? '';
      if (code.isEmpty) {
        return _jsonError('Код обязателен', 400);
      }

      final ip = _extractClientIp(request);

      List<String>? generatedBackupCodes;
      var otpInvalid = false;

      await connection.runTx((session) async {
        final verRows = await session.execute(
          Sql.named('''
            SELECT id, code_hash
            FROM public.email_verifications
            WHERE user_id = @user_id AND used = false AND expires_at > NOW()
              AND purpose = 'regenerate'
            ORDER BY created_at DESC
            LIMIT 1
            FOR UPDATE;
          '''),
          parameters: {'user_id': userId},
        );

        if (verRows.isEmpty) {
          otpInvalid = true;
          return;
        }

        final ver = verRows.first.toColumnMap();
        final verId = ver['id'] as int;
        final codeHash = ver['code_hash']?.toString() ?? '';
        if (codeHash.isEmpty || !_checkOtp(code, codeHash)) {
          otpInvalid = true;
          return;
        }

        await session.execute(
          Sql.named('''
            UPDATE public.email_verifications
            SET used = true
            WHERE id = @id;
          '''),
          parameters: {'id': verId},
        );

        await session.execute(
          Sql.named('''
            DELETE FROM public.two_factor_backup_codes
            WHERE user_id = @user_id;
          '''),
          parameters: {'user_id': userId},
        );

        final codes = _generateBackupCodes();
        for (final c in codes) {
          await session.execute(
            Sql.named('''
              INSERT INTO public.two_factor_backup_codes
                (user_id, code_hash, used, created_at)
              VALUES (@user_id, @code_hash, false, NOW());
            '''),
            parameters: {'user_id': userId, 'code_hash': _hashBackupCode(c)},
          );
        }

        await _writeTwoFactorAudit(
          session,
          actorUserId: userId,
          targetUserId: userId,
          action: 'regenerate_backup_codes',
          context: null,
          ipAddress: ip,
        );

        generatedBackupCodes = codes;
      });

      if (otpInvalid) {
        // Отдельная транзакция; context='regenerate' отделяет от lockout-расчётов.
        await connection.runTx((session) async {
          await _writeTwoFactorAudit(
            session,
            actorUserId: userId,
            targetUserId: userId,
            action: 'verify_failure',
            context: 'regenerate',
            ipAddress: ip,
          );
        });
        return _jsonError('Неверный код или истёк срок действия', 400);
      }

      return _jsonSuccess('Резервные коды обновлены', {
        'data': {'backupCodes': generatedBackupCodes ?? const <String>[]},
      });
    } catch (e, st) {
      print('Ошибка регенерации backup-кодов: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/trusted-devices/revoke-all', (Request request) async {
    try {
      final caller = await _resolveAuthenticatedUser(request, connection);
      if (caller is Response) return caller;
      final user = caller as Map<String, dynamic>;

      final userId = user['id'] as int;
      final enabled = (user['two_factor_enabled'] as bool?) ?? false;
      if (!enabled) {
        return _jsonError('Двухфакторная аутентификация выключена', 400);
      }

      final lockoutResponse = await _checkSensitiveLockout(
        connection,
        userId: userId,
        context: 'revoke',
      );
      if (lockoutResponse != null) return lockoutResponse;

      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final code = data['code']?.trim() ?? '';
      if (code.isEmpty) {
        return _jsonError('Код обязателен', 400);
      }

      final ip = _extractClientIp(request);

      // _revokeAllDeviceTokens идемпотентен.
      var otpInvalid = false;

      await connection.runTx((session) async {
        final verRows = await session.execute(
          Sql.named('''
            SELECT id, code_hash
            FROM public.email_verifications
            WHERE user_id = @user_id AND used = false AND expires_at > NOW()
              AND purpose = 'revoke'
            ORDER BY created_at DESC
            LIMIT 1
            FOR UPDATE;
          '''),
          parameters: {'user_id': userId},
        );

        if (verRows.isEmpty) {
          otpInvalid = true;
          return;
        }

        final ver = verRows.first.toColumnMap();
        final verId = ver['id'] as int;
        final codeHash = ver['code_hash']?.toString() ?? '';
        if (codeHash.isEmpty || !_checkOtp(code, codeHash)) {
          otpInvalid = true;
          return;
        }

        await session.execute(
          Sql.named('''
            UPDATE public.email_verifications
            SET used = true
            WHERE id = @id;
          '''),
          parameters: {'id': verId},
        );

        await _revokeAllDeviceTokens(session, userId);

        await _writeTwoFactorAudit(
          session,
          actorUserId: userId,
          targetUserId: userId,
          action: 'trusted_devices_revoked',
          context: 'manual',
          ipAddress: ip,
        );
      });

      if (otpInvalid) {
        // Отдельная транзакция; context='revoke' отделяет от lockout-расчётов.
        await connection.runTx((session) async {
          await _writeTwoFactorAudit(
            session,
            actorUserId: userId,
            targetUserId: userId,
            action: 'verify_failure',
            context: 'revoke',
            ipAddress: ip,
          );
        });
        return _jsonError('Неверный код или истёк срок действия', 400);
      }

      return _jsonSuccess('Доверенные устройства отозваны');
    } catch (e, st) {
      print('Ошибка отзыва доверенных устройств: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });

  router.post('/auth/2fa/admin-disable', (Request request) async {
    try {
      // Только moderator/super_admin; иначе вернётся Response 401/403.
      final actor = await _resolveModerationActor(request, connection);
      if (actor is Response) return actor;
      final moderatorId = actor as int;

      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);
      final rawUserId = data['userId']?.trim() ?? '';
      if (rawUserId.isEmpty) {
        return _jsonError('Не указан userId', 400);
      }
      final targetUserId = int.tryParse(rawUserId);
      if (targetUserId == null || targetUserId <= 0) {
        return _jsonError('Некорректный userId', 400);
      }

      final targetRows = await connection.execute(
        Sql.named('''
          SELECT id, email, two_factor_enabled
          FROM public.users
          WHERE id = @id
          LIMIT 1;
        '''),
        parameters: {'id': targetUserId},
      );
      if (targetRows.isEmpty) {
        return _jsonError('Пользователь не найден', 404);
      }
      final target = targetRows.first.toColumnMap();
      final targetEmail = (target['email']?.toString() ?? '').trim();
      final enabled = (target['two_factor_enabled'] as bool?) ?? false;
      if (!enabled) {
        return _jsonError('Двухфакторная аутентификация уже выключена', 400);
      }

      final ip = _extractClientIp(request);

      await connection.runTx((session) async {
        await session.execute(
          Sql.named('''
            UPDATE public.users
            SET two_factor_enabled = false
            WHERE id = @id;
          '''),
          parameters: {'id': targetUserId},
        );

        await session.execute(
          Sql.named('''
            DELETE FROM public.two_factor_backup_codes
            WHERE user_id = @user_id;
          '''),
          parameters: {'user_id': targetUserId},
        );

        await _revokeAllDeviceTokens(session, targetUserId);

        // Пишем безусловно для симметрии с disable-verify - аналитика
        // ожидает парную запись, даже если активных устройств у
        // пользователя не было.
        await _writeTwoFactorAudit(
          session,
          actorUserId: moderatorId,
          targetUserId: targetUserId,
          action: 'trusted_devices_revoked',
          context: 'admin',
          ipAddress: ip,
        );

        await _writeTwoFactorAudit(
          session,
          actorUserId: moderatorId,
          targetUserId: targetUserId,
          action: 'admin_disable',
          context: 'admin',
          ipAddress: ip,
        );
      });

      // Уведомление фоном - сбой SMTP не влияет на ответ модератору.
      if (targetEmail.isNotEmpty) {
        Future.microtask(() async {
          try {
            await _sendAdminDisableEmail(targetEmail);
          } catch (e) {
            print('Не удалось отправить уведомление об admin-disable: $e');
          }
        });
      }

      return _jsonSuccess('Двухфакторная аутентификация отключена');
    } catch (e, st) {
      print('Ошибка admin-disable 2FA: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });
}
