import '../services/localization/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/app_color_palette.dart';
import '../widgets/messages/top_message.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/api/api_config.dart';
import '../services/api/app_http_client.dart';
import '../services/app_logger.dart';
import '../services/storage/otp_cooldown_store.dart';
import '../utils/api_response_parser.dart';
import '../core/ui/widgets/thumb_zone_builder.dart';
import 'reset_password_page.dart';

class ForgotPasswordVerificationPage extends StatefulWidget {
  final String email;

  /// Сколько секунд до разблокировки кнопки повторной отправки. Это не срок
  /// жизни кода (он на сервере дольше), а окно между перезапросами.
  final int resendCooldownSeconds;

  const ForgotPasswordVerificationPage({
    super.key,
    required this.email,
    required this.resendCooldownSeconds,
  });

  @override
  State<ForgotPasswordVerificationPage> createState() =>
      _ForgotPasswordVerificationPageState();
}

class _ForgotPasswordVerificationPageState
    extends State<ForgotPasswordVerificationPage> {
  final TextEditingController _pinController = TextEditingController();
  late StreamController<ErrorAnimationType> _errorController;

  late final ValueNotifier<int> _remainingTimeNotifier;
  late final ValueNotifier<bool> _isButtonDisabledNotifier;
  Timer? _timer;
  bool _isLoading = false;

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
    _errorController = StreamController<ErrorAnimationType>();
    _remainingTimeNotifier = ValueNotifier<int>(widget.resendCooldownSeconds);
    _isButtonDisabledNotifier = ValueNotifier<bool>(
      widget.resendCooldownSeconds > 0,
    );
    _startTimer();
  }

  // Запускает таймер обратного отсчёта до разблокировки кнопки «Отправить снова»
  void _startTimer() {
    _remainingTimeNotifier.value = widget.resendCooldownSeconds;
    _isButtonDisabledNotifier.value = widget.resendCooldownSeconds > 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final current = _remainingTimeNotifier.value;
      if (current <= 1) {
        // Таймер истёк - активируем кнопку повторной отправки
        _remainingTimeNotifier.value = 0;
        _isButtonDisabledNotifier.value = false;
        timer.cancel();
      } else {
        _remainingTimeNotifier.value = current - 1;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorController.close();
    _pinController.dispose();
    _remainingTimeNotifier.dispose();
    _isButtonDisabledNotifier.dispose();
    super.dispose();
  }

  void _onPinCompleted(String code) {
    _verifyCode();
  }

  // Показ сообщения сверху экрана. Цвет берём из палитры по severity,
  // как в LoginPage - единый стиль для всей цепочки восстановления пароля.
  void _showMessage(String body, MessageSeverity severity) {
    final palette = context.colorPalette;
    final color = switch (severity) {
      MessageSeverity.info => palette.accent,
      MessageSeverity.warning => palette.warning,
      MessageSeverity.error => palette.error,
      MessageSeverity.critical => palette.error,
    };
    showTopMessage(
      context,
      body,
      backgroundColor: color,
      duration: const Duration(seconds: 4),
    );
  }

  // Верифицирует введенный OTP код
  Future<void> _verifyCode() async {
    final code = _pinController.text.trim();
    if (code.length != 6) {
      _errorController.add(ErrorAnimationType.shake);
      _showMessage(AppLocalizations.current.getString('auto_vvedite_6znachnyy_kod'), MessageSeverity.warning);
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/forgot-password/verify-code');
      final response = await AppHttpClient.instance.post(
        url,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        encoding: utf8,
        body: {'email': widget.email, 'code': code},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Код верифицирован, переходим к сбросу пароля
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPasswordPage(email: widget.email, code: code),
          ),
        );
      } else {
        // Ошибка верификации
        final body = utf8.decode(response.bodyBytes);
        final message = parseApiMessage(body, fallback: AppLocalizations.current.getString('auto_oshibka_servera'));
        _showMessage(message, MessageSeverity.error);
      }
    } catch (e) {
      AppLogger.error('Error verifying reset code: $e', scope: 'auth');
      _showMessage(AppLocalizations.current.getString('auto_oshibka_seti'), MessageSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Повторно отправляет код сброса пароля
  Future<void> _resendCode() async {
    // Если cooldown ещё не истёк - не дёргаем сервер, просто синхронизируем
    // оставшийся таймер с текущим TTL.
    final cooldown = await OtpCooldownStore.remainingSeconds(
      widget.email,
      'password_reset',
    );
    if (cooldown > 0) {
      if (!mounted) return;
      _remainingTimeNotifier.value = cooldown;
      _isButtonDisabledNotifier.value = true;
      _startTimer();
      return;
    }
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/forgot-password/resend-code');
      final response = await AppHttpClient.instance.post(
        url,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        encoding: utf8,
        body: {'email': widget.email},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Код отправлен повторно. Таймер крутим по cooldown'у, а не по TTL кода.
        await OtpCooldownStore.markRequested(widget.email, 'password_reset');

        _showMessage(AppLocalizations.current.getString('auto_kod_otpravlen_povtorno'), MessageSeverity.info);

        _remainingTimeNotifier.value = OtpCooldownStore.cooldown.inSeconds;
        _isButtonDisabledNotifier.value = true;
        _startTimer();
      } else {
        // Ошибка повторной отправки
        final body = utf8.decode(response.bodyBytes);
        final message = parseApiMessage(body, fallback: AppLocalizations.current.getString('auto_oshibka_servera'));
        _showMessage(message, MessageSeverity.error);
      }
    } catch (e) {
      AppLogger.error('Error resending reset code: $e', scope: 'auth');
      _showMessage(AppLocalizations.current.getString('auto_oshibka_seti'), MessageSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final gradientColors = _isDark
        ? [context.colorPalette.bgBottom, context.colorPalette.bgTop]
        : [context.colorPalette.accent, context.colorPalette.accentDark];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isKeyboardVisible)
              Expanded(
                child: Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.current.getString('auto_vosstanovlenie_parolya'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: Container(
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
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // КОД И ТАЙМЕР
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.current.getString('auto_kod'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            children: [
                              ValueListenableBuilder<int>(
                                valueListenable: _remainingTimeNotifier,
                                builder: (context, remainingTime, _) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: _isButtonDisabledNotifier,
                                    builder: (context, isDisabled, _) {
                                      return Text(
                                        isDisabled
                                            ? AppLocalizations.current.getString('util_seconds_left', params: {'count': remainingTime.toString()})
                                            : '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _mutedText,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              SizedBox(width: 4),
                              ValueListenableBuilder<bool>(
                                valueListenable: _isButtonDisabledNotifier,
                                builder: (context, isDisabled, _) {
                                  return TextButton(
                                    onPressed: isDisabled || _isLoading
                                        ? null
                                        : _resendCode,
                                    child: Text(
                                      AppLocalizations.current.getString('auto_otpravit_snova'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDisabled
                                            ? _mutedText
                                            : _colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // ПОЛЯ ВВОДА КОДА
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cellWidth = ((constraints.maxWidth - 10) / 6)
                              .clamp(40.0, 56.0);
                          final cellHeight = cellWidth + 6;
                          final inactiveBorder = _colorScheme.outline
                              .withValues(alpha: 0.6);
                          return PinCodeTextField(
                            appContext: context,
                            controller: _pinController,
                            length: 6,
                            animationType: AnimationType.fade,
                            // Сами владеем контроллером - LayoutBuilder
                            // перестраивает PinCodeTextField и при
                            // autoDispose=true диспозит наш контроллер.
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
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            onCompleted: _onPinCompleted,
                            errorAnimationController: _errorController,
                            beforeTextPaste: (text) {
                              final digits =
                                  text?.replaceAll(RegExp(r'\D'), '') ?? '';
                              return digits.length == 6;
                            },
                          );
                        },
                      ),
                      SizedBox(height: 32),

                      // КНОПКА ПОДТВЕРЖДЕНИЯ
                      ThumbZoneBuilder(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isDark
                                  ? _colorScheme.primary
                                  : context.colorPalette.ink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    AppLocalizations.current.getString('auto_prodolzhit'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
