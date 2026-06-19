import 'package:flutter/material.dart';
import 'package:flutter_project/theme/app_color_palette.dart';
import 'package:flutter_project/services/moderation_alert_service.dart';
import 'moderation_alert_dialog.dart';

class ModerationAlertBanner extends StatelessWidget {
  final List<ModerationAlertInfo> alerts;
  final VoidCallback onDismiss;
  final VoidCallback onContactSupport;

  const ModerationAlertBanner({
    super.key,
    required this.alerts,
    required this.onDismiss,
    required this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final palette = context.colorPalette;
    
    // Мы можем показать название первого товара, либо общий текст, если их несколько
    final String title = alerts.length == 1
        ? 'Товар «${alerts.first.productName}» удалён модератором'
        : 'Удалено товаров модератором: ${alerts.length}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.error,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: palette.error.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ModerationAlertDialog.show(
                context,
                alerts: alerts,
                onContactSupport: onContactSupport,
              );
              // Мы скрываем баннер при нажатии на "Подробнее",
              // так как пользователю теперь показаны полные детали.
              onDismiss();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Подробнее',
                style: TextStyle(
                  color: palette.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
