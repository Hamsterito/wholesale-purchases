import 'package:flutter/material.dart';
import 'package:flutter_project/theme/app_color_palette.dart';
import 'package:flutter_project/services/moderation_alert_service.dart';
import 'package:flutter_project/services/localization/app_localizations.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import 'package:flutter_project/models/language.dart';

class ModerationAlertDialog extends StatelessWidget {
  final List<ModerationAlertInfo> alerts;
  final VoidCallback onContactSupport;

  const ModerationAlertDialog({
    super.key,
    required this.alerts,
    required this.onContactSupport,
  });

  static void show(
    BuildContext context, {
    required List<ModerationAlertInfo> alerts,
    required VoidCallback onContactSupport,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModerationAlertDialog(
        alerts: alerts,
        onContactSupport: onContactSupport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final l10n = AppLocalizations.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: palette.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: palette.error,
                size: 32,
              ),
            ),
          ),
          Text(
            alerts.length > 1
                ? l10n.getString('moderation_dialog_title_multiple')
                : l10n.getString('moderation_dialog_title_single'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.getString('moderation_dialog_description'),
            style: TextStyle(
              fontSize: 15,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.bgTop,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.currentLanguage == LanguageCode.kazakh && alert.productNameKk.isNotEmpty
                            ? alert.productNameKk
                            : alert.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: palette.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 14, color: palette.error),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l10n.getString('moderation_dialog_reason_prefix', params: {'reason': alert.reason}),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.ink,
              foregroundColor: palette.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              l10n.getString('moderation_dialog_ok_button'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onContactSupport();
            },
            style: TextButton.styleFrom(
              foregroundColor: palette.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.getString('moderation_dialog_appeal_button'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
