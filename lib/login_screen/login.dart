import '../services/localization/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import 'package:flutter_project/reg_screan/register_page.dart';
import 'package:flutter_project/forgot_screan/forgot_password_page.dart';
import '../models/message.dart';
import '../services/api/api_config.dart';
import '../services/api/app_http_client.dart';
import '../services/api/two_factor_api.dart';
import '../services/app_logger.dart';
import '../services/storage/auth_storage.dart';
import '../services/notification_service.dart';
import '../services/store/templates_store.dart';
import '../widgets/messages/top_message.dart';
import '../widgets/navigation/navigation_shell.dart';
import '../forgot_screan/verification_page.dart';
import 'two_factor_challenge_page.dart';
import '../core/ui/widgets/thumb_zone_builder.dart';

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
  Color get _cardBg => context.colorPalette.card;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _isDark
      ? _colorScheme.surfaceContainerHighest
      : context.colorPalette.bgTop;

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

  // Показ сообщения сверху экрана. Цвет берём из палитры по severity,
  // чтобы login/register выглядели одинаково с остальными экранами.
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
      _showMessage(AppLocalizations.current.getString('auto_vvedite_pochtu_i_parol'), MessageSeverity.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      AppLogger.info('Login started', scope: 'auth');
      final url = Uri.parse('${ApiConfig.baseUrl}/login');
      // Подставляем device-токен 2FA для этого email, если он есть -
      // сервер пропустит challenge на доверенном устройстве.
      final headers = <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
      };
      final deviceToken = await AuthStorage.getDeviceTokenForLogin(email);
      if (deviceToken != null && deviceToken.isNotEmpty) {
        headers['X-Device-Token'] = deviceToken;
      }
      final response = await AppHttpClient.instance.post(
        url,
        headers: headers,
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
            _showMessage(message, MessageSeverity.error);
          }
          return;
        }

        // 2FA-челлендж: пользователь прошёл пароль, но нужен второй фактор.
        if (responseData['requiresTwoFactor'] == true) {
          final challengeId = responseData['challengeId']?.toString() ?? '';
          if (challengeId.isEmpty) {
            if (mounted) {
              _showMessage(
                AppLocalizations.current.getString('auto_server_ne_vernul_challenge_dlya_2fa'),
                MessageSeverity.error,
              );
            }
            return;
          }
          if (!mounted) return;
          final result = await Navigator.push<TwoFactorLoginResult>(
            context,
            MaterialPageRoute(
              builder: (_) => TwoFactorChallengePage(
                challengeId: challengeId,
                email: email,
                rememberMeForSession: _rememberMe,
              ),
            ),
          );
          // null - пользователь отменил или истёк challenge,
          // LoginPage остаётся открытой, пусть повторно жмёт «Войти».
          if (result == null) return;
          if (!mounted) return;

          final token = result.deviceToken;
          if (token != null && token.isNotEmpty) {
            await AuthStorage.setDeviceToken(
              userId: result.user.userId,
              email: email,
              token: token,
            );
          }
          if (!mounted) return;
          await _finalizeLoginSession(
            email: email,
            role: result.user.role,
            userId: result.user.userId,
            name: result.user.name,
            supplierName: result.user.supplierName,
          );
          return;
        }

        final data = responseData['user'] as Map<String, dynamic>;
        final role = data['role']?.toString() ?? 'buyer';
        final userId = int.tryParse(data['id']?.toString() ?? '') ?? 0;
        final name = data['name']?.toString();
        final supplierName = data['supplierName']?.toString();
        final avatarUrl = data['avatarUrl']?.toString();
        await _finalizeLoginSession(
          email: email,
          role: role,
          userId: userId,
          name: name,
          supplierName: supplierName,
          avatarUrl: avatarUrl,
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
            400 => AppLocalizations.current.getString('auto_proverte_chto_pochta_i_parol_zapoln'),
            401 => AppLocalizations.current.getString('auto_nevernaya_pochta_ili_parol'),
            403 => AppLocalizations.current.getString('auto_dostup_zapreshchen'),
            _ => AppLocalizations.current.getString('auto_ne_udalos_vypolnit_vkhod_poprobuyte'),
          };
          message = errorBody.isEmpty ? fallbackMessage : errorBody;
        }
        _showMessage(message, MessageSeverity.error);
      }
    } catch (e, st) {
      AppLogger.error(
        'Login request failed',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      _showMessage(AppLocalizations.current.getString('auto_oshibka_podklyucheniya_k_serveru_e', params: {'e': e.toString()}), MessageSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Завершение успешного входа: применяем remember/session-режим, показываем
  // приветствие, инициализируем уведомления и переходим в основное приложение.
  // Используется как для обычного логина, так и после успешного 2FA-челленджа.
  Future<void> _finalizeLoginSession({
    required String email,
    required String role,
    required int userId,
    required String? name,
    required String? supplierName,
    String? avatarUrl,
  }) async {
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
        avatarUrl: avatarUrl,
      );
    } else {
      await TemplatesStore.instance.clearCache();
      await AuthStorage.forget();
      await AuthStorage.setSession(
        email: email,
        role: role,
        userId: userId,
        name: name,
        supplierName: supplierName,
        avatarUrl: avatarUrl,
      );
    }
    if (!mounted) return;
    _showMessage(
      name == null || name.isEmpty
          ? AppLocalizations.current.getString('auto_vkhod_vypolnen')
          : AppLocalizations.current.getString('auto_dobro_pozhalovat_name', params: {'name': name}),
      MessageSeverity.info,
    );

    // Инициализируем сервис уведомлений для нового пользователя.
    // Не блокируем переход - initialize отработает в фоне
    unawaited(NotificationService().initialize());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const NavigationShell()),
    );
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
                  children: [
                    Text(
                      AppLocalizations.current.getString('auto_voyti'),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      AppLocalizations.current.getString('auto_zaydite_ili_zaregistriruytes'),
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      AppLocalizations.current.getString('auto_v_svoy_akkaunt'),
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
                          AppLocalizations.current.getString('auto_pochta'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 8),
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
                        SizedBox(height: 20),
                        Text(
                          AppLocalizations.current.getString('auto_parol'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 8),
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
                        SizedBox(height: 16),
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
                                        await TemplatesStore.instance
                                            .clearCache();
                                        await AuthStorage.forget();
                                      }
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  AppLocalizations.current.getString('auto_zapomnit_menya'),
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
                                AppLocalizations.current.getString('auto_zabyli_parol'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        ThumbZoneBuilder(
                          child: SizedBox(
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
                                    AppLocalizations.current.getString('auto_voyti_1'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.current.getString('auto_net_akkaunta'),
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
                                  AppLocalizations.current.getString('auto_zaregistriruytes'),
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
