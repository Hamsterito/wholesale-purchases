import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'forgot_password_verification_page.dart';
import '../services/api_config.dart';
import '../services/app_http_client.dart';
import '../services/app_logger.dart';
import '../utils/api_response_parser.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill =>
      _isDark ? _colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }



  // Отправляет код сброса пароля на email
  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/forgot-password/send-code');
      final response = await AppHttpClient.instance.post(
        url,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        encoding: utf8,
        body: {'email': email},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Успешно отправлен код, переходим к экрану верификации
        final body = utf8.decode(response.bodyBytes);
        final responseData = parseApiResponseWithData(body);
        final expiresIn = responseData.data['expires_in'] as int? ?? 60;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordVerificationPage(
              email: email,
              expiresIn: expiresIn,
            ),
          ),
        );
      } else {
        // Ошибка при отправке кода
        final body = utf8.decode(response.bodyBytes);
        final message = parseApiMessage(body, fallback: 'Ошибка сервера');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      AppLogger.error('Error sending reset code: $e', scope: 'auth');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сети')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                       'Забыли пароль',
                       style: TextStyle(
                         fontSize: 32,
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                       ),
                     ),
                     const SizedBox(height: 12),
                     const Text(
                       'Напиши свою почту',
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
                          'ЭЛ. ПОЧТА',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                         TextField(
                           controller: _emailController,
                           keyboardType: TextInputType.text,
                           decoration: InputDecoration(
                             hintText: 'primer@pochta.ru',
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
                           ),
                         ),
                         const SizedBox(height: 32),
                         SizedBox(
                           width: double.infinity,
                           height: 50,
                           child: ElevatedButton(
                             onPressed: _isLoading ? null : _sendResetCode,
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
                                 : const Text(
                                     'ОТПРАВИТЬ КОД',
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
