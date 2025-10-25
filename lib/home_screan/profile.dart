import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Назад
          },
        ),
        title: Text(
          'Профиль',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              // Меню
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Профиль пользователя
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Аватар
                CircleAvatar(
                  radius: 35,
                  backgroundImage: AssetImage('assets/profile/avatar.png'),
                  backgroundColor: Colors.grey[300],
                  onBackgroundImageError: (_, __) {},
                  child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                ),
                SizedBox(width: 16),
                // Имя и статус
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
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Личная информация и Адреса
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  iconColor: Colors.red,
                  title: 'Личная информация',
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56),
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  iconColor: Colors.yellow[700]!,
                  title: 'Адреса',
                  onTap: () {},
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Уведомления и Способ оплаты
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  iconColor: Colors.orange,
                  title: 'Уведомления',
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56),
                _buildMenuItem(
                  icon: Icons.credit_card_outlined,
                  iconColor: Colors.green,
                  title: 'Способ оплаты',
                  onTap: () {},
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // FAQs, Отзывы, Параметр
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.help_outline,
                  iconColor: Colors.orange,
                  title: 'FAQs',
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56),
                _buildMenuItem(
                  icon: Icons.star_outline,
                  iconColor: Colors.purple,
                  title: 'Ваши отзывы',
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  iconColor: Colors.grey[700]!,
                  title: 'Параметр',
                  onTap: () {},
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Техподдержка
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              icon: Icons.support_agent_outlined,
              iconColor: Colors.green,
              title: 'Техподдержка',
              onTap: () {},
            ),
          ),

          SizedBox(height: 16),

          // Выйти
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMenuItem(
              icon: Icons.logout_outlined,
              iconColor: Colors.red,
              title: 'Выйти',
              onTap: () {},
              showArrow: false,
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}