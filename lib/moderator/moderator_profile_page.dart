import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../login_screen/login.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import '../services/notification_service.dart';
import '../services/store/templates_store.dart';
import '../widgets/profile/user_avatar.dart';

class ModeratorProfilePage extends StatefulWidget {
  const ModeratorProfilePage({super.key});

  @override
  State<ModeratorProfilePage> createState() => _ModeratorProfilePageState();
}

class _ModeratorProfilePageState extends State<ModeratorProfilePage> {
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

  Future<void> _logout(BuildContext context) async {
    // Сначала очищаем уведомления - пока userId ещё доступен в AuthStorage
    await NotificationService().clearForLogout();
    await TemplatesStore.instance.clearCache();
    await AuthStorage.forget();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthStorage.name ?? 'Модератор';
    final email = AuthStorage.email ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль модератора')),
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorPalette.error,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
