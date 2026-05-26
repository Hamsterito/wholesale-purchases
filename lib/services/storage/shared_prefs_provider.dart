import 'package:shared_preferences/shared_preferences.dart';

/// Общий singleton поверх SharedPreferences. Гарантирует один вызов
/// SharedPreferences.getInstance на процесс - дальше отдаём кэш.
class SharedPrefsProvider {
  SharedPrefsProvider._();

  static SharedPreferences? _cached;

  /// Возвращает прогретый экземпляр или инициализирует его на первом вызове.
  static Future<SharedPreferences> getInstance() async {
    return _cached ??= await SharedPreferences.getInstance();
  }

  /// Синхронный доступ к уже прогретому экземпляру. Вернёт null, если warmup
  /// ещё не завершился - вызывающий код сам решает, ждать ли getInstance.
  static SharedPreferences? get cached => _cached;

  /// Прогрев в main до runApp, чтобы дальнейшие чтения шли без awaitов.
  static Future<void> warmup() async {
    _cached ??= await SharedPreferences.getInstance();
  }
}
