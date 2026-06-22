import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_color_palette.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../widgets/smooth_sheet.dart';
import 'dart:convert';
import '../widgets/expandable_text_block.dart';
import '../widgets/product/rating_stars.dart';
import '../widgets/smart_image.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import '../models/message.dart';
import '../models/review_entry.dart';
import '../utils/date_formatter.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import 'dart:math' as math;
import '../core/ui/theme/app_dimensions.dart';
import '../services/notification_service.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  static const String _fallbackImage = 'assets/cart_home/CocaCola.png';
  List<String> get _quickTags => [
    context.l10n.getString('auto_bystrayaDostavka'),
    context.l10n.getString('auto_horoshayaTsena'),
    context.l10n.getString('auto_kachestvennayaUpakovka'),
    context.l10n.getString('auto_svezhiyTovar'),
    context.l10n.getString('auto_vezhlivyyKurer'),
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
    NotificationService().markAllReviewsAsViewed();
    _loadReviews();
  }

  Future<void> _loadReviews({bool showLoading = true}) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.getString('auto_voyditeChtobyUvidetOtz');
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
        _errorMessage = context.l10n.getString('auto_neUdalosZagruzitOtzyvy');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = isDark
        ? theme.scaffoldBackgroundColor
        : context.colorPalette.bgTop;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: pageBackground,
      body: Stack(
        children: [
          if (isDark)
            Positioned.fill(child: ColoredBox(color: pageBackground))
          else
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.colorPalette.bgTop,
                      context.colorPalette.bgBottom,
                    ],
                  ),
                ),
              ),
            ),

          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: RoleInternalNavBar(currentIndex: 3),
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, MediaQuery.paddingOf(context).top + 12, 16, 12),
      decoration: BoxDecoration(
        color: context.colorPalette.card,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: context.colorPalette.line),
        boxShadow: [
          BoxShadow(
            color: context.colorPalette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-6, 0),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: context.colorPalette.ink),
              tooltip: context.l10n.getString('auto_nazad'),
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
                  context.l10n.getString('auto_vashiOtzyvy'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.colorPalette.ink,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _pending.isNotEmpty
                      ? context.l10n.getString('auto_estPokupkiDlyaOtsenki')
                      : context.l10n.getString('auto_vseOtzyvyOPokupkah'),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.colorPalette.accentSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                context.l10n.reviewsTotalCountWith(_reviews.length),
                style: TextStyle(
                  color: context.colorPalette.accentDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
        child: CircularProgressIndicator(color: context.colorPalette.accent),
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
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: context.colorPalette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colorPalette.line),
          boxShadow: [
            BoxShadow(
              color: context.colorPalette.shadow,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _buildSectionTitle(
          title: context.l10n.getString('auto_vashiOtzyvy'),
          subtitle: _reviews.isEmpty
              ? context.l10n.getString('auto_pokaNetOtzyvov')
              : context.l10n.reviewsSectionSubtitleTotal(_reviews.length),
        ),
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
      color: context.colorPalette.accent,
      onRefresh: () => _loadReviews(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
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
            color: context.colorPalette.ink,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: context.colorPalette.muted),
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
        color: context.colorPalette.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colorPalette.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: context.colorPalette.error, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: context.colorPalette.error,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: context.colorPalette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colorPalette.line),
            boxShadow: [
              BoxShadow(
                color: context.colorPalette.shadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildSectionTitle(
            title: context.l10n.getString('auto_ozhidayutOtzyvov'),
            subtitle: context.l10n.getString('auto_otsenitePokupkiEtoPomo'),
          ),
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
    final orderDate = DateFormatter.formatDate(item.orderDate);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colorPalette.line),
        boxShadow: [
          BoxShadow(
            color: context.colorPalette.shadow,
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
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: item.localizedProductName(context),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colorPalette.ink,
                              height: 1.22,
                            ),
                          ),
                          if (item.supplierName.trim().isNotEmpty) ...[
                            TextSpan(
                              text: ' - ${item.supplierName.trim()}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: context.colorPalette.muted,
                                height: 1.22,
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildMetaPill(
                          icon: Icons.event_outlined,
                          label: orderDate,
                        ),
                        _buildMetaPill(
                          icon: Icons.receipt_long_outlined,
                          label: context.l10n.reviewsOrderLabelWith(item.orderId),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: isSubmitting ? 0.6 : 1,
            child: _ActionButton(
              label: isSubmitting ? context.l10n.getString('auto_otpravlyaem') : context.l10n.getString('auto_ostavitOtzyv'),
              background: context.colorPalette.accent,
              foreground: Colors.white,
              borderColor: context.colorPalette.accent,
              icon: Icons.rate_review_outlined,
              expand: true,
              onTap: isSubmitting ? () {} : () => _openReviewSheet(item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colorPalette.accentMist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorPalette.line),
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
            color: context.colorPalette.accentMist,
            alignment: Alignment.center,
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 24,
              color: context.colorPalette.muted,
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
        color: context.colorPalette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colorPalette.shadow,
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
            color: context.colorPalette.accent,
          ),
          SizedBox(height: 12),
          Text(
            context.l10n.getString('auto_pokaNetOtzyvov'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colorPalette.ink,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.l10n.getString('auto_ostavteOtzyvPoslePriny'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.colorPalette.muted,
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
    final dateLabel = DateFormatter.formatDate(review.createdAt);
    final ratingValue = isEditing ? _editingRating : review.rating;
    final reviewText = review.reviewText.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: context.colorPalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorPalette.line),
        boxShadow: [
          BoxShadow(
            color: context.colorPalette.shadow,
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
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: review.localizedProductName(context),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.colorPalette.ink,
                              height: 1.18,
                            ),
                          ),
                          if (review.supplierName.trim().isNotEmpty) ...[
                            TextSpan(
                              text: ' - ${review.supplierName.trim()}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: context.colorPalette.muted,
                                height: 1.18,
                              ),
                            ),
                          ],
                        ],
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
                        if (review.orderId.isNotEmpty) ...[
                          _buildMetaPill(
                            icon: Icons.receipt_long_outlined,
                            label: context.l10n.reviewsOrderLabelWith(review.orderId),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: context.colorPalette.line),
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
                color: context.colorPalette.ink,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.getString('auto_tekstOtzyva'),
                hintStyle: TextStyle(color: context.colorPalette.muted),
                filled: true,
                fillColor: context.colorPalette.accentMist,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.colorPalette.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.colorPalette.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: context.colorPalette.accent,
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
                color: context.colorPalette.accentMist,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colorPalette.line),
              ),
              child: ExpandableTextBlock(
                reviewText.isEmpty ? context.l10n.getString('auto_bezTekstaOtzyva') : reviewText,
                key: ValueKey('profile-review-${review.id}'),
                textStyle: TextStyle(
                  fontSize: 15,
                  color: context.colorPalette.ink,
                  height: 1.4,
                ),
                actionColor: context.colorPalette.accentDark,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: isEditing ? context.l10n.getString('auto_otmena') : context.l10n.getString('auto_redaktirovat'),
                  background: context.colorPalette.accentMist,
                  foreground: context.colorPalette.accentDark,
                  borderColor: isEditing
                      ? context.colorPalette.line
                      : context.colorPalette.accentSoft,
                  icon: isEditing ? Icons.close_rounded : Icons.edit_outlined,
                  onTap: isEditing ? onCancel : onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: isEditing
                      ? (_isUpdatingReview ? context.l10n.getString('auto_sohranyaem') : context.l10n.getString('auto_sohranit_1'))
                      : context.l10n.getString('auto_udalit'),
                  background: isEditing
                      ? context.colorPalette.accent
                      : context.colorPalette.error.withValues(alpha: 0.12),
                  foreground: isEditing
                      ? Colors.white
                      : context.colorPalette.error,
                  borderColor: isEditing
                      ? context.colorPalette.accent
                      : context.colorPalette.error.withValues(alpha: 0.3),
                  icon: isEditing ? Icons.check_rounded : Icons.delete_outline,
                  onTap: isEditing && _isUpdatingReview
                      ? () {}
                      : (isEditing ? onSave : onDelete),
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
        color: context.colorPalette.accentMist,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colorPalette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colorPalette.muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.colorPalette.muted,
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
        filledColor: context.colorPalette.star,
        emptyColor: context.colorPalette.line,
      );
    }

    return Row(
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        final icon = isFilled ? Icons.star_rounded : Icons.star_outline_rounded;
        final color = isFilled
            ? context.colorPalette.star
            : context.colorPalette.line;
        final star = Icon(icon, color: color, size: size);
        return GestureDetector(onTap: () => onSelect(index + 1), child: star);
      }),
    );
  }

  void _startEdit(int index) {
    _openEditReviewSheet(index);
  }

  Future<void> _openEditReviewSheet(int index) async {
    final review = _reviews[index];
    final draft = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: smoothBottomSheetController(context),
      backgroundColor: Colors.transparent,
      builder: (context) {
        final controller = TextEditingController(text: review.reviewText);
        int rating = review.rating;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = math.max(MediaQuery.viewInsetsOf(context).bottom, AppDimensions.minBottomSafePadding);
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: context.colorPalette.card,
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
                          color: context.colorPalette.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        _buildProductImage(review.productImage),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: review.localizedProductName(context),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: context.colorPalette.ink,
                                      ),
                                    ),
                                    if (review.supplierName
                                        .trim()
                                        .isNotEmpty) ...[
                                      TextSpan(
                                        text:
                                            ' - ${review.supplierName.trim()}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: context.colorPalette.muted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      context.l10n.getString('auto_otseniteTovar'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.ink,
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
                      context.l10n.getString('auto_vashOtzyv'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.ink,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.text,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colorPalette.ink,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: context.l10n.getString('auto_podelitesVpechatleniyami'),
                        hintStyle: TextStyle(color: context.colorPalette.muted),
                        filled: true,
                        fillColor: context.colorPalette.accentMist,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colorPalette.line,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colorPalette.line,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colorPalette.accent,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    context.colorPalette.accentMist,
                                foregroundColor:
                                    context.colorPalette.accentDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: context.colorPalette.line,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                context.l10n.getString('auto_otmena'),
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
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
                                backgroundColor: context.colorPalette.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                context.l10n.getString('auto_izmenit'),
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
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

    await _submitEditReview(index, draft);
  }

  Future<void> _submitEditReview(int index, _ReviewDraft draft) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      _showSnack(
        context.l10n.getString('auto_voyditeChtobyRedaktirov'),
        severity: MessageSeverity.error,
      );
      return;
    }

    if (_isUpdatingReview) {
      return;
    }

    setState(() {
      _isUpdatingReview = true;
    });

    try {
      final updated = await ApiService.updateReview(
        reviewId: _reviews[index].id,
        userId: userId,
        rating: draft.rating,
        reviewText: draft.text,
      );
      if (!mounted) return;
      setState(() {
        _reviews[index] = updated;
        _isUpdatingReview = false;
      });
      _showSnack(context.l10n.getString('auto_otzyvObnovlen'));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUpdatingReview = false;
      });
      _showSnack(context.l10n.getString('auto_neUdalosSohranitOtzyv'), severity: MessageSeverity.error);
    }
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
      _showSnack(
        context.l10n.getString('auto_voyditeChtobyRedaktirov'),
        severity: MessageSeverity.error,
      );
      return;
    }
    final text = _editController.text.trim();
    if (_editingRating < 1) {
      _showSnack(context.l10n.getString('auto_postavteOtsenku'), severity: MessageSeverity.warning);
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
      _showSnack(context.l10n.getString('auto_otzyvObnovlen'));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUpdatingReview = false;
      });
      _showSnack(context.l10n.getString('auto_neUdalosSohranitOtzyv'), severity: MessageSeverity.error);
    }
  }

  Future<void> _openReviewSheet(PendingReviewItem item) async {
    final draft = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: smoothBottomSheetController(context),
      backgroundColor: Colors.transparent,
      builder: (context) {
        final controller = TextEditingController();
        int rating = 5;
        final selectedTags = <String>{};
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = math.max(MediaQuery.viewInsetsOf(context).bottom, AppDimensions.minBottomSafePadding);
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: context.colorPalette.card,
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
                          color: context.colorPalette.line,
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
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: item.localizedProductName(context),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: context.colorPalette.ink,
                                  ),
                                ),
                                if (item.supplierName.trim().isNotEmpty) ...[
                                  TextSpan(
                                    text: ' - ${item.supplierName.trim()}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: context.colorPalette.muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      context.l10n.getString('auto_otseniteTovar'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.ink,
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
                      context.l10n.getString('auto_dobavteDetali'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.ink,
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
                                ? context.colorPalette.accentDark
                                : context.colorPalette.muted,
                            fontWeight: FontWeight.w600,
                          ),
                          selectedColor: context.colorPalette.accentSoft,
                          backgroundColor: context.colorPalette.accentMist,
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
                        color: context.colorPalette.ink,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: context.l10n.getString('auto_podelitesVpechatleniyami'),
                        hintStyle: TextStyle(color: context.colorPalette.muted),
                        filled: true,
                        fillColor: context.colorPalette.accentMist,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colorPalette.line,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colorPalette.line,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colorPalette.accent,
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
                          backgroundColor: context.colorPalette.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          context.l10n.getString('auto_otpravitOtzyv'),
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
      _showSnack(
        context.l10n.getString('auto_voyditeChtobyOstavitOt'),
        severity: MessageSeverity.error,
      );
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
      _showSnack(context.l10n.getString('auto_spasiboZaOtzyv'));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submittingPending.remove(item.orderItemId);
      });
      _showSnack(context.l10n.getString('auto_neUdalosOtpravitOtzyv'), severity: MessageSeverity.error);
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
      barrierLabel: context.l10n.getString('auto_zakryt'),
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
      _showSnack(
        context.l10n.getString('auto_voyditeChtobyUdalitOtz'),
        severity: MessageSeverity.error,
      );
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
      _showSnack(context.l10n.getString('auto_otzyvUdalen'));
    } catch (_) {
      _showSnack(context.l10n.getString('auto_neUdalosUdalitOtzyv'), severity: MessageSeverity.error);
    }
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

  void _showSnack(
    String message, {
    MessageSeverity severity = MessageSeverity.info,
  }) {
    if (!mounted) {
      return;
    }
    final msg = Message(
      id: const Uuid().v4(),
      type: MessageType.notification,
      severity: severity,
      title: '',
      body: message,
      timestamp: DateTime.now(),
      language: 'ru',
    );
    AppMessageSnackBar.show(context, msg);
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
            color: context.colorPalette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.colorPalette.line),
            boxShadow: [
              BoxShadow(
                color: context.colorPalette.shadow,
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
                context.l10n.getString('auto_udalitOtzyv'),
                style: TextStyle(
                  color: context.colorPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.l10n.getString('auto_etoDeystvieNelzyaOtmen'),
                style: TextStyle(
                  color: context.colorPalette.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DialogActionButton(
                      label: context.l10n.getString('auto_otmena'),
                      background: context.colorPalette.accentMist,
                      foreground: context.colorPalette.accentDark,
                      borderColor: context.colorPalette.line,
                      onTap: onCancel,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _DialogActionButton(
                      label: context.l10n.getString('auto_udalit'),
                      background: context.colorPalette.error,
                      foreground: Colors.white,
                      borderColor: context.colorPalette.error,
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
