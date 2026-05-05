import 'package:flutter/material.dart';
import '../models/question.dart';
import 'expandable_text_block.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  const QuestionCard({Key? key, required this.question}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = question.userName;
    final date = _formatDate(question.createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар + имя + дата
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.surfaceContainerHighest,
                child: Text(name[0].toUpperCase(), style: TextStyle(color: const Color(0xFF6288D5), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(date, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
           const SizedBox(height: 12),
           ExpandableTextBlock(
             question.questionText,
             textStyle: TextStyle(fontSize: 15, height: 1.4),
             actionColor: const Color(0xFF6288D5),
             collapsedMaxLines: 2,
             actionFontSize: 11,
           ),
          // Ответ продавца
          if (question.answer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6288D5).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store_rounded, size: 16, color: const Color(0xFF6288D5)),
                      const SizedBox(width: 6),
                      Text('Ответ продавца', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF6288D5))),
                    ],
                  ),
                   const SizedBox(height: 8),
                   ExpandableTextBlock(
                     question.answer!.answerText,
                     textStyle: const TextStyle(fontSize: 14, height: 1.4),
                     actionColor: const Color(0xFF6288D5),
                     collapsedMaxLines: 2,
                     actionFontSize: 11,
                   ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['января','февраля','марта','апреля','мая','июня',
                    'июля','августа','сентября','октября','ноября','декабря'];
    return '${date.day} ${months[date.month-1]}, ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
  }
}