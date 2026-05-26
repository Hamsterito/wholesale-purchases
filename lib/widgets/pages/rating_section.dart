import 'package:flutter/material.dart';
import '../../theme/app_color_palette.dart';
import '../../utils/ru_plural.dart';
import '../product/rating_stars.dart';

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
    final palette = context.colorPalette;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: palette.card,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(width: 8),
            RatingStars(
              rating: rating,
              size: 14,
              spacing: 1,
              filledColor: palette.star,
              emptyColor: palette.muted,
            ),
            const SizedBox(width: 8),
            Text(
              reviewsLabel(reviewCount),
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: palette.muted),
          ],
        ),
      ),
    );
  }
}
