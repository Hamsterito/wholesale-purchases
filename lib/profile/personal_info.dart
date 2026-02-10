import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/phone_input_formatter.dart';
import '../widgets/main_bottom_nav.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage>
    with TickerProviderStateMixin {
  static const _primaryColor = Color(0xFF6288D5);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _aboutController;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _colorScheme.surfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;

  String _name = 'Kotik Milo';
  String _email = 'Kotik@ch3j.ma';
  String _phone = '77777777777';
  String _about = 'I love Kitcat';

  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _name);
    _emailController = TextEditingController(text: _email);
    _phoneController = TextEditingController(
      text: PhoneNumberInputFormatter.formatDigits(
        _phone.replaceAll(RegExp(r'\D'), ''),
      ),
    );
    _aboutController = TextEditingController(text: _about);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  String _displayValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Не указано' : trimmed;
  }

  String _displayPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return _displayValue('');
    if (digits.length != 11) return digits;
    return PhoneNumberInputFormatter.formatDigits(digits);
  }

  void _saveValue(TextEditingController controller, ValueSetter<String> apply) {
    final trimmed = controller.text.trim();
    setState(() {
      apply(trimmed);
      controller.text = trimmed;
      _expandedIndex = -1;
    });
    FocusScope.of(context).unfocus();
  }

  void _savePhone() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Номер должен быть в формате +7-XXX-XXX-XXXX'),
        ),
      );
      return;
    }
    setState(() {
      _phone = digits;
      _phoneController.text = PhoneNumberInputFormatter.formatDigits(digits);
      _expandedIndex = -1;
    });
    FocusScope.of(context).unfocus();
  }

  void _cancelEdit(TextEditingController controller, String currentValue) {
    setState(() {
      controller.text = currentValue;
      _expandedIndex = -1;
    });
    FocusScope.of(context).unfocus();
  }

  void _syncControllerForIndex(int index) {
    switch (index) {
      case 0:
        _nameController.text = _name;
        break;
      case 1:
        _emailController.text = _email;
        break;
      case 2:
        _phoneController.text = PhoneNumberInputFormatter.formatDigits(
          _phone.replaceAll(RegExp(r'\D'), ''),
        );
        break;
      case 3:
        _aboutController.text = _about;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Личная информация',
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Профиль пользователя
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: const AssetImage('assets/icons/avatar.png'),
                  backgroundColor: _colorScheme.surfaceVariant,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayValue(_name),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayValue(_about),
                      style: TextStyle(
                        fontSize: 14,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Информационные поля
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditableTile(
                    index: 0,
                    icon: Icons.person_outline,
                    title: 'ФИО',
                    value: _displayValue(_name),
                    controller: _nameController,
                    onSave: () =>
                        _saveValue(_nameController, (value) => _name = value),
                    onCancel: () => _cancelEdit(_nameController, _name),
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16),
                  _buildEditableTile(
                    index: 1,
                    icon: Icons.email_outlined,
                    title: 'EMAIL',
                    value: _displayValue(_email),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onSave: () =>
                        _saveValue(_emailController, (value) => _email = value),
                    onCancel: () => _cancelEdit(_emailController, _email),
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16),
                  _buildEditableTile(
                    index: 2,
                    icon: Icons.phone_outlined,
                    title: 'НОМЕР',
                    value: _displayPhone(_phone),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      const PhoneNumberInputFormatter(),
                    ],
                    onSave: _savePhone,
                    onCancel: () => _cancelEdit(_phoneController, _phone),
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16),
                  _buildEditableTile(
                    index: 3,
                    icon: Icons.info_outline,
                    title: 'ОПИСАНИЕ',
                    value: _displayValue(_about),
                    controller: _aboutController,
                    maxLines: 3,
                    onSave: () => _saveValue(
                      _aboutController,
                      (value) => _about = value,
                    ),
                    onCancel: () => _cancelEdit(_aboutController, _about),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildEditableTile({
    required int index,
    required IconData icon,
    required String title,
    required String value,
    required TextEditingController controller,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final isExpanded = _expandedIndex == index;
    final isSingleLine = maxLines == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedIndex = -1;
              } else {
                _syncControllerForIndex(index);
                _expandedIndex = index;
              }
            });
          },
          child: ListTile(
            leading: Icon(
              icon,
              color: _primaryColor,
              size: 24,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: _mutedText,
              ),
            ),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.expand_more,
                color: _mutedText,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: controller,
                          keyboardType: keyboardType,
                          inputFormatters: inputFormatters,
                          maxLines: maxLines,
                          textInputAction: isSingleLine
                              ? TextInputAction.done
                              : TextInputAction.newline,
                          onSubmitted: isSingleLine ? (_) => onSave() : null,
                          decoration: InputDecoration(
                            hintText: 'Введите новое значение',
                            filled: true,
                            fillColor: _inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onCancel,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _mutedText,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color: _borderColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Отмена',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Сохранить',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
