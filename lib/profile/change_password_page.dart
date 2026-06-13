import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../theme/app_color_palette.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import '../services/message/message_localization.dart';
import '../services/localization/localization_extension.dart';

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
  Color get _cardBg => context.colorPalette.card;
  Color get _inputFill => _colorScheme.surfaceContainerHighest;
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
      return context.l10n.getString('auto_vvediteTekushchiyParol');
    }
    if (trimmed.length < 6) {
      return context.l10n.getString('auto_minimum6Simvolov');
    }
    return null;
  }

  String? _validateNew(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return context.l10n.getString('auto_vvediteNovyyParol');
    }
    if (trimmed.length < 6) {
      return context.l10n.getString('auto_minimum6Simvolov');
    }
    if (trimmed == _currentPasswordController.text.trim()) {
      return context.l10n.getString('auto_novyyParolDolzhenOtlic');
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return context.l10n.getString('auto_povtoriteNovyyParol');
    }
    if (trimmed != _newPasswordController.text.trim()) {
      return context.l10n.getString('auto_paroliNeSovpadayut');
    }
    return null;
  }

  String _normalizeErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return context.l10n.getString('auto_neUdalosIzmenitParol');
    }

    const exceptionPrefix = 'Exception:';
    if (raw.startsWith(exceptionPrefix)) {
      final details = raw.substring(exceptionPrefix.length).trim();
      return details.isEmpty ? context.l10n.getString('auto_neUdalosIzmenitParol') : details;
    }

    const argumentPrefix = 'Invalid argument(s):';
    if (raw.startsWith(argumentPrefix)) {
      final details = raw.substring(argumentPrefix.length).trim();
      return details.isEmpty ? context.l10n.getString('auto_proverteVvedyonnyeDanny') : details;
    }

    return raw;
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      AppMessageSnackBar.show(
        context,
        Message(
          id: const Uuid().v4(),
          type: MessageType.notification,
          severity: MessageSeverity.warning,
          title: '',
          body: context.l10n.getString('auto_proverteVvedyonnyeDanny'),
          timestamp: DateTime.now(),
          language: MessageLocalizationManager.getCurrentLanguage(),
        ),
      );
      return;
    }

    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      AppMessageSnackBar.show(
        context,
        Message(
          id: const Uuid().v4(),
          type: MessageType.notification,
          severity: MessageSeverity.error,
          title: '',
          body: context.l10n.getString('auto_sessiyaIsteklaVoyditeS'),
          timestamp: DateTime.now(),
          language: MessageLocalizationManager.getCurrentLanguage(),
        ),
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
      AppMessageSnackBar.show(
        context,
        Message(
          id: const Uuid().v4(),
          type: MessageType.notification,
          severity: MessageSeverity.error,
          title: '',
          body: _normalizeErrorMessage(error),
          timestamp: DateTime.now(),
          language: MessageLocalizationManager.getCurrentLanguage(),
        ),
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
           title: Text(context.l10n.changePasswordSuccessTitle),
           content: Text(context.l10n.changePasswordSuccessMessage),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: Text(context.l10n.changePasswordDoneButton),
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
    final primaryColor = context.colorPalette.accent;
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
          context.l10n.getString('auto_izmenitParol'),
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
                  context.l10n.getString('auto_tekushchiyParol'),
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
                    hintText: context.l10n.getString('auto_vvediteTekushchiyParol'),
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
                  context.l10n.getString('auto_novyyParol'),
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
                    hintText: context.l10n.getString('auto_minimum6Simvolov'),
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
                  context.l10n.getString('auto_povtoriteNovyyParol'),
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
                    hintText: context.l10n.getString('auto_vvediteParolEshchyoRaz'),
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
                  context.l10n.getString('auto_parolDolzhenSoderzhatM'),
                  style: TextStyle(fontSize: 12, color: _mutedText),
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
                        : Text(context.l10n.getString('auto_sohranitParol'),
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
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }
}
