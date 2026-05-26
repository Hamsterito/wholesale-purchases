import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/message.dart';
import '../shared_prefs_provider.dart';

/// Кэш сообщений поверх SharedPreferences. FIFO по timestamp.
/// Ошибки SharedPreferences и парсинга не пробрасываются — сбой кэша не должен ронять приложение.
class MessageStore {
  MessageStore._();

  static const int maxCacheSize = 1000;
  static const String _storageKey = 'message_store_cache';

  static final List<Message> _cache = [];

  static Future<void> save(Message message) async {
    _cache.add(message);
    await _enforceMaxSize();
    await _persist();
  }

  static Future<Message?> getById(String id) async {
    if (_cache.isEmpty) {
      await loadAll();
    }
    for (final message in _cache) {
      if (message.id == id) return message;
    }
    return null;
  }

  static Future<List<Message>> getByType(MessageType type) async {
    if (_cache.isEmpty) {
      await loadAll();
    }
    return _cache.where((m) => m.type == type).toList();
  }

  static Future<List<Message>> getBySeverity(MessageSeverity severity) async {
    if (_cache.isEmpty) {
      await loadAll();
    }
    return _cache.where((m) => m.severity == severity).toList();
  }

  static Future<void> clear() async {
    _cache.clear();
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('MessageStore.clear: ошибка SharedPreferences — $e');
    }
  }

  /// Невалидные элементы пропускаются, чтобы один битый не ронял всю загрузку.
  static Future<List<Message>> loadAll() async {
    List<Message> loaded = [];
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        _cache
          ..clear()
          ..addAll(loaded);
        return loaded;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _cache
          ..clear()
          ..addAll(loaded);
        return loaded;
      }

      for (final entry in decoded) {
        if (entry is! Map) continue;
        try {
          final json = Map<String, dynamic>.from(entry);
          loaded.add(Message.fromJson(json));
        } catch (e) {
          debugPrint('MessageStore.loadAll: пропущена невалидная запись — $e');
        }
      }

      loaded.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      debugPrint('MessageStore.loadAll: ошибка чтения кэша — $e');
      loaded = [];
    }

    _cache
      ..clear()
      ..addAll(loaded);
    return loaded;
  }

  static Future<String> exportAll() async {
    if (_cache.isEmpty) {
      await loadAll();
    }
    final list = _cache.map((m) => m.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(list);
  }

  static Future<void> _enforceMaxSize() async {
    if (_cache.length <= maxCacheSize) {
      // save мог добавить сообщение со старым timestamp — пересортируем.
      _cache.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return;
    }
    _cache.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final overflow = _cache.length - maxCacheSize;
    _cache.removeRange(0, overflow);
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final list = _cache.map((m) => m.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('MessageStore._persist: ошибка записи кэша — $e');
    }
  }
}
