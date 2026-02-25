import 'package:flutter/material.dart';
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
import '../moderator/moderation_page.dart';
import '../moderator/support_chats_page.dart';
import '../services/auth_storage.dart';
import '../services/api_service.dart';
import '../models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
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
    return _pickValue([
      profile?.name,
      AuthStorage.name,
    ], 'Пользователь');
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
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
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
              );
            },
          ),

          const SizedBox(height: 16),

          if (isSupplier || isModerator) ...[
            _buildRoleSection(
              context: context,
              isSupplier: isSupplier,
              isModerator: isModerator,
            ),
            const SizedBox(height: 16),
          ],

          // Личная информация и адреса
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.person_outline,
                  iconColor: const Color(0xFFE53935),
                  title: 'Личная информация',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalInfoPage(),
                      ),
                    );
                  },
                ),
                _buildMenuDivider(context),
                _buildMenuItem(
                  context: context,
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFFFFB300),
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
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.shopping_cart_outlined,
                  iconColor: const Color(0xFF43A047),
                  title: 'Мои заказы',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOrdersPage(),
                      ),
                    );
                  },
                ),
                _buildMenuDivider(context),
                _buildMenuItem(
                  context: context,
                  icon: Icons.history_rounded,
                  iconColor: const Color(0xFF5C6BC0),
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
                  iconColor: const Color(0xFF2E7D32),
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
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              context: context,
              icon: Icons.favorite_outline,
              iconColor: const Color(0xFF3949AB),
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
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline,
                  iconColor: const Color(0xFFFB8C00),
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
                  iconColor: const Color(0xFF1E88E5),
                  title: 'Ваши отзывы',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const profile_reviews.ReviewsPage(),
                      ),
                    );
                  },
                ),
                _buildMenuDivider(context),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  iconColor: const Color(0xFF5E35B1),
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
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              context: context,
              icon: Icons.support_agent_outlined,
              iconColor: const Color(0xFF00C853),
              title: 'Техподдержка',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportPage()),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Выход
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              context: context,
              icon: Icons.logout,
              iconColor: const Color(0xFFE53935),
              title: 'Выйти',
              onTap: () async {
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
  }) {
    if (!isSupplier && !isModerator) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    final items = <Widget>[];

    if (isSupplier) {
      items.add(
        _buildMenuItem(
          context: context,
          icon: Icons.inventory_2_outlined,
          iconColor: const Color(0xFF1E88E5),
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
          iconColor: const Color(0xFF43A047),
          title: 'Заказы поставщика',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupplierOrdersPage(),
              ),
            );
          },
        ),
      );
    }

    if (isModerator) {
      items.add(
        _buildMenuItem(
          context: context,
          icon: Icons.fact_check_outlined,
          iconColor: const Color(0xFFF57C00),
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
          iconColor: const Color(0xFF00897B),
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

    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(_buildMenuDivider(context));
      }
      children.add(items[i]);
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
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
              child: Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
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

