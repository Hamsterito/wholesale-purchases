// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

// Web-реализация SSE через нативный EventSource. На XHR-стримы из
// package:http полагаться нельзя: сокеты не освобождаются мгновенно после
// close() и Chrome быстро упирается в лимит 6 на origin.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Имена SSE-кадров, которые присылает сервер. EventSource доставляет
/// каждое именованное событие отдельно, поэтому подписываемся явно.
const _knownEvents = <String>[
  'message',
  'connected',
  'support',
  'chat-created',
  'chat-message',
  'chat-read',
];

Stream<Map<String, dynamic>> openSseStream(
  Uri uri, {
  required String streamLabel,
}) {
  final controller = StreamController<Map<String, dynamic>>();
  html.EventSource? source;
  final subs = <StreamSubscription<html.Event>>[];
  StreamSubscription<html.Event>? errSub;

  void emit(html.MessageEvent event, String name) {
    if (controller.isClosed) return;
    final raw = event.data?.toString() ?? '';
    if (raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded);
        // Прокидываем имя кадра в payload под ключом 'event' - как в native.
        if (name.isNotEmpty && name != 'message') {
          m['event'] = name;
        }
        controller.add(m);
      } else {
        controller.add({'kind': 'message', 'payload': decoded});
      }
    } catch (e) {
      debugPrint('SSE ($streamLabel): не удалось распарсить кадр: $e');
    }
  }

  controller.onListen = () {
    try {
      source = html.EventSource(uri.toString());
      for (final name in _knownEvents) {
        subs.add(
          source!.on[name].listen((event) {
            if (event is html.MessageEvent) emit(event, name);
          }),
        );
      }

      errSub = source!.onError.listen((_) {
        // EventSource сам реконнектится, пока readyState != CLOSED. Если
        // CLOSED - пробрасываем ошибку наверх для backoff'а в _SharedEventStream.
        final rs = source?.readyState ?? html.EventSource.CLOSED;
        if (rs == html.EventSource.CLOSED) {
          if (!controller.isClosed) {
            controller.addError(
              Exception('SSE ($streamLabel): соединение закрыто'),
            );
          }
        }
      });
    } catch (e, st) {
      controller.addError(e, st);
    }
  };

  controller.onCancel = () async {
    for (final s in subs) {
      await s.cancel();
    }
    subs.clear();
    await errSub?.cancel();
    errSub = null;
    try {
      source?.close();
    } catch (_) {}
    source = null;
  };

  return controller.stream;
}
