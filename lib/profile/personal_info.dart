import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/phone_input_formatter.dart';
import '../widgets/main_bottom_nav.dart';
import '../services/auth_storage.dart';
import '../services/api_service.dart';
import '../models/user_profile.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage>
    with TickerProviderStateMixin {
  static const _primaryColor = Color(0xFF6288D5);
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyController;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _colorScheme.surfaceContainerHighest;
  Color get _borderColor => _colorScheme.outlineVariant;

  String _name = '';
  String _email = '';
  String _phone = '';
  String _companyName = '';
  String _role = '';
  bool get _isSupplier => _role.toLowerCase() == 'supplier';

  int _expandedIndex = -1;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _role = (AuthStorage.role ?? '').trim();
    _name = AuthStorage.name ?? '';
    _email = AuthStorage.email ?? '';
    _companyName = _isSupplier ? (AuthStorage.supplierName ?? '') : '';
    _nameController = TextEditingController(text: _name);
    _emailController = TextEditingController(text: _email);
    _phoneController = TextEditingController(
      text: PhoneNumberInputFormatter.formatDigits(
        _phone.replaceAll(RegExp(r'\D'), ''),
      ),
    );
    _companyController = TextEditingController(text: _companyName);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      return;
    }
    try {
      final profile = await ApiService.getUserProfile(userId: userId);
      if (!mounted) return;
      setState(() {
        _applyProfile(profile);
      });
    } catch (_) {}
  }

  void _applyProfile(UserProfile profile) {
    _name = profile.name.trim();
    _email = profile.email.trim();
    final normalizedRole = profile.role.trim();
    if (normalizedRole.isNotEmpty) {
      _role = normalizedRole;
    }

    final phoneDigits = profile.phone.replaceAll(RegExp(r'\D'), '');
    _phone = phoneDigits;
    _phoneController.text = phoneDigits.isEmpty
        ? ''
        : PhoneNumberInputFormatter.formatDigits(phoneDigits);

    if (_isSupplier) {
      _companyName = profile.supplierName.trim();
      _companyController.text = _companyName;
    } else {
      _companyName = '';
      _companyController.clear();
    }

    _nameController.text = _name;
    _emailController.text = _email;
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

  String _errorMessage(Object error) {
    final text = error.toString().trim();
    const prefix = 'Exception:';
    if (text.startsWith(prefix)) {
      return text.substring(prefix.length).trim();
    }
    return text;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateName(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      return 'Введите имя';
    }
    if (name.length < 2) {
      return 'Имя слишком короткое';
    }
    return null;
  }

  String? _validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) {
      return 'Введите email';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Некорректный email';
    }
    return null;
  }

  String? _validatePhoneDigits(String digits) {
    if (digits.isEmpty) {
      return 'Введите номер телефона';
    }
    if (digits.length != 11 || !digits.startsWith('7')) {
      return 'Номер должен быть в формате +7-XXX-XXX-XXXX';
    }
    return null;
  }

  Future<void> _saveProfile({
    String? name,
    String? email,
    String? phone,
    String? supplierName,
    required String successMessage,
  }) async {
    if (_isSavingProfile) return;
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      setState(() {
        if (name != null) {
          _name = name.trim();
          _nameController.text = _name;
        }
        if (email != null) {
          _email = email.trim();
          _emailController.text = _email;
        }
        if (phone != null) {
          final digits = phone.replaceAll(RegExp(r'\D'), '');
          _phone = digits;
          _phoneController.text = digits.isEmpty
              ? ''
              : PhoneNumberInputFormatter.formatDigits(digits);
        }
        if (_isSupplier && supplierName != null) {
          _companyName = supplierName.trim();
          _companyController.text = _companyName;
        }
        _expandedIndex = -1;
      });
      FocusScope.of(context).unfocus();
      _showSnack(successMessage);
      return;
    }

    setState(() {
      _isSavingProfile = true;
    });

    try {
      final profile = await ApiService.updateUserProfile(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        supplierName: supplierName,
      );

      await AuthStorage.updateProfile(
        name: profile.name,
        email: profile.email,
        supplierName: profile.supplierName,
      );

      if (!mounted) return;
      setState(() {
        _applyProfile(profile);
        _expandedIndex = -1;
      });
      FocusScope.of(context).unfocus();
      _showSnack(successMessage);
    } catch (e) {
      _showSnack('Не удалось сохранить: ${_errorMessage(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    final validationError = _validateName(name);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }
    await _saveProfile(name: name, successMessage: 'Имя сохранено');
  }

  Future<void> _saveEmail() async {
    final email = _emailController.text.trim();
    final validationError = _validateEmail(email);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }
    await _saveProfile(email: email, successMessage: 'Email сохранен');
  }

  Future<void> _savePhone() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final validationError = _validatePhoneDigits(digits);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }
    await _saveProfile(phone: digits, successMessage: 'Номер сохранен');
  }

  Future<void> _saveCompanyName() async {
    if (!_isSupplier) {
      return;
    }

    final companyName = _companyController.text.trim();
    if (companyName.isEmpty) {
      _showSnack('Введите название компании');
      return;
    }

    await _saveProfile(
      supplierName: companyName,
      successMessage: 'Название компании сохранено',
    );
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
        _companyController.text = _companyName;
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
                  backgroundColor: _colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    size: 36,
                    color: _colorScheme.onSurfaceVariant,
                  ),
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
                      _displayValue(_isSupplier ? _companyName : _email),
                      style: TextStyle(fontSize: 14, color: _mutedText),
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
                    onSave: _saveName,
                    onCancel: () => _cancelEdit(_nameController, _name),
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16),
                  _buildEditableTile(
                    index: 1,
                    icon: Icons.email_outlined,
                    title: 'ЭЛ. ПОЧТА',
                    value: _displayValue(_email),
                    controller: _emailController,
                    keyboardType: TextInputType.text,
                    onSave: _saveEmail,
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
                  if (_isSupplier) ...[
                    Divider(height: 1, indent: 56, endIndent: 16),
                    _buildEditableTile(
                      index: 3,
                      icon: Icons.business_outlined,
                      title: 'НАЗВАНИЕ КОМПАНИИ',
                      value: _displayValue(_companyName),
                      controller: _companyController,
                      onSave: _saveCompanyName,
                      onCancel: () =>
                          _cancelEdit(_companyController, _companyName),
                    ),
                  ],
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
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final isExpanded = _expandedIndex == index;
    final isSingleLine = maxLines == 1;
    final resolvedKeyboardType = isSingleLine
        ? keyboardType
        : (keyboardType == TextInputType.text
              ? TextInputType.multiline
              : keyboardType);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            if (_isSavingProfile) {
              return;
            }
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
            leading: Icon(icon, color: _primaryColor, size: 24),
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
              style: TextStyle(fontSize: 13, color: _mutedText),
            ),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(Icons.expand_more, color: _mutedText),
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
                          keyboardType: resolvedKeyboardType,
                          inputFormatters: inputFormatters,
                          maxLines: maxLines,
                          textInputAction: isSingleLine
                              ? TextInputAction.done
                              : TextInputAction.newline,
                          onSubmitted: isSingleLine && !_isSavingProfile
                              ? (_) => onSave()
                              : null,
                          decoration: InputDecoration(
                            hintText:
                                'Введите новое значение',
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
                                onPressed: _isSavingProfile ? null : onCancel,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _mutedText,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(color: _borderColor),
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
                                onPressed: _isSavingProfile ? null : onSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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

