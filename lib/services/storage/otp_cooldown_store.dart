import 'shared_prefs_provider.dart';

/// Cooldown запросов OTP в SharedPreferences по ключу (identifier, purpose).
/// Окно равно TTL OTP на сервере (60 сек), чтобы повторный заход на экран
/// не дёргал /request - сервер вернул бы остаток того же кода.
class OtpCooldownStore {
  OtpCooldownStore._();

  static const Duration cooldown = Duration(seconds: 60);

  static String _key(String identifier, String purpose) {
    final normalized = identifier.trim().toLowerCase();
    return 'otp_request_at_${normalized}_$purpose';
  }

  /// Помечает, что для (identifier, purpose) только что выпущен OTP.
  static Future<void> markRequested(String identifier, String purpose) async {
    if (identifier.trim().isEmpty || purpose.isEmpty) return;
    final prefs = await SharedPrefsProvider.getInstance();
    await prefs.setInt(
      _key(identifier, purpose),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Возвращает сколько секунд до следующего /request, 0 - можно запрашивать.
  static Future<int> remainingSeconds(String identifier, String purpose) async {
    if (identifier.trim().isEmpty || purpose.isEmpty) return 0;
    final prefs = await SharedPrefsProvider.getInstance();
    final lastMs = prefs.getInt(_key(identifier, purpose));
    if (lastMs == null) return 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
    final remainingMs = cooldown.inMilliseconds - elapsed;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil();
  }

  /// Сбрасывает cooldown - после успешного verify, чтобы новый запрос кода
  /// прошёл сразу без ожидания.
  static Future<void> clear(String identifier, String purpose) async {
    if (identifier.trim().isEmpty || purpose.isEmpty) return;
    final prefs = await SharedPrefsProvider.getInstance();
    await prefs.remove(_key(identifier, purpose));
  }
}
