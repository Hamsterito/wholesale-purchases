import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/payment_card_storage.dart';
import '../services/auth_storage.dart';
import '../widgets/main_bottom_nav.dart';

class AddPaymentCardPage extends StatefulWidget {
  const AddPaymentCardPage({super.key});

  @override
  State<AddPaymentCardPage> createState() => _AddPaymentCardPageState();
}

class _AddPaymentCardPageState extends State<AddPaymentCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardHolderFieldKey = GlobalKey<FormFieldState<String>>();
  final _cardNumberFieldKey = GlobalKey<FormFieldState<String>>();
  final _expireDateFieldKey = GlobalKey<FormFieldState<String>>();
  final _cvcFieldKey = GlobalKey<FormFieldState<String>>();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expireDateController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final FocusNode _cardHolderFocus = FocusNode();
  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _expireDateFocus = FocusNode();
  final FocusNode _cvcFocus = FocusNode();
  final CardNumberInputFormatter _cardNumberFormatter =
      CardNumberInputFormatter();
  final ExpiryDateInputFormatter _expiryFormatter = ExpiryDateInputFormatter();
  bool _isSaving = false;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _colorScheme.surfaceVariant;

  @override
  void initState() {
    super.initState();
    _cardHolderFocus.addListener(() {
      if (!_cardHolderFocus.hasFocus) {
        _cardHolderFieldKey.currentState?.validate();
      }
    });
    _cardNumberFocus.addListener(() {
      if (!_cardNumberFocus.hasFocus) {
        _cardNumberFieldKey.currentState?.validate();
      }
    });
    _expireDateFocus.addListener(() {
      if (!_expireDateFocus.hasFocus) {
        _expireDateFieldKey.currentState?.validate();
      }
    });
    _cvcFocus.addListener(() {
      if (!_cvcFocus.hasFocus) {
        _cvcFieldKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _cardHolderFocus.dispose();
    _cardNumberFocus.dispose();
    _expireDateFocus.dispose();
    _cvcFocus.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expireDateController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  String? _validateCardHolder(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Введите имя владельца карты';
    }
    if (trimmed.length < 2) {
      return 'Имя слишком короткое';
    }
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return 'Имя не должно содержать цифры';
    }
    return null;
  }

  String? _validateCardNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Введите номер карты';
    }
    if (digits.length != 16) {
      return 'Номер карты должен быть 16 цифр';
    }
    if (!_passesLuhn(digits)) {
      return 'Неверный номер карты';
    }
    return null;
  }

  bool _passesLuhn(String digits) {
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  String? _validateExpireDate(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Введите срок действия';
    }
    if (digits.length != 4) {
      return 'Введите формат ММ/ГГ';
    }
    final month = int.tryParse(digits.substring(0, 2)) ?? 0;
    final year = int.tryParse(digits.substring(2, 4)) ?? -1;
    if (month < 1 || month > 12) {
      return 'Месяц должен быть 01-12';
    }
    final now = DateTime.now();
    final fullYear = 2000 + year;
    final lastValidMonth = DateTime(fullYear, month + 1, 0);
    if (lastValidMonth.isBefore(DateTime(now.year, now.month, 1))) {
      return 'Срок действия истёк';
    }
    return null;
  }

  String? _validateCvc(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Введите CVC';
    }
    if (digits.length != 3) {
      return 'CVC: 3 цифры';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите, чтобы добавить карту')),
      );
      return;
    }
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проверьте введённые данные')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    final expiryDigits = _expireDateController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );
    final month = int.parse(expiryDigits.substring(0, 2));
    final year = int.parse(expiryDigits.substring(2, 4));
    final card = PaymentCard(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      holderName: _cardHolderController.text.trim(),
      last4: digits.substring(digits.length - 4),
      expMonth: month,
      expYear: 2000 + year,
      brand: detectCardBrand(digits),
    );
    try {
      await PaymentCardStorage.addCard(card, userId: userId);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить карту')),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
    Navigator.pop(context, card);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6288D5);
    const fieldContentPadding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 16,
    );
    const shortErrorStyle = TextStyle(fontSize: 11, height: 1.1);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Добавить метод оплаты',
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Владелец карты
              Text(
                'ИМЯ ВЛАДЕЛЬЦА КАРТЫ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: _cardHolderFieldKey,
                controller: _cardHolderController,
                focusNode: _cardHolderFocus,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: _validateCardHolder,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: fieldContentPadding,
                ),
              ),

              const SizedBox(height: 20),

              // Номер карты
              Text(
                'НОМЕР КАРТЫ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: _cardNumberFieldKey,
                controller: _cardNumberController,
                focusNode: _cardNumberFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _validateCardNumber,
                inputFormatters: [_cardNumberFormatter],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _inputFill,
                  hintText: '2134 5678 9012 3456',
                  hintStyle: TextStyle(color: _mutedText, letterSpacing: 1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: fieldContentPadding,
                ),
              ),

              const SizedBox(height: 20),

              // Срок действия и CVC
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'СРОК ДЕЙСТВИЯ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: _expireDateFieldKey,
                          controller: _expireDateController,
                          focusNode: _expireDateFocus,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: _validateExpireDate,
                          inputFormatters: [_expiryFormatter],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _inputFill,
                            hintText: 'ММ/ГГ',
                            hintStyle: TextStyle(color: _mutedText),
                            errorStyle: shortErrorStyle,
                            errorMaxLines: 2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: fieldContentPadding,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CVC',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: _cvcFieldKey,
                          controller: _cvcController,
                          focusNode: _cvcFocus,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          validator: _validateCvc,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _inputFill,
                            hintText: '***',
                            hintStyle: TextStyle(color: _mutedText),
                            errorStyle: shortErrorStyle,
                            errorMaxLines: 2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: fieldContentPadding,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Кнопка добавить
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'ДОБАВИТЬ МЕТОД ОПЛАТЫ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digitsOnly(newValue.text);
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final formatted = _groupDigits(limited, 4, ' ');
    final cursor = _cursorPosition(formatted, _digitsBeforeCursor(newValue));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digitsOnly(newValue.text);
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final formatted = _formatExpiry(limited);
    final cursor = _cursorPosition(formatted, _digitsBeforeCursor(newValue));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

String _digitsOnly(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

String _groupDigits(String digits, int groupSize, String separator) {
  if (digits.isEmpty) {
    return '';
  }
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && i % groupSize == 0) {
      buffer.write(separator);
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _formatExpiry(String digits) {
  if (digits.length <= 2) {
    return digits;
  }
  return '${digits.substring(0, 2)}/${digits.substring(2)}';
}

int _digitsBeforeCursor(TextEditingValue value) {
  if (!value.selection.isValid) {
    return _digitsOnly(value.text).length;
  }
  final end = value.selection.end.clamp(0, value.text.length).toInt();
  return _digitsOnly(value.text.substring(0, end)).length;
}

int _cursorPosition(String formatted, int digitsBeforeCursor) {
  if (digitsBeforeCursor <= 0) {
    return 0;
  }
  int digitsSeen = 0;
  for (int i = 0; i < formatted.length; i++) {
    final code = formatted.codeUnitAt(i);
    if (code >= 48 && code <= 57) {
      digitsSeen++;
      if (digitsSeen == digitsBeforeCursor) {
        return i + 1;
      }
    }
  }
  return formatted.length;
}

