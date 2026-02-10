import 'package:flutter/services.dart';

class PhoneNumberInputFormatter extends TextInputFormatter {
  const PhoneNumberInputFormatter();

  static String formatDigits(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.write('+');
    buffer.write(digits[0]);
    if (digits.length > 1) {
      buffer.write('-');
      buffer.write(digits.substring(1, digits.length < 4 ? digits.length : 4));
    }
    if (digits.length > 4) {
      buffer.write('-');
      buffer.write(digits.substring(4, digits.length < 7 ? digits.length : 7));
    }
    if (digits.length > 7) {
      buffer.write('-');
      buffer.write(digits.substring(7, digits.length < 11 ? digits.length : 11));
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = formatDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
