import 'package:flutter/material.dart';

import '../../theme/app_color_palette.dart';

/// Диалог «Заменить корзину товарами из шаблона?». Показывается только
/// при непустой корзине; true - подтверждено, иначе - отмена.
class ApplyTemplateConfirmDialog extends StatelessWidget {
  const ApplyTemplateConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

    // Ограничиваем масштабирование текста сверху до 2.0.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 2.0,
      child: AlertDialog(
        backgroundColor: palette.card,
        title: const Text('Заменить корзину?'),
        content: const Text(
          'Текущая корзина будет очищена и заменена товарами из шаблона. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Заменить'),
          ),
        ],
      ),
    );
  }
}

/// Открывает диалог замены корзины.
Future<bool?> showApplyTemplateConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const ApplyTemplateConfirmDialog(),
  );
}
