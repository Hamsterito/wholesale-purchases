import 'package:flutter/widgets.dart';
import 'package:flutter_project/moderator/moderation_page.dart';
import 'package:flutter_project/moderator/moderator_management_page.dart';
import 'package:flutter_project/moderator/support_chats_page.dart';
import 'package:flutter_project/pages/cart_page.dart';
import 'package:flutter_project/pages/catalog.dart';
import 'package:flutter_project/pages/home_page.dart';
import 'package:flutter_project/profile/profile_page.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import 'package:flutter_project/services/notification_service.dart';
import 'package:flutter_project/supplier/supplier_orders_page.dart';
import 'package:flutter_project/supplier/supplier_products_page.dart';
import 'package:flutter_project/supplier/supplier_statistics_page.dart';

import 'nav_role.dart';

/// Возвращает набор вкладок для роли в порядке слева направо.
///
/// Все роли рендерятся через один и тот же RoleNavigationBar, поэтому набор
/// вкладок - единственное, что отличает панели. moderator и super_admin
/// делят одну семью вкладок: super_admin добавляет Модераторы перед Профилем.
List<RoleNavTab> tabsForRole(NavRole role, BuildContext context) {
  final notifications = NotificationService();
  final l10n = context.l10n;

  switch (role) {
    case NavRole.buyer:
      return [
        RoleNavTab(
          label: l10n.home,
          icon: 'assets/icons/main.svg',
          activeIcon: 'assets/icons/main_active.svg',
          pageBuilder: (_) => const HomePage(),
        ),
        RoleNavTab(
          label: l10n.catalog,
          icon: 'assets/icons/catalog.svg',
          activeIcon: 'assets/icons/catalog_active.svg',
          pageBuilder: (_) => const CatalogPage(),
        ),
        RoleNavTab(
          label: l10n.cart,
          icon: 'assets/icons/cart.svg',
          activeIcon: 'assets/icons/cart_active.svg',
          pageBuilder: (_) => const CartPage(),
        ),
        RoleNavTab(
          label: l10n.profile,
          icon: 'assets/icons/profile.svg',
          activeIcon: 'assets/icons/profile_active.svg',
          pageBuilder: (_) => const ProfilePage(),
          badgeCount: notifications.totalNotificationCount,
        ),
      ];

    case NavRole.supplier:
      return [
        RoleNavTab(
          label: l10n.products,
          icon: 'assets/icons/products.svg',
          activeIcon: 'assets/icons/products_active.svg',
          pageBuilder: (_) => const SupplierProductsPage(),
        ),
        RoleNavTab(
          label: l10n.orders,
          icon: 'assets/icons/orders.svg',
          activeIcon: 'assets/icons/orders_active.svg',
          pageBuilder: (_) => const SupplierOrdersPage(),
          badgeCount: notifications.pendingSupplierOrdersCount,
        ),
        RoleNavTab(
          label: l10n.statistics,
          icon: 'assets/icons/stats.svg',
          activeIcon: 'assets/icons/stats_active.svg',
          pageBuilder: (_) => const SupplierStatisticsPage(),
        ),
        RoleNavTab(
          label: l10n.profile,
          icon: 'assets/icons/profile.svg',
          activeIcon: 'assets/icons/profile_active.svg',
          pageBuilder: (_) => const ProfilePage(),
        ),
      ];

    case NavRole.moderator:
    case NavRole.superAdmin:
      return _moderatorFamilyTabs(notifications, role, context);
  }
}

/// Вкладки для moderator и super_admin. super_admin получает Модераторы
/// перед Профилем - больше ничем семьи не отличаются.
List<RoleNavTab> _moderatorFamilyTabs(
  NotificationService notifications,
  NavRole role,
  BuildContext context,
) {
  final l10n = context.l10n;

  return [
    RoleNavTab(
      label: l10n.moderation,
      icon: 'assets/icons/moderation.svg',
      activeIcon: 'assets/icons/moderation_active.svg',
      pageBuilder: (_) => const ModerationPage(),
      badgeCount: notifications.pendingModerationsCount,
    ),
    RoleNavTab(
      label: l10n.chats,
      icon: 'assets/icons/chats.svg',
      activeIcon: 'assets/icons/chats_active.svg',
      pageBuilder: (_) => const ModeratorSupportChatsPage(),
      badgeCount: notifications.unreadMessagesCount,
    ),
    // Модераторы видны только super_admin.
    if (role == NavRole.superAdmin)
      RoleNavTab(
        label: l10n.moderators,
        icon: 'assets/icons/moderators.svg',
        activeIcon: 'assets/icons/moderators_active.svg',
        pageBuilder: (_) => const ModeratorManagementPage(),
      ),
    RoleNavTab(
      label: l10n.profile,
      icon: 'assets/icons/profile.svg',
      activeIcon: 'assets/icons/profile_active.svg',
      pageBuilder: (_) => const ProfilePage(),
    ),
  ];
}
