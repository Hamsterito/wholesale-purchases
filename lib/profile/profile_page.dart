import 'package:flutter/material.dart';
import '../profile/personal_info.dart';
import '../profile/address_page.dart';
import '../login_screen/login.dart';
import '../profile/payment_method.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // <-- Убирает стрелку назад
        title: const Text(
          'Профиль',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Профиль пользователя
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: const AssetImage('assets/icons/avatar.png'),
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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
                        color: Colors.grey,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  iconPath: 'assets/icons/prof.png',
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
                  iconPath: 'assets/icons/location.png',
                  title: 'Адреса',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddressPage(),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  iconPath: 'assets/icons/card.png',
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

          // FAQ, отзывы, настройки
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  iconPath: 'assets/icons/help.png',
                  title: 'FAQs',
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56, endIndent: 16),
                _buildMenuItem(
                  iconPath: 'assets/icons/otzivi.png',
                  title: 'Ваши отзывы',
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56, endIndent: 16),
                _buildMenuItem(
                  iconPath: 'assets/icons/settings.png',
                  title: 'Параметр',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Техподдержка
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              iconPath: 'assets/icons/support.png',
              title: 'Техподдержка',
              onTap: () {},
            ),
          ),

          const SizedBox(height: 16),

          // Выйти
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              iconPath: 'assets/icons/logout.png',
              title: 'Выйти',
              onTap: () {
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
    required String iconPath,
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showArrow)
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }
}