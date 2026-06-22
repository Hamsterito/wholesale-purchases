part of '../backend.dart';

// Хелперы аутентификации: OTP, пароли, очистка кодов и отправка писем.

// Длина OTP. debug-версия нужна для PBT.
const int debugOtpCodeLength = 6;

String _generateOtpCode() {
  final rnd = Random.secure();
  return List<int>.generate(debugOtpCodeLength, (_) => rnd.nextInt(10)).join();
}

String _hashPassword(String password) =>
    BCrypt.hashpw(password, BCrypt.gensalt());

bool _checkPassword(String password, String hashed) =>
    BCrypt.checkpw(password, hashed);

String _hashOtp(String otp) => BCrypt.hashpw(otp, BCrypt.gensalt());

bool _checkOtp(String otp, String hashed) => BCrypt.checkpw(otp, hashed);

// Публичные обертки для property-тестов.
String debugHashOtp(String otp) => _hashOtp(otp);
bool debugCheckOtp(String otp, String hashed) => _checkOtp(otp, hashed);

// Тестовая обертка для PBT энтропии.
String debugGenerateOtpCode() => _generateOtpCode();

// Деактивирует старые коды верификации и создает новый.
Future<void> _replacePendingEmailVerificationCode(
  Session session, {
  required int userId,
  required String codeHash,
  required DateTime expiresAt,
  String? purpose,
}) async {
  await session.execute(
    Sql.named('''
      UPDATE public.email_verifications
      SET used = true
      WHERE user_id = @user_id AND used = false;
    '''),
    parameters: {'user_id': userId},
  );

  final expiredResult = await session.execute(
    Sql.named('''
      DELETE FROM public.email_verifications
      WHERE expires_at < NOW();
    '''),
  );
  if (expiredResult.affectedRows > 0) {
    print('Очищено ${expiredResult.affectedRows} истекших кодов при замене');
  }

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

// Периодическая очистка истекших кодов подтверждения email (раз в 10 минут).
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

// Периодическая очистка кодов сброса пароля (раз в 10 минут).
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

Future<void> _sendVerificationEmail(String toEmail, String code) async {
  // Читаем из .env или переменных окружения.
  final smtpUser =
      env['SMTP_USERNAME'] ?? Platform.environment['SMTP_USERNAME'];
  final smtpPass =
      env['SMTP_PASSWORD'] ?? Platform.environment['SMTP_PASSWORD'];
  if (smtpUser == null || smtpPass == null) {
    print(
      'SMTP учетные данные не настроены в переменных окружения. Пропускаем отправку email.',
    );
    return;
  }

  final smtpServer = gmail(smtpUser, smtpPass);

  final message = Message()
    ..from = Address(smtpUser, 'Wholesale Purchases')
    ..recipients.add(toEmail)
    ..subject = 'Код подтверждения почты'
    ..text =
        'Ваш код подтверждения: $code\nСпасибо, что вы используете наше приложение!';

  try {
    final sendReport = await send(message, smtpServer);
    print('Email с подтверждением отправлен: $sendReport');
  } catch (e, st) {
    print('Не удалось отправить email с подтверждением: $e\n$st');
  }
}

// Уведомление об отключении 2FA модератором. Не пробрасывает ошибки SMTP,
// так как вызывается в Future.microtask и не должно ронять поток.
Future<void> _sendAdminDisableEmail(String toEmail) async {
  // Читаем из .env или переменных окружения.
  final smtpUser =
      env['SMTP_USERNAME'] ?? Platform.environment['SMTP_USERNAME'];
  final smtpPass =
      env['SMTP_PASSWORD'] ?? Platform.environment['SMTP_PASSWORD'];
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
