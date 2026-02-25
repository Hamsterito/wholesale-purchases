import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/review_entry.dart';
import '../services/api_service.dart';
import '../widgets/rating_stars.dart';

class _ProductReviewsPalette {
  const _ProductReviewsPalette({
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.line,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.accentMist,
    required this.danger,
    required this.shadow,
  });

  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color line;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color accentMist;
  final Color danger;
  final Color shadow;

  static const light = _ProductReviewsPalette(
    bgTop: Color(0xFFF6F8FF),
    bgBottom: Color(0xFFEFF3FF),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE3E8F3),
    ink: Color(0xFF1B1E2B),
    muted: Color(0xFF6D748A),
    accent: Color(0xFF6288D5),
    accentDark: Color(0xFF4F70C6),
    accentSoft: Color(0xFFDCE6FA),
    accentMist: Color(0xFFF0F4FF),
    danger: Color(0xFFE4572E),
    shadow: Color(0x14000000),
  );

  static const dark = _ProductReviewsPalette(
    bgTop: Color(0xFF0F141F),
    bgBottom: Color(0xFF141B2B),
    card: Color(0xFF1A2336),
    line: Color(0xFF2B364D),
    ink: Color(0xFFE9EDFF),
    muted: Color(0xFF9AA3B6),
    accent: Color(0xFF6288D5),
    accentDark: Color(0xFF9BB6FF),
    accentSoft: Color(0xFF243251),
    accentMist: Color(0xFF1A243A),
    danger: Color(0xFFFF6B4A),
    shadow: Color(0x66000000),
  );

  static _ProductReviewsPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

extension _ProductReviewsPaletteX on BuildContext {
  _ProductReviewsPalette get productReviewsPalette =>
      _ProductReviewsPalette.of(this);
}

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({
    super.key,
    required this.product,
    this.initialReviews = const <ReviewEntry>[],
  });

  final Product product;
  final List<ReviewEntry> initialReviews;

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  static const Color _star = Color(0xFFF5B400);

  late List<ReviewEntry> _reviews;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reviews = List<ReviewEntry>.from(widget.initialReviews);
    _isLoading = _reviews.isEmpty;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final reviews = await ApiService.getProductReviews(
        productId: widget.product.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _reviews = reviews;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Не удалось загрузить отзывы';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int get _effectiveReviewCount {
    if (_reviews.isNotEmpty) {
      return _reviews.length;
    }
    return widget.product.reviewCount;
  }

  double get _averageRating {
    if (_reviews.isEmpty) {
      return widget.product.rating;
    }
    final sum = _reviews.fold<int>(0, (total, item) => total + item.rating);
    return sum / _reviews.length;
  }

  int _ratingCount(int stars) {
    return _reviews.where((item) => item.rating == stars).length;
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day.$month.$year';
  }

  String _reviewerName(ReviewEntry review) {
    final normalized = review.reviewerName.trim();
    if (normalized.isEmpty) {
      return 'Покупатель';
    }
    return normalized;
  }

  String _initial(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'П';
    }
    return normalized.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.productReviewsPalette;

    return Scaffold(
      backgroundColor: palette.bgTop,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.bgTop, palette.bgBottom],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: _DecorativeBlob(
              size: 180,
              color: palette.accentSoft.withValues(alpha: 0.68),
            ),
          ),
          Positioned(
            top: 120,
            left: -55,
            child: _DecorativeBlob(
              size: 135,
              color: palette.accentMist.withValues(alpha: 0.7),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: palette.accent),
                        )
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final palette = context.productReviewsPalette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: palette.ink),
            tooltip: 'Назад',
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Отзывы',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Оценок: $_effectiveReviewCount',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.accentDark,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.star_rounded, size: 14, color: _star),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final palette = context.productReviewsPalette;

    return RefreshIndicator(
      color: palette.accent,
      onRefresh: _loadReviews,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _buildSummaryCard(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(_error!),
          ],
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            _buildEmptyState()
          else
            ..._reviews.map(_buildReviewCard),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final palette = context.productReviewsPalette;
    final total = _reviews.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 104,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: palette.accentMist,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 34,
                    height: 0.95,
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text('/5', style: TextStyle(fontSize: 13, color: palette.muted)),
                const SizedBox(height: 8),
                Text(
                  'Оценок: $_effectiveReviewCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.muted,
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
                final count = _ratingCount(stars);
                return _buildRatingBar(stars, count, total: total);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, {required int total}) {
    final palette = context.productReviewsPalette;
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0).toDouble() : 0.0;

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
                color: palette.ink,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, size: 13, color: _star),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: palette.accentMist,
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
              style: TextStyle(fontSize: 12, color: palette.muted),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String text) {
    final palette = context.productReviewsPalette;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.danger.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: palette.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: palette.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final palette = context.productReviewsPalette;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 28, color: palette.muted),
          const SizedBox(height: 10),
          Text(
            'Пока нет отзывов',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Здесь появятся оценки и мнения покупателей.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.muted, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewEntry review) {
    final palette = context.productReviewsPalette;
    final name = _reviewerName(review);
    final text = review.reviewText.trim().isEmpty
        ? 'Без текста отзыва'
        : review.reviewText.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.line),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initial(name),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.accentDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.accentMist,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.line),
                ),
                child: Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RatingStars(
            rating: review.rating.toDouble(),
            size: 14,
            spacing: 1.5,
            filledColor: _star,
            emptyColor: palette.line,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: palette.ink,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeBlob extends StatelessWidget {
  const _DecorativeBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
