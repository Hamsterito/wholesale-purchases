part of '../backend.dart';

// Хелперы аутентификации: генерация и хеширование OTP/паролей,
// замена кода подтверждения, периодическая очистка истекших кодов,
// отправка email с кодом подтверждения.

// Длина OTP - 6 знаков. Экспортируется как debugOtpCodeLength для PBT.
const int debugOtpCodeLength = 6;

// Генерация 6-значного OTP кода
String _generateOtpCode() {
  final rnd = Random.secure();
  return List<int>.generate(debugOtpCodeLength, (_) => rnd.nextInt(10)).join();
}

// Хеширование пароля с солью
String _hashPassword(String password) =>
    BCrypt.hashpw(password, BCrypt.gensalt());

// Проверка пароля с хешем
bool _checkPassword(String password, String hashed) =>
    BCrypt.checkpw(password, hashed);

// Хеширование OTP кода с солью
String _hashOtp(String otp) => BCrypt.hashpw(otp, BCrypt.gensalt());

// Проверка OTP кода с хешем
bool _checkOtp(String otp, String hashed) => BCrypt.checkpw(otp, hashed);

// Публичные обёртки для property-тестов: _hashOtp и _checkOtp приватные,
// а тестам нужен прямой доступ, чтобы валидировать инвариант
// «правильный код проходит, любой другой - нет» без БД и моков.
String debugHashOtp(String otp) => _hashOtp(otp);
bool debugCheckOtp(String otp, String hashed) => _checkOtp(otp, hashed);

// Тестовая обёртка вокруг _generateOtpCode - используется PBT энтропии OTP.
String debugGenerateOtpCode() => _generateOtpCode();

// Замена ожидающего кода подтверждения email
// Деактивирует старые коды пользователя и создает новый
Future<void> _replacePendingEmailVerificationCode(
  Session session, {
  required int userId,
  required String codeHash,
  required DateTime expiresAt,
  String? purpose,
}) async {
  // Помечаем старые неиспользованные коды как использованные
  await session.execute(
    Sql.named('''
      UPDATE public.email_verifications
      SET used = true
      WHERE user_id = @user_id AND used = false;
    '''),
    parameters: {'user_id': userId},
  );

  // Удаляем истекшие коды
  final expiredResult = await session.execute(
    Sql.named('''
      DELETE FROM public.email_verifications
      WHERE expires_at < NOW();
    '''),
  );
  if (expiredResult.affectedRows > 0) {
    print('Очищено ${expiredResult.affectedRows} истекших кодов при замене');
  }

  // Создаем новый код верификации
  await session.execute(
    Sql.named('''
      INSERT INTO public.email_verifications (user_id, code_hash, expires_at, used, purpose, created_at)
      VALUES (@user_id, @code_hash, @expires_at, false, @purpose, NOW());
    '''),
    parameters: {
      'user_id': userId,
      'code_hash': codeHash,
      'expires_at': expiresAt,
      'purpose': purpose,
    },
  );
}

// Периодическая очистка истекших кодов подтверждения email
// Запускается каждые 10 минут в main()
Future<void> _cleanupExpiredEmailVerifications(Connection connection) async {
  print('Запуск очистки истекших кодов подтверждения email...');
  try {
    final result = await connection.execute(
      Sql.named('''
        DELETE FROM public.email_verifications
        WHERE expires_at < NOW() AND used = false;
      '''),
    );
    print(
      'Очистка завершена. Удалено ${result.affectedRows} истекших записей.',
    );
    if (result.affectedRows > 0) {
      print(
        'Успешно очищено ${result.affectedRows} истекших кодов подтверждения email',
      );
    }
  } catch (e, st) {
    print('Ошибка при очистке истекших кодов подтверждения email: $e\n$st');
  }
}

// Периодическая очистка истекших кодов сброса пароля
// Запускается каждые 10 минут вместе с очисткой email верификаций
Future<void> _cleanupExpiredPasswordResets(Connection connection) async {
  print('Запуск очистки истекших кодов сброса пароля...');
  try {
    final result = await connection.execute(
      Sql.named('''
        DELETE FROM public.password_resets
        WHERE expires_at < NOW();
      '''),
    );
    print(
      'Очистка завершена. Удалено ${result.affectedRows} истекших записей сброса пароля.',
    );
    if (result.affectedRows > 0) {
      print(
        'Успешно очищено ${result.affectedRows} истекших кодов сброса пароля',
      );
    }
  } catch (e, st) {
    print('Ошибка при очистке истекших кодов сброса пароля: $e\n$st');
  }
}

// Отправка email с кодом подтверждения
Future<void> _sendVerificationEmail(String toEmail, String code) async {
  // Получаем учетные данные SMTP из переменных окружения
  final smtpUser = env['SMTP_USERNAME'];
  final smtpPass = env['SMTP_PASSWORD'];
  if (smtpUser == null || smtpPass == null) {
    print(
      'SMTP учетные данные не настроены в переменных окружения. Пропускаем отправку email.',
    );
    return;
  }

  // Настраиваем SMTP сервер Gmail
  final smtpServer = gmail(smtpUser, smtpPass);

  // Создаем сообщение
  final message = Message()
    ..from = Address(smtpUser, 'Wholesale Purchases')
    ..recipients.add(toEmail)
    ..subject = 'Код подтверждения почты'
    ..text =
        'Ваш код подтверждения: $code\nКод действителен $_emailVerificationOtpTtlMinutes минут.';

  try {
    final sendReport = await send(message, smtpServer);
    print('Email с подтверждением отправлен: $sendReport');
  } catch (e, st) {
    print('Не удалось отправить email с подтверждением: $e\n$st');
  }
}

// Уведомление пользователю о принудительном отключении 2FA модератором.
// Использует ту же SMTP-инфраструктуру, что и _sendVerificationEmail:
// при отсутствии SMTP-кредов в env молча пропускаем отправку, исключения
// SMTP не пробрасываем - вызывающий код всё равно дёргает функцию из
// Future.microtask и не должен падать из-за сбоя почты.
Future<void> _sendAdminDisableEmail(String toEmail) async {
  final smtpUser = env['SMTP_USERNAME'];
  final smtpPass = env['SMTP_PASSWORD'];
  if (smtpUser == null || smtpPass == null) {
    print(
      'SMTP учетные данные не настроены в переменных окружения. '
      'Пропускаем отправку уведомления об admin-disable.',
    );
    return;
  }

  final smtpServer = gmail(smtpUser, smtpPass);

  final message = Message()
    ..from = Address(smtpUser, 'Wholesale Purchases')
    ..recipients.add(toEmail)
    ..subject = 'Двухфакторная аутентификация отключена'
    ..text =
        'Двухфакторная аутентификация на вашем аккаунте отключена '
        'сотрудником поддержки. Все доверенные устройства отозваны и '
        'резервные коды удалены.\n\n'
        'Если вы не запрашивали отключение, обратитесь в поддержку '
        'и при необходимости включите 2FA повторно в настройках.';

  try {
    final sendReport = await send(message, smtpServer);
    print('Email об отключении 2FA отправлен: $sendReport');
  } catch (e, st) {
    print('Не удалось отправить уведомление об отключении 2FA: $e\n$st');
  }
}
