import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api/api_service.dart';
import '../services/localization/localization_extension.dart';
import '../theme/app_color_palette.dart';
import '../widgets/phone_input_formatter.dart';

/// Диалог добавления нового модератора. Возвращает созданного Moderator
/// при успехе или null при отмене / закрытии.
class AddModeratorDialog extends StatefulWidget {
  const AddModeratorDialog({super.key});

  @override
  State<AddModeratorDialog> createState() => _AddModeratorDialogState();
}

class _AddModeratorDialogState extends State<AddModeratorDialog> {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _showValidation = false;
  String? _serverError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return context.l10n.auto_vvediteImya;
    if (name.length < 2) return context.l10n.auto_slishkomKorotkoe;
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return context.l10n.auto_vvediteEmail;
    if (!_emailRegex.hasMatch(email)) return context.l10n.auto_nekorrektnyyEmail;
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return context.l10n.auto_vvediteTelefon;
    if (digits.length != 11) return context.l10n.auto_nuzhno11Tsifr;
    if (!digits.startsWith('7')) return context.l10n.auto_dolzhenNachinatsyaS7;
    return null;
  }

  String? _validatePassword(String? value) {
    final pwd = value ?? '';
    if (pwd.isEmpty) return context.l10n.auto_vvediteParol;
    if (pwd.length < 6) return context.l10n.auto_minimum6Simvolov;
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null) return;
    // Включаем валидацию по нажатию на «Добавить» - до этого момента
    // пользователю не показываются красные «Заполните поле».
    if (!_showValidation) {
      setState(() => _showValidation = true);
    }
    if (!form.validate()) return;

    setState(() {
      _isSubmitting = true;
      _serverError = null;
    });

    try {
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final moderator = await ApiService.createModerator(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: phoneDigits,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(moderator);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _serverError = _humanizeError(e);
        _isSubmitting = false;
      });
    }
  }

  // Сообщения уровня StateError (нет авторизации) - отдельным алертом,
  // прочие ошибки показываем плашкой внутри диалога
  String _humanizeError(Object error) {
    if (error is StateError) return error.message;
    var msg = error.toString();
    final exceptionPrefix = 'Exception: ';
    if (msg.startsWith(exceptionPrefix)) {
      msg = msg.substring(exceptionPrefix.length);
    }
    return msg.trim().isEmpty ? context.l10n.auto_neUdalosSozdatModerato : msg;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = context.colorPalette;

    return AlertDialog(
      backgroundColor: palette.card,
      title: Text(context.l10n.addModeratorTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            // До первого нажатия «Добавить» поля молчат, после - валидируют
            // на каждое изменение, чтобы ошибки гасились по мере исправления.
            autovalidateMode: _showValidation
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_serverError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: palette.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: palette.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serverError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: context.l10n.auto_imya_1,
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    const PhoneNumberInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: context.l10n.auto_telefon,
                    hintText: '7 (XXX) XXX-XX-XX',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePhone,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: context.l10n.auto_parol_1,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? context.l10n.auto_pokazat : context.l10n.auto_skryt,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                    ),
                  ),
                  validator: _validatePassword,
                  enabled: !_isSubmitting,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.moderatorAddButton),
        ),
      ],
    );
  }
}

/// Открывает диалог добавления модератора.
Future<Moderator?> showAddModeratorDialog(BuildContext context) {
  return showDialog<Moderator>(
    context: context,
    builder: (_) => const AddModeratorDialog(),
  );
}
