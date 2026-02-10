import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/product.dart';
import '../services/cart_store.dart';
import '../services/favorites_store.dart';
import '../widgets/category_tags.dart';
import '../widgets/info_section.dart';
import '../widgets/main_navigation.dart';
import '../widgets/nutritional_info_card.dart';
import '../widgets/product_image_carousel.dart';
import '../widgets/rating_section.dart';
import '../widgets/ratings_breakdown.dart';
import '../widgets/similar_products_carousel.dart';
import '../widgets/supplier_card.dart';
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
  static const double _bottomMessageOffset = 110;
  static const String _shareStubUrl =
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
  final Map<String, int> _supplierQuantities = {};
  final Map<String, bool> _supplierAdded = {};
  bool _isFavorite = false;
  late final VoidCallback _favoritesListener;
  String? _selectedSupplierId;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg {
    final base = _theme.scaffoldBackgroundColor;
    final overlay =
        Colors.black.withValues(alpha: _isDark ? 0.06 : 0.04);
    return Color.alphaBlend(overlay, base);
  }
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;
  Color get _shadowColor =>
      _isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.08);
  FavoritesStore get _favoritesStore => FavoritesStore.instance;

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
    }
  }

  void _updateQuantity(String supplierId, int delta) {
    final supplier =
        widget.product.suppliers.firstWhere((s) => s.id == supplierId);
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
      'Добавлено в корзину: ${widget.product.name} — $quantity шт. от ${supplier.name}',
      backgroundColor: const Color(0xFF6288D5),
      showAtBottom: true,
      bottomOffset: _bottomMessageOffset,
    );
  }

  void _removeFromCart(Supplier supplier) {
    final quantity = _supplierQuantities[supplier.id] ?? supplier.minQuantity;
    setState(() {
      _supplierAdded[supplier.id] = false;
    });
    CartStore.instance.removeItem(
      supplierId: supplier.id,
      productId: widget.product.id,
    );
    showTopMessage(
      context,
      'Удалено из корзины: ${widget.product.name} — $quantity шт. от ${supplier.name}',
      backgroundColor: const Color(0xFFEF4444),
      showAtBottom: true,
      bottomOffset: _bottomMessageOffset,
    );
  }

  void _selectSupplier(String supplierId) {
    setState(() {
      _selectedSupplierId = supplierId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomScrollPadding = MediaQuery.of(context).padding.bottom + 150;

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
                  const SizedBox(height: 8),
                  _buildSuppliersSection(),
                  NutritionalInfoCard(
                    nutritionalInfo: widget.product.nutritionalInfo,
                  ),
                  InfoSection(
                    title: 'Состав',
                    content: widget.product.ingredients,
                  ),
                  InfoSection(
                    title: 'Описание',
                    content: widget.product.description,
                  ),
                  _buildCharacteristicsSection(),
                  RatingsBreakdown(
                    rating: widget.product.rating,
                    reviewCount: widget.product.reviewCount,
                    distribution: widget.product.ratingDistribution,
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
    final volume = _extractVolume();

    return Container(
      color: _cardBg,
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          ProductImageCarousel(imageUrls: widget.product.imageUrls),
          if (volume != null)
            Positioned(
              bottom: 12,
              right: 12,
              child: _buildVolumeBadge(volume),
            ),
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
                          showClose: false,
                        );
                      } else {
                        showTopMessage(
                          context,
                          '\u0423\u0434\u0430\u043b\u0435\u043d\u043e \u0438\u0437 \u0438\u0437\u0431\u0440\u0430\u043d\u043d\u043e\u0433\u043e',
                          backgroundColor: const Color(0xFFEF4444),
                          showAtBottom: true,
                          duration: const Duration(seconds: 3),
                          actionText: '\u041e\u0442\u043c\u0435\u043d\u0438\u0442\u044c',
                          showCountdown: true,
                          showClose: false,
                          bottomOffset: _bottomMessageOffset,
                          onAction: () {
                            _favoritesStore.add(widget.product);
                            if (mounted) {
                              setState(() {
                                _isFavorite = true;
                              });
                            }
                          },
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

  Widget _buildVolumeBadge(String volume) {
    final bgColor = _isDark
        ? _colorScheme.surfaceVariant.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.85);
    final textColor = _isDark ? _colorScheme.onSurface : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        volume,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingSection(
            rating: widget.product.rating,
            reviewCount: widget.product.reviewCount,
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

  Widget _buildSuppliersSection() {
    return Container(
      color: _cardBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Продавцы',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.product.suppliers.asMap().entries.map((entry) {
            final index = entry.key;
            final supplier = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < widget.product.suppliers.length - 1 ? 12 : 0,
              ),
              child: SupplierCard(
                supplier: supplier,
                quantity:
                    _supplierQuantities[supplier.id] ?? supplier.minQuantity,
                onQuantityChanged: (delta) => _updateQuantity(supplier.id, delta),
                onSelect: () => _selectSupplier(supplier.id),
                isSelected: _selectedSupplierId == supplier.id,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCharacteristicsSection() {
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.product.characteristics.entries.toList().asMap().entries.map(
            (entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast =
                  index == widget.product.characteristics.length - 1;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.key,
                          style: TextStyle(
                            fontSize: 12,
                            color: _mutedText,
                          ),
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (widget.product.suppliers.isEmpty) {
      return const SizedBox.shrink();
    }

    final supplier = widget.product.suppliers.firstWhere(
      (s) => s.id == _selectedSupplierId,
      orElse: () => widget.product.bestSupplier,
    );
    final quantity = _supplierQuantities[supplier.id] ?? supplier.minQuantity;
    final totalPrice = supplier.getTotalPrice(quantity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _buildPriceBar(supplier, quantity, totalPrice),
        ),
        _buildBottomNav(),
      ],
    );
  }

  Widget _buildPriceBar(Supplier supplier, int quantity, int totalPrice) {
    final isAdded = _supplierAdded[supplier.id] ?? false;
    final barColor =
        isAdded ? const Color(0xFF22C55E) : const Color(0xFF6288D5);
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
          onTap: () {
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
                      '${supplier.pricePerUnit} \u20B8/шт',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Мин. ${supplier.minQuantity} шт.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  switchOutCurve:
                      const Interval(0.0, 0.3, curve: Curves.easeIn),
                  switchInCurve:
                      const Interval(0.7, 1.0, curve: Curves.easeOut),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale:
                            Tween<double>(begin: 0.7, end: 1.0).animate(animation),
                        child: RotationTransition(
                          turns: Tween<double>(begin: -0.05, end: 0.0)
                              .animate(animation),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Icon(
                    isAdded ? Icons.check : Icons.add,
                    key: ValueKey<bool>(isAdded),
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            '$quantity шт.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _mutedText,
                            ),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildNavItemSvg(
                'assets/icons/main.svg',
                'assets/icons/main_active.svg',
                'Главная',
                0,
                false,
              ),
              _buildNavItemSvg(
                'assets/icons/catalog.svg',
                'assets/icons/catalog_active.svg',
                'Каталог',
                1,
                false,
              ),
              _buildNavItemSvg(
                'assets/icons/cart.svg',
                'assets/icons/cart_active.svg',
                'Корзина',
                2,
                false,
              ),
              _buildNavItemSvg(
                'assets/icons/profile.svg',
                'assets/icons/profile_active.svg',
                'Профиль',
                3,
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemSvg(
    String iconPath,
    String activeIconPath,
    String label,
    int index,
    bool isActive,
  ) {
    final color =
        isActive ? const Color(0xFF6288D5) : _colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => _openMainNav(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              isActive ? activeIconPath : iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _extractVolume() {
    final regex = RegExp(r'(\d+(?:[\.,]\d+)?)\s*л', caseSensitive: false);
    final match = regex.firstMatch(widget.product.name);
    if (match == null) return null;
    final value = match.group(1)?.replaceAll('.', ',');
    return value == null ? null : '$valueл';
  }

  void _openMainNav(int index) {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainNavigation(initialIndex: index),
      ),
      (route) => false,
    );
  }

  void _openReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsPage(product: widget.product),
      ),
    );
  }

  Future<void> _shareProductStub() async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _shareStubUrl,
      subject: widget.product.name,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }
}

class _HoldRepeatIconButton extends StatefulWidget {
  const _HoldRepeatIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 18,
    this.padding = const EdgeInsets.all(4),
    this.constraints = const BoxConstraints(),
    this.repeatInterval = const Duration(milliseconds: 180),
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;
  final Duration repeatInterval;

  @override
  State<_HoldRepeatIconButton> createState() => _HoldRepeatIconButtonState();
}

class _HoldRepeatIconButtonState extends State<_HoldRepeatIconButton> {
  Timer? _repeatTimer;

  void _startRepeat() {
    if (widget.onPressed == null) return;
    widget.onPressed!();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(widget.repeatInterval, (_) {
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
        icon: Icon(widget.icon, size: widget.size),
        onPressed: widget.onPressed,
        padding: widget.padding,
        constraints: widget.constraints,
      ),
    );
  }
}

