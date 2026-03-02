import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/review_entry.dart';
import 'rating_stars.dart';

class RatingsBreakdown extends StatefulWidget {
  const RatingsBreakdown({
    super.key,
    required this.rating,
    required this.reviewCount,
    required this.distribution,
    required this.reviews,
    this.isLoading = false,
    this.onReadAll,
  });

  final double rating;
  final int reviewCount;
  final List<RatingDistribution> distribution;
  final List<ReviewEntry> reviews;
  final bool isLoading;
  final VoidCallback? onReadAll;

  @override
  State<RatingsBreakdown> createState() => _RatingsBreakdownState();
}

class _RatingsBreakdownState extends State<RatingsBreakdown> {
  static const Color _brand = Color(0xFF6288D5);
  static const Color _star = Color(0xFFF5B400);

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;

  Color get _cardBg => _colorScheme.surface;
  Color get _ink => _colorScheme.onSurface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _trackBg =>
      _colorScheme.surfaceContainerHighest.withValues(alpha: _isDark ? 0.78 : 0.9);
  Color get _softBorder => Color.alphaBlend(
    _brand.withValues(alpha: _isDark ? 0.24 : 0.12),
    _colorScheme.outlineVariant,
  );
  Color get _softPanel => Color.alphaBlend(
    _brand.withValues(alpha: _isDark ? 0.18 : 0.08),
    _cardBg,
  );

  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void didUpdateWidget(covariant RatingsBreakdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxIndex = _previewReviews.length - 1;
    if (maxIndex < 0) {
      if (_pageIndex != 0) {
        setState(() {
          _pageIndex = 0;
        });
      }
      return;
    }

    if (_pageIndex > maxIndex) {
      final target = maxIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _pageIndex = target;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(target);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<ReviewEntry> get _previewReviews {
    if (widget.reviews.length <= 6) {
      return widget.reviews;
    }
    return widget.reviews.take(6).toList(growable: false);
  }

  int get _effectiveReviewCount {
    if (widget.reviewCount > 0) {
      return widget.reviewCount;
    }
    return widget.reviews.length;
  }

  int _reviewCountByStars(int stars) {
    if (widget.distribution.isNotEmpty) {
      final ratingData = widget.distribution.firstWhere(
        (item) => item.stars == stars,
        orElse: () => RatingDistribution(stars: stars, count: 0),
      );
      return ratingData.count;
    }

    return widget.reviews.where((item) => item.rating == stars).length;
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day.$month.$year';
  }

  double _ratioFor(int count) {
    final total = _effectiveReviewCount;
    if (total <= 0) {
      return 0;
    }

    final ratio = count / total;
    if (ratio <= 0) {
      return 0;
    }
    if (ratio >= 1) {
      return 1;
    }
    return ratio;
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _previewReviews;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      color: _cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildSummary(),
          const SizedBox(height: 14),
          if (widget.isLoading)
            const SizedBox(
              height: 126,
              child: Center(
                child: CircularProgressIndicator(
                  color: _brand,
                  strokeWidth: 2.6,
                ),
              ),
            )
          else if (reviews.isEmpty)
            _buildEmptyState()
          else ...[
            SizedBox(
              height: 146,
              child: PageView.builder(
                controller: _pageController,
                itemCount: reviews.length,
                padEnds: false,
                onPageChanged: (index) {
                  if (_pageIndex == index) {
                    return;
                  }
                  setState(() {
                    _pageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildReviewCard(reviews[index]);
                },
              ),
            ),
            if (reviews.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(reviews.length, (index) {
                  final active = index == _pageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? _brand : _softBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Оценок ($_effectiveReviewCount)',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
        if (widget.onReadAll != null)
          TextButton(
            onPressed: widget.onReadAll,
            style: TextButton.styleFrom(
              foregroundColor: _brand,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Читать все',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummary() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 102,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: _softPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _softBorder.withValues(alpha: 0.85)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 34,
                  height: 0.95,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text('/5', style: TextStyle(fontSize: 13, color: _mutedText)),
              const SizedBox(height: 8),
              Text(
                'Оценок: $_effectiveReviewCount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final stars = 5 - index;
              final count = _reviewCountByStars(stars);
              return _buildRatingBar(stars, count);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    final ratio = _ratioFor(count);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$stars',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, size: 13, color: _star),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: _trackBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [_star, Color(0xFFF2A900)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, color: _mutedText),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _softBorder.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Icon(Icons.rate_review_outlined, color: _mutedText, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Пока нет отзывов. Станьте первым, кто оценит товар.',
              style: TextStyle(
                fontSize: 12,
                color: _mutedText,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewEntry review) {
    final title = review.reviewerName.trim().isEmpty
        ? 'Покупатель'
        : review.reviewerName.trim();
    final text = review.reviewText.trim().isEmpty
        ? 'Без текста отзыва'
        : review.reviewText.trim();

    return Padding(
      padding: const EdgeInsets.only(top: 1, right: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: _softPanel.withValues(alpha: _isDark ? 0.96 : 1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _softBorder.withValues(alpha: 0.9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _trackBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatDate(review.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _mutedText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            RatingStars(
              rating: review.rating.toDouble(),
              size: 13,
              spacing: 1.5,
              filledColor: _star,
              emptyColor: _softBorder,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: _mutedText,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
