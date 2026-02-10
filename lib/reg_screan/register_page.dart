import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Если тестируешь в Android Studio эмуляторе:
      final url = Uri.parse('http://10.0.2.2:8080/register');

      // ⚠️ Отправляем как form-urlencoded, без jsonEncode()
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Регистрация прошла успешно!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка подключения: $e')),
      );
    } finally {
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
                        icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
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
                  children: const [
                    Text(
                      'Регистрация',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Зарегистрируйтесь что бы начать',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NAME',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Введите имя',
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
                            hintText: '············',
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
                        const SizedBox(height: 20),
                        Text(
                          'RE-TYPE PASSWORD',
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
                            hintText: '············',
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
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
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
                            onPressed: _isLoading ? null : _registerUser,
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
                              'ЗАРЕГИСТРОВАТЬСЯ',
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
