import 'package:flutter/material.dart';
import '../utils/ru_plural.dart';

class RatingSection extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final VoidCallback? onTap;

  const RatingSection({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = colorScheme.surface;
    final mutedText = colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: cardBg,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(5, (index) {
              if (index < rating.floor()) {
                return Icon(
                  Icons.star,
                  color: Color(0xFFF5B400),
                  size: 14,
                );
              } else if (index < rating) {
                return Icon(
                  Icons.star_half,
                  color: Color(0xFFF5B400),
                  size: 14,
                );
              } else {
                return Icon(
                  Icons.star_border,
                  color: mutedText,
                  size: 14,
                );
              }
            }),
            const SizedBox(width: 8),
            Text(
              reviewsLabel(reviewCount),
              style: TextStyle(
                fontSize: 12,
                color: mutedText,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: mutedText),
          ],
        ),
      ),
    );
  }
}


