import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';
import 'dart:convert';
import '../widgets/rating_stars.dart';
import '../widgets/smart_image.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../models/review_entry.dart';

class _ReviewsPalette {
  final Color bgTop;
  final Color bgBottom;
  final Color ink;
  final Color muted;
  final Color card;
  final Color line;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color accentMist;
  final Color star;
  final Color danger;
  final Color dangerSoft;
  final Color shadow;

  const _ReviewsPalette({
    required this.bgTop,
    required this.bgBottom,
    required this.ink,
    required this.muted,
    required this.card,
    required this.line,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.accentMist,
    required this.star,
    required this.danger,
    required this.dangerSoft,
    required this.shadow,
  });

  static const light = _ReviewsPalette(
    bgTop: Color(0xFFF6F8FF),
    bgBottom: Color(0xFFEFF3FF),
    ink: Color(0xFF1B1E2B),
    muted: Color(0xFF6D748A),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE3E8F3),
    accent: Color(0xFF6288D5),
    accentDark: Color(0xFF4F70C6),
    accentSoft: Color(0xFFDCE6FA),
    accentMist: Color(0xFFF0F4FF),
    star: Color(0xFFF4B740),
    danger: Color(0xFFE4572E),
    dangerSoft: Color(0xFFFDE8E2),
    shadow: Color(0x14000000),
  );

  static const dark = _ReviewsPalette(
    bgTop: Color(0xFF0F141F),
    bgBottom: Color(0xFF141B2B),
    ink: Color(0xFFE9EDFF),
    muted: Color(0xFF9AA3B6),
    card: Color(0xFF1A2336),
    line: Color(0xFF2B364D),
    accent: Color(0xFF6288D5),
    accentDark: Color(0xFF9BB6FF),
    accentSoft: Color(0xFF243251),
    accentMist: Color(0xFF1A243A),
    star: Color(0xFFF4B740),
    danger: Color(0xFFFF6B4A),
    dangerSoft: Color(0xFF3A1E1A),
    shadow: Color(0x66000000),
  );

  static _ReviewsPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

extension _ReviewsPaletteX on BuildContext {
  _ReviewsPalette get reviewsPalette => _ReviewsPalette.of(this);
}

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  static const String _fallbackImage = 'assets/cart_home/CocaCola.png';
  static const List<String> _quickTags = [
    'Быстрая доставка',
    'Хорошая цена',
    'Качественная упаковка',
    'Свежий товар',
    'Вежливый курьер',
  ];

  final TextEditingController _editController = TextEditingController();
  int? _editingIndex;
  int _editingRating = 0;

  bool _isLoading = true;
  bool _isUpdatingReview = false;
  String? _errorMessage;
  List<ReviewEntry> _reviews = [];
  List<PendingReviewItem> _pending = [];
  final Set<String> _submittingPending = <String>{};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews({bool showLoading = true}) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Войдите, чтобы увидеть отзывы.';
        _reviews = [];
        _pending = [];
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final reviews = await ApiService.getUserReviews(userId: userId);
      final pending = await ApiService.getPendingReviews(userId: userId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _pending = pending;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить отзывы.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.reviewsPalette.bgTop,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.reviewsPalette.bgTop,
                    context.reviewsPalette.bgBottom,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: _DecorativeBlob(
              size: 180,
              color: context.reviewsPalette.accentSoft.withValues(alpha: 0.65),
            ),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: _DecorativeBlob(
              size: 140,
              color: context.reviewsPalette.accentMist.withValues(alpha: 0.7),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-6, 0),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: context.reviewsPalette.ink),
              tooltip: 'Назад',
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u0412\u0430\u0448\u0438 \u043e\u0442\u0437\u044b\u0432\u044b',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.reviewsPalette.ink,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _pending.isNotEmpty
                      ? 'Есть покупки для оценки'
                      : 'Все отзывы о покупках',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.reviewsPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.reviewsPalette.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_reviews.length} всего',
              style: TextStyle(
                color: context.reviewsPalette.accentDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.reviewsPalette.accent),
      );
    }

    final List<Widget> children = [];
    if (_errorMessage != null) {
      children.add(_buildErrorBanner(_errorMessage!));
    }
    if (_pending.isNotEmpty) {
      children.add(_buildPendingSection());
      children.add(SizedBox(height: 16));
    }

    children.add(
      _buildSectionTitle(
        title: 'Ваши отзывы',
        subtitle: _reviews.isEmpty
            ? 'Пока нет отзывов'
            : 'Всего: ${_reviews.length}',
      ),
    );
    children.add(SizedBox(height: 12));

    if (_reviews.isEmpty) {
      children.add(_buildEmptyState());
    } else {
      for (int i = 0; i < _reviews.length; i++) {
        children.add(
          _buildReviewCard(
            context: context,
            review: _reviews[i],
            isEditing: _editingIndex == i,
            onEdit: () => _startEdit(i),
            onCancel: _cancelEdit,
            onSave: () => _saveEdit(i),
            onDelete: () => _confirmDelete(i),
          ),
        );
        if (i < _reviews.length - 1) {
          children.add(SizedBox(height: 14));
        }
      }
    }

    return RefreshIndicator(
      color: context.reviewsPalette.accent,
      onRefresh: () => _loadReviews(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle({required String title, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.reviewsPalette.ink,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: context.reviewsPalette.muted),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.reviewsPalette.dangerSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.reviewsPalette.danger.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: context.reviewsPalette.danger,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: context.reviewsPalette.danger,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Ожидают отзывов',
          subtitle: 'Оцените покупки -это помогает другим',
        ),
        SizedBox(height: 12),
        ..._pending.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPendingCard(item),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingCard(PendingReviewItem item) {
    final isSubmitting = _submittingPending.contains(item.orderItemId);
    final orderDate = _formatShortDate(item.orderDate);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.reviewsPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.reviewsPalette.line),
        boxShadow: [
          BoxShadow(
            color: context.reviewsPalette.shadow,
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
              _buildProductImage(item.productImage),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.reviewsPalette.ink,
                        height: 1.22,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 13,
                          color: context.reviewsPalette.muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Заказ ${item.orderId} · $orderDate',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.reviewsPalette.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: context.reviewsPalette.line),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip('${item.quantity} шт'),
              if (item.supplierName.trim().isNotEmpty)
                _buildInfoChip(item.supplierName.trim()),
            ],
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: isSubmitting ? 0.6 : 1,
            child: _ActionButton(
              label: isSubmitting ? 'Отправляем...' : 'Оставить отзыв',
              background: context.reviewsPalette.accent,
              foreground: Colors.white,
              borderColor: context.reviewsPalette.accent,
              icon: Icons.rate_review_outlined,
              expand: true,
              onTap: isSubmitting ? () {} : () => _openReviewSheet(item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.reviewsPalette.accentMist,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.reviewsPalette.line),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: context.reviewsPalette.accentDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.reviewsPalette.accentMist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.reviewsPalette.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildProductImageContent(imageUrl),
      ),
    );
  }

  Widget _buildProductImageContent(String imageUrl) {
    final resolved = _resolveImage(imageUrl);
    return SmartImage(
      path: resolved,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      placeholder: Image.asset(
        _fallbackImage,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: context.reviewsPalette.accentMist,
            alignment: Alignment.center,
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 24,
              color: context.reviewsPalette.muted,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.reviewsPalette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.reviewsPalette.shadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 40,
            color: context.reviewsPalette.accent,
          ),
          SizedBox(height: 12),
          Text(
            'Пока нет отзывов',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.reviewsPalette.ink,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Оставьте отзыв после принятия заказа - он появится здесь.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.reviewsPalette.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required BuildContext context,
    required ReviewEntry review,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required VoidCallback onSave,
    required VoidCallback onDelete,
  }) {
    final dateLabel = _formatShortDate(review.createdAt);
    final ratingValue = isEditing ? _editingRating : review.rating;
    final reviewText = review.reviewText.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: context.reviewsPalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.reviewsPalette.line),
        boxShadow: [
          BoxShadow(
            color: context.reviewsPalette.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProductImage(review.productImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.reviewsPalette.ink,
                        height: 1.18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildMetaPill(
                          icon: Icons.event_outlined,
                          label: dateLabel,
                        ),
                        _buildMetaPill(
                          icon: Icons.rate_review_outlined,
                          label: 'Ваш отзыв',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: context.reviewsPalette.line),
          const SizedBox(height: 10),
          _buildStarRow(
            rating: ratingValue,
            size: isEditing ? 22 : 18,
            onSelect: isEditing
                ? (value) {
                    setState(() {
                      _editingRating = value;
                    });
                  }
                : null,
          ),
          const SizedBox(height: 12),
          if (isEditing)
            TextField(
              controller: _editController,
              keyboardType: TextInputType.text,
              maxLines: 4,
              style: TextStyle(
                fontSize: 13,
                color: context.reviewsPalette.ink,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'Текст отзыва',
                hintStyle: TextStyle(color: context.reviewsPalette.muted),
                filled: true,
                fillColor: context.reviewsPalette.accentMist,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.reviewsPalette.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.reviewsPalette.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: context.reviewsPalette.accent,
                    width: 1.4,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.reviewsPalette.accentMist,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.reviewsPalette.line),
              ),
              child: Text(
                reviewText.isEmpty ? 'Без текста отзыва' : reviewText,
                style: TextStyle(
                  fontSize: 13,
                  color: context.reviewsPalette.ink,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: isEditing ? 'Отмена' : 'Редактировать',
                  background: context.reviewsPalette.accentMist,
                  foreground: context.reviewsPalette.accentDark,
                  borderColor: isEditing
                      ? context.reviewsPalette.line
                      : context.reviewsPalette.accentSoft,
                  icon: isEditing ? Icons.close_rounded : Icons.edit_outlined,
                  onTap: isEditing ? onCancel : onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: isEditing
                      ? (_isUpdatingReview ? 'Сохраняем...' : 'Сохранить')
                      : 'Удалить',
                  background: isEditing
                      ? context.reviewsPalette.accent
                      : context.reviewsPalette.dangerSoft,
                  foreground: isEditing
                      ? Colors.white
                      : context.reviewsPalette.danger,
                  borderColor: isEditing
                      ? context.reviewsPalette.accent
                      : context.reviewsPalette.danger.withValues(alpha: 0.3),
                  icon: isEditing ? Icons.check_rounded : Icons.delete_outline,
                  onTap: isEditing && _isUpdatingReview ? () {} : (isEditing ? onSave : onDelete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.reviewsPalette.accentMist,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.reviewsPalette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.reviewsPalette.muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.reviewsPalette.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow({
    required int rating,
    ValueChanged<int>? onSelect,
    double size = 18,
  }) {
    if (onSelect == null) {
      return RatingStars(
        rating: rating.toDouble(),
        size: size,
        spacing: 2,
        filledColor: context.reviewsPalette.star,
        emptyColor: context.reviewsPalette.line,
      );
    }

    return Row(
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        final icon = isFilled ? Icons.star_rounded : Icons.star_outline_rounded;
        final color = isFilled
            ? context.reviewsPalette.star
            : context.reviewsPalette.line;
        final star = Icon(icon, color: color, size: size);
        return GestureDetector(onTap: () => onSelect(index + 1), child: star);
      }),
    );
  }

  void _startEdit(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingIndex = index;
      _editingRating = _reviews[index].rating;
      _editController.text = _reviews[index].reviewText;
    });
  }

  void _cancelEdit() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingIndex = null;
      _editingRating = 0;
      _editController.clear();
    });
  }

  Future<void> _saveEdit(int index) async {
    if (_isUpdatingReview) return;
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      _showSnack('Войдите, чтобы редактировать отзыв');
      return;
    }
    final text = _editController.text.trim();
    if (_editingRating < 1) {
      _showSnack('Поставьте оценку');
      return;
    }

    setState(() {
      _isUpdatingReview = true;
    });

    try {
      final updated = await ApiService.updateReview(
        reviewId: _reviews[index].id,
        userId: userId,
        rating: _editingRating,
        reviewText: text,
      );
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _reviews[index] = updated;
        _editingIndex = null;
        _editingRating = 0;
        _editController.clear();
        _isUpdatingReview = false;
      });
      _showSnack('Отзыв обновлен');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUpdatingReview = false;
      });
      _showSnack('Не удалось сохранить отзыв');
    }
  }

  Future<void> _openReviewSheet(PendingReviewItem item) async {
    final draft = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final controller = TextEditingController();
        int rating = 5;
        final selectedTags = <String>{};
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: context.reviewsPalette.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.reviewsPalette.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        _buildProductImage(item.productImage),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.reviewsPalette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Оцените товар',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.reviewsPalette.ink,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildStarRow(
                      rating: rating,
                      size: 24,
                      onSelect: (value) {
                        setModalState(() {
                          rating = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Добавьте детали',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.reviewsPalette.ink,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickTags.map((tag) {
                        final selected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: selected,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? context.reviewsPalette.accentDark
                                : context.reviewsPalette.muted,
                            fontWeight: FontWeight.w600,
                          ),
                          selectedColor: context.reviewsPalette.accentSoft,
                          backgroundColor: context.reviewsPalette.accentMist,
                          onSelected: (value) {
                            setModalState(() {
                              if (value) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                              final joined = selectedTags.join(', ');
                              controller.text = joined;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.text,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.reviewsPalette.ink,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Поделитесь впечатлениями',
                        hintStyle: TextStyle(
                          color: context.reviewsPalette.muted,
                        ),
                        filled: true,
                        fillColor: context.reviewsPalette.accentMist,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.reviewsPalette.line,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.reviewsPalette.line,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.reviewsPalette.accent,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _ReviewDraft(
                              rating: rating,
                              text: controller.text.trim(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.reviewsPalette.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Отправить отзыв',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (draft == null) {
      return;
    }

    await _submitReview(item, draft);
  }

  Future<void> _submitReview(PendingReviewItem item, _ReviewDraft draft) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      _showSnack('Войдите, чтобы оставить отзыв');
      return;
    }

    if (_submittingPending.contains(item.orderItemId)) {
      return;
    }

    setState(() {
      _submittingPending.add(item.orderItemId);
    });

    try {
      final created = await ApiService.createReview(
        userId: userId,
        orderId: item.orderId,
        orderItemId: item.orderItemId,
        productId: item.productId,
        rating: draft.rating,
        reviewText: draft.text,
      );

      if (!mounted) return;
      setState(() {
        _pending.removeWhere(
          (pending) => pending.orderItemId == item.orderItemId,
        );
        _reviews.insert(0, created);
        _submittingPending.remove(item.orderItemId);
      });
      _showSnack('Спасибо за отзыв!');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submittingPending.remove(item.orderItemId);
      });
      _showSnack('Не удалось отправить отзыв');
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(int index) async {
    final approved = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Закрыть',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: _DeleteReviewDialog(
              onCancel: () => Navigator.pop(context, false),
              onConfirm: () => Navigator.pop(context, true),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (!mounted || approved != true) {
      return;
    }

    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      _showSnack('Войдите, чтобы удалить отзыв');
      return;
    }

    try {
      await ApiService.deleteReview(
        reviewId: _reviews[index].id,
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _reviews.removeAt(index);
        if (_editingIndex == index) {
          _editingIndex = null;
          _editingRating = 0;
          _editController.clear();
        } else if (_editingIndex != null && _editingIndex! > index) {
          _editingIndex = _editingIndex! - 1;
        }
      });
      _showSnack('Отзыв удален');
    } catch (_) {
      _showSnack('Не удалось удалить отзыв');
    }
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  List<String> _extractImageCandidates(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }

    final encodedCandidates = _splitEncodedImageCandidates(trimmed);
    if (encodedCandidates.isNotEmpty) {
      return encodedCandidates;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      if (decoded is String) {
        return _extractImageCandidates(decoded);
      }
    } catch (_) {}

    return trimmed
        .split(RegExp(r'[;,|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  List<String> _splitEncodedImageCandidates(String raw) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    if (lower.startsWith('base64:')) {
      final parts = trimmed
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) {
        return const <String>[];
      }
      final encoded = parts.where(_isEncodedImage).toList();
      if (encoded.isNotEmpty) {
        return encoded;
      }
      return <String>[trimmed];
    }

    if (lower.startsWith('data:image')) {
      final dataUrlPattern = RegExp(
        r'data:image\/[a-z0-9.+-]+;base64,[a-z0-9+/=_-]+',
        caseSensitive: false,
      );
      final matches = dataUrlPattern
          .allMatches(trimmed)
          .map((match) => match.group(0)?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();
      if (matches.isNotEmpty) {
        return matches;
      }
      return <String>[trimmed];
    }

    return const <String>[];
  }

  String _normalizeImagePath(String raw) {
    var value = raw.trim();
    if (value.isEmpty) {
      return '';
    }

    value = value.replaceAll(r'\/', '/');
    value = value.replaceAll(RegExp(r'''^[\[\]\{\}'"]+|[\[\]\{\}'"]+$'''), '');
    if (value.isEmpty) {
      return '';
    }
    if (_isEncodedImage(value)) {
      return value;
    }
    if (_isNetworkUrl(value)) {
      return value;
    }
    if (value.startsWith('/assets/')) {
      return value.substring(1);
    }
    if (value.startsWith('/')) {
      return '${ApiService.baseUrl}$value';
    }
    if (value.startsWith('uploads/')) {
      return '${ApiService.baseUrl}/$value';
    }
    if (value.startsWith('assets/')) {
      return value;
    }
    return 'assets/$value';
  }

  String _resolveImage(String raw) {
    final candidates = _extractImageCandidates(raw);
    for (final candidate in candidates) {
      final normalized = _normalizeImagePath(candidate);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return _fallbackImage;
  }

  bool _isEncodedImage(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('base64:') ||
        normalized.startsWith('data:image');
  }

  bool _isNetworkUrl(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.onTap,
    this.icon,
    this.expand = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final VoidCallback onTap;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: foreground),
              SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteReviewDialog extends StatelessWidget {
  const _DeleteReviewDialog({required this.onCancel, required this.onConfirm});

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.reviewsPalette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.reviewsPalette.line),
            boxShadow: [
              BoxShadow(
                color: context.reviewsPalette.shadow,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Удалить отзыв?',
                style: TextStyle(
                  color: context.reviewsPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Это действие нельзя отменить.',
                style: TextStyle(
                  color: context.reviewsPalette.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DialogActionButton(
                      label: 'Отмена',
                      background: context.reviewsPalette.accentMist,
                      foreground: context.reviewsPalette.accentDark,
                      borderColor: context.reviewsPalette.line,
                      onTap: onCancel,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _DialogActionButton(
                      label: 'Удалить',
                      background: context.reviewsPalette.danger,
                      foreground: Colors.white,
                      borderColor: context.reviewsPalette.danger,
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ReviewDraft {
  final int rating;
  final String text;

  const _ReviewDraft({required this.rating, required this.text});
}

