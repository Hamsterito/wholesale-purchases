// Native-реализация SSE через package:http. На web подключается
// sse_stream_web.dart с нативным EventSource.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_http_client.dart';

/// Один SSE-стрим по uri. Завершается при разрыве — reconnect/backoff
/// делает _SharedEventStream.
Stream<Map<String, dynamic>> openSseStream(
  Uri uri, {
  required String streamLabel,
}) async* {
  final client = AppHttpClient.create();
  try {
    final request = http.Request('GET', uri)
      ..headers['accept'] = 'text/event-stream';
    final response = await client.send(request);

    if (response.statusCode != 200) {
      final bodyBytes = await response.stream.toBytes();
      final body = utf8.decode(bodyBytes, allowMalformed: true);
      final suffix = body.trim().isEmpty ? '' : ': ${body.trim()}';
      throw Exception(
        'Не удалось подключиться к SSE ($streamLabel), код ${response.statusCode}$suffix',
      );
    }

    final dataLines = <String>[];
    String? eventName;

    Map<String, dynamic>? flushFrame() {
      if (dataLines.isEmpty) {
        eventName = null;
        return null;
      }
      final rawPayload = dataLines.join('\n');
      dataLines.clear();
      final currentEvent = eventName;
      eventName = null;

      if (rawPayload.trim().isEmpty) return null;
      try {
        final decoded = jsonDecode(rawPayload);
        if (decoded is Map) {
          final m = Map<String, dynamic>.from(decoded);
          if (currentEvent != null && currentEvent.isNotEmpty) {
            m['event'] = currentEvent;
          }
          return m;
        }
        return {'kind': 'message', 'payload': decoded};
      } catch (_) {
        return null;
      }
    }

    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.isEmpty) {
        final frame = flushFrame();
        if (frame != null) yield frame;
        continue;
      }
      if (line.startsWith(':')) continue;
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
        continue;
      }
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    final trailingFrame = flushFrame();
    if (trailingFrame != null) yield trailingFrame;
  } catch (e) {
    debugPrint('Ошибка SSE-подписки ($streamLabel): $e');
    rethrow;
  } finally {
    client.close();
  }
}
