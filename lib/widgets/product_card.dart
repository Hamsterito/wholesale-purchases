import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'smart_image.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/cart_store.dart';
import '../services/favorites_store.dart';
import '../utils/ru_plural.dart';
import 'rating_stars.dart';
import 'top_message.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final bool compact;
  final bool showMessages;
  final bool enableImageSwipe;
  final bool showFavoritesUndo;
  final bool computeDeliveryDateFromRemaining;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    this.compact = false,
    this.showMessages = true,
    this.enableImageSwipe = true,
    this.showFavoritesUndo = false,
    this.computeDeliveryDateFromRemaining = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  static const Map<int, String> _weekdaysFull = <int, String>{
    DateTime.monday: 'Понедельник',
    DateTime.tuesday: 'Вторник',
    DateTime.wednesday: 'Среда',
    DateTime.thursday: 'Четверг',
    DateTime.friday: 'Пятница',
    DateTime.saturday: 'Суббота',
    DateTime.sunday: 'Воскресенье',
  };
  static const Map<int, String> _weekdaysShort = <int, String>{
    DateTime.monday: 'Пн',
    DateTime.tuesday: 'Вт',
    DateTime.wednesday: 'Ср',
    DateTime.thursday: 'Чт',
    DateTime.friday: 'Пт',
    DateTime.saturday: 'Сб',
    DateTime.sunday: 'Вс',
  };
  static const List<int> _weekdayOrder = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];
  static const List<int> _workdaysPreset = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];
  static const List<int> _weekendPreset = <int>[
    DateTime.saturday,
    DateTime.sunday,
  ];
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
  Color get _shadowColor => _isDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.08);
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
  bool get computeDeliveryDateFromRemaining =>
      widget.computeDeliveryDateFromRemaining;

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
    final isAvailable = supplier.isAvailable;
    final displayQuantity = _isInCart && _selectedQuantity > 0
        ? _selectedQuantity
        : (isAvailable ? supplier.minQuantity : 0);
    final totalPrice = supplier.getTotalPrice(displayQuantity);
    final hasCarouselIndicator =
        enableImageSwipe && widget.product.imageUrls.length > 1;
    final imageToCarouselGap = compact ? 3.0 : 4.0;
    final carouselToDeliveryGap = compact ? 2.0 : 3.0;
    final padding = EdgeInsets.fromLTRB(
      10,
      hasCarouselIndicator ? 0 : 10,
      10,
      compact ? 10 : 8,
    );
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
                    if (hasCarouselIndicator) ...[
                      SizedBox(height: imageToCarouselGap),
                      _buildImageCarouselIndicator(),
                      SizedBox(height: carouselToDeliveryGap),
                    ],
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
    if (!supplier.isAvailable) {
      if (showMessages) {
        showTopMessage(
          context,
          'Нет в наличии: ${product.name}',
          backgroundColor: const Color(0xFFEF4444),
        );
      }
      return;
    }

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
        'Добавлено в корзину: ${product.name} -$selected шт.',
        backgroundColor: const Color(0xFF6288D5),
      );
    }
  }

  Future<int?> _showQuantityPicker(Supplier supplier) {
    final minQuantity = supplier.minQuantity;
    final initialQuantity = _selectedQuantity > 0
        ? _selectedQuantity
        : minQuantity;

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _QuantityPickerSheet(
            minQuantity: minQuantity,
            initialQuantity: initialQuantity,
            maxQuantity: supplier.maxQuantity,
          ),
        );
      },
    );
  }

  Widget _buildImageSection(Supplier supplier) {
    final deliveryBadge = _resolveDeliveryBadgeText(supplier);
    return Stack(
      children: [
        RepaintBoundary(
          child: Container(
            height: compact ? 146 : 173,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              color: _surfaceVariant,
            ),
            clipBehavior: Clip.hardEdge,
            child: PageView.builder(
              controller: _pageController,
              physics: enableImageSwipe
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: widget.product.imageUrls.isNotEmpty
                  ? widget.product.imageUrls.length
                  : 1,
              onPageChanged: (index) {
                setState(() {
                  _imageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final images = widget.product.imageUrls.isNotEmpty
                    ? widget.product.imageUrls
                    : [''];
                final path = images[index];
                return SmartImage(
                  path: path,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: Center(
                    child: Icon(Icons.image, size: 60, color: _mutedText),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: _isFavorite
                ? Icon(Icons.favorite, color: Color(0xFF6288D5), size: 29)
                : Stack(
                    alignment: Alignment.center,
                    children: const [
                      Icon(Icons.favorite, color: Color(0x80BFC5CF), size: 29),
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
          right: 10,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6288D5).withValues(alpha: 0.9),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                deliveryBadge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarouselIndicator() {
    if (!enableImageSwipe || widget.product.imageUrls.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 8,
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
                  : _mutedText.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDeliveryInfo(Supplier supplier) {
    final deliveryDate = _resolveDeliveryDateText(supplier);
    return Text(
      'Доставка: $deliveryDate',
      style: TextStyle(fontSize: compact ? 10 : 11, color: _mutedText),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _resolveDeliveryBadgeText(Supplier supplier) {
    final source = supplier.deliveryBadge.trim().isNotEmpty
        ? supplier.deliveryBadge.trim()
        : supplier.deliveryDate.trim();
    if (source.isEmpty) {
      return 'Доставка';
    }

    final normalized = source.toLowerCase().trim();
    final timeMatch = RegExp(
      r'([01]?\d|2[0-3]):([0-5]\d)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (timeMatch == null) {
      return source;
    }
    final hour = int.tryParse(timeMatch.group(1) ?? '');
    final minute = int.tryParse(timeMatch.group(2) ?? '');
    if (hour == null || minute == null) {
      return source;
    }

    final weekdaysPart = normalized.substring(0, timeMatch.start).trim();
    final weekdays = _parseDeliveryWeekdays(weekdaysPart);
    if (weekdays.isEmpty) {
      return source;
    }

    final sortedWeekdays = _sortWeekdays(weekdays);
    final time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    if (sortedWeekdays.length == 1) {
      final day = _weekdaysFull[sortedWeekdays.first] ?? 'Понедельник';
      return '$day $time';
    }
    if (_sameWeekdays(sortedWeekdays, _weekdayOrder)) {
      return 'Ежедневно $time';
    }
    if (_sameWeekdays(sortedWeekdays, _workdaysPreset)) {
      return 'Будни $time';
    }
    if (_sameWeekdays(sortedWeekdays, _weekendPreset)) {
      return 'Выходные $time';
    }
    if (sortedWeekdays.length <= 3) {
      final label = sortedWeekdays
          .map((weekday) => _weekdaysShort[weekday] ?? 'Пн')
          .join(', ');
      return '$label $time';
    }

    final rangeLabel = _continuousRangeLabel(sortedWeekdays);
    if (rangeLabel != null) {
      return '$rangeLabel $time';
    }
    return '${sortedWeekdays.length} дн./нед $time';
  }

  String _resolveDeliveryDateText(Supplier supplier) {
    final fallbackSource = supplier.deliveryDate.trim().isNotEmpty
        ? supplier.deliveryDate.trim()
        : supplier.deliveryBadge.trim();
    if (!computeDeliveryDateFromRemaining || fallbackSource.isEmpty) {
      return fallbackSource;
    }

    final now = DateTime.now();
    final nextSlot = _findNextDeliveryDateTime(fallbackSource, now);
    if (nextSlot == null) {
      return fallbackSource;
    }
    return _formatComputedDeliveryLabel(nextSlot, now);
  }

  DateTime? _findNextDeliveryDateTime(String source, DateTime now) {
    final normalized = source.toLowerCase().trim();
    if (normalized.isEmpty) {
      return null;
    }

    final rangeMatch = RegExp(
      r'^(пн|вт|ср|чт|пт|сб|вс)\s*-\s*(пн|вт|ср|чт|пт|сб|вс)\s+([01]?\d|2[0-3]):([0-5]\d)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (rangeMatch != null) {
      final startWeekday = _parseWeekdayShort(rangeMatch.group(1));
      final endWeekday = _parseWeekdayShort(rangeMatch.group(2));
      final hour = int.tryParse(rangeMatch.group(3) ?? '');
      final minute = int.tryParse(rangeMatch.group(4) ?? '');
      if (startWeekday != null &&
          endWeekday != null &&
          hour != null &&
          minute != null) {
        return _findNextFromWeekdayRange(
          startWeekday: startWeekday,
          endWeekday: endWeekday,
          hour: hour,
          minute: minute,
          now: now,
        );
      }
    }

    final dayMatch = RegExp(
      r'^(Понедельник|Вторник|Среда|Четверг|Пятница|Суббота|Воскресенье)\s+([01]?\d|2[0-3]):([0-5]\d)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (dayMatch != null) {
      final weekday = _parseWeekdayFull(dayMatch.group(1));
      final hour = int.tryParse(dayMatch.group(2) ?? '');
      final minute = int.tryParse(dayMatch.group(3) ?? '');
      if (weekday != null && hour != null && minute != null) {
        return _findNextFromWeekdays(
          weekdays: <int>{weekday},
          hour: hour,
          minute: minute,
          now: now,
        );
      }
    }

    final timeMatch = RegExp(
      r'([01]?\d|2[0-3]):([0-5]\d)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1) ?? '');
      final minute = int.tryParse(timeMatch.group(2) ?? '');
      if (hour != null && minute != null) {
        final weekdaysPart = normalized.substring(0, timeMatch.start).trim();
        final weekdays = _parseDeliveryWeekdays(weekdaysPart);
        if (weekdays.isNotEmpty) {
          return _findNextFromWeekdays(
            weekdays: weekdays,
            hour: hour,
            minute: minute,
            now: now,
          );
        }
      }
    }

    return null;
  }

  Set<int> _parseDeliveryWeekdays(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const <int>{};
    }

    if (normalized == 'будни') {
      return _workdaysPreset.toSet();
    }
    if (normalized == 'выходные') {
      return _weekendPreset.toSet();
    }
    if (normalized == 'ежедневно' || normalized == 'каждый день') {
      return _weekdayOrder.toSet();
    }

    final rangeParts = normalized.split(RegExp(r'\s*-\s*'));
    if (rangeParts.length == 2) {
      final start = _parseWeekdayAny(rangeParts.first);
      final end = _parseWeekdayAny(rangeParts.last);
      if (start != null && end != null) {
        final weekdays = <int>{};
        var current = start;
        while (true) {
          weekdays.add(current);
          if (current == end) {
            break;
          }
          current = current == DateTime.sunday ? DateTime.monday : current + 1;
        }
        return weekdays;
      }
    }

    final sourceTokens = normalized.contains(',')
        ? normalized.split(RegExp(r'\s*,\s*'))
        : normalized.split(RegExp(r'\s+'));
    final weekdays = <int>{};
    for (final token in sourceTokens) {
      final weekday = _parseWeekdayAny(token);
      if (weekday != null) {
        weekdays.add(weekday);
      }
    }
    if (weekdays.isNotEmpty) {
      return weekdays;
    }

    final single = _parseWeekdayAny(normalized);
    if (single != null) {
      return <int>{single};
    }
    return const <int>{};
  }

  List<int> _sortWeekdays(Iterable<int> weekdays) {
    final sorted = weekdays.toSet().toList(growable: false)
      ..sort(
        (a, b) => _weekdayOrder.indexOf(a).compareTo(_weekdayOrder.indexOf(b)),
      );
    return sorted;
  }

  bool _sameWeekdays(Iterable<int> first, Iterable<int> second) {
    final left = _sortWeekdays(first);
    final right = _sortWeekdays(second);
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  String? _continuousRangeLabel(List<int> sortedWeekdays) {
    if (sortedWeekdays.isEmpty) {
      return null;
    }
    for (var index = 1; index < sortedWeekdays.length; index++) {
      final previous = sortedWeekdays[index - 1];
      final current = sortedWeekdays[index];
      if (current != previous + 1) {
        return null;
      }
    }
    final start = _weekdaysShort[sortedWeekdays.first] ?? 'Пн';
    final end = _weekdaysShort[sortedWeekdays.last] ?? 'Пн';
    return '$start-$end';
  }

  DateTime? _findNextFromWeekdayRange({
    required int startWeekday,
    required int endWeekday,
    required int hour,
    required int minute,
    required DateTime now,
  }) {
    final weekdays = <int>{};
    var current = startWeekday;
    while (true) {
      weekdays.add(current);
      if (current == endWeekday) {
        break;
      }
      current = current == DateTime.sunday ? DateTime.monday : current + 1;
    }
    return _findNextFromWeekdays(
      weekdays: weekdays,
      hour: hour,
      minute: minute,
      now: now,
    );
  }

  DateTime? _findNextFromWeekdays({
    required Set<int> weekdays,
    required int hour,
    required int minute,
    required DateTime now,
  }) {
    for (var dayOffset = 0; dayOffset <= 14; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      if (!weekdays.contains(date.weekday)) {
        continue;
      }
      final candidate = DateTime(date.year, date.month, date.day, hour, minute);
      if (!candidate.isBefore(now)) {
        return candidate;
      }
    }
    return null;
  }

  String _formatComputedDeliveryLabel(DateTime deliveryAt, DateTime now) {
    final nowDate = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(
      deliveryAt.year,
      deliveryAt.month,
      deliveryAt.day,
    );
    final daysLeft = targetDate.difference(nowDate).inDays;
    final time = _formatTime(deliveryAt);

    if (daysLeft <= 0) {
      return 'сегодня $time';
    }
    if (daysLeft == 1) {
      return 'завтра $time';
    }

    final day = deliveryAt.day.toString().padLeft(2, '0');
    final month = deliveryAt.month.toString().padLeft(2, '0');
    return '$day.$month $time';
  }

  int? _parseWeekdayAny(String? value) {
    final short = _parseWeekdayShort(value);
    if (short != null) {
      return short;
    }
    return _parseWeekdayFull(value);
  }

  int? _parseWeekdayShort(String? value) {
    final normalized = value?.replaceAll('.', '').trim().toLowerCase();
    switch (normalized) {
      case 'пн':
        return DateTime.monday;
      case 'вт':
        return DateTime.tuesday;
      case 'ср':
        return DateTime.wednesday;
      case 'чт':
        return DateTime.thursday;
      case 'пт':
        return DateTime.friday;
      case 'сб':
        return DateTime.saturday;
      case 'вс':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  int? _parseWeekdayFull(String? value) {
    final normalized = value?.replaceAll('.', '').trim().toLowerCase();
    switch (normalized) {
      case 'понедельник':
        return DateTime.monday;
      case 'вторник':
        return DateTime.tuesday;
      case 'среда':
        return DateTime.wednesday;
      case 'четверг':
        return DateTime.thursday;
      case 'пятница':
        return DateTime.friday;
      case 'суббота':
        return DateTime.saturday;
      case 'воскресенье':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildProductTitle() {
    return Text(
      widget.product.name,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMinOrder(Supplier supplier) {
    return Text(
      'Минимум: ${supplier.minQuantity} шт.',
      style: TextStyle(fontSize: compact ? 10 : 11, color: _mutedText),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildWarehouse(Supplier supplier) {
    return Text(
      supplier.name,
      style: TextStyle(fontSize: compact ? 10 : 11, color: _mutedText),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
        RatingStars(
          rating: product.rating,
          size: compact ? 11 : 12,
          spacing: 0.5,
          filledColor: const Color(0xFFF5B400),
          emptyColor: _mutedText.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          reviewsLabel(product.reviewCount),
          style: TextStyle(fontSize: compact ? 10 : 11, color: _mutedText),
        ),
      ],
    );
  }

  Widget _buildPriceSection(Supplier supplier, int totalPrice) {
    final isAvailable = supplier.isAvailable;
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
                isAvailable ? '$totalPrice \u20B8' : 'Нет в наличии',
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  color: isAvailable
                      ? const Color(0xFF6288D5)
                      : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Material(
          color: isAvailable ? _surfaceVariant : _surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: isAvailable ? () => _handleCartTap(supplier) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchOutCurve: const Interval(
                      0.0,
                      0.35,
                      curve: Curves.easeIn,
                    ),
                    switchInCurve: const Interval(
                      0.65,
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
                      isAvailable
                          ? (_isInCart ? Icons.close : Icons.add)
                          : Icons.block_outlined,
                      key: ValueKey<bool>(_isInCart),
                      color: isAvailable ? const Color(0xFF6288D5) : _mutedText,
                      size: compact ? 22 : 26,
                    ),
                  ),
                  if (_isInCart && isAvailable)
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
  Color get _shadowColor => _isDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.08);
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
    var next = _quantity < widget.minQuantity
        ? widget.minQuantity
        : _quantity + 1;
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
                      'Минимум: ${widget.minQuantity} шт.',
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
      onLongPressStart: enabled ? (_) => _startRepeat(onPressed) : null,
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

