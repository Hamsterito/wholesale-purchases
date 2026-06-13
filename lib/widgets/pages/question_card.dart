import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../services/localization/localization_extension.dart';
import '../../theme/app_color_palette.dart';
import '../expandable_text_block.dart';
import '../profile/user_avatar.dart';
import '../../utils/date_formatter.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final AppColorPalette palette;

  const QuestionCard({
    super.key,
    required this.question,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final name = question.userName;
    final relativeTime = DateFormatter.formatDate(question.createdAt);
    final questionText = question.questionText.trim().isEmpty
        ? context.l10n.auto_bezTeksta
        : question.questionText.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: question.userAvatarUrl,
                displayName: name,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      relativeTime,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
ExpandableTextBlock(
             questionText,
             textStyle: TextStyle(
               fontSize: 15,
               color: palette.ink,
               height: 1.4,
               fontWeight: FontWeight.w500,
             ),
             actionColor: palette.accent,
             collapsedMaxLines: 3,
             moreLabel: context.l10n.qaExpand,
             lessLabel: context.l10n.qaCollapse,
           ),
          if (question.answer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.accentMist,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.line.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        size: 16,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.auto_otvetProdavtsa,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question.answer!.supplierName,
                          style: TextStyle(fontSize: 11, color: palette.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
ExpandableTextBlock(
                     question.answer!.answerText,
                     textStyle: TextStyle(
                       fontSize: 15,
                       color: palette.ink,
                       height: 1.4,
                       fontWeight: FontWeight.w500,
                     ),
                     actionColor: palette.accent,
                     collapsedMaxLines: 3,
                     moreLabel: context.l10n.qaExpand,
                     lessLabel: context.l10n.qaCollapse,
                   ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
