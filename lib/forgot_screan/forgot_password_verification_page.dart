import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_config.dart';
import '../services/app_http_client.dart';
import '../services/app_logger.dart';
import '../utils/api_response_parser.dart';
import 'reset_password_page.dart';

class ForgotPasswordVerificationPage extends StatefulWidget {
  final String email;
  final int expiresIn;

  const ForgotPasswordVerificationPage({super.key, required this.email, required this.expiresIn});

  @override
  State<ForgotPasswordVerificationPage> createState() => _ForgotPasswordVerificationPageState();
}

class _ForgotPasswordVerificationPageState extends State<ForgotPasswordVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  int _remainingTime = 60;
  Timer? _timer;
  bool _isButtonDisabled = true;
  bool _isLoading = false;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill =>
      _isDark ? _colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
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
        setState(() {
          _isButtonDisabled = false;
        });
        timer.cancel();
      } else {
        // Уменьшаем оставшееся время
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  // Верифицирует введенный OTP код
  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите 4-значный код')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
            builder: (context) => ResetPasswordPage(
              email: widget.email,
              code: code,
            ),
          ),
        );
      } else {
        // Ошибка верификации
        final body = utf8.decode(response.bodyBytes);
        final message = parseApiMessage(body, fallback: 'Ошибка сервера');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      AppLogger.error('Error verifying reset code: $e', scope: 'auth');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сети')),
      );
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код отправлен повторно')),
        );

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      AppLogger.error('Error resending reset code: $e', scope: 'auth');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сети')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _isDark
        ? const [Color(0xFF1B2434), Color(0xFF0F1115)]
        : const [Color(0xFF6288D5), Color(0xFF5A8BC5)];

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
                              const SizedBox(width: 4),
                              Text(
                                _isButtonDisabled ? '$_remainingTime сек' : '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _mutedText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ПОЛЯ ВВОДА КОДА
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          return Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              color: _inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                _onCodeChanged(value, index);
                              },
                            ),
                          );
                        }),
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
                                : const Color(0xFF2D2D2D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
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