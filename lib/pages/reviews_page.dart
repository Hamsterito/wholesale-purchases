import 'package:flutter/material.dart';
import '../models/product.dart';

class ReviewsPage extends StatelessWidget {
  final Product product;

  const ReviewsPage({
    super.key,
    required this.product,
  });

  List<_ReviewData> get _reviews => const [
        _ReviewData(
          title: 'Название организации',
          date: '18.09.2025',
          rating: 5,
          text: 'Отзыв данному товару. Отзыв данному товару.',
        ),
        _ReviewData(
          title: 'Название организации',
          date: '18.09.2025',
          rating: 5,
          text: 'Отзыв данному товару. Отзыв данному товару.',
        ),
        _ReviewData(
          title: 'Название организации',
          date: '12.09.2025',
          rating: 4,
          text: 'Хороший товар, быстрая доставка.',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pageBg = theme.scaffoldBackgroundColor;
    final cardBg = colorScheme.surface;
    final mutedText = colorScheme.onSurfaceVariant;
    final borderColor = colorScheme.outlineVariant;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: const Text(
          'Отзывы',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(
            cardBg: cardBg,
            borderColor: borderColor,
            mutedText: mutedText,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          ..._reviews.map(
            (review) => _buildReviewCard(
              review,
              cardBg: cardBg,
              borderColor: borderColor,
              mutedText: mutedText,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required Color cardBg,
    required Color borderColor,
    required Color mutedText,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Оценок: ${product.reviewCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                final ratingData = product.ratingDistribution.firstWhere(
                  (r) => r.stars == stars,
                  orElse: () => RatingDistribution(stars: stars, count: 0),
                );
                return _buildRatingBar(
                  stars,
                  ratingData.count,
                  product.reviewCount,
                  colorScheme: colorScheme,
                  mutedText: mutedText,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(
    int stars,
    int count,
    int total, {
    required ColorScheme colorScheme,
    required Color mutedText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Color(0xFFF5B400)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total > 0 ? count / total : 0,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFF5B400),
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 18,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: mutedText,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    _ReviewData review, {
    required Color cardBg,
    required Color borderColor,
    required Color mutedText,
    required ColorScheme colorScheme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            review.date,
            style: TextStyle(
              fontSize: 10,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                size: 12,
                color: index < review.rating
                    ? const Color(0xFFF5B400)
                    : colorScheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            review.text,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewData {
  final String title;
  final String date;
  final int rating;
  final String text;

  const _ReviewData({
    required this.title,
    required this.date,
    required this.rating,
    required this.text,
  });
}
