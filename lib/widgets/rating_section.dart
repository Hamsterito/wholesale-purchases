import 'package:flutter/material.dart';

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
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(5, (index) {
              if (index < rating.floor()) {
                return const Icon(Icons.star, color: Colors.amber, size: 20);
              } else if (index < rating) {
                return const Icon(Icons.star_half, color: Colors.amber, size: 20);
              } else {
                return Icon(Icons.star_border, color: Colors.grey.shade400, size: 20);
              }
            }),
            const SizedBox(width: 8),
            Text(
              '$reviewCount отзывов',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}