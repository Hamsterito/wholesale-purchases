import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../models/review_entry.dart';
import '../services/api_service.dart';
import '../services/cart_store.dart';
import '../services/favorites_store.dart';
import '../widgets/category_tags.dart';
import '../widgets/info_section.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/nutritional_info_card.dart';
import '../widgets/product_image_carousel.dart';
import '../widgets/rating_section.dart';
import '../widgets/ratings_breakdown.dart';
import '../widgets/similar_products_carousel.dart';
import '../widgets/top_message.dart';
import 'reviews_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final List<Product> similarProducts;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.similarProducts = const [],
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  static const double _bottomMessageOffset = 150;
  static const String _shareStubUrl =
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
  final Map<String, int> _supplierQuantities = {};
  final Map<String, bool> _supplierAdded = {};
  List<ReviewEntry> _productReviews = const <ReviewEntry>[];
  bool _isLoadingReviews = false;
  bool _isFavorite = false;
  late final VoidCallback _favoritesListener;
  String? _selectedSupplierId;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg {
    final base = _theme.scaffoldBackgroundColor;
    final overlay = Colors.black.withValues(alpha: _isDark ? 0.06 : 0.04);
    return Color.alphaBlend(overlay, base);
  }

  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;
  Color get _shadowColor => _isDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.08);
  FavoritesStore get _favoritesStore => FavoritesStore.instance;
  int get _resolvedReviewCount => _productReviews.isNotEmpty
      ? _productReviews.length
      : widget.product.reviewCount;

  @override
  void initState() {
    super.initState();
    _isFavorite = _favoritesStore.contains(widget.product.id);
    _favoritesListener = () {
      final isFav = _favoritesStore.contains(widget.product.id);
      if (isFav != _isFavorite && mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    };
    _favoritesStore.addListener(_favoritesListener);
    for (var supplier in widget.product.suppliers) {
      _supplierQuantities[supplier.id] = supplier.minQuantity;
      _supplierAdded[supplier.id] = false;
    }
    if (widget.product.suppliers.isNotEmpty) {
      _selectedSupplierId = widget.product.bestSupplier.id;
    }
    _loadProductReviews();
  }

  @override
  void dispose() {
    _favoritesStore.removeListener(_favoritesListener);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      final isFav = _favoritesStore.contains(widget.product.id);
      if (isFav != _isFavorite) {
        setState(() {
          _isFavorite = isFav;
        });
      }
      _supplierQuantities.clear();
      _supplierAdded.clear();
      for (final supplier in widget.product.suppliers) {
        _supplierQuantities[supplier.id] = supplier.minQuantity;
        _supplierAdded[supplier.id] = false;
      }
      _selectedSupplierId = widget.product.suppliers.isEmpty
          ? null
          : widget.product.bestSupplier.id;
      _loadProductReviews();
    }
  }

  Future<void> _loadProductReviews() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviews = await ApiService.getProductReviews(
        productId: widget.product.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _productReviews = reviews;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _productReviews = const <ReviewEntry>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  void _updateQuantity(String supplierId, int delta) {
    final supplier = widget.product.suppliers.firstWhere(
      (s) => s.id == supplierId,
    );
    if (!supplier.isAvailable) {
      return;
    }
    final currentQty = _supplierQuantities[supplierId] ?? supplier.minQuantity;
    final newQty = currentQty + delta;
    final maxQuantity = supplier.maxQuantity;
    final effectiveMax =
        maxQuantity != null && maxQuantity < supplier.minQuantity
        ? supplier.minQuantity
        : maxQuantity;
    if (newQty < supplier.minQuantity || newQty == currentQty) {
      return;
    }
    if (effectiveMax != null && newQty > effectiveMax) {
      return;
    }
    setState(() {
      _supplierQuantities[supplierId] = newQty;
    });
  }

  void _addToCart(Supplier supplier) {
    if (!supplier.isAvailable) {
      showTopMessage(
        context,
        'Нет в наличии',
        backgroundColor: const Color(0xFFEF4444),
        showAtBottom: true,
        bottomOffset: _bottomMessageOffset,
      );
      return;
    }
    final quantity = _supplierQuantities[supplier.id] ?? supplier.minQuantity;
    setState(() {
      _supplierAdded[supplier.id] = true;
    });
    CartStore.instance.addOrUpdate(
      product: widget.product,
      supplier: supplier,
      quantity: quantity,
    );
    showTopMessage(
      context,
      'Добавлено в корзину: ${widget.product.name}',
      backgroundColor: const Color(0xFF6288D5),
      showAtBottom: true,
      bottomOffset: _bottomMessageOffset,
    );
  }

  void _removeFromCart(Supplier supplier) {
    setState(() {
      _supplierAdded[supplier.id] = false;
    });
    CartStore.instance.removeItem(
      supplierId: supplier.id,
      productId: widget.product.id,
    );
    showTopMessage(
      context,
      'Удалено из корзины: ${widget.product.name}',
      backgroundColor: const Color(0xFFEF4444),
      showAtBottom: true,
      bottomOffset: _bottomMessageOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomScrollPadding = MediaQuery.of(context).padding.bottom + 150;
    final ingredients = widget.product.ingredients.trim();
    final description = widget.product.description.trim();
    final characteristics = _filteredCharacteristics();
    final hasNutritionalInfo = _hasNutritionalInfo();

    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomScrollPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(),
                  _buildTitleBlock(),
                  _buildAvailabilitySection(),
                  if (hasNutritionalInfo)
                    NutritionalInfoCard(
                      nutritionalInfo: widget.product.nutritionalInfo,
                    ),
                  if (ingredients.isNotEmpty)
                    InfoSection(title: 'Состав', content: ingredients),
                  if (description.isNotEmpty)
                    InfoSection(title: 'Описание', content: description),
                  if (characteristics.isNotEmpty)
                    _buildCharacteristicsSection(characteristics),
                  RatingsBreakdown(
                    rating: widget.product.rating,
                    reviewCount: _resolvedReviewCount,
                    distribution: widget.product.ratingDistribution,
                    reviews: _productReviews,
                    isLoading: _isLoadingReviews,
                    onReadAll: _openReviews,
                  ),
                  if (widget.similarProducts.isNotEmpty)
                    SimilarProductsCarousel(
                      products: widget.similarProducts,
                      onProductTap: (product) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              product: product,
                              similarProducts: widget.similarProducts
                                  .where((p) => p.id != product.id)
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      color: _cardBg,
      child: Stack(
        children: [
          ProductImageCarousel(imageUrls: widget.product.imageUrls),
          Positioned(
            top: 0,
            left: 16,
            child: SafeArea(
              bottom: false,
              child: _buildIconPill(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  _buildIconPill(
                    icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                    iconColor: const Color(0xFF6288D5),
                    onTap: () {
                      final added = _favoritesStore.toggle(widget.product);
                      setState(() {
                        _isFavorite = added;
                      });
                      if (added) {
                        showTopMessage(
                          context,
                          '\u0414\u043e\u0431\u0430\u0432\u043b\u0435\u043d\u043e \u0432 \u0438\u0437\u0431\u0440\u0430\u043d\u043d\u043e\u0435',
                          backgroundColor: const Color(0xFF6288D5),
                          showAtBottom: true,
                          bottomOffset: _bottomMessageOffset,
                        );
                      } else {
                        showTopMessage(
                          context,
                          '\u0423\u0434\u0430\u043b\u0435\u043d\u043e \u0438\u0437 \u0438\u0437\u0431\u0440\u0430\u043d\u043d\u043e\u0433\u043e',
                          backgroundColor: const Color(0xFFEF4444),
                          showAtBottom: true,
                          duration: const Duration(seconds: 3),
                          showClose: true,
                          bottomOffset: _bottomMessageOffset,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconPill(
                    icon: Icons.share_outlined,
                    onTap: _shareProductStub,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPill({
    required IconData icon,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final resolvedColor = iconColor ?? _colorScheme.onSurface;

    return Material(
      color: _cardBg,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: resolvedColor, size: 29),
        ),
      ),
    );
  }

  Widget _buildProductTitle() {
    return Text(
      widget.product.name,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.1,
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Container(
      color: _cardBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingSection(
            rating: widget.product.rating,
            reviewCount: _resolvedReviewCount,
            onTap: _openReviews,
          ),
          const SizedBox(height: 4),
          _buildProductTitle(),
          const SizedBox(height: 6),
          CategoryTags(categories: widget.product.categories),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    if (widget.product.suppliers.isEmpty) {
      return Container(
        color: _cardBg,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Нет в наличии',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final supplier = widget.product.suppliers.firstWhere(
      (s) => s.id == _selectedSupplierId,
      orElse: () => widget.product.bestSupplier,
    );
    final isAvailable = supplier.isAvailable;
    return Container(
      color: _cardBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${supplier.pricePerUnit} ₸/шт',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  (isAvailable
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isAvailable
                  ? 'В наличии: ${supplier.stockQuantity} шт.'
                  : 'Нет в наличии',
              style: TextStyle(
                color: isAvailable
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _filteredCharacteristics() {
    final result = <String, String>{};
    widget.product.characteristics.forEach((key, value) {
      final normalizedKey = key.trim();
      final normalizedValue = value.trim();
      if (normalizedKey.isEmpty || normalizedValue.isEmpty) {
        return;
      }
      result[normalizedKey] = normalizedValue;
    });
    return result;
  }

  bool _hasNutritionalInfo() {
    final info = widget.product.nutritionalInfo;
    return info.calories > 0 ||
        info.protein > 0 ||
        info.fat > 0 ||
        info.carbohydrates > 0;
  }

  Widget _buildCharacteristicsSection(Map<String, String> characteristics) {
    return Container(
      width: double.infinity,
      color: _cardBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Общие характеристики',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...characteristics.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == characteristics.length - 1;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.key,
                        style: TextStyle(fontSize: 12, color: _mutedText),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 8),
                  Divider(color: _borderColor, height: 1),
                  const SizedBox(height: 8),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (widget.product.suppliers.isEmpty) {
      return const MainBottomNav(currentIndex: null);
    }

    final supplier = widget.product.suppliers.firstWhere(
      (s) => s.id == _selectedSupplierId,
      orElse: () => widget.product.bestSupplier,
    );
    final quantity =
        _supplierQuantities[supplier.id] ??
        (supplier.isAvailable ? supplier.minQuantity : 0);
    final totalPrice = supplier.getTotalPrice(quantity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _buildPriceBar(supplier, quantity, totalPrice),
        ),
        const MainBottomNav(currentIndex: null),
      ],
    );
  }

  Widget _buildPriceBar(Supplier supplier, int quantity, int totalPrice) {
    final isAvailable = supplier.isAvailable;
    final isAdded = (_supplierAdded[supplier.id] ?? false) && isAvailable;
    const outOfStockButtonWidth = 164.0;
    const outOfStockButtonHeight = 57.0;
    final barColor = !isAvailable
        ? const Color(0xFF9CA3AF)
        : isAdded
        ? const Color(0xFF22C55E)
        : const Color(0xFF6288D5);
    final accentColor = barColor;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: barColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: !isAvailable
              ? null
              : () {
                  if (isAdded) {
                    _removeFromCart(supplier);
                  } else {
                    _addToCart(supplier);
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${supplier.pricePerUnit} \u20B8/\u0448\u0442',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable
                          ? '\u041c\u0438\u043d\u0438\u043c\u0443\u043c: ${supplier.minQuantity} \u0448\u0442.'
                          : '\u041d\u0435\u0442 \u0432 \u043d\u0430\u043b\u0438\u0447\u0438\u0438',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Center(
                    child: isAvailable
                        ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            switchOutCurve: const Interval(
                              0.0,
                              0.3,
                              curve: Curves.easeIn,
                            ),
                            switchInCurve: const Interval(
                              0.7,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.7,
                                    end: 1.0,
                                  ).animate(animation),
                                  child: RotationTransition(
                                    turns: Tween<double>(
                                      begin: -0.05,
                                      end: 0.0,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Icon(
                              isAdded ? Icons.close : Icons.check,
                              key: ValueKey<bool>(isAdded),
                              size: 20,
                              color: Colors.white,
                            ),
                          )
                        : const SizedBox(
                            width: outOfStockButtonWidth,
                            height: outOfStockButtonHeight,
                            child: Center(
                              child: Text(
                                '\u041d\u0435\u0442 \u0432 \u043d\u0430\u043b\u0438\u0447\u0438\u0438',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                if (isAvailable) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _HoldRepeatIconButton(
                          icon: Icons.remove,
                          onPressed: () => _updateQuantity(supplier.id, -1),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalPrice \u20B8',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$quantity \u0448\u0442.',
                              style: TextStyle(fontSize: 13, color: _mutedText),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        _HoldRepeatIconButton(
                          icon: Icons.add,
                          onPressed: () => _updateQuantity(supplier.id, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsPage(
          product: widget.product,
          initialReviews: _productReviews,
        ),
      ),
    );
  }

  Future<void> _shareProductStub() async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _shareStubUrl,
      subject: widget.product.name,
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    );
  }
}

class _HoldRepeatIconButton extends StatefulWidget {
  const _HoldRepeatIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_HoldRepeatIconButton> createState() => _HoldRepeatIconButtonState();
}

class _HoldRepeatIconButtonState extends State<_HoldRepeatIconButton> {
  Timer? _repeatTimer;

  void _startRepeat() {
    if (widget.onPressed == null) return;
    widget.onPressed!();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted || widget.onPressed == null) {
        _stopRepeat();
        return;
      }
      widget.onPressed!();
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRepeat(),
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: IconButton(
        icon: Icon(widget.icon, size: 18),
        onPressed: widget.onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

