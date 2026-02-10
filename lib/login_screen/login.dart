import 'package:flutter/material.dart';
import 'package:flutter_project/reg_screan/register_page.dart';
import 'package:flutter_project/forgot_screan/forgot_password_page.dart';
import '../widgets/main_navigation.dart';
import 'package:http/http.dart' as http;
import '../services/auth_storage.dart';

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
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill =>
      _isDark ? _colorScheme.surfaceVariant : const Color(0xFFF5F5F5);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите email и пароль')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://10.0.2.2:8080/login');
      final response = await http.post(url, body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        if (_rememberMe) {
          await AuthStorage.remember(email: email);
        } else {
          await AuthStorage.forget();
        }
        if (!mounted) return;
        // Успешный вход
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body)),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        if (!mounted) return;
        // Ошибка логина
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка подключения к серверу: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
                          'EMAIL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'example@gmail.com',
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
                          'PASSWORD',
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
                                  : const Color(0xFF2D2D2D),
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
