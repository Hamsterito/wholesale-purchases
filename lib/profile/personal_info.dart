import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_color_palette.dart';
import 'package:flutter/services.dart';
import '../widgets/phone_input_formatter.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../services/storage/auth_storage.dart';
import '../services/api/api_service.dart';
import '../services/message/message_localization.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../widgets/profile/user_avatar.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../core/ui/theme/app_dimensions.dart';

// Лимит размера аватарки совпадает с серверным - чтобы не гонять сетевой
// запрос ради 413.
const int _avatarMaxSizeBytes = 5 * 1024 * 1024;

// Для multipart важно отдать сервереный MIME из whitelist, иначе backend вернёт 415.
String? _avatarMimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return null;
}

// На Web XFile.name бывает пустым - возвращаем дефолтное имя с расширением.
String _avatarFilename(XFile picked) {
  final raw = picked.name.trim();
  if (raw.isNotEmpty) return raw;
  final mime = picked.mimeType?.toLowerCase() ?? '';
  final ext = mime == 'image/png'
      ? 'png'
      : mime == 'image/webp'
          ? 'webp'
          : 'jpg';
  return 'avatar.$ext';
}

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage>
    with TickerProviderStateMixin {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyController;

  final _AvatarPicker _avatarPicker = _AvatarPicker();

  String? _avatarUrl;
  bool _avatarUploading = false;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => context.colorPalette.card;
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
    _avatarUrl = AuthStorage.avatarUrl;
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
      // Кладём свежий URL в кэш - профильные экраны читают AuthStorage.
      await AuthStorage.setAvatarUrl(profile.avatarUrl);
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
    _avatarUrl = profile.avatarUrl;

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
    return trimmed.isEmpty ? context.l10n.getString('auto_neUkazano') : trimmed;
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

  void _showSnack(
    String message, {
    MessageSeverity severity = MessageSeverity.info,
  }) {
    if (!mounted) return;
    final msg = Message(
      id: const Uuid().v4(),
      type: MessageType.notification,
      severity: severity,
      title: '',
      body: message,
      timestamp: DateTime.now(),
      language: MessageLocalizationManager.getCurrentLanguage(),
    );
    AppMessageSnackBar.show(context, msg);
  }

  String? _validateName(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      return context.l10n.getString('auto_vvediteImya');
    }
    if (name.length < 2) {
      return context.l10n.getString('auto_imyaSlishkomKorotkoe');
    }
    return null;
  }

  String? _validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) {
      return context.l10n.getString('auto_vvediteEmail');
    }
    if (!_emailRegex.hasMatch(email)) {
      return context.l10n.getString('auto_nekorrektnyyEmail');
    }
    return null;
  }

  String? _validatePhoneDigits(String digits) {
    if (digits.isEmpty) {
      return context.l10n.getString('auto_vvediteNomerTelefona');
    }
    if (digits.length != 11 || !digits.startsWith('7')) {
      return context.l10n.getString('auto_nomerDolzhenBytVForma_1');
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
      _showSnack(
        context.l10n.personalInfoSaveError(_errorMessage(e)),
        severity: MessageSeverity.error,
      );
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
      _showSnack(validationError, severity: MessageSeverity.warning);
      return;
    }
    await _saveProfile(name: name, successMessage: context.l10n.getString('auto_imyaSohraneno'));
  }

  Future<void> _saveEmail() async {
    final email = _emailController.text.trim();
    final validationError = _validateEmail(email);
    if (validationError != null) {
      _showSnack(validationError, severity: MessageSeverity.warning);
      return;
    }
    await _saveProfile(email: email, successMessage: context.l10n.getString('auto_emailSohranen'));
  }

  Future<void> _savePhone() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final validationError = _validatePhoneDigits(digits);
    if (validationError != null) {
      _showSnack(validationError, severity: MessageSeverity.warning);
      return;
    }
    await _saveProfile(phone: digits, successMessage: context.l10n.getString('auto_nomerSohranen'));
  }

  Future<void> _saveCompanyName() async {
    if (!_isSupplier) {
      return;
    }

    final companyName = _companyController.text.trim();
    if (companyName.isEmpty) {
      _showSnack(
        context.l10n.getString('auto_vvediteNazvanieKompanii'),
        severity: MessageSeverity.warning,
      );
      return;
    }

    await _saveProfile(
      supplierName: companyName,
      successMessage: context.l10n.getString('auto_nazvanieKompaniiSohrane'),
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

  // Действия с аватаркой

  void _openAvatarSheet() {
    if (_avatarUploading || _isSavingProfile) return;
    final palette = context.colorPalette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          minimum: const EdgeInsets.only(bottom: AppDimensions.minBottomSafePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera, color: palette.accent),
                title: Text(
                  context.l10n.getString('auto_sdelatSnimok'),
                  style: TextStyle(color: palette.ink),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _handlePickFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: palette.accent),
                title: Text(
                  context.l10n.getString('auto_vybratIzGalerei'),
                  style: TextStyle(color: palette.ink),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _handlePickFromGallery();
                },
              ),
              if (_avatarUrl != null)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: palette.error),
                  title: Text(
                    context.l10n.getString('auto_udalitFoto'),
                    style: TextStyle(color: palette.error),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _handleDeleteAvatar();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePickFromCamera() async {
    try {
      final file = await _avatarPicker.pickFromCamera();
      if (file == null) return;
      await _uploadFile(file);
    } catch (e) {
      _showSnack(_errorMessage(e), severity: MessageSeverity.error);
    }
  }

  Future<void> _handlePickFromGallery() async {
    try {
      final file = await _avatarPicker.pickFromGallery();
      if (file == null) return;
      await _uploadFile(file);
    } catch (e) {
      _showSnack(_errorMessage(e), severity: MessageSeverity.error);
    }
  }

  Future<void> _uploadFile(XFile picked) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      _showSnack(context.l10n.getString('auto_vyNeAvtorizovany'), severity: MessageSeverity.error);
      return;
    }

    // Читаем байты напрямую из XFile - File(picked.path) не работает на Web,
    // там path это blob URL и dart:io File падает с _Namespace.
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _avatarMaxSizeBytes) {
      _showSnack(
        context.l10n.getString('auto_razmerFaylaNeDolzhenP'),
        severity: MessageSeverity.warning,
      );
      return;
    }

    setState(() => _avatarUploading = true);
    try {
      final newUrl = await ApiService.uploadAvatar(
        userId: userId,
        bytes: bytes,
        filename: _avatarFilename(picked),
        mimeType: picked.mimeType ?? _avatarMimeFromName(picked.name),
      );
      if (!mounted) return;
      setState(() => _avatarUrl = newUrl);
      await AuthStorage.setAvatarUrl(newUrl);
    } catch (e) {
      if (!mounted) return;
      _showSnack(_errorMessage(e), severity: MessageSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
      }
    }
  }

  Future<void> _handleDeleteAvatar() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      _showSnack(context.l10n.getString('auto_vyNeAvtorizovany'), severity: MessageSeverity.error);
      return;
    }

    setState(() => _avatarUploading = true);
    try {
      await ApiService.deleteAvatar(userId: userId);
      if (!mounted) return;
      setState(() => _avatarUrl = null);
      await AuthStorage.setAvatarUrl(null);
    } catch (e) {
      if (!mounted) return;
      _showSnack(_errorMessage(e), severity: MessageSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
      }
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
          context.l10n.getString('auto_lichnayaInformatsiya'),
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
                GestureDetector(
                  onTap: _avatarUploading ? null : _openAvatarSheet,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      UserAvatar(
                        avatarUrl: _avatarUrl,
                        displayName: _name.isNotEmpty
                            ? _name
                            : (AuthStorage.name ?? ''),
                        radius: 35,
                      ),
                      if (_avatarUploading)
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Material(
                          color: context.colorPalette.accent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _avatarUploading ? null : _openAvatarSheet,
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                    title: context.l10n.getString('auto_fio'),
                    value: _displayValue(_name),
                    controller: _nameController,
                    onSave: _saveName,
                    onCancel: () => _cancelEdit(_nameController, _name),
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16),
                  _buildEditableTile(
                    index: 1,
                    icon: Icons.email_outlined,
                    title: context.l10n.getString('auto_elPochta'),
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
                    title: context.l10n.getString('auto_nomer'),
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
                      title: context.l10n.getString('auto_nazvanieKompanii'),
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
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
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
            leading: Icon(icon, color: context.colorPalette.accent, size: 24),
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
                            hintText: context.l10n.getString('auto_vvediteNovoeZnachenie'),
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
                                  context.l10n.getString('auto_otmena'),
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
                                  backgroundColor: context.colorPalette.accent,
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
                                  context.l10n.getString('auto_sohranit_1'),
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

// Локальная обёртка над image_picker - позволяет проще мокать в тестах
// и не тащит ImagePicker по всему стейту страницы.
class _AvatarPicker {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromCamera() {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2048,
    );
  }

  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
    );
  }
}
