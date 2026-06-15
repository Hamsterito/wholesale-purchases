import 'package:http/http.dart' as http;

import '../app_logger.dart';

class AppHttpClient {
  AppHttpClient._();

  static http.Client instance = create();

  static http.Client create() {
    return _LoggingHttpClient();
  }
}

class _LoggingHttpClient extends http.BaseClient {
  _LoggingHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.debug('${request.method} ${request.url}', scope: 'http');

    try {
      final response = await _inner.send(request);
      stopwatch.stop();

      final message =
          '${request.method} ${request.url} -> ${response.statusCode} (${stopwatch.elapsedMilliseconds} ms)';
      if (response.statusCode >= 500) {
        AppLogger.error(message, scope: 'http');
      } else if (response.statusCode >= 400) {
        AppLogger.warning(message, scope: 'http');
      } else {
        AppLogger.info(message, scope: 'http');
      }

      return response;
    } catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.error(
        '${request.method} ${request.url} failed after ${stopwatch.elapsedMilliseconds} ms',
        scope: 'http',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}
