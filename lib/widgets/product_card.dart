import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/cart_store.dart';
import '../services/favorites_store.dart';
import '../utils/ru_plural.dart';
import 'top_message.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final bool compact;
  final bool showMessages;
  final bool enableImageSwipe;
  final bool showFavoritesUndo;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    this.compact = false,
    this.showMessages = true,
    this.enableImageSwipe = true,
    this.showFavoritesUndo = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;
  int _imageIndex = 0;
  late final VoidCallback _favoritesListener;
  late final VoidCallback _cartListener;
  final CartStore _cartStore = CartStore.instance;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _surfaceVariant => _colorScheme.surfaceContainerHighest;
  Color get _shadowColor =>
      _isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.08);
  final PageController _pageController = PageController();
  bool _isInCart = false;
  int _selectedQuantity = 0;
  FavoritesStore get _favoritesStore => FavoritesStore.instance;

  Product get product => widget.product;
  VoidCallback get onTap => widget.onTap;
  VoidCallback get onAddToCart => widget.onAddToCart;
  bool get compact => widget.compact;
  bool get showMessages => widget.showMessages;
  bool get enableImageSwipe => widget.enableImageSwipe;
  bool get showFavoritesUndo => widget.showFavoritesUndo;

  @override
  void initState() {
    super.initState();
    _isFavorite = _favoritesStore.contains(widget.product.id);
    final initialQuantity = _findCartQuantity();
    _isInCart = initialQuantity != null;
    _selectedQuantity = initialQuantity ?? 0;
    _favoritesListener = () {
      final isFav = _favoritesStore.contains(widget.product.id);
      if (isFav != _isFavorite && mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    };
    _cartListener = () {
      if (!mounted) return;
      _syncCartState();
    };
    _favoritesStore.addListener(_favoritesListener);
    _cartStore.addListener(_cartListener);
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      final isFav = _favoritesStore.contains(widget.product.id);
      if (isFav != _isFavorite) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
    _syncCartState();
  }

  int? _findCartQuantity() {
    for (final List<CartItem> items in _cartStore.itemsBySupplier.values) {
      for (final item in items) {
        if (item.product.id == product.id) {
          return item.quantity;
        }
      }
    }
    return null;
  }

  void _syncCartState() {
    final quantity = _findCartQuantity();
    final isInCart = quantity != null;
    final selectedQuantity = quantity ?? 0;
    if (isInCart == _isInCart && selectedQuantity == _selectedQuantity) {
      return;
    }
    setState(() {
      _isInCart = isInCart;
      _selectedQuantity = selectedQuantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final supplier = widget.product.bestSupplier;
    final displayQuantity =
        _isInCart && _selectedQuantity > 0 ? _selectedQuantity : supplier.minQuantity;
    final totalPrice = supplier.getTotalPrice(displayQuantity);
    final padding = compact ? const EdgeInsets.all(10) : const EdgeInsets.all(12);
    final gapSmall = compact ? 1.0 : 2.0;
    final gapTiny = compact ? 0.0 : 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(supplier),
            Expanded(
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeliveryInfo(supplier),
                    SizedBox(height: gapSmall),
                    _buildProductTitle(),
                    SizedBox(height: gapSmall),
                    _buildMinOrder(supplier),
                    SizedBox(height: gapTiny),
                    _buildWarehouse(supplier),
                    SizedBox(height: gapTiny),
                    _buildRating(),
                    const Spacer(),
                    _buildPriceSection(supplier, totalPrice),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCartTap(Supplier supplier) async {
    if (_isInCart) {
      setState(() {
        _isInCart = false;
        _selectedQuantity = 0;
      });
      CartStore.instance.removeItem(
        supplierId: supplier.id,
        productId: product.id,
      );
      if (showMessages) {
        showTopMessage(
          context,
          'Удалено из корзины: ${product.name}',
          backgroundColor: const Color(0xFFEF4444),
        );
      }
      return;
    }

    final selected = await _showQuantityPicker(supplier);
    if (!mounted || selected == null) return;
    setState(() {
      _isInCart = true;
      _selectedQuantity = selected;
    });
    CartStore.instance.addOrUpdate(
      product: product,
      supplier: supplier,
      quantity: selected,
    );
    onAddToCart();
    if (showMessages) {
      showTopMessage(
        context,
        'Добавлено в корзину: ${product.name} — $selected шт.',
        backgroundColor: const Color(0xFF6288D5),
      );
    }
  }

  Future<int?> _showQuantityPicker(Supplier supplier) {
    final minQuantity = supplier.minQuantity;
    final initialQuantity =
        _selectedQuantity > 0 ? _selectedQuantity : minQuantity;
    final navigator = Navigator.of(context, rootNavigator: true);
    final animationController =
        BottomSheet.createAnimationController(navigator);
    animationController.duration = const Duration(milliseconds: 180);
    animationController.reverseDuration = const Duration(milliseconds: 150);

    return showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      transitionAnimationController: animationController,
      builder: (context) => _QuantityPickerSheet(
        minQuantity: minQuantity,
        initialQuantity: initialQuantity,
        maxQuantity: supplier.maxQuantity,
      ),
    ).whenComplete(() => animationController.dispose());
  }


  Widget _buildImageSection(Supplier supplier) {
    return Stack(
      children: [
        Container(
          height: compact ? 150 : 173,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            color: _surfaceVariant,
          ),
          clipBehavior: Clip.hardEdge,
          child: PageView.builder(
            controller: _pageController,
            physics: enableImageSwipe
                ? const PageScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: widget.product.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _imageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final path = widget.product.imageUrls[index];
              return Image.asset(
                path,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.image, size: 60, color: _mutedText),
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: _isFavorite
                ? Icon(
                    Icons.favorite,
                    color: Color(0xFF6288D5),
                    size: 29,
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: const [
                      Icon(
                        Icons.favorite,
                        color: Color(0x80BFC5CF),
                        size: 29,
                      ),
                      Icon(
                        Icons.favorite_border,
                        color: Color(0xFF6288D5),
                        size: 29,
                      ),
                    ],
                  ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () {
              final added = _favoritesStore.toggle(product);
              setState(() {
                _isFavorite = added;
              });
              if (!showMessages) return;
              if (added) {
                showTopMessage(
                  context,
                  'Добавлено в избранное',
                  backgroundColor: const Color(0xFF6288D5),
                  showClose: !showFavoritesUndo,
                );
              } else {
                if (showFavoritesUndo) {
                  showTopMessage(
                    context,
                    'Удалено из избранного',
                    backgroundColor: const Color(0xFFEF4444),
                    duration: const Duration(seconds: 3),
                    actionText: 'Отменить',
                    showCountdown: true,
                    showClose: false,
                    onAction: () {
                      _favoritesStore.add(product);
                      if (mounted) {
                        setState(() {
                          _isFavorite = true;
                        });
                      }
                    },
                  );
                } else {
                  showTopMessage(
                    context,
                    'Удалено из избранного',
                    backgroundColor: const Color(0xFFEF4444),
                    showClose: !showFavoritesUndo,
                  );
                }
              }
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6288D5).withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              supplier.deliveryBadge,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (enableImageSwipe && widget.product.imageUrls.length > 1)
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.product.imageUrls.length, (index) {
                final active = index == _imageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: active ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF6288D5)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryInfo(Supplier supplier) {
    return Text(
      'Доставка: ${supplier.deliveryDate}',
      style: TextStyle(
        fontSize: compact ? 10 : 11,
        color: _mutedText,
      ),
    );
  }

  Widget _buildProductTitle() {
    return Text(
      widget.product.name,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMinOrder(Supplier supplier) {
    return Text(
      'Минимум: ${supplier.minQuantity} шт.',
      style: TextStyle(
        fontSize: compact ? 10 : 11,
        color: _mutedText,
      ),
    );
  }

  Widget _buildWarehouse(Supplier supplier) {
    return Text(
      supplier.name,
      style: TextStyle(
        fontSize: compact ? 10 : 11,
        color: _mutedText,
      ),
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        Text(
          product.rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.star, size: compact ? 11 : 12, color: Colors.amber),
        Icon(Icons.star, size: compact ? 11 : 12, color: Colors.amber),
        Icon(Icons.star, size: compact ? 11 : 12, color: Colors.amber),
        Icon(Icons.star, size: compact ? 11 : 12, color: Colors.amber),
        Icon(Icons.star, size: compact ? 11 : 12, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          reviewsLabel(product.reviewCount),
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            color: _mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(Supplier supplier, int totalPrice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${supplier.pricePerUnit} \u20B8',
              style: TextStyle(
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6288D5).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$totalPrice \u20B8',
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  color: const Color(0xFF6288D5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Material(
          color: _surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _handleCartTap(supplier),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchOutCurve:
                        const Interval(0.0, 0.35, curve: Curves.easeIn),
                    switchInCurve:
                        const Interval(0.65, 1.0, curve: Curves.easeOut),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.7, end: 1.0)
                              .animate(animation),
                          child: RotationTransition(
                            turns: Tween<double>(begin: -0.05, end: 0.0)
                                .animate(animation),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Icon(
                      _isInCart ? Icons.close : Icons.add,
                      key: ValueKey<bool>(_isInCart),
                      color: const Color(0xFF6288D5),
                      size: compact ? 22 : 26,
                    ),
                  ),
                  if (_isInCart)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6288D5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_selectedQuantity',
                          textAlign: TextAlign.center,
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false,
                          ),
                          style: TextStyle(
                            fontSize: compact ? 8 : 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _favoritesStore.removeListener(_favoritesListener);
    _cartStore.removeListener(_cartListener);
    _pageController.dispose();
    super.dispose();
  }
}

class _QuantityPickerSheet extends StatefulWidget {
  const _QuantityPickerSheet({
    required this.minQuantity,
    required this.initialQuantity,
    this.maxQuantity,
  });

  final int minQuantity;
  final int initialQuantity;
  final int? maxQuantity;

  @override
  State<_QuantityPickerSheet> createState() => _QuantityPickerSheetState();
}

class _QuantityPickerSheetState extends State<_QuantityPickerSheet> {
  static const Color _brandBlue = Color(0xFF6288D5);
  static const Duration _repeatInterval = Duration(milliseconds: 180);

  late int _quantity;
  late final TextEditingController _controller;
  Timer? _repeatTimer;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;
  Color get _surfaceVariant => _colorScheme.surfaceContainerHighest;
  Color get _shadowColor =>
      _isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.08);
  int? get _effectiveMax {
    final max = widget.maxQuantity;
    if (max == null) return null;
    if (max < widget.minQuantity) return widget.minQuantity;
    return max;
  }

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _controller = TextEditingController(text: _quantity.toString());
  }

  @override
  void dispose() {
    _stopRepeat();
    _controller.dispose();
    super.dispose();
  }

  void _syncController(int value) {
    if (!mounted) return;
    final text = value.toString();
    if (_controller.text == text) return;
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  void _setQuantity(int value) {
    if (!mounted) return;
    if (_quantity == value) return;
    setState(() {
      _quantity = value;
    });
  }

  void _startRepeat(VoidCallback action) {
    if (!mounted) return;
    action();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(_repeatInterval, (_) {
      if (!mounted) {
        _stopRepeat();
        return;
      }
      action();
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _normalizeQuantity() {
    if (!mounted) return;
    final max = _effectiveMax;
    var normalized = _quantity;
    if (normalized < widget.minQuantity) {
      normalized = widget.minQuantity;
    }
    if (max != null && normalized > max) {
      normalized = max;
    }
    if (normalized != _quantity) {
      _setQuantity(normalized);
    }
    _syncController(normalized);
  }

  void _increase() {
    if (!mounted) return;
    final max = _effectiveMax;
    var next =
        _quantity < widget.minQuantity ? widget.minQuantity : _quantity + 1;
    if (max != null && next > max) {
      next = max;
    }
    _setQuantity(next);
    _syncController(next);
  }

  void _decrease() {
    if (!mounted) return;
    if (_quantity <= widget.minQuantity) {
      _setQuantity(widget.minQuantity);
      _syncController(widget.minQuantity);
      return;
    }
    final next = _quantity - 1;
    _setQuantity(next);
    _syncController(next);
  }

  void _onTextChanged(String value) {
    if (!mounted) return;
    final trimmed = value.trim();
    final parsed = trimmed.isEmpty ? 0 : int.tryParse(trimmed);
    if (parsed == null) return;
    final max = _effectiveMax;
    if (max != null && parsed > max) {
      _setQuantity(max);
      _syncController(max);
      return;
    }
    setState(() {
      _quantity = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: _borderColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Количество',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 0.95,
                      ),
                    ),
                    Text(
                      'Мин. ${widget.minQuantity} шт.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 0.85,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildQuantityStepper(),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final max = _effectiveMax;
                var normalized = _quantity < widget.minQuantity
                    ? widget.minQuantity
                    : _quantity;
                if (max != null && normalized > max) {
                  normalized = max;
                }
                Navigator.pop(context, normalized);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Добавить',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper() {
    final max = _effectiveMax;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onPressed: _quantity > widget.minQuantity ? _decrease : null,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 46,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _onTextChanged,
                    onEditingComplete: _normalizeQuantity,
                    onSubmitted: (_) => _normalizeQuantity(),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'шт',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _mutedText,
                  ),
                ),
              ],
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onPressed: max != null && _quantity >= max ? null : _increase,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return GestureDetector(
      onLongPressStart: enabled ? (_) => _startRepeat(onPressed!) : null,
      onLongPressEnd: enabled ? (_) => _stopRepeat() : null,
      onLongPressCancel: enabled ? _stopRepeat : null,
      child: Material(
        color: enabled ? _brandBlue : _surfaceVariant,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              icon,
              size: 18,
              color: enabled ? Colors.white : _mutedText,
            ),
          ),
        ),
      ),
    );
  }
}



