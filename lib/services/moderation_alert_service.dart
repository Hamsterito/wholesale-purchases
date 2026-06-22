import 'package:flutter/widgets.dart';
import 'package:flutter_project/services/api/api_service.dart';
import 'package:flutter_project/services/storage/auth_storage.dart';

import 'app_logger.dart';
import 'notification_service.dart';

/// Сервис для отслеживания и управления уведомлениями модерации (например, об удаленных товарах)
/// с использованием существующих сообщений техподдержки.
class ModerationAlertService extends ChangeNotifier {
  static final ModerationAlertService _instance =
      ModerationAlertService._internal();

  factory ModerationAlertService() => _instance;

  ModerationAlertService._internal() {
    NotificationService().pendingModerationDeletionsCount.addListener(_onPendingModerationsChanged);
  }

  List<ModerationAlertInfo> _pendingAlerts = [];
  bool _isLoading = false;

  List<ModerationAlertInfo> get pendingAlerts => _pendingAlerts;
  bool get hasAlerts => _pendingAlerts.isNotEmpty;
  bool get isLoading => _isLoading;

  void _onPendingModerationsChanged() {
    if (NotificationService().pendingModerationDeletionsCount.value > 0) {
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
      final deletionsData = await ApiService.getModerationDeletions(userId: userId);
      final newAlerts = deletionsData.map((d) => ModerationAlertInfo.fromJson(d as Map<String, dynamic>)).toList();
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

  /// Скрывает все текущие уведомления модерации.
  Future<void> dismissAllAlerts() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    if (_pendingAlerts.isEmpty) return;

    for (final alert in _pendingAlerts) {
      if (alert.id > 0) {
        try {
          await ApiService.dismissModerationDeletion(id: alert.id, userId: userId);
        } catch (e) {
          debugPrint('Failed to dismiss alert ${alert.id}: $e');
        }
      }
    }

    _pendingAlerts = [];
    notifyListeners();
  }



  @override
  void dispose() {
    NotificationService().pendingModerationDeletionsCount.removeListener(_onPendingModerationsChanged);
    super.dispose();
  }
}

class ModerationAlertInfo {
  final int id;
  final String productName;
  final String productNameKk;
  final String reason;
  final DateTime? createdAt;

  ModerationAlertInfo({
    required this.id,
    required this.productName,
    required this.productNameKk,
    required this.reason,
    this.createdAt,
  });

  factory ModerationAlertInfo.fromJson(Map<String, dynamic> json) {
    return ModerationAlertInfo(
      id: int.tryParse(json['id'].toString()) ?? 0,
      productName: json['productName'] ?? '',
      productNameKk: json['productNameKk'] ?? '',
      reason: json['reason'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

