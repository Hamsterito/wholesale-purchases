import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../profile/personal_info.dart';
import '../profile/my_addresses.dart';
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
import '../services/storage/auth_storage.dart';
import '../services/api/api_service.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../utils/logout_flow.dart';
import '../services/localization/app_localizations.dart';
import '../widgets/profile/user_avatar.dart';

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
      final profile = await ApiService.getUserProfile(userId: userId);
      await AuthStorage.setAvatarUrl(profile.avatarUrl);
      return profile;
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
    return _pickValue([profile?.name, AuthStorage.name], AppLocalizations.current.getString('profile_user_fallback'));
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
    final l10n = AppLocalizations.current;
    switch (trimmed.toLowerCase()) {
      case 'buyer':
        return l10n.getString('role_buyer');
      case 'supplier':
        return l10n.getString('role_supplier');
      case 'moderator':
        return l10n.getString('role_moderator');
      case 'super_admin':
        return l10n.getString('role_super_admin');
      default:
        return trimmed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = AuthStorage.role?.toLowerCase();
    final isSupplier = role == 'supplier';
    final isModerator = role == 'moderator';
    final isSuperAdmin = role == 'super_admin';
    final isBuyer = role == 'buyer';

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
          l10n.getString('profile_title'),
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
              final avatarUrl = profile?.avatarUrl ?? AuthStorage.avatarUrl;
              final avatarName = _pickValue(
                [profile?.name, AuthStorage.name],
                '',
              );
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
                        UserAvatar(
                          avatarUrl: avatarUrl,
                          displayName: avatarName,
                          radius: 35,
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

          // Личная информация доступна всем ролям, адреса - только покупателям.
          if (isBuyer || isSupplier || isModerator || isSuperAdmin) ...[
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
                        title: l10n.getString('profile_personal_info'),
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
                      if (isBuyer) ...[
                        _buildMenuDivider(context),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.location_on_outlined,
                          iconColor: context.colorPalette.warning,
                          title: l10n.getString('profile_addresses_label'),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Оплаты (только для покупателей)
          if (isBuyer) ...[
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
                     title: l10n.getString('zakazi_my_orders'),
                     badge: AnimatedBuilder(
                       animation: Listenable.merge([
                         NotificationService().pendingBuyerOrdersCount,
                         NotificationService().deliveredOrdersCount,
                       ]),
                       builder: (context, _) {
                         final total =
                             NotificationService().pendingBuyerOrdersCount.value +
                             NotificationService().deliveredOrdersCount.value;
                         return _buildInlineBadge(context, total);
                       },
                     ),
                     onTap: () async {
                       await Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => const MyOrdersPage(),
                         ),
                       );
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
                     title: l10n.getString('order_history'),
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
                     title: l10n.getString('profile_payment_method'),
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
          ],

          // Избранное (только для покупателей)
          if (isBuyer) ...[
            Container(
              decoration: BoxDecoration(
                color: context.colorPalette.card,
                borderRadius: BorderRadius.circular(12),
              ),
               child: _buildMenuItem(
                 context: context,
                 icon: Icons.favorite_outline,
                 iconColor: context.colorPalette.accent,
                 title: l10n.getString('profile_favorites'),
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
          ],

          // Вопросы, отзывы, настройки
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
                   title: l10n.getString('profile_qa'),
                   onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => const FAQsPage()),
                     );
                   },
                 ),
                 if (isBuyer) ...[
                   _buildMenuDivider(context),
                   _buildMenuItem(
                     context: context,
                     icon: Icons.rate_review_outlined,
                     iconColor: context.colorPalette.info,
                     title: l10n.getString('profile_reviews_title'),
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
                       if (mounted) {
                         NotificationService().refreshNotifications();
                       }
                     },
                   ),
                 ],
                 _buildMenuDivider(context),
                 _buildMenuItem(
                   context: context,
                   icon: Icons.settings_outlined,
                   iconColor: context.colorPalette.secondary,
                   title: l10n.getString('profile_settings'),
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

          // Техподдержка (для покупателей и поставщиков)
          if (isBuyer || isSupplier) ...[
            Container(
              decoration: BoxDecoration(
                color: context.colorPalette.card,
                borderRadius: BorderRadius.circular(12),
              ),
               child: _buildMenuItem(
                 context: context,
                 icon: Icons.support_agent_outlined,
                 iconColor: context.colorPalette.success,
                 title: l10n.getString('profile_support'),
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
                   if (mounted) {
                     NotificationService().refreshNotifications();
                   }
                 },
               ),
            ),
            const SizedBox(height: 16),
          ],

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
               title: l10n.getString('auth_logout'),
               onTap: () => performLogout(context),
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
    final l10n = AppLocalizations.of(context);
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
          title: l10n.getString('supplier_my_products'),
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
          title: l10n.getString('supplier_my_orders'),
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
          title: l10n.getString('supplier_stats'),
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
          title: l10n.getString('mod_product_moderation'),
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
          title: l10n.getString('mod_support_chats'),
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
          title: l10n.getString('mod_mod_management'),
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

  Widget _buildInlineBadge(BuildContext context, int count) {
    if (count == 0) return const SizedBox.shrink();

    final label = count > 99 ? '99+' : count.toString();
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label:
          '$count ${l10n.pluralize('notifications_count', count)}',
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
