import 'package:flutter/material.dart';
import '../models/product.dart';

class RatingsBreakdown extends StatefulWidget {
  final double rating;
  final int reviewCount;
  final List<RatingDistribution> distribution;
  final VoidCallback? onReadAll;

  const RatingsBreakdown({
    super.key,
    required this.rating,
    required this.reviewCount,
    required this.distribution,
    this.onReadAll,
  });

  @override
  State<RatingsBreakdown> createState() => _RatingsBreakdownState();
}

class _RatingsBreakdownState extends State<RatingsBreakdown> {
  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _surfaceVariant => _colorScheme.surfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;
  int _pageIndex = 0;

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
    return Container(
      color: _cardBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Оценок (${widget.reviewCount})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: widget.onReadAll,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  'Читать все >',
                  style: TextStyle(
                    color: Color(0xFF6288D5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '/5',
                    style: TextStyle(
                      fontSize: 14,
                      color: _mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Оценок: ${widget.reviewCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _mutedText,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final stars = 5 - index;
                    final ratingData = widget.distribution.firstWhere(
                      (r) => r.stars == stars,
                      orElse: () => RatingDistribution(stars: stars, count: 0),
                    );
                    return _buildRatingBar(
                      stars,
                      ratingData.count,
                      widget.reviewCount,
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: PageView.builder(
              itemCount: _reviews.length,
              padEnds: false,
              onPageChanged: (index) {
                setState(() {
                  _pageIndex = index;
                });
              },
              controller: PageController(viewportFraction: 0.88),
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildReviewCard(
                    title: review.title,
                    date: review.date,
                    rating: review.rating,
                    text: review.text,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_reviews.length, (index) {
                final active = index == _pageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF6288D5)
                        : _borderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star, size: 12, color: Color(0xFFF5B400)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total > 0 ? count / total : 0,
                backgroundColor: _surfaceVariant,
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
                color: _mutedText,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required String date,
    required int rating,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 10,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                size: 12,
                color: index < rating
                    ? const Color(0xFFF5B400)
                    : _borderColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: _mutedText,
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
