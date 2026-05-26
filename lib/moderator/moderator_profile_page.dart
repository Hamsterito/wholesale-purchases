import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../login_screen/login.dart';
import '../services/storage/auth_storage.dart';
import '../services/notification_service.dart';
import '../services/store/templates_store.dart';

class ModeratorProfilePage extends StatelessWidget {
  const ModeratorProfilePage({super.key});

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
