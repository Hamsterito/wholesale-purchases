import 'dart:developer' as developer;

class AppLogger {
  const AppLogger._();

  static const String _namespace = 'wholesale_purchases';

  static void debug(String message, {String scope = 'app'}) {
    _write(level: 500, levelLabel: 'DEBUG', message: message, scope: scope);
  }

  static void info(String message, {String scope = 'app'}) {
    _write(level: 800, levelLabel: 'INFO', message: message, scope: scope);
  }

  static void warning(String message, {String scope = 'app'}) {
    _write(level: 900, levelLabel: 'WARN', message: message, scope: scope);
  }

  static void error(
    String message, {
    String scope = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(
      level: 1000,
      levelLabel: 'ERROR',
      message: message,
      scope: scope,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _write({
    required int level,
    required String levelLabel,
    required String message,
    required String scope,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '[$levelLabel] $message',
      name: '$_namespace.$scope',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
