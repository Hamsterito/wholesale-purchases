import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../profile/personal_info.dart';
import '../profile/my_addresses.dart';
import '../login_screen/login.dart';
import '../profile/payment_method.dart';
import '../profile/faqs_page.dart';
import 'package:flutter_project/profile/reviews_page.dart' as profile_reviews;
import '../profile/settings_page.dart';
import '../profile/tehpoderzhka.dart';
import '../profile/zakazi.dart';
import '../profile/favorites_page.dart';
import '../pages/order_history_page.dart';
import '../supplier/supplier_products_page.dart';
import '../supplier/supplier_orders_page.dart';
import '../supplier/supplier_statistics_page.dart';
import '../moderator/moderation_page.dart';
import '../moderator/moderator_management_page.dart';
import '../moderator/support_chats_page.dart';
import '../services/auth_storage.dart';
import '../services/api_service.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../services/templates_store.dart';
import '../utils/ru_plural.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _reloadProfile();
  }

  void _reloadProfile() {
    _profileFuture = _loadProfile();
  }

  Future<UserProfile?> _loadProfile() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      return null;
    }
    try {
      return await ApiService.getUserProfile(userId: userId);
    } catch (_) {
      return null;
    }
  }

  String _pickValue(List<String?> values, String fallback) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  String _resolveName(UserProfile? profile) {
    return _pickValue([profile?.name, AuthStorage.name], 'Пользователь');
  }

  bool _isSupplierRole(String? role) {
    return role?.trim().toLowerCase() == 'supplier';
  }

  String _resolveSubtitle(UserProfile? profile) {
    final effectiveRole = _pickValue([profile?.role, AuthStorage.role], '');
    if (_isSupplierRole(effectiveRole)) {
      return _pickValue([
        profile?.supplierName,
        AuthStorage.supplierName,
        profile?.email,
        AuthStorage.email,
        _localizeRole(effectiveRole),
        _localizeRole(AuthStorage.role),
      ], '?');
    }

    return _pickValue([
      profile?.email,
      AuthStorage.email,
      _localizeRole(effectiveRole),
      _localizeRole(AuthStorage.role),
    ], '?');
  }

  String? _localizeRole(String? role) {
    final trimmed = role?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    switch (trimmed.toLowerCase()) {
      case 'buyer':
        return 'Покупатель';
      case 'supplier':
        return 'Поставщик';
      case 'moderator':
        return 'Модератор';
      case 'super_admin':
        return 'Главный администратор';
      default:
        return trimmed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = AuthStorage.role?.toLowerCase();
    final isSupplier = role == 'supplier';
    final isModerator = role == 'moderator';
    final isSuperAdmin = role == 'super_admin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Профиль',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Профиль пользователя
          FutureBuilder<UserProfile?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final name = _resolveName(profile);
              final subtitle = _resolveSubtitle(profile);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colorPalette.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          if (isSupplier || isModerator || isSuperAdmin) ...[
            _buildRoleSection(
              context: context,
              isSupplier: isSupplier,
              isModerator: isModerator,
              isSuperAdmin: isSuperAdmin,
            ),
            const SizedBox(height: 16),
          ],

          // Личная информация и адреса
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.person_outline,
                  iconColor: context.colorPalette.error,
                  title: 'Личная информация',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalInfoPage(),
                      ),
                    );
                    if (!mounted) return;
                    setState(_reloadProfile);
                  },
                ),
                _buildMenuDivider(context),
                _buildMenuItem(
                  context: context,
                  icon: Icons.location_on_outlined,
                  iconColor: context.colorPalette.warning,
                  title: 'Адреса',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyAddressesPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Оплаты
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.shopping_cart_outlined,
                  iconColor: context.colorPalette.success,
                  title: 'Мои заказы',
                  badge: ValueListenableBuilder<int>(
                    valueListenable: NotificationService().deliveredOrdersCount,
                    builder: (context, count, _) =>
                        _buildInlineBadge(context, count),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOrdersPage(),
                      ),
                    );
                    // Синхронизируем счётчики после возврата с экрана заказов
                    if (mounted) {
                      NotificationService().refreshNotifications();
                    }
                  },
                ),
                _buildMenuDivider(context),
                _buildMenuItem(
                  context: context,
                  icon: Icons.history_rounded,
                  iconColor: context.colorPalette.info,
                  title: 'История заказов',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryPage(),
                      ),
                    );
                  },
                ),
                _buildMenuDivider(context),
                _buildMenuItem(
                  context: context,
                  icon: Icons.credit_card,
                  iconColor: context.colorPalette.success,
                  title: 'Способ оплаты',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentMethodPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              context: context,
              icon: Icons.favorite_outline,
              iconColor: context.colorPalette.accent,
              title: '\u0418\u0437\u0431\u0440\u0430\u043d\u043d\u043e\u0435',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline,
                  iconColor: context.colorPalette.warning,
                  title: 'Вопросы и ответы',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FAQsPage()),
                    );
                  },
                ),
                _buildMenuDivider(context),
                _buildMenuItem(
                  context: context,
                  icon: Icons.rate_review_outlined,
                  iconColor: context.colorPalette.info,
                  title: 'Ваши отзывы',
                  badge: ValueListenableBuilder<int>(
                    valueListenable: NotificationService().pendingReviewsCount,
                    builder: (context, count, _) =>
                        _buildInlineBadge(context, count),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const profile_reviews.ReviewsPage(),
                      ),
                    );
                    // Синхронизируем счётчики после возврата со страницы отзывов
                    if (mounted) {
                      NotificationService().refreshNotifications();
                    }
                  },
                ),
                _buildMenuDivider(context),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  iconColor: context.colorPalette.secondary,
                  title: 'Настройки',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Техподдержка
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              context: context,
              icon: Icons.support_agent_outlined,
              iconColor: context.colorPalette.success,
              title: 'Техподдержка',
              badge: ValueListenableBuilder<int>(
                valueListenable: NotificationService().unreadMessagesCount,
                builder: (context, count, _) =>
                    _buildInlineBadge(context, count),
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportPage()),
                );
                // Синхронизируем счётчики после возврата из техподдержки
                if (mounted) {
                  NotificationService().refreshNotifications();
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Выход
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              context: context,
              icon: Icons.logout,
              iconColor: context.colorPalette.error,
              title: 'Выйти',
              onTap: () async {
                // Чистим счётчики, пока userId ещё доступен в AuthStorage.
                await NotificationService().clearForLogout();
                await TemplatesStore.instance.clearCache();
                await AuthStorage.forget();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              showArrow: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSection({
    required BuildContext context,
    required bool isSupplier,
    required bool isModerator,
    required bool isSuperAdmin,
  }) {
    if (!isSupplier && !isModerator && !isSuperAdmin) {
      return const SizedBox.shrink();
    }
    final items = <Widget>[];

    if (isSupplier) {
      items.add(
        _buildMenuItem(
          context: context,
          icon: Icons.inventory_2_outlined,
          iconColor: context.colorPalette.info,
          title: 'Мои товары (поставщик)',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupplierProductsPage(),
              ),
            );
          },
        ),
      );
      items.add(
        _buildMenuItem(
          context: context,
          icon: Icons.receipt_long,
          iconColor: context.colorPalette.success,
          title: 'Заказы поставщика',
          // Значок показывает количество заказов, ожидающих действия поставщика
          badge: ValueListenableBuilder<int>(
            valueListenable: NotificationService().pendingSupplierOrdersCount,
            builder: (context, count, _) => _buildInlineBadge(context, count),
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupplierOrdersPage(),
              ),
            );
            // Обновляем счётчик после возврата — поставщик мог принять заказы
            if (mounted) {
              NotificationService().refreshNotifications();
            }
          },
        ),
      );
      items.add(
        _buildMenuItem(
          context: context,
          icon: Icons.analytics_outlined,
          iconColor: context.colorPalette.accent,
          title: 'Статистика',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupplierStatisticsPage(),
              ),
            );
          },
        ),
      );
    }

    if (isModerator || isSuperAdmin) {
      items.add(
        _buildMenuItem(
          context: context,
          icon: Icons.fact_check_outlined,
          iconColor: context.colorPalette.warning,
          title: 'Модерация товаров',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ModerationPage()),
            );
          },
        ),
      );
      items.add(
        _buildMenuItem(
          context: context,
          icon: Icons.forum_outlined,
          iconColor: context.colorPalette.tertiary,
          title: 'Чаты техподдержки',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModeratorSupportChatsPage(),
              ),
            );
          },
        ),
      );
    }

    if (isSuperAdmin) {
      items.add(
        _buildMenuItem(
          context: context,
          icon: Icons.admin_panel_settings_outlined,
          iconColor: context.colorPalette.accent,
          title: 'Управление модераторами',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModeratorManagementPage(),
              ),
            );
          },
        ),
      );
    }

    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(_buildMenuDivider(context));
      }
      children.add(items[i]);
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colorPalette.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  /// Строит инлайн-значок уведомлений для пунктов меню.
  /// В отличие от NotificationBadge (который использует Positioned),
  /// этот виджет можно размещать прямо в Row.
  Widget _buildInlineBadge(BuildContext context, int count) {
    if (count == 0) return const SizedBox.shrink();

    final label = count > 99 ? '99+' : count.toString();

    return Semantics(
      label:
          '$count ${pluralizeRu(count, 'уведомление', 'уведомления', 'уведомлений')}',
      child: Container(
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: context.colorPalette.error,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: context.colorPalette.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              // Colors.white — допустимое исключение для контраста на цветном фоне
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: colorScheme.outlineVariant.withValues(alpha: 0.55),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool showArrow = true,
    // Опциональный значок уведомлений — отображается справа от названия пункта
    Widget? badge,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor ?? colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 8), badge],
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: colorScheme.primary.withValues(alpha: 0.7),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
