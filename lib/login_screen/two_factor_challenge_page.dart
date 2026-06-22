import '../services/localization/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../services/api/two_factor_api.dart';
import '../services/app_logger.dart';
import '../theme/app_color_palette.dart';
import '../widgets/messages/top_message.dart';
import '../core/ui/widgets/thumb_zone_builder.dart';

/// Сигнатура верификации 2FA-кода - в проде TwoFactorApi.verifyLogin, в тестах фейк.
typedef TwoFactorVerifyLoginFn =
    Future<TwoFactorLoginResult> Function({
      required String challengeId,
      String? code,
      String? backupCode,
      bool rememberDevice,
    });

/// Сигнатура повторной отправки OTP - точка инъекции для тестов.
typedef TwoFactorResendChallengeFn = Future<void> Function(String challengeId);

/// Экран ввода 2FA-кода при логине; OTP или backup-код, результат через Navigator.pop.
class TwoFactorChallengePage extends StatefulWidget {
  const TwoFactorChallengePage({
    super.key,
    required this.challengeId,
    required this.email,
    this.rememberMeForSession = false,
    @visibleForTesting this.verifyLogin,
    @visibleForTesting this.resendChallenge,
  });

  final String challengeId;
  final String email;

  /// Состояние «Запомнить меня» из LoginPage; страница его не пишет, а пробрасывает обратно.
  final bool rememberMeForSession;

  /// Точка инъекции для виджет-тестов; null - реальный TwoFactorApi.verifyLogin.
  final TwoFactorVerifyLoginFn? verifyLogin;

  /// Точка инъекции для виджет-тестов; null - TwoFactorApi.resendChallenge.
  final TwoFactorResendChallengeFn? resendChallenge;

  @override
  State<TwoFactorChallengePage> createState() => _TwoFactorChallengePageState();
}

class _TwoFactorChallengePageState extends State<TwoFactorChallengePage> {
  // OTP длиной 6 знаков (см. _generateOtpCode на сервере).
  static const int _emailOtpLength = 6;
  static const int _backupCodeLength = 10;
  static const int _resendCooldownSeconds = 60;

  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _backupController = TextEditingController();
  final FocusNode _backupFocusNode = FocusNode();
  late final StreamController<ErrorAnimationType> _errorController;

  Timer? _resendTimer;
  int _resendSecondsLeft = _resendCooldownSeconds;

  bool _useBackupCode = false;
  bool _rememberDevice = false;
  bool _isSubmitting = false;
  bool _isResending = false;
  String? _inlineError;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _isDark
      ? _colorScheme.surfaceContainerHighest
      : context.colorPalette.bgTop;

  @override
  void initState() {
    super.initState();
    _errorController = StreamController<ErrorAnimationType>.broadcast();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _errorController.close();
    _pinController.dispose();
    _backupController.dispose();
    _backupFocusNode.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = _resendCooldownSeconds);
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

  void _toggleBackupMode() {
    if (_isSubmitting) return;
    setState(() {
      _useBackupCode = !_useBackupCode;
      _inlineError = null;
      _pinController.clear();
      _backupController.clear();
    });
    if (_useBackupCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _backupFocusNode.requestFocus();
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final String? code;
    final String? backupCode;
    if (_useBackupCode) {
      final raw = _backupController.text.trim().toUpperCase();
      if (raw.length != _backupCodeLength) {
        setState(() => _inlineError = AppLocalizations.current.getString('auto_vvedite_10_simvolnyy_backup_kod'));
        return;
      }
      code = null;
      backupCode = raw;
    } else {
      final raw = _pinController.text.trim();
      if (raw.length != _emailOtpLength) {
        setState(() => _inlineError = AppLocalizations.current.getString('auto_vvedite_emailotplength_znachnyy_kod', params: {'emailOtpLength': _emailOtpLength.toString()}));
        _errorController.add(ErrorAnimationType.shake);
        return;
      }
      code = raw;
      backupCode = null;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      final verifier = widget.verifyLogin ?? TwoFactorApi.verifyLogin;
      final result = await verifier(
        challengeId: widget.challengeId,
        code: code,
        backupCode: backupCode,
        rememberDevice: _rememberDevice,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on TwoFactorChallengeExpiredException catch (e) {
      AppLogger.warning('2FA challenge expired: ${e.message}', scope: 'auth');
      _handleExpiredChallenge();
    } on TwoFactorInvalidCodeException catch (e) {
      _errorController.add(ErrorAnimationType.shake);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _inlineError = _useBackupCode ? e.message : AppLocalizations.current.getString('auto_nevernyy_kod');
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
        '2FA verify request failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _inlineError = AppLocalizations.current.getString('auto_oshibka_podklyucheniya_k_serveru');
        });
      }
    }
  }

  void _handleExpiredChallenge() {
    if (!mounted) return;
    // persistAcrossNavigation - сообщение должно пережить pop на LoginPage.
    showTopMessage(
      context,
      AppLocalizations.current.getString('auto_srok_deystviya_koda_istek_povtorite'),
      backgroundColor: context.colorPalette.error,
      duration: const Duration(seconds: 4),
      persistAcrossNavigation: true,
    );
    Navigator.of(context).pop();
  }

  Future<void> _resendCode() async {
    if (_isResending || _resendSecondsLeft > 0) return;
    setState(() {
      _isResending = true;
      _inlineError = null;
    });
    try {
      final resender = widget.resendChallenge ?? TwoFactorApi.resendChallenge;
      await resender(widget.challengeId);
      if (!mounted) return;
      _startResendCooldown();
      showTopMessage(
        context,
        AppLocalizations.current.getString('auto_kod_otpravlen_povtorno'),
        backgroundColor: context.colorPalette.success,
        duration: const Duration(seconds: 2),
      );
    } on TwoFactorRateLimitException catch (e) {
      // Сервер не готов выдать новый код - блокируем кнопку до конца cooldown.
      if (!mounted) return;
      _startResendCooldown();
      setState(() => _inlineError = e.message);
    } on TwoFactorChallengeExpiredException catch (e) {
      AppLogger.warning(
        '2FA resend on expired challenge: ${e.message}',
        scope: 'auth',
      );
      _handleExpiredChallenge();
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      setState(() => _inlineError = e.message);
    } catch (e, st) {
      AppLogger.error(
        '2FA resend request failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() => _inlineError = AppLocalizations.current.getString('auto_ne_udalos_otpravit_kod_povtorno'));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final gradientColors = _isDark
        ? [palette.bgBottom, palette.bgTop]
        : [palette.accent, palette.accentDark];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: _cardBg,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: _colorScheme.onSurface,
                                ),
                                tooltip: AppLocalizations.current.getString('auto_nazad'),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.of(context).pop(),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppLocalizations.current.getString('auto_podtverzhdenie_vkhoda'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.current.getString('auto_dvukhfaktornaya_nautentifikatsiya').replaceAll(r'\n', '\n'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            AppLocalizations.current.getString('auto_my_otpravili_kod_na_vashu_pochtu'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderRow(),
                              SizedBox(height: 16),
                              if (_useBackupCode)
                                _buildBackupCodeField()
                              else
                                _buildPinCodeField(),
                              if (_inlineError != null) ...[
                                SizedBox(height: 12),
                                Text(
                                  _inlineError!,
                                  style: TextStyle(
                                    color: palette.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              SizedBox(height: 16),
                              _buildToggleBackupButton(),
                              SizedBox(height: 8),
                              _buildRememberDeviceCheckbox(),
                              SizedBox(height: 16),
                              _buildSubmitButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    final label = _useBackupCode ? AppLocalizations.current.getString('auto_backup_kod') : AppLocalizations.current.getString('auto_kod_iz_pochty');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (!_useBackupCode) _buildResendControl(),
      ],
    );
  }

  Widget _buildResendControl() {
    final disabled = _resendSecondsLeft > 0 || _isResending || _isSubmitting;
    return TextButton(
      onPressed: disabled ? null : _resendCode,
      child: Text(
        AppLocalizations.current.getString('auto_otpravit_snova'),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: disabled ? _mutedText : _colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildPinCodeField() {
    // LayoutBuilder адаптирует ячейку под ширину - 6×48 не везде помещается.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = ((constraints.maxWidth - 10) / _emailOtpLength).clamp(
          38.0,
          52.0,
        );
        final cellHeight = cellWidth + 6;
        final inactiveBorder = _colorScheme.outline.withValues(alpha: 0.6);
        return PinCodeTextField(
          appContext: context,
          controller: _pinController,
          length: _emailOtpLength,
          animationType: AnimationType.fade,
          // Контроллеры держим сами - иначе PinCodeTextField диспозит наш
          // _pinController при переключении OTP/backup, и clear() падает.
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
          enabled: !_isSubmitting,
          onChanged: (_) {
            if (_inlineError != null) {
              setState(() => _inlineError = null);
            }
          },
          onCompleted: (_) => _submit(),
          errorAnimationController: _errorController,
          beforeTextPaste: (text) {
            final digits = text?.replaceAll(RegExp(r'\D'), '') ?? '';
            return digits.length == _emailOtpLength;
          },
        );
      },
    );
  }

  Widget _buildBackupCodeField() {
    return TextField(
      controller: _backupController,
      focusNode: _backupFocusNode,
      enabled: !_isSubmitting,
      maxLength: _backupCodeLength,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
      inputFormatters: [
        // Алфавит совпадает с _twoFactorBackupCodeAlphabet на сервере.
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z2-9]')),
        _UpperCaseTextFormatter(),
        LengthLimitingTextInputFormatter(_backupCodeLength),
      ],
      decoration: InputDecoration(
        hintText: 'XXXXXXXXXX',
        counterText: '',
        hintStyle: TextStyle(
          color: _mutedText,
          fontSize: 18,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      onChanged: (_) {
        if (_inlineError != null) {
          setState(() => _inlineError = null);
        }
      },
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _buildToggleBackupButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: _isSubmitting ? null : _toggleBackupMode,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          _useBackupCode
              ? AppLocalizations.current.getString('auto_vernutsya_k_kodu_iz_pochty')
              : AppLocalizations.current.getString('auto_ispolzovat_backup_kod'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildRememberDeviceCheckbox() {
    return InkWell(
      onTap: _isSubmitting
          ? null
          : () => setState(() => _rememberDevice = !_rememberDevice),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberDevice,
                onChanged: _isSubmitting
                    ? null
                    : (value) =>
                          setState(() => _rememberDevice = value ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.current.getString('auto_zapomnit_ustroystvo_na_30_dney'),
                style: TextStyle(fontSize: 14, color: _colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final bg = _isDark ? _colorScheme.primary : context.colorPalette.ink;
    return ThumbZoneBuilder(
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                AppLocalizations.current.getString('auto_podtverdit'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    ),
  );
  }
}

/// Форматтер: приводит ввод backup-кода к верхнему регистру.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
