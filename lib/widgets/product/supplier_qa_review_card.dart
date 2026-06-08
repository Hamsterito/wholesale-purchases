import 'package:flutter/material.dart';
import '../../models/review_entry.dart';
import '../../models/product.dart';
import '../../services/localization/localization_extension.dart';
import '../smart_image.dart';
import 'rating_stars.dart';
import '../expandable_text_block.dart';
import '../../utils/date_formatter.dart';
import '../../theme/app_color_palette.dart';

class SupplierQAReviewCard extends StatelessWidget {
  final ReviewEntry review;
  final Product product;
  final VoidCallback onRespond;
  final VoidCallback onEditResponse;
  final VoidCallback onDelete;
  final bool hasResponse;
  final String? responseText;
  final DateTime? responseDate;
  final String? responderName;

  const SupplierQAReviewCard({
    super.key,
    required this.review,
    required this.product,
    required this.onRespond,
    required this.onEditResponse,
    required this.onDelete,
    this.hasResponse = false,
    this.responseText,
    this.responseDate,
    this.responderName,
  });

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

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
          // Заголовок товара с изображением слева, названием и звездами справа
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SmartImage(
                  path: review.productImage,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            review.productName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Звезды в правом верхнем углу
                        RatingStars(
                          rating: review.rating.toDouble(),
                          size: 14,
                          filledColor: palette.accent,
                          emptyColor: palette.line,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Имя пользователя под названием товара
                    Text(
                      review.reviewerName,
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Текст отзыва черным цветом (цвет чернил)
ExpandableTextBlock(
             review.reviewText,
             textStyle: TextStyle(fontSize: 13, color: palette.ink, height: 1.4),
             actionColor: palette.accent,
             collapsedMaxLines: 3,
             moreLabel: context.l10n.qaExpand,
             lessLabel: context.l10n.qaCollapse,
           ),
          const SizedBox(height: 8),
          // Дата
          Text(
            _formatDate(review.createdAt),
            style: TextStyle(fontSize: 11, color: palette.muted),
          ),
          // Секция ответа (если существует)
          if (hasResponse && responseText != null) ...[
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
                        'Ответ от ${responderName ?? "поставщика"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
ExpandableTextBlock(
                     responseText!,
                     textStyle: TextStyle(
                       fontSize: 12,
                       color: palette.ink,
                       height: 1.4,
                     ),
                     actionColor: palette.accent,
                     collapsedMaxLines: 3,
                     moreLabel: context.l10n.qaExpand,
                     lessLabel: context.l10n.qaCollapse,
                   ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(responseDate ?? DateTime.now()),
                    style: TextStyle(fontSize: 10, color: palette.muted),
                  ),
                ],
              ),
            ),
          ],
          // Кнопки действий
          const SizedBox(height: 12),
          _buildActionButtons(context, palette),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppColorPalette palette) {
    if (hasResponse) {
      // Показать кнопки "Изменить ответ" и "Удалить"
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onEditResponse,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: palette.accent),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'Изменить ответ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: palette.error),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            child: Icon(Icons.delete_outline, size: 18, color: palette.error),
          ),
        ],
      );
    } else {
      // Показать кнопку "Ответить"
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onRespond,
          style: FilledButton.styleFrom(
            backgroundColor: palette.accent,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
child: Text(
              context.l10n.qaRespond,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
        ),
      );
    }
  }
}
