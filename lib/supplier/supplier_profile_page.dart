import 'package:flutter/material.dart';
import '../login_screen/login.dart';
import '../services/auth_storage.dart';
import '../services/notification_service.dart';
import '../services/templates_store.dart';
import '../theme/app_color_palette.dart';

class SupplierProfilePage extends StatelessWidget {
  const SupplierProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    // Сначала очищаем сервис уведомлений, пока userId ещё доступен —
    // иначе следующий пользователь увидит чужие счётчики
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
    final palette = AppColorPalette.of(context);
    final name = AuthStorage.name ?? 'Поставщик';
    final email = AuthStorage.email ?? '-';
    final supplierName = AuthStorage.supplierName ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль поставщика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(label: 'Имя', value: name),
          _InfoTile(label: 'Эл. почта', value: email),
          _InfoTile(label: 'Компания', value: supplierName),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _logout(context),
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
