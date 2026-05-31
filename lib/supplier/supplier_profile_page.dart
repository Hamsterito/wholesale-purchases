import 'package:flutter/material.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import '../theme/app_color_palette.dart';
import '../utils/logout_flow.dart';
import '../widgets/profile/user_avatar.dart';

class SupplierProfilePage extends StatefulWidget {
  const SupplierProfilePage({super.key});

  @override
  State<SupplierProfilePage> createState() => _SupplierProfilePageState();
}

class _SupplierProfilePageState extends State<SupplierProfilePage> {
  // null пока профиль не загружен - тогда берём аватарку из кэша AuthStorage.
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _avatarUrl = AuthStorage.avatarUrl;
    _loadAvatar();
  }

  // Подтягиваем актуальную аватарку с сервера и синхронизируем кэш
  Future<void> _loadAvatar() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;
    try {
      final profile = await ApiService.getUserProfile(userId: userId);
      await AuthStorage.setAvatarUrl(profile.avatarUrl);
      if (!mounted) return;
      setState(() => _avatarUrl = profile.avatarUrl);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColorPalette.of(context);
    final name = AuthStorage.name ?? 'Поставщик';
    final email = AuthStorage.email ?? '-';
    final supplierName = AuthStorage.supplierName ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль поставщика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: UserAvatar(
                avatarUrl: _avatarUrl,
                displayName: name,
                radius: 50,
              ),
            ),
          ),
          _InfoTile(label: 'Имя', value: name),
          _InfoTile(label: 'Эл. почта', value: email),
          _InfoTile(label: 'Компания', value: supplierName),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => performLogout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppColorPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: palette.muted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
