import '../services/localization/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/app_color_palette.dart';
import '../widgets/messages/top_message.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/api/api_config.dart';
import '../services/api/app_http_client.dart';
import '../services/app_logger.dart';
import '../services/storage/otp_cooldown_store.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _pinController = TextEditingController();
  late StreamController<ErrorAnimationType> _errorController;

  late final ValueNotifier<int> _remainingTimeNotifier;
  late final ValueNotifier<bool> _isButtonDisabledNotifier;
  Timer? _timer;

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
    _remainingTimeNotifier = ValueNotifier<int>(60);
    _isButtonDisabledNotifier = ValueNotifier<bool>(true);
    _initTimer();
  }

  // Если у юзера ещё активен cooldown по этому email - подхватываем его.
  // Иначе стартуем с дефолта 60 сек.
  Future<void> _initTimer() async {
    final remaining = await OtpCooldownStore.remainingSeconds(
      widget.email,
      'register',
    );
    if (!mounted) return;
    if (remaining > 0) {
      _remainingTimeNotifier.value = remaining;
      _isButtonDisabledNotifier.value = true;
    }
    _startTimer();
  }

  void _startTimer() {
    final initial = _remainingTimeNotifier.value > 0
        ? _remainingTimeNotifier.value
        : 60;
    _remainingTimeNotifier.value = initial;
    _isButtonDisabledNotifier.value = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final current = _remainingTimeNotifier.value;
      if (current <= 1) {
        // Таймер истёк - активируем кнопку повторной отправки
        _remainingTimeNotifier.value = 0;
        _isButtonDisabledNotifier.value = false;
        timer.cancel();
      } else {
        _remainingTimeNotifier.value = current - 1;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorController.close();
    _pinController.dispose();
    _remainingTimeNotifier.dispose();
    _isButtonDisabledNotifier.dispose();
    super.dispose();
  }

  void _onPinCompleted(String code) {
    _confirmCode();
  }

  // Показ сообщения сверху экрана. Цвет берём из палитры по severity,
  // как в LoginPage - единый стиль для всей цепочки auth-страниц.
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

  Future<void> _confirmCode() async {
    final code = _pinController.text.trim();
    if (code.length != 6) {
      AppLogger.warning('Invalid code length: $code', scope: 'auth');
      _errorController.add(ErrorAnimationType.shake);
      _showMessage(AppLocalizations.current.getString('auto_vvedite_6znachnyy_kod'), MessageSeverity.warning);
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
        await OtpCooldownStore.clear(widget.email, 'register');
        _showMessage(
          AppLocalizations.current.getString('auto_email_podtverzhdn_teper_mozhno_voyt'),
          MessageSeverity.info,
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        final body = utf8.decode(response.bodyBytes);
        _showMessage(body, MessageSeverity.error);
      }
    } catch (e) {
      AppLogger.error('Error confirming code: $e', scope: 'auth');
      _showMessage(AppLocalizations.current.getString('auto_oshibka_seti_pri_podtverzhdenii'), MessageSeverity.error);
    }
  }

  Future<void> _resendCode() async {
    final cooldown = await OtpCooldownStore.remainingSeconds(
      widget.email,
      'register',
    );
    if (cooldown > 0) {
      if (!mounted) return;
      _remainingTimeNotifier.value = cooldown;
      _isButtonDisabledNotifier.value = true;
      _startTimer();
      return;
    }
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
        await OtpCooldownStore.markRequested(widget.email, 'register');
        _showMessage(AppLocalizations.current.getString('auto_kod_otpravlen_povtorno'), MessageSeverity.info);
        _remainingTimeNotifier.value = 60;
        _startTimer();
      } else {
        final body = utf8.decode(response.bodyBytes);
        _showMessage(body, MessageSeverity.error);
      }
    } catch (e) {
      AppLogger.error('Error resending code: $e', scope: 'auth');
      _showMessage(AppLocalizations.current.getString('auto_oshibka_seti_pri_povtornoy_otpravke'), MessageSeverity.error);
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
                      AppLocalizations.current.getString('auto_verifikatsiya'),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      AppLocalizations.current.getString('auto_my_otpravili_kod_na_vashu_pochtu'),
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 4),
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
                            AppLocalizations.current.getString('auto_kod'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            children: [
                              ValueListenableBuilder<int>(
                                valueListenable: _remainingTimeNotifier,
                                builder: (context, remainingTime, _) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: _isButtonDisabledNotifier,
                                    builder: (context, isDisabled, _) {
                                      return Text(
                                        isDisabled
                                            ? '$remainingTime секунд'
                                            : '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _mutedText,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              SizedBox(width: 4),
                              ValueListenableBuilder<bool>(
                                valueListenable: _isButtonDisabledNotifier,
                                builder: (context, isDisabled, _) {
                                  return TextButton(
                                    onPressed: isDisabled
                                        ? null
                                        : () {
                                            _resendCode();
                                          },
                                    child: Text(
                                      AppLocalizations.current.getString('auto_otpravit_snova'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDisabled
                                            ? _mutedText
                                            : _colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // ПОЛЯ ВВОДА КОДА
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cellWidth = ((constraints.maxWidth - 10) / 6)
                              .clamp(40.0, 56.0);
                          final cellHeight = cellWidth + 6;
                          final inactiveBorder = _colorScheme.outline
                              .withValues(alpha: 0.6);
                          return PinCodeTextField(
                            appContext: context,
                            controller: _pinController,
                            length: 6,
                            animationType: AnimationType.fade,
                            // Сами владеем контроллером - LayoutBuilder
                            // перестраивает PinCodeTextField и при
                            // autoDispose=true диспозит наш контроллер.
                            autoDisposeControllers: false,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(12),
                              fieldHeight: cellHeight,
                              fieldWidth: cellWidth,
                              activeFillColor: _inputFill,
                              inactiveFillColor: _inputFill,
                              selectedFillColor: _inputFill,
                              activeColor: _colorScheme.primary,
                              inactiveColor: inactiveBorder,
                              selectedColor: _colorScheme.primary,
                              borderWidth: 2,
                            ),
                            cursorColor: _colorScheme.primary,
                            cursorHeight: 28,
                            cursorWidth: 2,
                            animationDuration: const Duration(milliseconds: 50),
                            animationCurve: Curves.easeInOut,
                            enableActiveFill: true,
                            keyboardType: TextInputType.number,
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            onCompleted: _onPinCompleted,
                            errorAnimationController: _errorController,
                            beforeTextPaste: (text) {
                              final digits =
                                  text?.replaceAll(RegExp(r'\D'), '') ?? '';
                              return digits.length == 6;
                            },
                          );
                        },
                      ),
                      SizedBox(height: 32),

                      // КНОПКА ПОДТВЕРЖДЕНИЯ
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDark
                                ? _colorScheme.primary
                                : context.colorPalette.ink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.current.getString('auto_podtverdit'),
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
