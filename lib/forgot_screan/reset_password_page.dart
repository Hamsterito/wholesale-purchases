import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/app_color_palette.dart';
import '../widgets/messages/top_message.dart';
import '../services/api/api_config.dart';
import '../services/api/app_http_client.dart';
import '../services/app_logger.dart';
import '../services/storage/otp_cooldown_store.dart';
import '../utils/api_response_parser.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordPage({super.key, required this.email, required this.code});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _isDark
      ? _colorScheme.surfaceContainerHighest
      : context.colorPalette.bgTop;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Заполните все поля', MessageSeverity.warning);
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Пароль должен содержать минимум 6 символов',
        MessageSeverity.warning,
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Пароли не совпадают', MessageSeverity.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/forgot-password/reset-password',
      );
      final response = await AppHttpClient.instance.post(
        url,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        encoding: utf8,
        body: {
          'email': widget.email,
          'code': widget.code,
          'newPassword': password,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await OtpCooldownStore.clear(widget.email, 'password_reset');
        _showMessage('Пароль успешно изменён', MessageSeverity.info);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        // Возврат на экран входа
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final body = utf8.decode(response.bodyBytes);
        final message = parseApiMessage(body, fallback: 'Ошибка сервера');
        _showMessage(message, MessageSeverity.error);
      }
    } catch (e) {
      AppLogger.error('Error resetting password: $e', scope: 'auth');
      _showMessage('Ошибка сети', MessageSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                      'Новый пароль',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Введите новый пароль',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'НОВЫЙ ПАРОЛЬ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Введите новый пароль',
                            hintStyle: TextStyle(color: _mutedText),
                            filled: true,
                            fillColor: _inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: _mutedText,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ПОДТВЕРДИТЕ ПАРОЛЬ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Подтвердите новый пароль',
                            hintStyle: TextStyle(color: _mutedText),
                            filled: true,
                            fillColor: _inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: _mutedText,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
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
                                    'СОХРАНИТЬ ПАРОЛЬ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
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
            ),
          ],
        ),
      ),
    );
  }
}
