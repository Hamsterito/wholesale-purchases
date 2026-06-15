import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../services/api/two_factor_api.dart';
import '../../services/app_logger.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../../services/storage/auth_storage.dart';
import '../../services/storage/otp_cooldown_store.dart';
import '../../theme/app_color_palette.dart';
import '../../widgets/messages/top_message.dart';
import '../../widgets/navigation/role_internal_nav_bar.dart';
import 'two_factor_backup_codes_view.dart';
import 'two_factor_disable_otp_page.dart';
import 'two_factor_enable_otp_page.dart';

/// Сигнатура загрузчика статуса 2FA - в проде TwoFactorApi.getStatus, в тестах фейк.
typedef TwoFactorSettingsStatusLoader = Future<TwoFactorStatus> Function();

/// Главный экран настроек 2FA: загрузка статуса, переключатель, действия.
class TwoFactorSettingsPage extends StatefulWidget {
  const TwoFactorSettingsPage({
    super.key,
    @visibleForTesting this.statusLoader,
  });

  /// Точка инъекции для виджет-тестов; null - реальный TwoFactorApi.getStatus.
  final TwoFactorSettingsStatusLoader? statusLoader;

  @override
  State<TwoFactorSettingsPage> createState() => _TwoFactorSettingsPageState();
}

class _TwoFactorSettingsPageState extends State<TwoFactorSettingsPage> {
  // OTP длиной 6 знаков (см. _generateOtpCode на сервере).
  static const int _otpLength = 6;

  TwoFactorStatus? _status;
  bool _isLoading = true;
  String? _loadError;

  bool _isPerformingAction = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final loader = widget.statusLoader ?? () => TwoFactorApi.getStatus();
      final status = await loader();
      if (!mounted) return;
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (e, st) {
      AppLogger.error(
        '2FA status load failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _loadError = context.l10n.getString('auto_neUdalosZagruzitStatus');
        _isLoading = false;
      });
    }
  }

  Future<void> _onToggleChanged(bool value) async {
    if (_isPerformingAction) return;
    final current = _status?.enabled ?? false;
    if (value == current) return;

    if (value) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TwoFactorEnableOtpPage(onEnabled: _loadStatus),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TwoFactorDisableOtpPage(onDisabled: _loadStatus),
        ),
      );
    }
    // Системный back мог отменить действие - перечитываем, чтобы Switch ожил.
    if (mounted) {
      await _loadStatus();
    }
  }

  Future<void> _regenerateBackupCodes() async {
    if (_isPerformingAction) return;
    setState(() => _isPerformingAction = true);
    final userId = AuthStorage.userId ?? 0;
    final cooldownLeft = await OtpCooldownStore.remainingSeconds(
      userId.toString(),
      'regenerate',
    );
    // Если cooldown ещё активен - сервер вернул бы тот же OTP, не дёргаем API
    // и стартуем диалог с оставшимся TTL. Иначе запрашиваем новый код и
    // открываем диалог с полными 60 сек.
    final int initialTtl = cooldownLeft > 0 ? cooldownLeft : 60;
    if (cooldownLeft == 0) {
      try {
        await TwoFactorApi.requestRegenerateBackupCodes();
        await OtpCooldownStore.markRequested(userId.toString(), 'regenerate');
      } on TwoFactorException catch (e) {
        if (!mounted) return;
        setState(() => _isPerformingAction = false);
        showTopMessage(
          context,
          e.message,
          backgroundColor: context.colorPalette.error,
        );
        return;
      } catch (e, st) {
        AppLogger.error(
          '2FA regenerate request OTP failed',
          scope: 'auth',
          error: e,
          stackTrace: st,
        );
        if (!mounted) return;
        setState(() => _isPerformingAction = false);
        showTopMessage(
          context,
          context.l10n.getString('auto_neUdalosOtpravitKodPo'),
          backgroundColor: context.colorPalette.error,
        );
        return;
      }
    }

    if (!mounted) return;
    final code = await _showOtpInputDialog(
      title: context.l10n.getString('auto_regeneratsiyaBackupkodov'),
      description:
          '${context.l10n.getString('auto_vvediteKodPodtverzhdeni')} ${context.l10n.getString('auto_chtobyZamenitTekushchie')}',
      initialTtlSeconds: initialTtl,
    );
    if (!mounted) {
      return;
    }
    if (code == null) {
      setState(() => _isPerformingAction = false);
      return;
    }

    try {
      final newCodes = await TwoFactorApi.regenerateBackupCodes(code);
      if (!mounted) return;
      setState(() => _isPerformingAction = false);
      await OtpCooldownStore.clear(userId.toString(), 'regenerate');
      if (!mounted) return;
      // Коды показываем единожды; после возврата перечитываем статус.
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (sheetContext) => TwoFactorBackupCodesView(
            codes: newCodes,
            onDone: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      );
      if (mounted) {
        await _loadStatus();
      }
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      setState(() => _isPerformingAction = false);
      showTopMessage(
        context,
        e.message,
        backgroundColor: context.colorPalette.error,
      );
    } catch (e, st) {
      AppLogger.error(
        '2FA regenerate backup codes failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _isPerformingAction = false);
      showTopMessage(
        context,
        context.l10n.getString('auto_neUdalosSgenerirovatNo'),
        backgroundColor: context.colorPalette.error,
      );
    }
  }

  Future<void> _revokeTrustedDevices() async {
    if (_isPerformingAction) return;
    setState(() => _isPerformingAction = true);
    final userId = AuthStorage.userId ?? 0;
    final cooldownLeft = await OtpCooldownStore.remainingSeconds(
      userId.toString(),
      'revoke',
    );
    final int initialTtl = cooldownLeft > 0 ? cooldownLeft : 60;
    if (cooldownLeft == 0) {
      try {
        await TwoFactorApi.requestRevokeTrustedDevices();
        await OtpCooldownStore.markRequested(userId.toString(), 'revoke');
      } on TwoFactorException catch (e) {
        if (!mounted) return;
        setState(() => _isPerformingAction = false);
        showTopMessage(
          context,
          e.message,
          backgroundColor: context.colorPalette.error,
        );
        return;
      } catch (e, st) {
        AppLogger.error(
          '2FA revoke request OTP failed',
          scope: 'auth',
          error: e,
          stackTrace: st,
        );
        if (!mounted) return;
        setState(() => _isPerformingAction = false);
        showTopMessage(
          context,
          context.l10n.getString('auto_neUdalosOtpravitKodPo'),
          backgroundColor: context.colorPalette.error,
        );
        return;
      }
    }

    if (!mounted) return;
    final code = await _showOtpInputDialog(
      title: context.l10n.getString('auto_otzyvDoverennyhUstroyst'),
      description:
          '${context.l10n.getString('auto_vvediteKodPodtverzhdeni')} ${context.l10n.getString('auto_chtobyOtozvatVseRanee')}',
      initialTtlSeconds: initialTtl,
    );
    if (!mounted) {
      return;
    }
    if (code == null) {
      setState(() => _isPerformingAction = false);
      return;
    }

    try {
      await TwoFactorApi.revokeAllTrustedDevices(code);
      if (!mounted) return;
      setState(() => _isPerformingAction = false);
      await OtpCooldownStore.clear(userId.toString(), 'revoke');
      if (!mounted) return;
      showTopMessage(
        context,
        context.l10n.getString('auto_doverennyeUstroystvaOto'),
        backgroundColor: context.colorPalette.success,
      );
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      setState(() => _isPerformingAction = false);
      showTopMessage(
        context,
        e.message,
        backgroundColor: context.colorPalette.error,
      );
    } catch (e, st) {
      AppLogger.error(
        '2FA revoke trusted devices failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _isPerformingAction = false);
      showTopMessage(
        context,
        context.l10n.getString('auto_neUdalosOtozvatUstroys'),
        backgroundColor: context.colorPalette.error,
      );
    }
  }

  // Диалог OTP - возвращает введённый код или null при отмене.
  // initialTtlSeconds - стартовое значение TTL-таймера; если cooldown ещё
  // активен, передаём остаток, иначе полные 60 сек.
  Future<String?> _showOtpInputDialog({
    required String title,
    required String description,
    required int initialTtlSeconds,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtpInputDialog(
        title: title,
        description: description,
        otpLength: _otpLength,
        initialTtlSeconds: initialTtlSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: palette.card,
        elevation: 0,
        title: Text(
          context.l10n.getString('auto_dvuhfaktornayaAutentifik_1'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: SafeArea(child: _buildBody(palette, cs)),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }

  Widget _buildBody(AppColorPalette palette, ColorScheme cs) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: palette.primary));
    }

    // При ошибке загрузки падаем в «выключено» как fallback и показываем ретрай.
    final status =
        _status ??
        const TwoFactorStatus(enabled: false, backupCodesRemaining: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loadError != null) _buildLoadErrorBlock(palette),
          if (status.enabled && status.backupCodesRemaining <= 2)
            _buildLowBackupCodesBanner(palette),
          _buildToggleCard(status, palette, cs),
          if (status.enabled) ...[
            const SizedBox(height: 16),
            _buildActionsCard(palette, cs),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadErrorBlock(AppColorPalette palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: palette.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadError!,
              style: TextStyle(fontSize: 13, height: 1.4, color: palette.ink),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _isLoading ? null : _loadStatus,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.getString('auto_povtorit'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowBackupCodesBanner(AppColorPalette palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.getString('auto_ostalosMaloRezervnyhKo'),
              style: TextStyle(fontSize: 13, height: 1.35, color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard(
    TwoFactorStatus status,
    AppColorPalette palette,
    ColorScheme cs,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          context.l10n.getString('auto_dvuhfaktornayaAutentifik_1'),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            status.enabled
                ? context.l10n.getString('auto_vklyuchenaPriVhodePotr')
                : context.l10n.getString('auto_vyklyuchenaZashchititeA'),
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        value: status.enabled,
        onChanged: _isPerformingAction ? null : _onToggleChanged,
        activeThumbColor: palette.primary,
      ),
    );
  }

  Widget _buildActionsCard(AppColorPalette palette, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.refresh,
            title: context.l10n.getString('auto_sgenerirovatNovyeBackup'),
            subtitle: context.l10n.getString('auto_staryeKodyBudutUdaleny'),
            onTap: _isPerformingAction ? null : _regenerateBackupCodes,
            palette: palette,
            cs: cs,
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: palette.line),
          _buildActionTile(
            icon: Icons.devices_other,
            title: context.l10n.getString('auto_otozvatDoverennyeUstroy'),
            subtitle: context.l10n.getString('auto_naVsehUstroystvahPotre'),
            onTap: _isPerformingAction ? null : _revokeTrustedDevices,
            palette: palette,
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required AppColorPalette palette,
    required ColorScheme cs,
  }) {
    return ListTile(
      leading: Icon(icon, color: cs.onSurface),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

/// Диалог ввода OTP для sensitive-действий (regenerate / revoke).
class _OtpInputDialog extends StatefulWidget {
  const _OtpInputDialog({
    required this.title,
    required this.description,
    required this.otpLength,
    required this.initialTtlSeconds,
  });

  final String title;
  final String description;
  final int otpLength;

  /// Стартовое значение обратного отсчёта - остаток TTL OTP, который
  /// прокинули из cooldown'а вызывающей страницы.
  final int initialTtlSeconds;

  @override
  State<_OtpInputDialog> createState() => _OtpInputDialogState();
}

class _OtpInputDialogState extends State<_OtpInputDialog> {
  final TextEditingController _pinController = TextEditingController();
  late final StreamController<ErrorAnimationType> _errorController;

  Timer? _ttlTimer;
  int _ttlSecondsLeft = 0;
  String? _inlineError;

  bool get _ttlExpired => _ttlSecondsLeft <= 0;

  @override
  void initState() {
    super.initState();
    _errorController = StreamController<ErrorAnimationType>();
    _startTtlCountdown();
  }

  @override
  void dispose() {
    _ttlTimer?.cancel();
    _errorController.close();
    _pinController.dispose();
    super.dispose();
  }

  void _startTtlCountdown() {
    _ttlTimer?.cancel();
    setState(() => _ttlSecondsLeft = widget.initialTtlSeconds);
    if (_ttlSecondsLeft <= 0) return;
    _ttlTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_ttlSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _ttlSecondsLeft = 0);
      } else {
        setState(() => _ttlSecondsLeft -= 1);
      }
    });
  }

  void _submit() {
    final code = _pinController.text.trim();
    if (code.length != widget.otpLength) {
      _errorController.add(ErrorAnimationType.shake);
      setState(() => _inlineError = context.l10n.twoFactorEnterCode(widget.otpLength));
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFill = isDark ? cs.surfaceContainerHighest : palette.bgTop;

    // AlertDialog оборачивает content в IntrinsicWidth и не передаёт
    // нормальные констрейнты по ширине, поэтому считаем ширину контента сами
    // от ширины экрана и фиксируем её через SizedBox. Дефолтный AlertDialog
    // съедает 40px по бокам у диалога и 24px у padding контента - итого 128px.
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = (screenWidth - 128).clamp(220.0, 320.0);
    final cellWidth = ((contentWidth - 12) / widget.otpLength).clamp(
      32.0,
      48.0,
    );
    final cellHeight = cellWidth + 4;
    final inactiveBorder = cs.outline.withValues(alpha: 0.6);

    return AlertDialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _ttlExpired
                    ? context.l10n.getString('auto_srokIstyok', params: {'ttlSecondsLeft': _ttlSecondsLeft.toString()})
                    : context.l10n.twoFactorCodeValid(_ttlSecondsLeft),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: _ttlExpired ? palette.error : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              PinCodeTextField(
                appContext: context,
                controller: _pinController,
                length: widget.otpLength,
                animationType: AnimationType.fade,
                // Сами владеем контроллером - иначе rebuild диалога диспозит его.
                autoDisposeControllers: false,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: cellHeight,
                  fieldWidth: cellWidth,
                  activeFillColor: inputFill,
                  inactiveFillColor: inputFill,
                  selectedFillColor: inputFill,
                  activeColor: cs.primary,
                  inactiveColor: inactiveBorder,
                  selectedColor: cs.primary,
                  borderWidth: 2,
                ),
                cursorColor: cs.primary,
                cursorHeight: 28,
                cursorWidth: 2,
                animationDuration: const Duration(milliseconds: 50),
                animationCurve: Curves.easeInOut,
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                enabled: !_ttlExpired,
                onChanged: (_) {
                  if (_inlineError != null) {
                    setState(() => _inlineError = null);
                  }
                },
                onCompleted: (_) => _submit(),
                errorAnimationController: _errorController,
                beforeTextPaste: (text) {
                  final digits = text?.replaceAll(RegExp(r'\D'), '') ?? '';
                  return digits.length == widget.otpLength;
                },
              ),
              if (_inlineError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _inlineError!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        ElevatedButton(
          onPressed: _ttlExpired ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: palette.primary.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(context.l10n.getString('auto_podtverdit'),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
