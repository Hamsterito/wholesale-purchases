import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../services/api/two_factor_api.dart';
import '../services/store/app_settings.dart';
import '../widgets/navigation/main_bottom_nav.dart';
import 'change_password_page.dart';
import 'security/two_factor_settings_page.dart';

/// Сигнатура загрузчика статуса 2FA для trailing-индикатора.
/// В проде указывает на TwoFactorApi.getStatus, в тестах подменяется фейком.
typedef SettingsTwoFactorStatusLoader = Future<TwoFactorStatus> Function();

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    @visibleForTesting this.twoFactorStatusLoader,
  });

  /// Точка инъекции для виджет-тестов. Если null - используется
  /// TwoFactorApi.getStatus, который ходит в реальный backend.
  final SettingsTwoFactorStatusLoader? twoFactorStatusLoader;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;

  // Статус 2FA для trailing-индикатора. null - ещё не загружен или ошибка.
  TwoFactorStatus? _twoFactorStatus;

  Color get _settingsAccent {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (theme.brightness == Brightness.dark) {
      return colorScheme.primary;
    }
    return ColorScheme.fromSeed(
      seedColor: colorScheme.primary,
      brightness: Brightness.dark,
    ).primary;
  }

  String _selectedLanguage = 'Русский';
  String _selectedCurrency = '₸ (Тенге)';

  @override
  void initState() {
    super.initState();
    _darkMode = AppSettings.isDark;
    _loadTwoFactorStatus();
  }

  Future<void> _loadTwoFactorStatus() async {
    try {
      final loader =
          widget.twoFactorStatusLoader ?? () => TwoFactorApi.getStatus();
      final status = await loader();
      if (!mounted) return;
      setState(() => _twoFactorStatus = status);
    } catch (_) {
      // Сбой запроса не должен ломать страницу - показываем «Выключена» как fallback.
      if (!mounted) return;
      setState(() => _twoFactorStatus = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sectionLabelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurfaceVariant,
      letterSpacing: 0.6,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Параметры',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Внешний вид
          Text('ВНЕШНИЙ ВИД', style: sectionLabelStyle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
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
                AppSettings.setDarkMode(value);
              },
            ),
          ),

          const SizedBox(height: 24),

          // Язык и регион
          Text('ЯЗЫК И РЕГИОН', style: sectionLabelStyle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
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
          Text('БЕЗОПАСНОСТЬ', style: sectionLabelStyle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  title: 'Изменить пароль',
                  icon: Icons.lock_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                _buildActionTile(
                  title: 'Двухфакторная аутентификация',
                  icon: Icons.shield_outlined,
                  trailing: _buildTwoFactorTrailing(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TwoFactorSettingsPage(),
                      ),
                    ).then((_) => _loadTwoFactorStatus());
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // О приложении
          Text('О ПРИЛОЖЕНИИ', style: sectionLabelStyle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildActionTile(
              title: 'Версия приложения',
              icon: Icons.info_outline,
              trailing: Text(
                '2.6.7',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SwitchListTile(
      title: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: _settingsAccent,
    );
  }

  Widget _buildSelectTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      title: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _buildTwoFactorTrailing() {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.colorPalette;
    final enabled = _twoFactorStatus?.enabled ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          enabled ? 'Включена' : 'Выключена',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: enabled ? palette.success : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите язык'),
          content: RadioGroup<String>(
            groupValue: _selectedLanguage,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedLanguage = value;
              });
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildLanguageOption('Русский')],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return RadioListTile<String>(
      title: Text(language),
      value: language,
      activeColor: _settingsAccent,
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите валюту'),
          content: RadioGroup<String>(
            groupValue: _selectedCurrency,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedCurrency = value;
              });
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildCurrencyOption('₸ (Тенге)')],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyOption(String currency) {
    return RadioListTile<String>(
      title: Text(currency),
      value: currency,
      activeColor: _settingsAccent,
    );
  }
}
