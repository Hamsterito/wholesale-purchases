import 'package:flutter/widgets.dart';
import 'package:flutter_project/models/support_message.dart';
import 'package:flutter_project/services/api/api_service.dart';
import 'package:flutter_project/services/storage/auth_storage.dart';
import 'package:flutter_project/services/storage/shared_prefs_provider.dart';

import 'app_logger.dart';
import 'notification_service.dart';

/// Сервис для отслеживания и управления уведомлениями модерации (например, об удаленных товарах)
/// с использованием существующих сообщений техподдержки.
class ModerationAlertService extends ChangeNotifier {
  static final ModerationAlertService _instance =
      ModerationAlertService._internal();

  factory ModerationAlertService() => _instance;

  ModerationAlertService._internal() {
    NotificationService().unreadMessagesCount.addListener(_onUnreadMessagesChanged);
  }

  static const String _lastMessageIdKeyPrefix = 'last_dismissed_moderation_msg_';

  List<SupportMessage> _pendingAlerts = [];
  bool _isLoading = false;

  List<SupportMessage> get pendingAlerts => _pendingAlerts;
  bool get hasAlerts => _pendingAlerts.isNotEmpty;
  bool get isLoading => _isLoading;

  void _onUnreadMessagesChanged() {
    // Если есть непрочитанные сообщения, проверяем, не являются ли они уведомлениями модерации
    if (NotificationService().unreadMessagesCount.value > 0) {
      checkNewAlerts();
    }
  }

  Future<void> checkNewAlerts() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final thread = await ApiService.getSupportThread(userId: userId);
      final prefs = await SharedPrefsProvider.getInstance();
      final lastDismissedId = prefs.getInt('$_lastMessageIdKeyPrefix$userId') ?? 0;

      // Фильтруем сообщения от модератора в категории 'Модерация товаров',
      // у которых ID больше последнего скрытого.
      final newAlerts = thread.messages.where((msg) {
        if (!msg.isFromModerator) return false;
        if (msg.category != 'Модерация товаров') return false;
        
        final msgId = int.tryParse(msg.id) ?? 0;
        return msgId > lastDismissedId;
      }).toList();

      _pendingAlerts = newAlerts;
    } catch (e, st) {
      AppLogger.error(
        'Ошибка загрузки уведомлений модерации',
        scope: 'moderation_alert',
        error: e,
        stackTrace: st,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Скрывает все текущие уведомления модерации, сохраняя наибольший ID сообщения.
  Future<void> dismissAllAlerts() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    if (_pendingAlerts.isEmpty) return;

    int maxId = 0;
    for (final msg in _pendingAlerts) {
      final msgId = int.tryParse(msg.id) ?? 0;
      if (msgId > maxId) {
        maxId = msgId;
      }
    }

    if (maxId > 0) {
      final prefs = await SharedPrefsProvider.getInstance();
      await prefs.setInt('$_lastMessageIdKeyPrefix$userId', maxId);
    }

    _pendingAlerts = [];
    notifyListeners();
  }

  /// Извлекает название товара и причину из стандартного текста сообщения модерации.
  /// Пример: Товар "Voda" удален модератором за нарушение. Причина: спам
  static ModerationAlertInfo parseMessageText(String text) {
    String productName = 'Неизвестный товар';
    String reason = 'Нарушение правил площадки';

    final match = RegExp(r'Товар "(.*?)" удален.*?Причина: (.*)').firstMatch(text);
    if (match != null) {
      productName = match.group(1) ?? productName;
      reason = match.group(2) ?? reason;
    } else {
      // Пробуем одинарные кавычки или без кавычек
      final fallbackMatch = RegExp(r'Товар (.*?) удален.*?Причина: (.*)').firstMatch(text);
      if (fallbackMatch != null) {
        productName = fallbackMatch.group(1)?.replaceAll(RegExp(r'["'']'), '') ?? productName;
        reason = fallbackMatch.group(2) ?? reason;
      }
    }

    return ModerationAlertInfo(productName: productName, reason: reason);
  }

  @override
  void dispose() {
    NotificationService().unreadMessagesCount.removeListener(_onUnreadMessagesChanged);
    super.dispose();
  }
}

class ModerationAlertInfo {
  final String productName;
  final String reason;

  ModerationAlertInfo({required this.productName, required this.reason});
}
