import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../models/product.dart';
import '../../services/localization/localization_extension.dart';
import '../smart_image.dart';
import '../../utils/date_formatter.dart';

class SupplierQAQuestionCard extends StatelessWidget {
  final Question question;
  final Product product;
  final VoidCallback onAnswer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final dynamic palette;

  const SupplierQAQuestionCard({
    super.key,
    required this.question,
    required this.product,
    required this.onAnswer,
    required this.onEdit,
    required this.onDelete,
    required this.palette,
  });

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок товара
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SmartImage(
                  path: question.productImage,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.productName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      question.userName,
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Текст вопроса
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 15,
              color: palette.ink,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Дата
          Text(
            _formatDate(question.createdAt),
            style: TextStyle(fontSize: 11, color: palette.muted),
          ),
          // Секция ответа (если отвечено)
          if (question.isAnswered && question.answer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.accentMist,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.accentSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: palette.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ответ от ${question.answer!.supplierName}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.answer!.answerText,
                    style: TextStyle(
                      fontSize: 15,
                      color: palette.ink,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(question.answer!.answeredAt),
                    style: TextStyle(fontSize: 10, color: palette.muted),
                  ),
                ],
              ),
            ),
          ],
const SizedBox(height: 12),
           // Кнопки действий
           Row(
             mainAxisAlignment: MainAxisAlignment.end,
             children: [
               if (!question.isAnswered)
                 FilledButton(
                   onPressed: onAnswer,
                   style: FilledButton.styleFrom(
                     backgroundColor: palette.accent,
                     padding: const EdgeInsets.symmetric(
                       horizontal: 16,
                       vertical: 8,
                     ),
                   ),
                   child: Text(context.l10n.qaRespond, style: TextStyle(fontSize: 12)),
                 )
               else ...[
                 OutlinedButton(
                   onPressed: onEdit,
                   style: OutlinedButton.styleFrom(
                     side: BorderSide(color: palette.accent),
                     padding: const EdgeInsets.symmetric(
                       horizontal: 16,
                       vertical: 8,
                     ),
                   ),
                   child: Text(
                     context.l10n.edit,
                     style: TextStyle(fontSize: 12, color: palette.accent),
                   ),
                 ),
                 const SizedBox(width: 8),
                 OutlinedButton(
                   onPressed: onDelete,
                   style: OutlinedButton.styleFrom(
                     side: BorderSide(color: palette.danger),
                     padding: const EdgeInsets.symmetric(
                       horizontal: 16,
                       vertical: 8,
                     ),
                   ),
                   child: Text(
                     context.l10n.delete,
                     style: TextStyle(fontSize: 12, color: palette.danger),
                   ),
                 ),
               ],
             ],
           ),
        ],
      ),
    );
  }
}
