
import 'dart:async';
import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../pages/order_history_page.dart';
import '../services/api_service.dart';
import '../services/cart_store.dart';
import '../widgets/top_message.dart';

const double _buttonRadius = 18;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const Color _brandBlue = Color(0xFF6288D5);
  static const Color _payAllBlue = Color(0xFF2D2D2D);
  static const Color _payAllDark = Color(0xFF6B88FF);

  late final CartStore _cartStore = CartStore.instance;
  bool _isPlacingAllOrders = false;
  final Set<String> _submittingSuppliers = <String>{};

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _isDark ? _theme.scaffoldBackgroundColor : const Color(0xFFF1F5FB);
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _chipBg => _colorScheme.surfaceVariant;
  Color get _shadowColor =>
      _isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.04);
  Color get _payAllColor => _isDark ? _payAllDark : _payAllBlue;

  @override
  void initState() {
    super.initState();
    _cartStore.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartStore.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Map<String, List<CartItem>> get _cartItemsBySupplier =>
      _cartStore.itemsBySupplier;

  int get _totalPositions => _cartStore.totalPositions;
  int get _totalUnits => _cartStore.totalUnits;
  int get _totalAmount => _cartStore.totalAmount;

  int _getSupplierTotal(List<CartItem> items) {
    int total = 0;
    for (final item in items) {
      total += item.supplier.pricePerUnit * item.quantity;
    }
    return total;
  }

  int _getSupplierUnits(List<CartItem> items) {
    int total = 0;
    for (final item in items) {
      total += item.quantity;
    }
    return total;
  }

  void _updateQuantity(String supplierId, int itemIndex, int delta) {
    final items = _cartItemsBySupplier[supplierId];
    if (items == null || itemIndex < 0 || itemIndex >= items.length) {
      return;
    }
    final item = items[itemIndex];
    if (delta < 0 && item.quantity <= item.supplier.minQuantity) {
      return;
    }
    final newQuantity = item.quantity + delta;
    _cartStore.updateQuantity(
      supplierId: supplierId,
      productId: item.product.id,
      quantity: newQuantity,
      minQuantity: item.supplier.minQuantity,
      maxQuantity: item.supplier.maxQuantity,
    );
  }

  void _removeItem(String supplierId, int itemIndex) {
    final items = _cartItemsBySupplier[supplierId];
    if (items == null || itemIndex < 0 || itemIndex >= items.length) {
      return;
    }
    final removedItem = items[itemIndex];
    _cartStore.removeItem(
      supplierId: supplierId,
      productId: removedItem.product.id,
    );
    _showUndoSnackBar(removedItem);
  }

  void _showUndoSnackBar(CartItem removedItem) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _shadowColor.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _CountdownRing(
                duration: const Duration(seconds: 3),
                color: _brandBlue,
                textColor: _colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Товар удален',
                  style: TextStyle(
                    color: _colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  _cartStore.addOrUpdate(
                    product: removedItem.product,
                    supplier: removedItem.supplier,
                    quantity: removedItem.quantity,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: _brandBlue,
                  backgroundColor: _colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Отменить',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearCart() {
    _cartStore.clear();
  }

  Future<void> _confirmClearCart() async {
    if (_cartItemsBySupplier.isEmpty) return;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Очистить корзину?'),
          content: const Text('Все товары будут удалены из корзины.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );
    if (shouldClear == true) {
      _cartStore.clear();
    }
  }

  Future<bool> _confirmPayment({
    required String title,
    required int amount,
    required int units,
  }) async {
    if (!mounted) return false;
    final formattedAmount = _formatMoney(amount);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Подтверждение оплаты'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _colorScheme.onSurface,
                  ),
                ),
              if (title.isNotEmpty) const SizedBox(height: 8),
              _buildConfirmRow('Сумма', '$formattedAmount ₸'),
              const SizedBox(height: 6),
              _buildConfirmRow('Штук', '$units'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Оплатить'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: _mutedText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatMoney(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final positionFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  String _formatSupplierName(String name) {
    return name.trim();
  }

  String _resolveCartImage(CartItem item) {
    final imagePath = item.product.imageUrls.isNotEmpty
        ? item.product.imageUrls.first
        : '';
    if (imagePath.contains('coca_cola')) {
      return 'assets/coca_cola.jpeg';
    }
    return imagePath.isNotEmpty ? imagePath : 'assets/coca_cola.jpeg';
  }

  String _resolveOrderItemVolume(CartItem item) {
    const knownKeys = ['Объем', 'Объём', 'volume', 'Volume'];
    for (final key in knownKeys) {
      final value = item.product.characteristics[key];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '1 шт.';
  }

  List<Map<String, dynamic>> _buildOrderItemsPayload(List<CartItem> items) {
    return items
        .map(
          (item) => {
            'name': item.product.name,
            'volume': _resolveOrderItemVolume(item),
            'price': item.supplier.pricePerUnit,
            'quantity': item.quantity,
            'imageUrl': _resolveCartImage(item),
            'isReceived': false,
          },
        )
        .toList();
  }

  String _friendlyCheckoutError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('failed host lookup')) {
      return 'Нет соединения с сервером';
    }
    if (message.contains('400')) {
      return 'Некорректные данные заказа';
    }
    return 'Не удалось оформить заказ';
  }

  void _showCheckoutSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      showTopMessage(
        context,
        message,
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
  }

  Future<void> _placeOrderForSupplier(String supplierId) async {
    if (_isPlacingAllOrders || _submittingSuppliers.contains(supplierId)) {
      return;
    }
    final sourceItems = _cartItemsBySupplier[supplierId];
    if (sourceItems == null || sourceItems.isEmpty) {
      return;
    }
    final itemsSnapshot = List<CartItem>.from(sourceItems);
    final supplierTotal = _getSupplierTotal(itemsSnapshot);
    final supplierUnits = _getSupplierUnits(itemsSnapshot);
    final supplierName = _formatSupplierName(itemsSnapshot.first.supplier.name);
    final shouldPay = await _confirmPayment(
      title: supplierName.isNotEmpty ? supplierName : 'Заказ',
      amount: supplierTotal,
      units: supplierUnits,
    );
    if (!shouldPay) {
      return;
    }

    setState(() {
      _submittingSuppliers.add(supplierId);
    });

    try {
      await ApiService.createOrder(
        items: _buildOrderItemsPayload(itemsSnapshot),
        status: 'Собирается',
      );

      for (final item in itemsSnapshot) {
        _cartStore.removeItem(
          supplierId: supplierId,
          productId: item.product.id,
        );
      }

      _showCheckoutSnackBar('Заказ по поставщику оформлен');
    } catch (error) {
      _showCheckoutSnackBar(_friendlyCheckoutError(error), isError: true);
    } finally {
      if (!mounted) return;
      setState(() {
        _submittingSuppliers.remove(supplierId);
      });
    }
  }
  Future<void> _placeAllOrders() async {
    if (_isPlacingAllOrders || _cartItemsBySupplier.isEmpty) {
      return;
    }

    final supplierEntries = _cartItemsBySupplier.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => MapEntry(entry.key, List<CartItem>.from(entry.value)))
        .toList();

    if (supplierEntries.isEmpty) {
      return;
    }

    final shouldPay = await _confirmPayment(
      title: 'Все заказы',
      amount: _totalAmount,
      units: _totalUnits,
    );
    if (!shouldPay) {
      return;
    }

    setState(() {
      _isPlacingAllOrders = true;
      _submittingSuppliers.clear();
    });

    int successCount = 0;
    int failCount = 0;

    for (final entry in supplierEntries) {
      try {
        await ApiService.createOrder(
          items: _buildOrderItemsPayload(entry.value),
          status: 'Собирается',
        );
        successCount++;
        for (final item in entry.value) {
          _cartStore.removeItem(
            supplierId: entry.key,
            productId: item.product.id,
          );
        }
      } catch (_) {
        failCount++;
      }
    }

    if (!mounted) return;
    setState(() {
      _isPlacingAllOrders = false;
    });

    if (successCount > 0 && failCount == 0) {
      _showCheckoutSnackBar('Все заказы успешно оформлены');
      return;
    }
    if (successCount > 0 && failCount > 0) {
      _showCheckoutSnackBar(
        'Оформлено: $successCount, с ошибкой: $failCount',
        isError: true,
      );
      return;
    }
    _showCheckoutSnackBar('Не удалось оформить заказы', isError: true);
  }

  Widget _buildAnimatedValueText(
    String value, {
    required TextStyle style,
    TextAlign textAlign = TextAlign.start,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchOutCurve: Curves.easeOut,
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: Text(
        value,
        key: ValueKey<String>(value),
        style: style,
        textAlign: textAlign,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      bottomNavigationBar: _buildPayAllBar(),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 160),
              children: [
                _buildSummaryCard(),
                ..._cartItemsBySupplier.entries.map((entry) {
                  return _buildSupplierSection(entry.key, entry.value);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _cardBg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Корзина',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeaderAction(
                    label: 'История заказов',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderHistoryPage(),
                        ),
                      );
                    },
                  ),
                  _buildHeaderAction(
                    label: 'Очистить все',
                    onTap: _confirmClearCart,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction({
    required String label,
    required VoidCallback onTap,
  }) {
    return _PressableHeaderAction(
      label: label,
      onTap: onTap,
      color: _brandBlue,
    );
  }

  Widget _buildPayAllBar() {
    final canCheckout = _cartItemsBySupplier.isNotEmpty && !_isPlacingAllOrders;
    const buttonHeight = 48.0;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canCheckout ? _placeAllOrders : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _payAllColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _payAllColor.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size.fromHeight(buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_buttonRadius),
                ),
                elevation: 0,
              ),
              child: SizedBox(
                height: buttonHeight,
                child: Center(
                  child: _isPlacingAllOrders
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                          'Оформить все заказы',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAnimatedValueText(
                              '${_formatMoney(_totalAmount)} ₸',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '· $_totalUnits шт.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final hasItems = _cartItemsBySupplier.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _brandBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Общая сумма заказа',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          _buildAnimatedValueText(
            '${_formatMoney(_totalAmount)} ₸',
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Штук: $_totalUnits  Позиций: $_totalPositions',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.left,
          ),
          if (hasItems) ...[
            const SizedBox(height: 12),
            _buildSummaryProductsCard(),
          ],
        ],
      ),
    );
  }
  Widget _buildSummaryProductsCard() {
    final items = _cartItemsBySupplier.values.expand((supplier) => supplier).toList();
    final shown = items.take(4).toList();
    final restCount = items.length - shown.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _isDark ? _colorScheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${item.product.name} - ${item.quantity} шт.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      _isDark ? _colorScheme.onSurface : const Color(0xFF1E293B),
                ),
              ),
            ),
          if (restCount > 0)
            Text(
              '+$restCount еще в корзине',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _isDark ? _mutedText : const Color(0xFF475569),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierSection(String supplierId, List<CartItem> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final supplierName = items.first.supplier.name;
    final supplierTotal = _getSupplierTotal(items);
    final supplierUnits = _getSupplierUnits(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: _isDark ? _cardBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatSupplierName(supplierName),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Штук: $supplierUnits · Позиций: ${items.length}',
                style: TextStyle(fontSize: 12, color: _mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
            child: _buildCartItemCard(supplierId, index, item),
          );
        }),
        const SizedBox(height: 14),
        _buildSupplierSummaryCard(
          supplierId: supplierId,
          supplierTotal: supplierTotal,
          supplierUnits: supplierUnits,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSupplierSummaryCard({
    required String supplierId,
    required int supplierTotal,
    required int supplierUnits,
  }) {
    final isSubmitting =
        _isPlacingAllOrders || _submittingSuppliers.contains(supplierId);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Итого по поставщику',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                _buildAnimatedValueText(
                  '${_formatMoney(supplierTotal)} ₸',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () => _placeOrderForSupplier(supplierId),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _brandBlue.withValues(alpha: 0.55),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.86),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(150, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_buttonRadius),
              ),
              elevation: 0,
            ),
            child: SizedBox(
              width: 150,
              height: 20,
              child: Center(
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Оформить заказ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(String supplierId, int index, CartItem item) {
    final totalPrice = item.supplier.pricePerUnit * item.quantity;
    final tags = List<String>.from(item.product.categories);
    tags.sort((a, b) => b.length.compareTo(a.length));
    final imagePath = _resolveCartImage(item);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 104,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 1.15,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image,
                              size: 28,
                              color: Color(0xFF9CA3AF),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${item.quantity} шт.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 34),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (int i = 0; i < tags.length; i++) ...[
                                if (i > 0) const SizedBox(width: 6),
                                _buildTag(tags[i]),
                              ],
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Дата доставки: ${item.supplier.deliveryDate}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.product.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatSupplierName(item.supplier.name),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _mutedText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Минимум: ${item.supplier.minQuantity} шт.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _mutedText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildQuantityPill(
                          supplierId: supplierId,
                          index: index,
                          item: item,
                          totalPrice: totalPrice,
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: -3,
                  right: -10,
                  child: _buildRemoveButton(
                    supplierId: supplierId,
                    index: index,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildQuantityPill({
    required String supplierId,
    required int index,
    required CartItem item,
    required int totalPrice,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _brandBlue,
        borderRadius: BorderRadius.circular(_buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HoverIconButton(
            onTap: () => _updateQuantity(supplierId, index, -1),
            icon: Icons.remove,
            size: 16,
            enableRepeat: true,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnimatedValueText(
                '${_formatMoney(totalPrice)} ₸',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          _HoverIconButton(
            onTap: () => _updateQuantity(supplierId, index, 1),
            icon: Icons.add,
            size: 16,
            enableRepeat: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton({
    required String supplierId,
    required int index,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: _HoverIconButton(
        onTap: () => _removeItem(supplierId, index),
        icon: Icons.delete_outline,
        size: 20,
        color: const Color(0xFFDC2626),
        hoverColor: const Color(0xFFDC2626).withValues(alpha: 0.12),
        pressedColor: const Color(0xFFDC2626).withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: _brandBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
class _HoverIconButton extends StatefulWidget {
  const _HoverIconButton({
    required this.onTap,
    required this.icon,
    this.color = Colors.white,
    this.size = 18,
    this.enableRepeat = false,
    this.repeatInterval = const Duration(milliseconds: 180),
    this.hoverColor,
    this.pressedColor,
    this.baseColor,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final double size;
  final bool enableRepeat;
  final Duration repeatInterval;
  final Color? hoverColor;
  final Color? pressedColor;
  final Color? baseColor;

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _PressableHeaderAction extends StatefulWidget {
  const _PressableHeaderAction({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  State<_PressableHeaderAction> createState() => _PressableHeaderActionState();
}

class _PressableHeaderActionState extends State<_PressableHeaderAction> {
  static const _animationDuration = Duration(milliseconds: 140);
  bool _isHovered = false;
  bool _isPressed = false;

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() => _isHovered = value);
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  double get _scale {
    if (_isPressed) {
      return 0.96;
    }
    if (_isHovered) {
      return 1.03;
    }
    return 1.0;
  }

  Color get _backgroundColor {
    if (_isPressed) {
      return widget.color.withValues(alpha: 0.16);
    }
    if (_isHovered) {
      return widget.color.withValues(alpha: 0.1);
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _scale,
          duration: _animationDuration,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  static const _animationDuration = Duration(milliseconds: 120);
  bool _isHovered = false;
  bool _isPressed = false;
  Timer? _repeatTimer;

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() => _isHovered = value);
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  void _startRepeat() {
    if (!widget.enableRepeat) return;
    widget.onTap();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(widget.repeatInterval, (_) {
      if (!mounted || !widget.enableRepeat) {
        _stopRepeat();
        return;
      }
      widget.onTap();
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  double get _scale {
    if (_isPressed) {
      return 0.92;
    }
    if (_isHovered) {
      return 1.08;
    }
    return 1.0;
  }

  Color get _backgroundColor {
    if (_isPressed) {
      return widget.pressedColor ?? Colors.white.withValues(alpha: 0.28);
    }
    if (_isHovered) {
      return widget.hoverColor ?? Colors.white.withValues(alpha: 0.18);
    }
    return widget.baseColor ?? Colors.transparent;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () {
          _setPressed(false);
        },
        onLongPressStart:
            widget.enableRepeat ? (_) => _startRepeat() : null,
        onLongPressEnd: widget.enableRepeat ? (_) => _stopRepeat() : null,
        onLongPressCancel: widget.enableRepeat ? _stopRepeat : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _scale,
          duration: _animationDuration,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            child: Icon(
              widget.icon,
              color: widget.color,
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownRing extends StatefulWidget {
  const _CountdownRing({
    required this.duration,
    required this.color,
    required this.textColor,
    this.size = 28,
  });

  final Duration duration;
  final Color color;
  final Color textColor;
  final double size;

  @override
  State<_CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<_CountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = 1.0 - _controller.value;
        final secondsLeft =
            (widget.duration.inSeconds * progress).ceil().clamp(0, 99);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.4,
                  color: widget.color,
                  backgroundColor: widget.color.withValues(alpha: 0.16),
                ),
              ),
              Text(
                '$secondsLeft',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: widget.textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
