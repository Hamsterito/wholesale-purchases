import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isSaving = false;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _inputFill => _colorScheme.surfaceVariant;
  Color get _mutedText => _colorScheme.onSurfaceVariant;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrent(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Введите текущий пароль';
    }
    if (trimmed.length < 6) {
      return 'Минимум 6 символов';
    }
    return null;
  }

  String? _validateNew(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Введите новый пароль';
    }
    if (trimmed.length < 6) {
      return 'Минимум 6 символов';
    }
    if (trimmed == _currentPasswordController.text.trim()) {
      return 'Новый пароль должен отличаться от текущего';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Повторите новый пароль';
    }
    if (trimmed != _newPasswordController.text.trim()) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  String _normalizeErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return 'Не удалось изменить пароль';
    }

    const exceptionPrefix = 'Exception:';
    if (raw.startsWith(exceptionPrefix)) {
      final details = raw.substring(exceptionPrefix.length).trim();
      return details.isEmpty ? 'Не удалось изменить пароль' : details;
    }

    const argumentPrefix = 'Invalid argument(s):';
    if (raw.startsWith(argumentPrefix)) {
      final details = raw.substring(argumentPrefix.length).trim();
      return details.isEmpty ? 'Проверьте введённые данные' : details;
    }

    return raw;
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проверьте введённые данные')),
      );
      return;
    }

    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сессия истекла. Войдите снова.')),
      );
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.changeUserPassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_normalizeErrorMessage(error))),
      );
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Пароль изменён'),
          content: const Text('Ваш пароль успешно обновлён.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Готово'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6288D5);
    const fieldContentPadding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 16,
    );

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
          'Изменить пароль',
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Текущий пароль',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  enabled: !_isSaving,
                  controller: _currentPasswordController,
                  textInputAction: TextInputAction.next,
                  obscureText: !_showCurrent,
                  validator: _validateCurrent,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _inputFill,
                    hintText: 'Введите текущий пароль',
                    hintStyle: TextStyle(color: _mutedText),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: fieldContentPadding,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showCurrent ? Icons.visibility_off : Icons.visibility,
                        color: _mutedText,
                      ),
                      onPressed: () {
                        setState(() {
                          _showCurrent = !_showCurrent;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Новый пароль',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  enabled: !_isSaving,
                  controller: _newPasswordController,
                  textInputAction: TextInputAction.next,
                  obscureText: !_showNew,
                  validator: _validateNew,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _inputFill,
                    hintText: 'Минимум 6 символов',
                    hintStyle: TextStyle(color: _mutedText),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: fieldContentPadding,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNew ? Icons.visibility_off : Icons.visibility,
                        color: _mutedText,
                      ),
                      onPressed: () {
                        setState(() {
                          _showNew = !_showNew;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Повторите новый пароль',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  enabled: !_isSaving,
                  controller: _confirmPasswordController,
                  textInputAction: TextInputAction.done,
                  obscureText: !_showConfirm,
                  validator: _validateConfirm,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _inputFill,
                    hintText: 'Введите пароль ещё раз',
                    hintStyle: TextStyle(color: _mutedText),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: fieldContentPadding,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirm ? Icons.visibility_off : Icons.visibility,
                        color: _mutedText,
                      ),
                      onPressed: () {
                        setState(() {
                          _showConfirm = !_showConfirm;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Пароль должен содержать минимум 6 символов и отличаться от текущего.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _mutedText,
                  ),
                ),
                const SizedBox(height: 24),
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
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'СОХРАНИТЬ ПАРОЛЬ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }
}

