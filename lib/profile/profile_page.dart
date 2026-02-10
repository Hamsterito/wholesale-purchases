import 'package:flutter/material.dart';
import '../profile/personal_info.dart';
import '../profile/my_addresses.dart';
import '../login_screen/login.dart';
import '../profile/payment_method.dart';
import '../profile/faqs_page.dart';
import '../profile/reviews_page.dart';
import '../profile/settings_page.dart';
import '../profile/tehpoderzhka.dart';
import '../profile/zakazi.dart';
import '../profile/favorites_page.dart';
import '../services/auth_storage.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scaffoldBackground = Color.lerp(
      colorScheme.surface,
      colorScheme.surfaceVariant,
      0.6,
    )!;

    return Scaffold(
      backgroundColor: scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: const AssetImage('assets/icons/avatar.png'),
                  backgroundColor: colorScheme.surfaceVariant,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kotik Milo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Novo Kitcat',
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

          const SizedBox(height: 16),

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
                Divider(height: 1, indent: 56, endIndent: 16),
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

          // оплаты
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
                Divider(height: 1, indent: 56, endIndent: 16),
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
                  title: 'FAQs',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FAQsPage(),
                      ),
                    );
                  },                ),
                Divider(height: 1, indent: 56, endIndent: 16),
                _buildMenuItem(
                  context: context,
                  icon: Icons.rate_review_outlined,
                  iconColor: const Color(0xFF1E88E5),
                  title: 'Ваши отзывы',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewsPage(),
                      ),
                    );
                  },                   ),
                Divider(height: 1, indent: 56, endIndent: 16),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  iconColor: const Color(0xFF5E35B1),
                  title: 'Параметр',
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
                  MaterialPageRoute(
                    builder: (context) => const SupportPage(),
                  ),
                );
              },              ),
          ),

          const SizedBox(height: 16),

          // Выйти
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
                child: Icon(icon, size: 22, color: iconColor ?? colorScheme.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
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
