import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import 'package:flutter_project/reg_screan/register_page.dart';
import 'package:flutter_project/forgot_screan/forgot_password_page.dart';
import '../services/api_config.dart';
import '../services/app_http_client.dart';
import '../services/app_logger.dart';
import '../services/auth_storage.dart';
import '../widgets/main_navigation.dart';
import '../forgot_screan/verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill =>
      _isDark ? _colorScheme.surfaceContainerHighest : context.colorPalette.bgTop;

  @override
  void initState() {
    super.initState();
    _rememberMe = AuthStorage.isRemembered;
    final rememberedEmail = AuthStorage.email;
    if (rememberedEmail != null && rememberedEmail.isNotEmpty) {
      _emailController.text = rememberedEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  // Авторизация через бэкенд
  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите почту и пароль')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      AppLogger.info('Login started', scope: 'auth');
      final url = Uri.parse('${ApiConfig.baseUrl}/login');
      final response = await AppHttpClient.instance.post(
        url,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        encoding: utf8,
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(body) as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ?? 'Unknown error';
          if (responseData['requiresVerification'] == true) {
            final email = responseData['email']?.toString() ?? '';
            // Переход на экран верификации
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerificationPage(email: email),
                ),
              );
            }
            return;
          }
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
          return;
        }
        final data = responseData['user'] as Map<String, dynamic>;
        final role = data['role']?.toString() ?? 'buyer';
        final userId = int.tryParse(data['id']?.toString() ?? '') ?? 0;
        final name = data['name']?.toString();
        final supplierName = data['supplierName']?.toString();
        AppLogger.info(
          'Login succeeded for userId=$userId role=$role',
          scope: 'auth',
        );

        if (_rememberMe) {
          await AuthStorage.remember(
            email: email,
            role: role,
            userId: userId,
            name: name,
            supplierName: supplierName,
          );
        } else {
          await AuthStorage.forget();
          await AuthStorage.setSession(
            email: email,
            role: role,
            userId: userId,
            name: name,
            supplierName: supplierName,
          );
        }
        if (!mounted) return;
        // Успешный вход
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              name == null || name.isEmpty
                  ? 'Вход выполнен'
                  : 'Добро пожаловать, $name!',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        AppLogger.warning(
          'Login rejected with status ${response.statusCode}',
          scope: 'auth',
        );
        if (!mounted) return;
        // Ошибка логина
        final errorBody = utf8.decode(response.bodyBytes).trim();
        String message;
        try {
          final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
          if (errorData['success'] == false) {
            message = errorData['message']?.toString() ?? 'Unknown error';
          } else {
            message = errorBody;
          }
        } catch (_) {
          final fallbackMessage = switch (response.statusCode) {
            400 => 'Проверьте, что почта и пароль заполнены',
            401 => 'Неверная почта или пароль',
            403 => 'Доступ запрещён',
            _ => 'Не удалось выполнить вход. Попробуйте позже.',
          };
          message = errorBody.isEmpty ? fallbackMessage : errorBody;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e, st) {
      AppLogger.error(
        'Login request failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка подключения к серверу: $e')),
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
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Войти',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Зайдите или зарегистрируйтесь',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      'В свой аккаунт',
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
                          'ПОЧТА',
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
                        const SizedBox(height: 20),
                        Text(
                          'ПАРОЛЬ',
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
                            hintText: '••••••••••••',
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) async {
                                      final nextValue = value ?? false;
                                      setState(() {
                                        _rememberMe = nextValue;
                                      });
                                      if (!nextValue) {
                                        await AuthStorage.forget();
                                      }
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Запомнить меня',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _navigateToForgotPassword,
                              child: Text(
                                'Забыли пароль?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginUser,
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
                                    'ВОЙТИ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Нет аккаунта? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _mutedText,
                                ),
                              ),
                              TextButton(
                                onPressed: _navigateToRegister,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Зарегистрируйтесь',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
