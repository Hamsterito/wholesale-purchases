import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import 'package:flutter/services.dart';
import '../services/api/api_config.dart';
import '../services/api/app_http_client.dart';
import '../services/app_logger.dart';
import '../services/storage/otp_cooldown_store.dart';
import '../forgot_screan/verification_page.dart';
import '../widgets/messages/top_message.dart';
import '../widgets/phone_input_formatter.dart';
import '../widgets/animated_select_field.dart';

// Один общий RegExp для удаления нецифровых символов в валидации телефона.
// Top-level final - чтобы не пересоздавать на каждое нажатие клавиши.
final RegExp _nonDigitRegExp = RegExp(r'\D');

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final Map<String, String?> _fieldErrors = {};
  // Поля, с которых пользователь уже уходил (или которые подсветила
  // валидация при переходе на след. шаг). Только для них показываем ошибки -
  // чтобы не дёргать сообщениями на каждой клавише.
  final Set<String> _touchedFields = {};
  final Map<String, FocusNode> _focusNodes = {
    'name': FocusNode(),
    'email': FocusNode(),
    'phone': FocusNode(),
    'supplierName': FocusNode(),
    'password': FocusNode(),
    'confirmPassword': FocusNode(),
  };
  String _role = 'buyer';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _step = 0;
  Timer? _emailCheckDebounce;
  int _emailCheckTicket = 0;
  String _lastCheckedEmail = '';
  String? _emailAvailabilityError;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _cardBg => context.colorPalette.card;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _isDark
      ? _colorScheme.surfaceContainerHighest
      : context.colorPalette.bgTop;
  TextStyle get _labelStyle => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: _mutedText,
  );
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  // Вспомогательный виджет для поля с зарезервированным местом под ошибку.
  // Место под ошибку резервируем всегда (min-height), чтобы соседние поля
  // не прыгали при появлении/исчезновении сообщения.
  Widget _buildFieldWithError({
    required String label,
    required Widget field,
    required String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 5),
        field,
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 18),
          child: errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 14,
                        color: _colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          errorText,
                          style: TextStyle(
                            color: _colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ],
    );
  }

  // Единый InputDecoration для всех полей: красная рамка в состоянии ошибки,
  // светлая - в обычном. Иначе пришлось бы дублировать border в каждом поле.
  InputDecoration _inputDecoration({
    required String hintText,
    required bool hasError,
    Widget? suffixIcon,
  }) {
    final borderColor = hasError
        ? _colorScheme.error
        : context.colorPalette.line;
    OutlineInputBorder buildBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: _mutedText),
      filled: true,
      fillColor: _inputFill,
      isDense: true,
      enabledBorder: buildBorder(borderColor),
      border: buildBorder(borderColor),
      focusedBorder: buildBorder(
        hasError ? _colorScheme.error : context.colorPalette.accent,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixIcon,
    );
  }

  List<String> _fieldsForStep(int step) {
    if (step == 0) {
      return const <String>['name', 'email', 'phone'];
    }
    if (step == 1) {
      if (_role == 'supplier') {
        return const <String>['supplierName', 'password', 'confirmPassword'];
      }
      return const <String>[];
    }
    if (_role == 'supplier') {
      return const <String>[];
    }
    return const <String>['password', 'confirmPassword'];
  }

  int _stepForField(String field) {
    switch (field) {
      case 'name':
      case 'email':
      case 'phone':
        return 0;
      case 'supplierName':
        return _role == 'buyer' ? 0 : 1;
      case 'password':
      case 'confirmPassword':
        return _role == 'supplier' ? 1 : 2;
      default:
        return _step;
    }
  }

  String? _validateName(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      return 'Введите имя';
    }
    if (name.length < 2) {
      return 'Имя должно быть не короче 2 символов';
    }
    return null;
  }

  String? _validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) {
      return 'Введите почту';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Введите корректную почту';
    }
    if (_lastCheckedEmail == email && _emailAvailabilityError != null) {
      return _emailAvailabilityError;
    }
    return null;
  }

  String? _validatePhone(String value) {
    final digits = value.replaceAll(_nonDigitRegExp, '');
    if (digits.isEmpty) {
      return 'Введите номер телефона';
    }
    if (digits.length != 11) {
      return 'Номер должен быть в формате +7-000-000-0000';
    }
    if (!digits.startsWith('7')) {
      return 'Номер должен начинаться с +7';
    }
    return null;
  }

  String? _validateSupplierName(String value) {
    if (value.trim().isEmpty) {
      return 'Введите название компании';
    }
    return null;
  }

  String? _validatePassword(String value) {
    final password = value.trim();
    if (password.isEmpty) {
      return 'Введите пароль';
    }
    if (password.length < 6) {
      return 'Пароль должен быть не короче 6 символов';
    }
    return null;
  }

  String? _validateConfirmPassword(String value) {
    final confirm = value.trim();
    if (confirm.isEmpty) {
      return 'Повторите пароль';
    }
    if (confirm != _passwordController.text.trim()) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  String? _validateField(String field) {
    switch (field) {
      case 'name':
        return _validateName(_nameController.text);
      case 'email':
        return _validateEmail(_emailController.text);
      case 'phone':
        return _validatePhone(_phoneController.text);
      case 'supplierName':
        return _validateSupplierName(_supplierNameController.text);
      case 'password':
        return _validatePassword(_passwordController.text);
      case 'confirmPassword':
        return _validateConfirmPassword(_confirmPasswordController.text);
      default:
        return null;
    }
  }

  // Показ ошибок поверх экрана. Список errors склеиваем в одно сообщение,
  // потому что top-message - однострочный баннер, а детальные ошибки
  // и так уже видны под каждым полем.
  void _showTopError(String message, Iterable<String> errors) {
    final cleaned = <String>{};
    for (final error in errors) {
      final trimmed = error.trim();
      if (trimmed.isNotEmpty) cleaned.add(trimmed);
    }
    final body = cleaned.isEmpty
        ? message
        : '$message: ${cleaned.join('; ')}';
    showTopMessage(
      context,
      body,
      backgroundColor: context.colorPalette.error,
      duration: const Duration(seconds: 4),
    );
  }

  void _showTopSuccess(String message) {
    showTopMessage(
      context,
      message,
      backgroundColor: context.colorPalette.success,
      duration: const Duration(seconds: 3),
    );
  }

  void _clearTopMessage() {
    dismissTopMessage();
  }

  void _scheduleEmailAvailabilityCheck() {
    final email = _emailController.text.trim();
    _emailCheckDebounce?.cancel();
    _emailCheckTicket += 1;

    final hasFormat = _emailRegex.hasMatch(email);
    if (_lastCheckedEmail != email || !hasFormat) {
      _lastCheckedEmail = '';
      _emailAvailabilityError = null;
    }

    if (!hasFormat) {
      return;
    }

    final ticket = _emailCheckTicket;
    _emailCheckDebounce = Timer(const Duration(milliseconds: 450), () {
      _checkEmailAvailability(email, ticket);
    });
  }

  Future<void> _checkEmailAvailability(String email, int ticket) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/register/check-email',
      ).replace(queryParameters: {'email': email});
      final response = await AppHttpClient.instance.get(url);

      if (!mounted || ticket != _emailCheckTicket) {
        return;
      }

      String? availabilityError;
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['available'] == false) {
          availabilityError = 'Email уже зарегистрирован';
        }
      }

      if (!mounted || email != _emailController.text.trim()) {
        return;
      }

      setState(() {
        _lastCheckedEmail = email;
        _emailAvailabilityError = availabilityError;
        // Сам результат проверки сохраняем всегда, но в видимую ошибку
        // пишем только если с поля уже уходили - чтобы не выскакивало при наборе.
        if (_touchedFields.contains('email')) {
          _fieldErrors['email'] = _validateEmail(_emailController.text);
        }
      });
    } catch (_) {
      if (!mounted || ticket != _emailCheckTicket) {
        return;
      }
      if (email != _emailController.text.trim()) {
        return;
      }

      setState(() {
        _lastCheckedEmail = email;
        _emailAvailabilityError = null;
        if (_touchedFields.contains('email')) {
          _fieldErrors['email'] = _validateEmail(_emailController.text);
        }
      });
    }
  }

  void _onFieldChanged(String field) {
    if (field == 'email') {
      _scheduleEmailAvailabilityCheck();
    }

    // Пока поле не "тронуто" (фокус с него не уходил) - не зажигаем ошибку
    // во время набора. Но если ошибка уже показана, гасим её сразу,
    // как только ввод стал валидным.
    if (!_touchedFields.contains(field) && _fieldErrors[field] == null) {
      return;
    }

    final fieldError = _validateField(field);

    setState(() {
      _fieldErrors[field] = fieldError;
    });
  }

  bool _validateStep(int step) {
    final fields = _fieldsForStep(step);
    final messages = <String>{};
    final errors = <String, String?>{};

    for (final field in fields) {
      final error = _validateField(field);
      errors[field] = error;
      if (error != null) {
        messages.add(error);
      }
    }

    setState(() {
      _touchedFields.addAll(fields);
      _fieldErrors.addAll(errors);
    });

    if (messages.isEmpty) {
      _clearTopMessage();
    } else {
      _showTopError('Проверьте заполнение полей', messages);
    }

    return messages.isEmpty;
  }

  bool _validateAllBeforeSubmit() {
    final fields = <String>[
      'name',
      'email',
      'phone',
      if (_role == 'supplier') 'supplierName',
      'password',
      'confirmPassword',
    ];
    final messages = <String>{};
    final errors = <String, String?>{};
    int? targetStep;

    for (final field in fields) {
      final error = _validateField(field);
      errors[field] = error;
      if (error != null) {
        messages.add(error);
        final stepForField = _stepForField(field);
        if (targetStep == null || stepForField < targetStep) {
          targetStep = stepForField;
        }
      }
    }

    setState(() {
      _touchedFields.addAll(fields);
      _fieldErrors.addAll(errors);
      if (messages.isNotEmpty && targetStep != null) {
        _step = targetStep;
      }
    });

    if (messages.isEmpty) {
      _clearTopMessage();
    } else {
      _showTopError('Проверьте заполнение полей', messages);
    }

    return messages.isEmpty;
  }

  void _selectRole(String nextRole) {
    if (nextRole == _role) return;
    setState(() {
      _role = nextRole;
      _fieldErrors['supplierName'] = null;
    });
    // Меняется роль - старый баннер может быть неактуален,
    // прячем его. Следующая валидация покажет новый при необходимости.
    _clearTopMessage();
  }

  // Кастомное меню роли вместо стандартного DropdownButton: у того меню
  // рисуется во всю ширину без скруглений. AnimatedSelectField раскрывает
  // список по ширине поля с плавной анимацией.
  Widget _buildRoleField() {
    return _buildFieldWithError(
      label: 'РОЛЬ',
      errorText: null,
      field: AnimatedSelectField<String>(
        value: _role,
        decoration: _inputDecoration(hintText: '', hasError: false),
        textStyle: TextStyle(color: _colorScheme.onSurface, fontSize: 15),
        onChanged: _selectRole,
        options: const [
          SelectOption('buyer', 'Покупатель'),
          SelectOption('supplier', 'Поставщик'),
        ],
      ),
    );
  }

  Widget _buildAccountStep(double fieldGap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldWithError(
          label: 'ИМЯ',
          errorText: _fieldErrors['name'],
          field: TextField(
            controller: _nameController,
            focusNode: _focusNodes['name'],
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _onFieldChanged('name'),
            decoration: _inputDecoration(
              hintText: 'Введите имя',
              hasError: _fieldErrors['name'] != null,
            ),
          ),
        ),
        SizedBox(height: fieldGap),
        _buildFieldWithError(
          label: 'ПОЧТА',
          errorText: _fieldErrors['email'],
          field: TextField(
            controller: _emailController,
            focusNode: _focusNodes['email'],
            keyboardType: TextInputType.text,
            onChanged: (_) => _onFieldChanged('email'),
            decoration: _inputDecoration(
              hintText: 'primer@pochta.ru',
              hasError: _fieldErrors['email'] != null,
            ),
          ),
        ),
        SizedBox(height: fieldGap),
        _buildFieldWithError(
          label: 'НОМЕР ТЕЛЕФОНА',
          errorText: _fieldErrors['phone'],
          field: TextField(
            controller: _phoneController,
            focusNode: _focusNodes['phone'],
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              const PhoneNumberInputFormatter(),
            ],
            onChanged: (_) => _onFieldChanged('phone'),
            decoration: _inputDecoration(
              hintText: '+7-___-___-____',
              hasError: _fieldErrors['phone'] != null,
            ),
          ),
        ),
        SizedBox(height: fieldGap),
        _buildRoleField(),
      ],
    );
  }

  Widget _buildRoleStep(double fieldGap) {
    if (_role == 'supplier') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldWithError(
            label: 'НАЗВАНИЕ КОМПАНИИ',
            errorText: _fieldErrors['supplierName'],
            field: TextField(
              controller: _supplierNameController,
              focusNode: _focusNodes['supplierName'],
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _onFieldChanged('supplierName'),
              decoration: _inputDecoration(
                hintText: 'Например, ТОО Склад Манса',
                hasError: _fieldErrors['supplierName'] != null,
              ),
            ),
          ),
          SizedBox(height: fieldGap),
          ..._buildPasswordFields(fieldGap),
        ],
      );
    }

    return Text(
      'Дополнительные данные не требуются.',
      style: TextStyle(color: _mutedText, fontSize: 14),
    );
  }

  List<Widget> _buildPasswordFields(double fieldGap) {
    return [
      _buildFieldWithError(
        label: 'ПАРОЛЬ',
        errorText: _fieldErrors['password'],
        field: TextField(
          controller: _passwordController,
          focusNode: _focusNodes['password'],
          obscureText: _obscurePassword,
          onChanged: (_) {
            _onFieldChanged('password');
            _onFieldChanged('confirmPassword');
          },
          decoration: _inputDecoration(
            hintText: '************',
            hasError: _fieldErrors['password'] != null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
      ),
      SizedBox(height: fieldGap),
      _buildFieldWithError(
        label: 'ПОВТОРИТЕ ПАРОЛЬ',
        errorText: _fieldErrors['confirmPassword'],
        field: TextField(
          controller: _confirmPasswordController,
          focusNode: _focusNodes['confirmPassword'],
          obscureText: _obscureConfirmPassword,
          onChanged: (_) => _onFieldChanged('confirmPassword'),
          decoration: _inputDecoration(
            hintText: '************',
            hasError: _fieldErrors['confirmPassword'] != null,
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
      ),
    ];
  }

  Widget _buildPasswordStep(double fieldGap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildPasswordFields(fieldGap),
    );
  }

  @override
  void initState() {
    super.initState();
    // На потере фокуса помечаем поле как "тронутое" и валидируем -
    // так ошибка появляется когда пользователь ушёл с поля, а не на каждой клавише.
    _focusNodes.forEach((field, node) {
      node.addListener(() {
        if (!node.hasFocus) {
          _touchedFields.add(field);
          setState(() {
            _fieldErrors[field] = _validateField(field);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _emailCheckDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _supplierNameController.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  int get _submitStep {
    if (_role == 'supplier') {
      return 1;
    }
    return 2;
  }

  bool get _isSubmitStep => _step == _submitStep;
  bool get _isTopAlignedStep =>
      (_role == 'buyer' && _step == 2) || (_role == 'supplier' && _step == 1);

  String get _stepTitle {
    if (_role == 'supplier') {
      return _step == 0 ? 'Данные' : 'Компания и пароль';
    }
    return _step == 0 ? 'Данные' : 'Пароль';
  }

  String get _stepIndicator {
    final visibleStep = _role == 'buyer' && _step == 2 ? 1 : _step;
    return 'Шаг ${visibleStep + 1} из 2';
  }

  String get _primaryActionLabel {
    if (_isSubmitStep) {
      return 'ЗАРЕГИСТРИРОВАТЬСЯ';
    }
    return 'ДАЛЕЕ';
  }

  void _goNext() {
    if (!_validateStep(_step)) {
      return;
    }

    if (_isSubmitStep) {
      if (!_isLoading) {
        _registerUser();
      }
      return;
    }

    if (_step == 0) {
      setState(() => _step = _role == 'buyer' ? 2 : 1);
      return;
    }
  }

  void _goBack() {
    if (_step == 0) return;
    setState(() {
      if (_role == 'buyer' && _step == 2) {
        _step = 0;
      } else if (_role == 'supplier' && _step > 1) {
        _step = 1;
      } else {
        _step -= 1;
      }
    });
    // Возврат на предыдущий шаг - убираем баннер ошибок, чтобы не висел
    // поверх формы, пока пользователь правит поля.
    _clearTopMessage();
  }

  Future<void> _registerUser() async {
    if (!_validateAllBeforeSubmit()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phoneDigits = _phoneController.text.replaceAll(_nonDigitRegExp, '');
    final password = _passwordController.text.trim();
    final role = _role;
    final supplierName = _supplierNameController.text.trim();

    setState(() => _isLoading = true);

    try {
      AppLogger.info('Registration started for role=$role', scope: 'auth');
      final url = Uri.parse('${ApiConfig.baseUrl}/register');

      final response = await AppHttpClient.instance.post(
        url,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        encoding: utf8,
        body: {
          'name': name,
          'email': email,
          'phone': phoneDigits,
          'password': password,
          'role': role,
          'supplier_name': supplierName,
        },
      );
      final responseBody = utf8.decode(response.bodyBytes);

      if (!mounted) return;

      try {
        final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          AppLogger.info(
            'Registration succeeded for role=$role',
            scope: 'auth',
          );
          await OtpCooldownStore.markRequested(email, 'register');
          _showTopSuccess(
            responseData['message']?.toString() ?? 'Регистрация прошла успешно',
          );
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationPage(email: email),
            ),
          );
        } else {
          AppLogger.warning(
            'Registration rejected with status ${response.statusCode} for role=$role',
            scope: 'auth',
          );
          final message =
              responseData['message']?.toString() ?? 'Сервер вернул ошибку';
          _showTopError('Не удалось завершить регистрацию', [message]);
        }
      } catch (_) {
        AppLogger.warning(
          'Registration rejected with status ${response.statusCode} for role=$role',
          scope: 'auth',
        );
        final cleanMessage = responseBody.trim().isEmpty
            ? 'Сервер вернул ошибку. Попробуйте снова.'
            : responseBody.trim();
        _showTopError('Не удалось завершить регистрацию', [cleanMessage]);
      }
    } catch (e, st) {
      AppLogger.error(
        'Registration request failed for role=$role',
        scope: 'auth',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        _showTopError('Ошибка подключения', ['$e']);
      }
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
    final isCompact = MediaQuery.sizeOf(context).height < 720;
    final formPadding = EdgeInsets.all(isCompact ? 20 : 32);
    final fieldGap = isCompact ? 14.0 : 20.0;
    final sectionGap = isCompact ? 12.0 : 16.0;
    final headerFlex = isCompact ? 2 : 3;
    final formFlex = isCompact ? 8 : 7;
    final headerTitleSize = isCompact ? 28.0 : 32.0;
    final headerSubtitleSize = isCompact ? 14.0 : 16.0;
    final backBorderColor = context.colorPalette.line;
    final backTextEnabledColor = context.colorPalette.muted;
    final backTextDisabledColor = context.colorPalette.muted;
    final primaryButtonColor = context.colorPalette.ink;
    final primaryButtonDisabled = context.colorPalette.ink;
    final buttonRadius = BorderRadius.circular(100);
    final backButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(46)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: buttonRadius),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? backBorderColor.withValues(alpha: 0.6)
              : backBorderColor,
        ),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? backTextDisabledColor
            : backTextEnabledColor,
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1),
      ),
    );
    final primaryButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(46)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: buttonRadius),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? primaryButtonDisabled
            : primaryButtonColor,
      ),
      elevation: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? 0 : 3,
      ),
      shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.25)),
    );

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
              flex: headerFlex,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Регистрация',
                      style: TextStyle(
                        fontSize: headerTitleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    Text(
                      'Зарегистрируйтесь чтобы начать',
                      style: TextStyle(
                        fontSize: headerSubtitleSize,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: formFlex,
              child: Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: formPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _stepTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _stepIndicator,
                              style: TextStyle(fontSize: 12, color: _mutedText),
                            ),
                          ],
                        ),
                        SizedBox(height: sectionGap),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: _isTopAlignedStep
                                    ? Alignment.topCenter
                                    : Alignment.center,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            child: SingleChildScrollView(
                              key: ValueKey(_step),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: _step == 0
                                    ? _buildAccountStep(fieldGap)
                                    : (_step == 1
                                          ? _buildRoleStep(fieldGap)
                                          : _buildPasswordStep(fieldGap)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                child: OutlinedButton(
                                  onPressed: _step == 0 ? null : _goBack,
                                  style: backButtonStyle,
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('НАЗАД'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _goNext,
                                  style: primaryButtonStyle,
                                  child: _isSubmitStep && _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _primaryActionLabel,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
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
