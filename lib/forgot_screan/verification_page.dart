import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/api_config.dart';
import '../services/app_http_client.dart';
import '../services/app_logger.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _pinController = TextEditingController();
  late StreamController<ErrorAnimationType> _errorController;

  int _remainingTime = 60;
  Timer? _timer;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill =>
      _isDark ? _colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5);
  bool _isButtonDisabled = true;

  @override
  void initState() {
    super.initState();
    _errorController = StreamController<ErrorAnimationType>();
    _startTimer();
  }

  void _startTimer() {
    _remainingTime = 60;
    _isButtonDisabled = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == 0) {
        if (mounted) {
          setState(() {
            _isButtonDisabled = false;
          });
        }
        timer.cancel();
      } else {
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
    _confirmCode();
  }

  Future<void> _confirmCode() async {
    final code = _pinController.text.trim();
    if (code.length != 4) {
      AppLogger.warning('Invalid code length: $code', scope: 'auth');
      _errorController.add(ErrorAnimationType.shake);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите 4-значный код')),
      );
      return;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/confirm-email');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email подтверждён. Теперь можно войти.')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        final body = utf8.decode(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body)));
      }
    } catch (e) {
      AppLogger.error('Error confirming code: $e', scope: 'auth');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сети при подтверждении')),
      );
    }
  }

  Future<void> _resendCode() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/resend-verification');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код отправлен повторно')),
        );
        _startTimer();
      } else {
        final body = utf8.decode(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body)));
      }
    } catch (e) {
      AppLogger.error('Error resending code: $e', scope: 'auth');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сети при повторной отправке')),
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
                      'Верификация',
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
                                _isButtonDisabled ? '$_remainingTime секунд' : '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _mutedText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: _isButtonDisabled
                                    ? null
                                    : () {
                                        _resendCode();
                                      },
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
                          final digits = text?.replaceAll(RegExp(r'\D'), '') ?? '';
                          return digits.length == 4;
                        },
                      ),
                      const SizedBox(height: 32),

                      // КНОПКА ПОДТВЕРЖДЕНИЯ
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDark
                                ? _colorScheme.primary
                                : const Color(0xFF2D2D2D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Подтвердить',
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
