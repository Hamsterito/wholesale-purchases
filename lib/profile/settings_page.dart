import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _darkMode = false;
  String _selectedLanguage = 'Русский';
  String _selectedCurrency = '₸ (Тенге)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Параметры',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Уведомления
          const Text(
            'УВЕДОМЛЕНИЯ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Push-уведомления',
                  subtitle: 'Получать уведомления о заказах',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                _buildSwitchTile(
                  title: 'Email-уведомления',
                  subtitle: 'Получать письма на почту',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                _buildSwitchTile(
                  title: 'SMS-уведомления',
                  subtitle: 'Получать SMS о статусе заказа',
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() {
                      _smsNotifications = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Внешний вид
          const Text(
            'ВНЕШНИЙ ВИД',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildSwitchTile(
              title: 'Темная тема',
              subtitle: 'Использовать темное оформление',
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          // Язык и регион
          const Text(
            'ЯЗЫК И РЕГИОН',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSelectTile(
                  title: 'Язык',
                  value: _selectedLanguage,
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                _buildSelectTile(
                  title: 'Валюта',
                  value: _selectedCurrency,
                  onTap: () {
                    _showCurrencyDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Безопасность
          const Text(
            'БЕЗОПАСНОСТЬ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  title: 'Изменить пароль',
                  icon: Icons.lock_outline,
                  onTap: () {
                    // Открыть страницу смены пароля
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                _buildActionTile(
                  title: 'Двухфакторная аутентификация',
                  icon: Icons.security_outlined,
                  onTap: () {
                    // Настройка 2FA
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // О приложении
          const Text(
            'О ПРИЛОЖЕНИИ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  title: 'Версия приложения',
                  icon: Icons.info_outline,
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () {},
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                _buildActionTile(
                  title: 'Условия использования',
                  icon: Icons.description_outlined,
                  onTap: () {
                    // Открыть условия использования
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                _buildActionTile(
                  title: 'Политика конфиденциальности',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    // Открыть политику конфиденциальности
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }

  Widget _buildSelectTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите язык'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('Русский'),
              _buildLanguageOption('English'),
              _buildLanguageOption('Қазақша'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return RadioListTile<String>(
      title: Text(language),
      value: language,
      groupValue: _selectedLanguage,
      onChanged: (String? value) {
        setState(() {
          _selectedLanguage = value!;
        });
        Navigator.pop(context);
      },
      activeColor: Colors.blue,
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите валюту'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCurrencyOption('₸ (Тенге)'),
              _buildCurrencyOption('₽ (Рубль)'),
              _buildCurrencyOption('\$ (Доллар)'),
              _buildCurrencyOption('€ (Евро)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyOption(String currency) {
    return RadioListTile<String>(
      title: Text(currency),
      value: currency,
      groupValue: _selectedCurrency,
      onChanged: (String? value) {
        setState(() {
          _selectedCurrency = value!;
        });
        Navigator.pop(context);
      },
      activeColor: Colors.blue,
    );
  }
}