import 'package:flutter/material.dart';
import '../models/user_address.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/main_bottom_nav.dart';
import 'package:flutter_project/profile/address_page.dart';

class MyAddressesPage extends StatefulWidget {
  const MyAddressesPage({super.key});

  @override
  State<MyAddressesPage> createState() => _MyAddressesPageState();
}

class _MyAddressesPageState extends State<MyAddressesPage> {
  static const Color _primaryColor = Color(0xFF6288D5);

  List<UserAddress> _addresses = [];
  int? _selectedAddressId;
  bool _isLoading = true;
  bool _isSaving = false;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg =>
      _isDark ? _theme.scaffoldBackgroundColor : const Color(0xFFF3F6FB);
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  int? _resolveSelectedAddressId(List<UserAddress> addresses) {
    if (addresses.isEmpty) {
      return null;
    }
    final storedId = AuthStorage.selectedAddressId;
    if (storedId != null && addresses.any((item) => item.id == storedId)) {
      return storedId;
    }
    return addresses.first.id;
  }

  Future<void> _loadAddresses({bool showLoading = true}) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      setState(() {
        _addresses = [];
        _isLoading = false;
      });
      return;
    }

    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final addresses = await ApiService.getUserAddresses(userId: userId);
      final selectedId = _resolveSelectedAddressId(addresses);
      if (selectedId != AuthStorage.selectedAddressId) {
        await AuthStorage.saveSelectedAddressId(selectedId);
      }
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _isLoading = false;
        _selectedAddressId = selectedId;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Не удалось загрузить адреса');
    }
  }

  Future<void> _openAddressEditor({UserAddress? address}) async {
    if (_isSaving) return;
    final draft = await Navigator.push<AddressDraft>(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPage(
          initial: address == null ? null : AddressDraft.fromAddress(address),
        ),
      ),
    );

    if (draft == null) return;

    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      _showSnack('Нужно войти в аккаунт');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final saved = address == null
          ? await ApiService.createUserAddress(userId: userId, draft: draft)
          : await ApiService.updateUserAddress(
              userId: userId,
              addressId: address.id,
              draft: draft,
            );

      if (!mounted) return;
      setState(() {
        if (address == null) {
          _addresses = [saved, ..._addresses];
          _selectedAddressId ??= saved.id;
        } else {
          final index = _addresses.indexWhere((item) => item.id == address.id);
          if (index != -1) {
            _addresses[index] = saved;
          }
        }
        _isSaving = false;
      });
      if (_selectedAddressId != null) {
        await AuthStorage.saveSelectedAddressId(_selectedAddressId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Не удалось сохранить адрес');
    }
  }

  Future<void> _confirmDelete(UserAddress address) async {
    final approved = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Закрыть',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: _DeleteAddressDialog(
              title: address.displayTitle,
              onCancel: () => Navigator.pop(context, false),
              onConfirm: () => Navigator.pop(context, true),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (approved != true) return;

    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      _showSnack('Нужно войти в аккаунт');
      return;
    }

    try {
      await ApiService.deleteUserAddress(
        userId: userId,
        addressId: address.id,
      );

      if (!mounted) return;
      final remainingAddresses = _addresses
          .where((item) => item.id != address.id)
          .toList();
      final nextSelectedId = remainingAddresses.isNotEmpty
          ? remainingAddresses.first.id
          : null;
      setState(() {
        _addresses = remainingAddresses;
        if (_selectedAddressId == address.id) {
          _selectedAddressId = nextSelectedId;
        }
      });
      await AuthStorage.saveSelectedAddressId(_selectedAddressId);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Не удалось удалить адрес');
    }
  }

  Future<void> _selectAddress(int addressId) async {
    if (_selectedAddressId == addressId) {
      return;
    }
    setState(() => _selectedAddressId = addressId);
    await AuthStorage.saveSelectedAddressId(addressId);
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _resolveIcon(UserAddress address) {
    switch (address.normalizedLabel) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primarySoft = _primaryColor.withValues(alpha: _isDark ? 0.18 : 0.12);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Мои адреса',
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : () => _openAddressEditor(),
            icon: const Icon(Icons.add_circle_outline, color: _primaryColor),
            tooltip: 'Добавить адрес',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            )
          : _addresses.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = _addresses[index];
                    return _buildAddressCard(
                      context: context,
                      icon: _resolveIcon(entry),
                      iconColor: _primaryColor,
                      iconBgColor: primarySoft,
                      title: entry.displayTitle,
                      address: entry.displayAddress,
                      isSelected: entry.id == _selectedAddressId,
                      onTap: () => _selectAddress(entry.id),
                      onEdit: () => _openAddressEditor(address: entry),
                      onDelete: () => _confirmDelete(entry),
                    );
                  },
                ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 36, color: _primaryColor),
            const SizedBox(height: 12),
            Text(
              'Адресов пока нет',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Добавьте адрес, чтобы оформить заказ быстрее.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _mutedText,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _openAddressEditor(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Добавить адрес'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String address,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final borderColor = isSelected ? _primaryColor : Colors.transparent;
    final shadowColor = _isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.06);

    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.isEmpty ? 'Без адреса' : address,
                      style: TextStyle(
                        fontSize: 13,
                        color: _mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _primaryColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Редактировать',
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: _primaryColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Удалить',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAddressDialog extends StatelessWidget {
  const _DeleteAddressDialog({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = colorScheme.surface;
    final titleColor = colorScheme.onSurface;
    final bodyColor = colorScheme.onSurfaceVariant;
    final outlineColor = colorScheme.outline.withValues(alpha: 0.6);
    final danger = colorScheme.error;
    final dangerText = colorScheme.onError;
    final neutralBg = colorScheme.surfaceContainerHighest;
    final neutralText = colorScheme.onSurface;
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.16);

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: outlineColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Удалить адрес?',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Адрес "$title" будет удален без возможности восстановления.',
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DeleteDialogActionButton(
                      label: 'Отмена',
                      background: neutralBg,
                      foreground: neutralText,
                      borderColor: outlineColor,
                      onTap: onCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DeleteDialogActionButton(
                      label: 'Удалить',
                      background: danger,
                      foreground: dangerText,
                      borderColor: danger,
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteDialogActionButton extends StatelessWidget {
  const _DeleteDialogActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}


