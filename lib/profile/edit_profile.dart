import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/message.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import '../services/message/message_localization.dart';
import '../theme/app_color_palette.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../widgets/phone_input_formatter.dart';
import '../widgets/profile/user_avatar.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../core/ui/theme/app_dimensions.dart';

class EditProfilePage extends StatefulWidget {
  final String title;
  final String initialValue;
  final String fieldType; // 'name', 'email', 'phone', 'description'

  const EditProfilePage({
    super.key,
    required this.title,
    required this.initialValue,
    required this.fieldType,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

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

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;

  final _AvatarPicker _avatarPicker = _AvatarPicker();

  String? _avatarUrl;
  bool _avatarUploading = false;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => context.colorPalette.card;
  Color get _inputFill => _colorScheme.surfaceContainerHighest;

  @override
  void initState() {
    super.initState();
    _avatarUrl = AuthStorage.avatarUrl;
    _nameController = TextEditingController(text: context.l10n.getString('auto_ivanIvanov'));
    _emailController = TextEditingController(text: 'ivanov@mail.ru');
    _phoneController = TextEditingController(
      text: PhoneNumberInputFormatter.formatDigits('77777777777'),
    );
    _descriptionController = TextEditingController(text: context.l10n.getString('auto_lyublyuSladosti'));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11;
  }

  // Действия с аватаркой

  void _openAvatarSheet() {
    if (_avatarUploading) return;
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
      _showError(_errorMessage(e));
    }
  }

  Future<void> _handlePickFromGallery() async {
    try {
      final file = await _avatarPicker.pickFromGallery();
      if (file == null) return;
      await _uploadFile(file);
    } catch (e) {
      _showError(_errorMessage(e));
    }
  }

  Future<void> _uploadFile(XFile picked) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      _showError(context.l10n.getString('auto_vyNeAvtorizovany'));
      return;
    }

    // Читаем байты напрямую из XFile - File(picked.path) не работает на Web,
    // там path это blob URL и dart:io File падает с _Namespace.
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _avatarMaxSizeBytes) {
      _showError(context.l10n.getString('auto_razmerFaylaNeDolzhenP'));
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
      _showError(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
      }
    }
  }

  Future<void> _handleDeleteAvatar() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      _showError(context.l10n.getString('auto_vyNeAvtorizovany'));
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
      _showError(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
      }
    }
  }

  String _errorMessage(Object error) {
    final text = error.toString().trim();
    const prefix = 'Exception:';
    if (text.startsWith(prefix)) {
      return text.substring(prefix.length).trim();
    }
    return text;
  }

  void _showError(String body) {
    if (!mounted || body.isEmpty) return;
    AppMessageSnackBar.show(
      context,
      Message(
        id: const Uuid().v4(),
        type: MessageType.notification,
        severity: MessageSeverity.error,
        title: '',
        body: body,
        timestamp: DateTime.now(),
        language: MessageLocalizationManager.getCurrentLanguage(),
      ),
    );
  }

  void _showWarning(String body) {
    if (!mounted || body.isEmpty) return;
    AppMessageSnackBar.show(
      context,
      Message(
        id: const Uuid().v4(),
        type: MessageType.notification,
        severity: MessageSeverity.warning,
        title: '',
        body: body,
        timestamp: DateTime.now(),
        language: MessageLocalizationManager.getCurrentLanguage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final primaryColor = palette.accent;
    final displayName = AuthStorage.name ?? '';

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
          context.l10n.getString('auto_redProfil'),
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Аватар с кнопкой редактирования и оверлеем загрузки
            GestureDetector(
              onTap: _avatarUploading ? null : _openAvatarSheet,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  UserAvatar(
                    avatarUrl: _avatarUrl,
                    displayName: displayName,
                    radius: 50,
                  ),
                  if (_avatarUploading)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
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
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: primaryColor,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _avatarUploading ? null : _openAvatarSheet,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _buildTextField(label: context.l10n.getString('auto_fio'), controller: _nameController),

            const SizedBox(height: 16),

            _buildTextField(
              label: context.l10n.getString('auto_elPochta'),
              controller: _emailController,
              keyboardType: TextInputType.text,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              label: context.l10n.getString('auto_nomer'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                const PhoneNumberInputFormatter(),
              ],
            ),

            const SizedBox(height: 16),

            _buildTextField(
              label: context.l10n.getString('auto_opisanie'),
              controller: _descriptionController,
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _avatarUploading
                    ? null
                    : () {
                        if (!_isValidPhone(_phoneController.text)) {
                          _showWarning(
                            context.l10n.getString('auto_nomerDolzhenBytVForma'),
                          );
                          return;
                        }
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(context.l10n.getString('auto_sohranit'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          decoration: InputDecoration(
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
