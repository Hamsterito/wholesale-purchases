import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../theme/app_color_palette.dart';
import '../widgets/app_message_snackbar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/api_config.dart';
import '../services/app_http_client.dart';
import '../services/app_logger.dart';
import '../utils/api_response_parser.dart';
import 'reset_password_page.dart';

class ForgotPasswordVerificationPage extends StatefulWidget {
  final String email;
  final int expiresIn;

  const ForgotPasswordVerificationPage({
    super.key,
    required this.email,
    required this.expiresIn,
  });

  @override
  State<ForgotPasswordVerificationPage> createState() =>
      _ForgotPasswordVerificationPageState();
}

class _ForgotPasswordVerificationPageState
    extends State<ForgotPasswordVerificationPage> {
  final TextEditingController _pinController = TextEditingController();
  late StreamController<ErrorAnimationType> _errorController;

  int _remainingTime = 60;
  Timer? _timer;
  bool _isButtonDisabled = true;
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
    _startTimer();
  }

  // Запускает таймер с полученным временем истечения
  void _startTimer() {
    _remainingTime = widget.expiresIn;
    _isButtonDisabled = _remainingTime > 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == 0) {
        // Таймер истек, активируем кнопку повторной отправки
        if (mounted) {
          setState(() {
            _isButtonDisabled = false;
          });
        }
        timer.cancel();
      } else {
        // Уменьшаем оставшееся время
        if (mounted) {
          setState(() {
            _remainingTime--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorController.close();
    _pinController.dispose();
    super.dispose();
  }

  void _onPinCompleted(String code) {
    _verifyCode();
  }

  // Унифицированный показ SnackBar поверх Message_System.
  // title оставляем пустым: исходные SnackBar содержали только content без заголовка.
  void _showMessage(String body, MessageSeverity severity) {
    AppMessageSnackBar.show(
      context,
      Message(
        id: const Uuid().v4(),
        type: MessageType.notification,
        severity: severity,
        title: '',
        body: body,
        timestamp: DateTime.now(),
        language: 'ru',
      ),
    );
  }

  // Верифицирует введенный OTP код
  Future<void> _verifyCode() async {
    final code = _pinController.text.trim();
    if (code.length != 4) {
      _errorController.add(ErrorAnimationType.shake);
      _showMessage('Введите 4-значный код', MessageSeverity.warning);
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
        final message = parseApiMessage(body, fallback: 'Ошибка сервера');
        _showMessage(message, MessageSeverity.error);
      }
    } catch (e) {
      AppLogger.error('Error verifying reset code: $e', scope: 'auth');
      _showMessage('Ошибка сети', MessageSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Повторно отправляет код сброса пароля
  Future<void> _resendCode() async {
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
        // Код отправлен повторно, обновляем таймер
        final body = utf8.decode(response.bodyBytes);
        final responseData = parseApiResponseWithData(body);
        final expiresIn = responseData.data['expires_in'] as int? ?? 60;

        _showMessage('Код отправлен повторно', MessageSeverity.info);

        // Обновляем время истечения и перезапускаем таймер
        setState(() {
          _remainingTime = expiresIn;
          _isButtonDisabled = true;
        });
        _startTimer();
      } else {
        // Ошибка повторной отправки
        final body = utf8.decode(response.bodyBytes);
        final message = parseApiMessage(body, fallback: 'Ошибка сервера');
        _showMessage(message, MessageSeverity.error);
      }
    } catch (e) {
      AppLogger.error('Error resending reset code: $e', scope: 'auth');
      _showMessage('Ошибка сети', MessageSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Восстановление пароля',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Мы отправили код на вашу почту',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
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
            Container(
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
                            'КОД',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _isButtonDisabled
                                    ? '$_remainingTime секунд'
                                    : '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _mutedText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: _isButtonDisabled || _isLoading
                                    ? null
                                    : _resendCode,
                                child: Text(
                                  'Отправить снова',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _isButtonDisabled
                                        ? _mutedText
                                        : _colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ПОЛЯ ВВОДА КОДА
                      PinCodeTextField(
                        appContext: context,
                        controller: _pinController,
                        length: 4,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 65,
                          fieldWidth: 65,
                          activeFillColor: _inputFill,
                          inactiveFillColor: _inputFill,
                          selectedFillColor: _inputFill,
                          activeColor: _colorScheme.primary,
                          inactiveColor: Colors.transparent,
                          selectedColor: _colorScheme.primary,
                          borderWidth: 2,
                        ),
                        cursorColor: _colorScheme.primary,
                        cursorHeight: 32,
                        cursorWidth: 2,
                        animationDuration: const Duration(milliseconds: 50),
                        animationCurve: Curves.easeInOut,
                        enableActiveFill: true,
                        keyboardType: TextInputType.number,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        onCompleted: _onPinCompleted,
                        errorAnimationController: _errorController,
                        beforeTextPaste: (text) {
                          final digits =
                              text?.replaceAll(RegExp(r'\D'), '') ?? '';
                          return digits.length == 4;
                        },
                      ),
                      const SizedBox(height: 32),

                      // КНОПКА ПОДТВЕРЖДЕНИЯ
                      SizedBox(
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
                                  'ПРОДОЛЖИТЬ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
