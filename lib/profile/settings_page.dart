import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../services/api/two_factor_api.dart';
import '../services/store/app_settings.dart';
import '../services/localization/app_localizations.dart';
import '../services/localization/localization_extension.dart';
import '../models/language.dart';
import '../models/currency.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import 'change_password_page.dart';
import 'security/two_factor_settings_page.dart';

typedef SettingsTwoFactorStatusLoader = Future<TwoFactorStatus> Function();

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    @visibleForTesting this.twoFactorStatusLoader,
  });

  final SettingsTwoFactorStatusLoader? twoFactorStatusLoader;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  late Language _selectedLanguage;
  late Currency _selectedCurrency;
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

  @override
  void initState() {
    super.initState();
    _darkMode = AppSettings.isDark;
    _selectedLanguage = AppSettings.language.value;
    _selectedCurrency = AppSettings.currency.value;
    _loadTwoFactorStatus();

    AppSettings.language.addListener(_onSettingsChanged);
    AppSettings.currency.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    setState(() {
      _selectedLanguage = AppSettings.language.value;
      _selectedCurrency = AppSettings.currency.value;
    });
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onSettingsChanged);
    AppSettings.currency.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadTwoFactorStatus() async {
    try {
      final loader =
          widget.twoFactorStatusLoader ?? () => TwoFactorApi.getStatus();
      final status = await loader();
      if (!mounted) return;
      setState(() => _twoFactorStatus = status);
    } catch (_) {
      if (!mounted) return;
      setState(() => _twoFactorStatus = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
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
          l10n.settings,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.appearance.toUpperCase(), style: sectionLabelStyle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildSwitchTile(
              title: l10n.darkMode,
              subtitle: l10n.useDarkTheme,
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
          Text(l10n.languageAndRegion.toUpperCase(), style: sectionLabelStyle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSelectTile(
                  title: l10n.languageLabel,
                  value: _selectedLanguage.displayNameInLanguage,
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                _buildSelectTile(
                  title: l10n.currency,
                  value:
                      '${_selectedCurrency.code.symbol} (${l10n.currencyName(_selectedCurrency.code.code)})',
                  onTap: () {
                    _showCurrencyDialog();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.security.toUpperCase(), style: sectionLabelStyle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  title: l10n.changePassword,
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
                  title: l10n.twoFactorAuthentication,
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
          Text(l10n.about.toUpperCase(), style: sectionLabelStyle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildActionTile(
              title: l10n.appVersion,
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
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
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
          enabled ? context.l10n.enabled : context.l10n.disabled,
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
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.languageLabel),
          content: RadioGroup<LanguageCode>(
            groupValue: _selectedLanguage.code,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedLanguage =
                    Language.supported.firstWhere((l) => l.code == value);
              });
              AppSettings.setLanguage(_selectedLanguage);
              Navigator.pop(context);
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final lang in Language.supported)
                    _buildLanguageOption(lang),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(Language lang) {
    return RadioListTile<LanguageCode>(
      title: Text(lang.displayNameInLanguage),
      value: lang.code,
      activeColor: _settingsAccent,
    );
  }

  void _showCurrencyDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.currency),
          content: RadioGroup<CurrencyCode>(
            groupValue: _selectedCurrency.code,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedCurrency =
                    Currency.supported.firstWhere((c) => c.code == value);
              });
              AppSettings.setCurrency(_selectedCurrency);
              Navigator.pop(context);
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final curr in Currency.supported)
                    _buildCurrencyOption(curr, l10n),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyOption(Currency curr, AppLocalizations l10n) {
    return RadioListTile<CurrencyCode>(
      title: Text('${curr.code.symbol} (${l10n.currencyName(curr.code.code)})'),
      value: curr.code,
      activeColor: _settingsAccent,
    );
  }
}
