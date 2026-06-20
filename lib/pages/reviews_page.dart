import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../models/review_entry.dart';
import '../services/api/api_service.dart';
import '../theme/app_color_palette.dart';
import '../widgets/product/rating_stars.dart';
import '../widgets/expandable_text_block.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../widgets/profile/user_avatar.dart';
import '../utils/date_formatter.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';

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
        _error = context.l10n.getString('auto_neUdalosZagruzitOtzyvy_1');
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
    return DateFormatter.formatDate(value);
  }

  String _reviewerName(ReviewEntry review) {
    final normalized = review.reviewerName.trim();
    if (normalized.isEmpty) {
      return context.l10n.getString('auto_pokupatel');
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
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

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: palette.accent,
                          ),
                        )
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: null),
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    final palette = context.colorPalette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: palette.line),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: palette.ink),
              tooltip: context.l10n.getString('auto_nazad'),
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
                    context.l10n.getString('auto_otzyvy'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.reviewsCountPrefix(_effectiveReviewCount),
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final palette = context.colorPalette;

    // Фиксированные слоты перед карточками отзывов:
    // 0 - сводная карточка рейтинга
    // 1 - баннер ошибки (только если есть ошибка) или отступ
    // 2 - отступ перед списком (только когда нет ошибки)
    // Далее - сами отзывы (или заглушка «нет отзывов»)
    final bool hasError = _error != null;
    // Количество слотов до отзывов: сводка + (ошибка ? 2 : 1) отступ
    const int headerSlots = 1; // сводная карточка
    final int errorSlots = hasError ? 2 : 0; // отступ + баннер ошибки
    const int spacerSlots = 1; // отступ перед списком отзывов
    final int reviewSlots = _reviews.isEmpty ? 1 : _reviews.length;

    final int totalItems = headerSlots + errorSlots + spacerSlots + reviewSlots;

    return RefreshIndicator(
      color: palette.accent,
      onRefresh: _loadReviews,
      // ListView.builder строит только видимые элементы - ленивая загрузка
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          // Слот 0: сводная карточка рейтинга
          if (index == 0) {
            return _buildSummaryCard();
          }

          int cursor = headerSlots;

          // Слоты ошибки (если есть)
          if (hasError) {
            if (index == cursor) {
              return const SizedBox(height: 12);
            }
            cursor++;
            if (index == cursor) {
              return _buildErrorBanner(_error!);
            }
            cursor++;
          }

          // Отступ перед списком отзывов
          if (index == cursor) {
            return const SizedBox(height: 12);
          }
          cursor++;

          // Слоты отзывов
          final reviewIndex = index - cursor;
          if (_reviews.isEmpty) {
            return _buildEmptyState();
          }
          return KeyedSubtree(
            // Стабильный ключ предотвращает лишние перестройки при обновлении
            key: ValueKey(_reviews[reviewIndex].id),
            child: _buildReviewCard(_reviews[reviewIndex]),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final palette = context.colorPalette;
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
                Text(
                  '/5',
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.reviewsCountPrefix(_effectiveReviewCount),
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
    final palette = context.colorPalette;
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
          Icon(Icons.star_rounded, size: 13, color: palette.star),
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
                      gradient: LinearGradient(
                        colors: [palette.star, palette.star],
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
    final palette = context.colorPalette;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.error.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: palette.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: palette.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final palette = context.colorPalette;

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
            context.l10n.getString('auto_pokaNetOtzyvov'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.getString('auto_zdesPoyavyatsyaOtsenki'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.muted, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewEntry review) {
    final palette = context.colorPalette;
    final name = _reviewerName(review);
    final text = review.reviewText.trim().isEmpty
        ? context.l10n.getString('auto_bezTeksta')
        : review.reviewText.trim();
    final dateStr = _formatDate(review.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхняя строка: аватар + имя/дата + звёзды
          Row(
            children: [
              UserAvatar(
                avatarUrl: review.userAvatarUrl,
                displayName: name,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ),
              ),
              RatingStars(
                rating: review.rating.toDouble(),
                size: 16,
                spacing: 2,
                filledColor: palette.star,
                emptyColor: palette.line,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpandableTextBlock(
            text,
            textStyle: TextStyle(fontSize: 14, color: palette.ink, height: 1.4),
            actionColor: palette.accent,
            collapsedMaxLines: 3,
            moreLabel: context.l10n.getString('auto_podrobnee'),
            lessLabel: context.l10n.getString('auto_svernut'),
          ),
          // Ответ поставщика (если есть)
          if (review.response != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.accentMist,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.line.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        size: 16,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.getString('auto_otvetProdavtsa'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          review.response!.supplierName,
                          style: TextStyle(fontSize: 11, color: palette.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpandableTextBlock(
                    review.response!.responseText,
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: palette.ink,
                      height: 1.4,
                    ),
                    actionColor: palette.accent,
                    collapsedMaxLines: 3,
                    moreLabel: context.l10n.getString('auto_podrobnee'),
                    lessLabel: context.l10n.getString('auto_svernut'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(review.response!.respondedAt),
                    style: TextStyle(fontSize: 11, color: palette.muted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
