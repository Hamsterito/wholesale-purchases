import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../services/api/two_factor_api.dart';
import '../../services/app_logger.dart';
import '../../services/storage/auth_storage.dart';
import '../../services/storage/otp_cooldown_store.dart';
import '../../theme/app_color_palette.dart';
import '../../widgets/messages/top_message.dart';
import '../../widgets/navigation/role_internal_nav_bar.dart';
import 'two_factor_backup_codes_view.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';

/// Экран ввода OTP для включения 2FA; после успеха показывает backup-коды.
class TwoFactorEnableOtpPage extends StatefulWidget {
  const TwoFactorEnableOtpPage({super.key, this.onEnabled});

  /// Колбэк успешного включения. Вызывается после закрытия экрана с backup-кодами.
  final VoidCallback? onEnabled;

  @override
  State<TwoFactorEnableOtpPage> createState() => _TwoFactorEnableOtpPageState();
}

class _TwoFactorEnableOtpPageState extends State<TwoFactorEnableOtpPage> {
  // OTP длиной 6 знаков (см. _generateOtpCode на сервере).
  static const int _otpLength = 6;

  // TTL OTP на сервере - 1 минута.
  static const Duration _otpTtl = Duration(seconds: 60);

  // Cooldown между нажатиями «Отправить повторно».
  static const int _resendCooldownSeconds = 60;

  final TextEditingController _pinController = TextEditingController();
  late final StreamController<ErrorAnimationType> _errorController;

  Timer? _ttlTimer;
  Timer? _resendTimer;

  int _ttlSecondsLeft = 0;
  int _resendSecondsLeft = 0;

  bool _isRequestingOtp = false;
  bool _isSubmitting = false;
  bool _isResending = false;

  // Ошибка начальной отправки кода - блокирует ввод и показывает ретрай.
  String? _initialError;

  // Инлайновая ошибка под полем ввода.
  String? _inlineError;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _isDark
      ? _colorScheme.surfaceContainerHighest
      : context.colorPalette.bgTop;

  bool get _ttlExpired => _ttlSecondsLeft <= 0;

  @override
  void initState() {
    super.initState();
    _errorController = StreamController<ErrorAnimationType>();
    _requestInitialOtp();
  }

  @override
  void dispose() {
    _ttlTimer?.cancel();
    _resendTimer?.cancel();
    _errorController.close();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _requestInitialOtp() async {
    setState(() {
      _isRequestingOtp = true;
      _initialError = null;
    });
    final userId = AuthStorage.userId ?? 0;
    final remaining = await OtpCooldownStore.remainingSeconds(
      userId.toString(),
      'enable',
    );
    if (remaining > 0) {
      if (!mounted) return;
      _startTtlCountdown(initial: remaining);
      _startResendCooldown(initial: remaining);
      setState(() => _isRequestingOtp = false);
      return;
    }
    try {
      await TwoFactorApi.requestEnable();
      if (!mounted) return;
      await OtpCooldownStore.markRequested(userId.toString(), 'enable');
      _startTtlCountdown();
      _startResendCooldown();
    } on TwoFactorRateLimitException catch (e) {
      if (!mounted) return;
      setState(() => _initialError = e.message);
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      setState(() => _initialError = e.message);
    } catch (e, st) {
      AppLogger.error(
        '2FA enable request failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(
        () => _initialError = context.l10n.getString('auto_neUdalosOtpravitKodPo'),
      );
    } finally {
      if (mounted) setState(() => _isRequestingOtp = false);
    }
  }

  void _startTtlCountdown({int? initial}) {
    _ttlTimer?.cancel();
    setState(() => _ttlSecondsLeft = initial ?? _otpTtl.inSeconds);
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

  void _startResendCooldown({int? initial}) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = initial ?? _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft -= 1);
      }
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || _ttlExpired) return;
    final code = _pinController.text.trim();
    if (code.length != _otpLength) {
      _errorController.add(ErrorAnimationType.shake);
      setState(() => _inlineError = 'Введите $_otpLength-значный код');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      final codes = await TwoFactorApi.verifyEnable(code);
      if (!mounted) return;
      _ttlTimer?.cancel();
      _resendTimer?.cancel();
      // Cooldown больше не нужен - 2FA включена.
      await OtpCooldownStore.clear(
        (AuthStorage.userId ?? 0).toString(),
        'enable',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (sheetContext) => TwoFactorBackupCodesView(
            codes: codes,
            onDone: () {
              Navigator.of(sheetContext).pop();
              widget.onEnabled?.call();
            },
          ),
        ),
      );
    } on TwoFactorInvalidCodeException catch (_) {
      _errorController.add(ErrorAnimationType.shake);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _inlineError = context.l10n.getString('auto_nevernyyKod');
      });
    } on TwoFactorRateLimitException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _inlineError = e.message;
      });
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _inlineError = e.message;
      });
    } catch (e, st) {
      AppLogger.error(
        '2FA enable verify failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _inlineError = context.l10n.getString('auto_oshibkaPodklyucheniyaK');
      });
    }
  }

  Future<void> _resendCode() async {
    if (_isResending || _resendSecondsLeft > 0) return;
    setState(() {
      _isResending = true;
      _inlineError = null;
    });
    try {
      await TwoFactorApi.requestEnable();
      if (!mounted) return;
      final userId = AuthStorage.userId ?? 0;
      await OtpCooldownStore.markRequested(userId.toString(), 'enable');
      if (!mounted) return;
      _pinController.clear();
      _startTtlCountdown();
      _startResendCooldown();
      showTopMessage(
        context,
        context.l10n.getString('auto_kodOtpravlenPovtorno'),
        backgroundColor: context.colorPalette.success,
        duration: const Duration(seconds: 2),
      );
    } on TwoFactorRateLimitException catch (e) {
      if (!mounted) return;
      // Сервер ещё не готов - синхронизируем локальный cooldown.
      _startResendCooldown();
      setState(() => _inlineError = e.message);
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      setState(() => _inlineError = e.message);
    } catch (e, st) {
      AppLogger.error(
        '2FA enable resend failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _inlineError = context.l10n.getString('auto_neUdalosOtpravitKodPo_1'));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = _colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: palette.card,
        elevation: 0,
        title: Text(
          context.l10n.getString('auto_vklyuchenie2fa'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.getString('auto_podtverzhdeniePoPochte'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${context.l10n.getString('auto_vvediteKodPodtverzhdeni')} ${context.l10n.getString('auto_chtobyVklyuchitDvuhfakt')}',
                style: TextStyle(fontSize: 14, height: 1.4, color: _mutedText),
              ),
              const SizedBox(height: 24),
              if (_initialError != null)
                _buildInitialErrorBlock(palette)
              else
                _buildOtpFormBlock(palette),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }

  Widget _buildInitialErrorBlock(AppColorPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
                  _initialError!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isRequestingOtp ? null : _requestInitialOtp,
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
            child: _isRequestingOtp
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(context.l10n.getString('auto_povtoritOtpravku'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpFormBlock(AppColorPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderRow(palette),
        const SizedBox(height: 12),
        _buildPinCodeField(),
        if (_ttlExpired) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.getString('auto_srokDeystviyaKodaIstyo'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: palette.error,
            ),
          ),
        ],
        if (_inlineError != null) ...[
          const SizedBox(height: 12),
          Text(
            _inlineError!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: palette.error,
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildSubmitButton(palette),
      ],
    );
  }

  Widget _buildHeaderRow(AppColorPalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            _ttlExpired
                ? context.l10n.getString('auto_srokIstyok')
                : 'КОД ДЕЙСТВИТЕЛЕН $_ttlSecondsLeft СЕК',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: _ttlExpired ? palette.error : _mutedText,
            ),
          ),
        ),
        _buildResendControl(),
      ],
    );
  }

  Widget _buildResendControl() {
    final disabled =
        _resendSecondsLeft > 0 ||
        _isResending ||
        _isSubmitting ||
        _isRequestingOtp;
    return TextButton(
      onPressed: disabled ? null : _resendCode,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        context.l10n.getString('auto_otpravitPovtorno'),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: disabled ? _mutedText : _colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildPinCodeField() {
    final enabled = !_isSubmitting && !_ttlExpired && !_isRequestingOtp;
    // LayoutBuilder адаптирует ячейку под ширину - на узких экранах 6×65
    // не помещается, на широких ограничиваем сверху, чтобы не растягивать.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = ((constraints.maxWidth - 10) / _otpLength).clamp(
          40.0,
          56.0,
        );
        final cellHeight = cellWidth + 6;
        final inactiveBorder = _colorScheme.outline.withValues(alpha: 0.6);
        return PinCodeTextField(
          appContext: context,
          controller: _pinController,
          length: _otpLength,
          animationType: AnimationType.fade,
          // Сами владеем контроллером - LayoutBuilder перестраивает PinCodeTextField,
          // и при autoDispose=true старый инстанс диспозит наш _pinController.
          autoDisposeControllers: false,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: cellHeight,
            fieldWidth: cellWidth,
            activeFillColor: _inputFill,
            inactiveFillColor: _inputFill,
            selectedFillColor: _inputFill,
            activeColor: _colorScheme.primary,
            inactiveColor: inactiveBorder,
            selectedColor: _colorScheme.primary,
            borderWidth: 2,
          ),
          cursorColor: _colorScheme.primary,
          cursorHeight: 28,
          cursorWidth: 2,
          animationDuration: const Duration(milliseconds: 50),
          animationCurve: Curves.easeInOut,
          enableActiveFill: true,
          keyboardType: TextInputType.number,
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          enabled: enabled,
          onChanged: (_) {
            if (_inlineError != null) {
              setState(() => _inlineError = null);
            }
          },
          onCompleted: (_) => _submit(),
          errorAnimationController: _errorController,
          beforeTextPaste: (text) {
            final digits = text?.replaceAll(RegExp(r'\D'), '') ?? '';
            return digits.length == _otpLength;
          },
        );
      },
    );
  }

  Widget _buildSubmitButton(AppColorPalette palette) {
    final disabled = _isSubmitting || _ttlExpired || _isRequestingOtp;
    final bg = _isDark ? _colorScheme.primary : palette.ink;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: disabled ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(context.l10n.getString('auto_podtverdit'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
