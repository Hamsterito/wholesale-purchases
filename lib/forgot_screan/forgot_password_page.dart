import '../services/localization/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/app_color_palette.dart';
import '../widgets/messages/top_message.dart';
import 'forgot_password_verification_page.dart';
import '../services/api/api_config.dart';
import '../services/api/app_http_client.dart';
import '../services/app_logger.dart';
import '../services/storage/otp_cooldown_store.dart';
import '../utils/api_response_parser.dart';
import '../core/ui/widgets/thumb_zone_builder.dart';
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
  Color get _inputFill => _isDark
      ? _colorScheme.surfaceContainerHighest
      : context.colorPalette.bgTop;

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage(AppLocalizations.current.getString('auto_vvedite_email'), MessageSeverity.warning);
      return;
    }

    setState(() => _isLoading = true);

    // Если ещё активен cooldown - не дёргаем сервер, сразу переходим
    // на verification-страницу с оставшимся TTL.
    final cooldown = await OtpCooldownStore.remainingSeconds(
      email,
      'password_reset',
    );
    if (cooldown > 0) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForgotPasswordVerificationPage(
            email: email,
            resendCooldownSeconds: cooldown,
          ),
        ),
      );
      return;
    }

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
        await OtpCooldownStore.markRequested(email, 'password_reset');
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordVerificationPage(
              email: email,
              resendCooldownSeconds: OtpCooldownStore.cooldown.inSeconds,
            ),
          ),
        );
      } else {
        final body = utf8.decode(response.bodyBytes);
        final message = parseApiMessage(body, fallback: AppLocalizations.current.getString('auto_oshibka_servera'));
        _showMessage(message, MessageSeverity.error);
      }
    } catch (e) {
      AppLogger.error('Error sending reset code: $e', scope: 'auth');
      _showMessage(AppLocalizations.current.getString('auto_oshibka_seti'), MessageSeverity.error);
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
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.current.getString('auto_zabyli_parol_1'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              AppLocalizations.current.getString('auto_napishi_svoyu_pochtu'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
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
                            Text(
                              AppLocalizations.current.getString('auto_el_pochta'),
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
                            SizedBox(height: 32),
                            ThumbZoneBuilder(
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _sendResetCode,
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
                                          AppLocalizations.current.getString('auto_otpravit_kod'),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      );
  }
}
