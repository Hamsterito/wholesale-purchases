import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Роль для выбора нижней навигации. super_admin отделён от moderator,
/// потому что у него на одну вкладку больше (Модераторы).
enum NavRole { buyer, supplier, moderator, superAdmin }

/// Сопоставляет строку роли из AuthStorage с NavRole.
/// Сравнение строгое и регистрозависимое: всё, что не равно точно
/// одному из токенов, трактуется как buyer (безопасный дефолт).
NavRole resolveNavRole(String? rawRole) {
  switch (rawRole) {
    case 'buyer':
      return NavRole.buyer;
    case 'supplier':
      return NavRole.supplier;
    case 'moderator':
      return NavRole.moderator;
    case 'super_admin':
      return NavRole.superAdmin;
    default:
      return NavRole.buyer;
  }
}

/// Описание одной вкладки роль-зависимой навигации.
class RoleNavTab {
  const RoleNavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.pageBuilder,
    this.badgeCount,
  });

  /// Текстовая метка, она же то, что озвучивает screen reader вместо SVG.
  final String label;

  /// SVG в неактивном/активном состоянии.
  final String icon;
  final String activeIcon;

  /// Страница, которую показывает IndexedStack для этой вкладки.
  final WidgetBuilder pageBuilder;

  /// Источник счётчика значка. null - значок не показывается.
  final ValueListenable<int>? badgeCount;
}
