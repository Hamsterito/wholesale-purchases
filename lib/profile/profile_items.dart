import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_color_palette.dart';
import '../widgets/navigation/nav_role.dart';
import '../services/notification_service.dart';
import 'personal_info.dart';
import 'my_addresses.dart';
import 'payment_method.dart';
import 'faqs_page.dart';
import 'settings_page.dart';
import 'tehpoderzhka.dart';
import 'zakazi.dart';
import 'favorites_page.dart';
import 'reviews_page.dart' as profile_reviews;
import '../pages/order_history_page.dart';

/// Идентификатор пункта профиля. Общие пункты видит любая роль,
/// покупательские - только buyer.
enum ProfileItemId {
  personalInfo,
  faqs,
  settings,
  support,
  logout,
  addresses,
  myOrders,
  orderHistory,
  paymentMethod,
  favorites,
  reviews,
}

/// Резолвер цвета иконки. Данные не знают о теме, поэтому цвет берётся
/// из палитры на этапе build, а не в момент объявления списка.
typedef ProfileIconColorResolver = Color Function(AppColorPalette palette);

/// Пункт меню профиля. Чистые данные - экран и цвет резолвятся при отрисовке.
class ProfileItem {
  const ProfileItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.builder,
    this.badge,
  });

  final ProfileItemId id;
  final String title;
  final IconData icon;
  final ProfileIconColorResolver iconColor;

  /// Экран, открываемый по тапу. null у пунктов-действий (например, Выйти).
  final WidgetBuilder? builder;

  /// Источник счётчика для инлайн-значка. null - значка нет.
  final ValueListenable<int>? badge;
}

/// Сумма двух счётчиков как единый ValueListenable. Живёт всё время работы
/// приложения вместе с NotificationService, поэтому не освобождается.
class _SumListenable extends ValueNotifier<int> {
  _SumListenable(this._a, this._b) : super(_a.value + _b.value) {
    _a.addListener(_recompute);
    _b.addListener(_recompute);
  }

  final ValueListenable<int> _a;
  final ValueListenable<int> _b;

  void _recompute() => value = _a.value + _b.value;
}

/// Значок Мои заказы складывает заказы в обработке и доставленные.
final ValueListenable<int> _myOrdersBadge = _SumListenable(
  NotificationService().pendingBuyerOrdersCount,
  NotificationService().deliveredOrdersCount,
);

/// Общие пункты в порядке отображения. Видны любой роли.
final List<ProfileItem> _commonProfileItems = [
  ProfileItem(
    id: ProfileItemId.personalInfo,
    title: 'Личная информация',
    icon: Icons.person_outline,
    iconColor: (p) => p.error,
    builder: (context) => const PersonalInfoPage(),
  ),
  ProfileItem(
    id: ProfileItemId.faqs,
    title: 'Вопросы и ответы',
    icon: Icons.help_outline,
    iconColor: (p) => p.warning,
    builder: (context) => const FAQsPage(),
  ),
  ProfileItem(
    id: ProfileItemId.settings,
    title: 'Настройки',
    icon: Icons.settings_outlined,
    iconColor: (p) => p.secondary,
    builder: (context) => const SettingsPage(),
  ),
  ProfileItem(
    id: ProfileItemId.support,
    title: 'Техподдержка',
    icon: Icons.support_agent_outlined,
    iconColor: (p) => p.success,
    builder: (context) => const SupportPage(),
    badge: NotificationService().unreadMessagesCount,
  ),
  // У выхода нет экрана - это действие, поэтому builder отсутствует.
  ProfileItem(
    id: ProfileItemId.logout,
    title: 'Выйти',
    icon: Icons.logout,
    iconColor: (p) => p.error,
  ),
];

/// Покупательские пункты в порядке отображения. Видны только buyer.
final List<ProfileItem> _buyerProfileItems = [
  ProfileItem(
    id: ProfileItemId.addresses,
    title: 'Адреса',
    icon: Icons.location_on_outlined,
    iconColor: (p) => p.warning,
    builder: (context) => const MyAddressesPage(),
  ),
  ProfileItem(
    id: ProfileItemId.myOrders,
    title: 'Мои заказы',
    icon: Icons.shopping_cart_outlined,
    iconColor: (p) => p.success,
    builder: (context) => const MyOrdersPage(),
    badge: _myOrdersBadge,
  ),
  ProfileItem(
    id: ProfileItemId.orderHistory,
    title: 'История заказов',
    icon: Icons.history_rounded,
    iconColor: (p) => p.info,
    builder: (context) => const OrderHistoryPage(),
  ),
  ProfileItem(
    id: ProfileItemId.paymentMethod,
    title: 'Способ оплаты',
    icon: Icons.credit_card,
    iconColor: (p) => p.success,
    builder: (context) => const PaymentMethodPage(),
  ),
  ProfileItem(
    id: ProfileItemId.favorites,
    title: 'Избранное',
    icon: Icons.favorite_outline,
    iconColor: (p) => p.accent,
    builder: (context) => const FavoritesPage(),
  ),
  ProfileItem(
    id: ProfileItemId.reviews,
    title: 'Ваши отзывы',
    icon: Icons.rate_review_outlined,
    iconColor: (p) => p.info,
    builder: (context) => const profile_reviews.ReviewsPage(),
    badge: NotificationService().pendingReviewsCount,
  ),
];

/// Пункты профиля для роли: общие для всех плюс покупательские только у buyer,
/// минус всё, что уже доступно во вкладках навигации. Канонические списки
/// не мутируются - возвращается отфильтрованная копия.
List<ProfileItem> profileItemsForRole(
  NavRole role,
  Set<ProfileItemId> navTabItems,
) {
  final items = <ProfileItem>[..._commonProfileItems];
  if (role == NavRole.buyer) {
    items.addAll(_buyerProfileItems);
  }
  return items.where((it) => !navTabItems.contains(it.id)).toList();
}
