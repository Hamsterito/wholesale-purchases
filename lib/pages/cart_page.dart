import 'dart:async';
import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user_address.dart';
import '../pages/order_history_page.dart';
import '../profile/add_payment_card.dart';
import 'package:flutter_project/profile/address_page.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import '../services/store/cart_store.dart';
import '../services/storage/payment_card_storage.dart';
import '../services/api/product_resolver.dart';
import '../services/store/templates_store.dart';
import '../theme/app_color_palette.dart';
import '../utils/delivery_schedule.dart';
import '../widgets/pages/apply_template_confirm_dialog.dart';
import '../widgets/pages/rename_template_dialog.dart';
import '../widgets/pages/save_template_dialog.dart';
import '../widgets/smart_image.dart';
import '../widgets/smooth_sheet.dart';
import '../widgets/pages/templates_sheet.dart';
import '../widgets/messages/top_message.dart';

const double _buttonRadius = 18;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartStore _cartStore = CartStore.instance;
  bool _isPlacingAllOrders = false;
  final Set<String> _submittingSuppliers = <String>{};

  // Кэш отсортированных тегов товара. Ключ - productId, значение - список
  // категорий, отсортированных по убыванию длины. Категории товара не
  // меняются между ребилдами, поэтому пересортировывать их каждый раз
  // в _buildCartItemCard смысла нет.
  final Map<String, List<String>> _sortedTagsByProductId = {};

  int _templatesCount = 0;
  late final VoidCallback _templatesListener;

  // Свёрнут ли sheet шаблонов через крестик: true → показан FAB, тап
  // по нему открывает sheet обратно.
  bool _isTemplatesMinimized = false;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => context.colorPalette.card;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _chipBg => _colorScheme.surfaceContainerHighest;
  Color get _shadowColor => _isDark
      ? Colors.black.withValues(alpha: 0.4)
      : Colors.black.withValues(alpha: 0.04);

  @override
  void initState() {
    super.initState();
    _cartStore.addListener(_onCartChanged);
    _templatesListener = () {
      if (!mounted) return;
      setState(() => _templatesCount = TemplatesStore.instance.count);
    };
    TemplatesStore.instance.addListener(_templatesListener);
    _templatesCount = TemplatesStore.instance.count;
  }

  @override
  void dispose() {
    _cartStore.removeListener(_onCartChanged);
    TemplatesStore.instance.removeListener(_templatesListener);
    super.dispose();
  }

  void _onCartChanged() {
    if (!mounted) return;
    _pruneSortedTagsCache();
    setState(() {});
  }

  // Возвращает отсортированный по убыванию длины список категорий товара
  // и кеширует результат по productId. Категории не меняются для уже
  // добавленного товара, так что повторные ребилды переиспользуют список.
  List<String> _getSortedTags(String productId, List<String> categories) {
    final cached = _sortedTagsByProductId[productId];
    if (cached != null) return cached;
    final sorted = List<String>.from(categories)
      ..sort((a, b) => b.length.compareTo(a.length));
    _sortedTagsByProductId[productId] = sorted;
    return sorted;
  }

  // Удаляем из кеша записи по тем productId, которых больше нет в корзине,
  // чтобы кеш не накапливал мусор после удаления позиций или clear().
  void _pruneSortedTagsCache() {
    if (_sortedTagsByProductId.isEmpty) return;
    final activeProductIds = <String>{};
    for (final items in _cartStore.itemsBySupplier.values) {
      for (final item in items) {
        activeProductIds.add(item.product.id);
      }
    }
    _sortedTagsByProductId.removeWhere(
      (productId, _) => !activeProductIds.contains(productId),
    );
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

  void _removeSummaryItem(CartItem item) {
    if (item.supplier.id.isEmpty) {
      return;
    }
    _cartStore.removeItem(
      supplierId: item.supplier.id,
      productId: item.product.id,
    );
    _showUndoSnackBar(item);
  }

  void _showUndoSnackBar(CartItem removedItem) {
    showTopMessage(
      context,
      'Товар удален',
      duration: const Duration(seconds: 3),
      actionText: 'Отменить',
      onAction: () {
        _cartStore.addOrUpdate(
          product: removedItem.product,
          supplier: removedItem.supplier,
          quantity: removedItem.quantity,
        );
      },
      showCountdown: true,
      showClose: false,
    );
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
                backgroundColor: context.colorPalette.error,
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
    String? paymentLabel,
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
              if (paymentLabel != null && paymentLabel.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildConfirmRow('Оплата', paymentLabel.trim()),
              ],
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
                backgroundColor: context.colorPalette.accent,
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
        Text(label, style: TextStyle(fontSize: 13, color: _mutedText)),
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

  Future<_CheckoutPaymentChoice?> _resolveCheckoutPaymentChoice() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      _showCheckoutSnackBar('Войдите, чтобы выбрать оплату', isError: true);
      return null;
    }

    final cards = await PaymentCardStorage.loadCards(userId: userId);
    final savedSelection = await PaymentCardStorage.loadSelection(
      userId: userId,
    );

    PaymentCard? cardById(String? id) {
      if (id == null || id.isEmpty) return null;
      for (final card in cards) {
        if (card.id == id) return card;
      }
      return null;
    }

    PaymentCard? firstCardForBrand(String brand) {
      for (final card in cards) {
        if (card.brand.toLowerCase() == brand.toLowerCase()) {
          return card;
        }
      }
      return null;
    }

    PaymentCard? selectedCard = cardById(savedSelection?.cardId);

    if (selectedCard == null && cards.isNotEmpty) {
      final method = savedSelection?.method;
      if (method == 'Visa' || method == 'Mastercard') {
        selectedCard = firstCardForBrand(method!);
      }
      selectedCard ??= cards.first;
    }

    final selectedMethod = await _promptCheckoutPaymentMethod(
      selectedCard: selectedCard,
    );
    if (selectedMethod == null) {
      return null;
    }

    if (selectedMethod == _CheckoutMethodAction.cash) {
      const cashChoice = _CheckoutPaymentChoice(
        method: 'Cash',
        label: 'Наличными при получении',
      );
      await PaymentCardStorage.saveSelection(
        const PaymentSelection(method: 'Cash'),
        userId: userId,
      );
      return cashChoice;
    }

    var cardForPayment = selectedCard;
    if (cardForPayment == null) {
      cardForPayment = await _promptAddCardForCheckout();
      if (cardForPayment == null) {
        return null;
      }
    }

    final method = _normalizedTopBrand(cardForPayment.brand) ?? 'Card';
    final label = '${cardForPayment.brand} ${cardForPayment.maskedNumber}';
    await PaymentCardStorage.saveSelection(
      PaymentSelection(method: method, cardId: cardForPayment.id),
      userId: userId,
    );

    return _CheckoutPaymentChoice(
      method: method,
      label: label,
      cardId: cardForPayment.id,
    );
  }

  Future<_CheckoutMethodAction?> _promptCheckoutPaymentMethod({
    required PaymentCard? selectedCard,
  }) async {
    if (!mounted) {
      return null;
    }

    var selectedMethod = selectedCard == null
        ? _CheckoutMethodAction.cash
        : _CheckoutMethodAction.card;

    return showModalBottomSheet<_CheckoutMethodAction>(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: smoothBottomSheetController(context),
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: _cardBg,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasCard = selectedCard != null;
            final cardSubtitle = hasCard
                ? '${selectedCard.brand} ${selectedCard.maskedNumber}'
                : 'Карта не добавлена';
            return SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                decoration: BoxDecoration(
                  color: context.colorPalette.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Способ оплаты',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentSheetTile(
                      icon: Icons.payments_outlined,
                      title: 'Наличные',
                      subtitle: 'Оплата при получении',
                      isSelected: selectedMethod == _CheckoutMethodAction.cash,
                      onTap: () {
                        setModalState(() {
                          selectedMethod = _CheckoutMethodAction.cash;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentSheetTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Карта',
                      subtitle: cardSubtitle,
                      isSelected: selectedMethod == _CheckoutMethodAction.card,
                      onTap: () {
                        setModalState(() {
                          selectedMethod = _CheckoutMethodAction.card;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSelectedPaymentBanner(
                      selectedMethod: selectedMethod,
                      selectedCard: selectedCard,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, selectedMethod),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorPalette.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Подтвердить выбор',
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
  }

  Widget _buildPaymentSheetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected
        ? context.colorPalette.accent
        : Colors.transparent;
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colorPalette.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: context.colorPalette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: context.colorPalette.accent,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPaymentBanner({
    required _CheckoutMethodAction selectedMethod,
    required PaymentCard? selectedCard,
  }) {
    final text = selectedMethod == _CheckoutMethodAction.cash
        ? 'Оплата наличными при получении'
        : selectedCard == null
        ? 'Оплата картой. На следующем шаге добавьте карту.'
        : 'Оплата картой ${selectedCard.brand} ${selectedCard.maskedNumber}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorPalette.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: context.colorPalette.accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<PaymentCard?> _promptAddCardForCheckout() async {
    if (!mounted) {
      return null;
    }

    final createdCard = await Navigator.push<PaymentCard>(
      context,
      MaterialPageRoute(builder: (context) => const AddPaymentCardPage()),
    );
    if (!mounted) {
      return null;
    }
    return createdCard;
  }

  String? _normalizedTopBrand(String brand) {
    final lower = brand.toLowerCase();
    if (lower == 'visa') {
      return 'Visa';
    }
    if (lower == 'mastercard') {
      return 'Mastercard';
    }
    return null;
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

  // Расчётная дата доставки - приоритет даём декодеру, иначе оставляем сырое значение.
  String _resolveDeliveryDateText(Supplier supplier) {
    final raw = supplier.deliveryDate.trim().isNotEmpty
        ? supplier.deliveryDate
        : supplier.deliveryBadge;
    final schedule = DeliverySchedule.decode(raw);
    if (schedule != null) {
      return formatExpectedDelivery(schedule, DateTime.now());
    }
    return raw;
  }

  String _resolveCartImage(CartItem item) {
    for (final rawPath in item.product.imageUrls) {
      final imagePath = rawPath.trim();
      if (imagePath.isNotEmpty) {
        return imagePath;
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _buildOrderItemsPayload(List<CartItem> items) {
    return items
        .map(
          (item) => {
            'productId': item.product.id,
            'name': item.product.name,
            'price': item.supplier.pricePerUnit,
            'quantity': item.quantity,
            'imageUrl': _resolveCartImage(item),
            'supplierName': item.supplier.name,
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
        backgroundColor: context.colorPalette.error,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    showTopMessage(
      context,
      message,
    );
  }

  int? _resolveInitialSelectedAddressId(List<UserAddress> addresses) {
    if (addresses.isEmpty) {
      return null;
    }
    final savedId = AuthStorage.selectedAddressId;
    if (savedId != null && addresses.any((item) => item.id == savedId)) {
      return savedId;
    }
    return addresses.first.id;
  }

  UserAddress? _findAddressById(List<UserAddress> addresses, int? addressId) {
    if (addressId == null) {
      return null;
    }
    for (final address in addresses) {
      if (address.id == addressId) {
        return address;
      }
    }
    return null;
  }

  Future<UserAddress?> _pickDeliveryAddress() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      _showCheckoutSnackBar('Войдите, чтобы выбрать адрес', isError: true);
      return null;
    }

    List<UserAddress> addresses = [];
    try {
      addresses = await ApiService.getUserAddresses(userId: userId);
    } catch (_) {
      _showCheckoutSnackBar('Не удалось загрузить адреса', isError: true);
      return null;
    }

    if (!mounted) return null;
    final initialSelectedId = _resolveInitialSelectedAddressId(addresses);
    if (initialSelectedId != AuthStorage.selectedAddressId) {
      await AuthStorage.saveSelectedAddressId(initialSelectedId);
    }

    final selected = await _showAddressPickerSheet(
      userId: userId,
      initialAddresses: addresses,
      initialSelectedId: initialSelectedId,
    );
    if (selected != null) {
      await AuthStorage.saveSelectedAddressId(selected.id);
    }
    return selected;
  }

  Future<UserAddress?> _showAddressPickerSheet({
    required int userId,
    required List<UserAddress> initialAddresses,
    required int? initialSelectedId,
  }) async {
    final addresses = List<UserAddress>.from(initialAddresses);
    int? selectedId = initialSelectedId;

    return showModalBottomSheet<UserAddress>(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: smoothBottomSheetController(context),
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: _cardBg,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedAddress = _findAddressById(addresses, selectedId);
            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                decoration: BoxDecoration(
                  color: context.colorPalette.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Адрес доставки',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final created = await _createAddressFromCheckout(
                              userId,
                            );
                            if (created == null) return;
                            if (!context.mounted) return;
                            setModalState(() {
                              addresses.insert(0, created);
                              selectedId = created.id;
                            });
                          },
                          child: const Text('Добавить'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: addresses.isEmpty
                          ? _buildEmptyAddressSheet(colorScheme)
                          : ListView.separated(
                              itemCount: addresses.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final address = addresses[index];
                                final isSelected = address.id == selectedId;
                                return _buildAddressSheetTile(
                                  address: address,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setModalState(() {
                                      selectedId = address.id;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    if (selectedAddress != null) ...[
                      const SizedBox(height: 12),
                      _buildSelectedAddressBanner(selectedAddress),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedAddress == null
                            ? null
                            : () => Navigator.pop(context, selectedAddress),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorPalette.accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: context.colorPalette.accent
                              .withValues(alpha: 0.35),
                          disabledForegroundColor: Colors.white.withValues(
                            alpha: 0.8,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Подтвердить выбор',
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
  }

  Widget _buildSelectedAddressBanner(UserAddress address) {
    final text = address.displayAddress.isNotEmpty
        ? address.displayAddress
        : address.displayTitle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorPalette.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: context.colorPalette.accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAddressSheet(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 36,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Адресов пока нет',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Добавьте адрес, чтобы продолжить оформление.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSheetTile({
    required UserAddress address,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final displayAddress = address.displayAddress.isEmpty
        ? 'Без адреса'
        : address.displayAddress;
    final borderColor = isSelected
        ? context.colorPalette.accent
        : Colors.transparent;
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colorPalette.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _resolveAddressIcon(address),
                  color: context.colorPalette.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.displayTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: _mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: context.colorPalette.accent,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveAddressIcon(UserAddress address) {
    switch (address.normalizedLabel) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  Future<UserAddress?> _createAddressFromCheckout(int userId) async {
    final draft = await Navigator.push<AddressDraft>(
      context,
      MaterialPageRoute(builder: (context) => const AddressPage()),
    );

    if (draft == null) return null;

    try {
      return await ApiService.createUserAddress(userId: userId, draft: draft);
    } catch (_) {
      _showCheckoutSnackBar('Не удалось сохранить адрес', isError: true);
      return null;
    }
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
    final selectedAddress = await _pickDeliveryAddress();
    if (selectedAddress == null) {
      return;
    }
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      _showCheckoutSnackBar('Войдите, чтобы оформить заказ', isError: true);
      return;
    }
    final paymentChoice = await _resolveCheckoutPaymentChoice();
    if (paymentChoice == null) {
      return;
    }
    final shouldPay = await _confirmPayment(
      title: supplierName.isNotEmpty ? supplierName : 'Заказ',
      amount: supplierTotal,
      units: supplierUnits,
      paymentLabel: paymentChoice.label,
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
        deliveryAddress: selectedAddress.displayAddress,
        userId: userId,
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
      if (mounted) {
        setState(() {
          _submittingSuppliers.remove(supplierId);
        });
      }
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

    final selectedAddress = await _pickDeliveryAddress();
    if (selectedAddress == null) {
      return;
    }
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      _showCheckoutSnackBar('Войдите, чтобы оформить заказ', isError: true);
      return;
    }
    final paymentChoice = await _resolveCheckoutPaymentChoice();
    if (paymentChoice == null) {
      return;
    }

    final shouldPay = await _confirmPayment(
      title: 'Все заказы',
      amount: _totalAmount,
      units: _totalUnits,
      paymentLabel: paymentChoice.label,
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
          deliveryAddress: selectedAddress.displayAddress,
          userId: userId,
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
        final scale = Tween<double>(
          begin: 0.98,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
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
      body: Stack(
        children: [
          Column(
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
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: Text(
                      'Корзина',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Иконка часов - навигация в историю заказов.
                  _HeaderIconButton(
                    icon: Icons.history,
                    tooltip: 'История заказов',
                    semanticsLabel: 'Открыть историю заказов',
                    color: _mutedText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderHistoryPage(),
                        ),
                      );
                    },
                  ),
                  // Иконка закладки с плюсом - сохранить текущую корзину
                  // как шаблон. Активна только при непустой корзине.
                  if (_cartItemsBySupplier.isNotEmpty)
                    _HeaderIconButton(
                      icon: Icons.bookmark_add_outlined,
                      tooltip: 'Сохранить как шаблон',
                      semanticsLabel: 'Сохранить текущую корзину как шаблон',
                      color: _mutedText,
                      onTap: _saveCurrentCartAsTemplate,
                    ),
                  // Иконка закладки с бейджем-счётчиком - навигация в шаблоны.
                  _HeaderIconButton(
                    icon: Icons.bookmark_outline,
                    tooltip: 'Шаблоны',
                    semanticsLabel: 'Открыть список шаблонов покупок',
                    color: _mutedText,
                    badgeCount: _templatesCount,
                    onTap: _openTemplatesSheet,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTemplatesSheet() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      showTopMessage(
        context,
        'Войдите, чтобы пользоваться шаблонами',
      );
      return;
    }
    // Скрываем FAB на время открытого sheet.
    if (_isTemplatesMinimized) {
      setState(() => _isTemplatesMinimized = false);
    }
    final result = await showTemplatesSheet(
      context,
      onApply: _applyTemplate,
      onRename: _renameTemplate,
      onDelete: _deleteTemplate,
    );
    if (!mounted) return;
    // minimized - свёрнут через крестик, показываем FAB; иначе FAB не нужен.
    setState(() {
      _isTemplatesMinimized = result == TemplatesSheetResult.minimized;
    });
  }

  // Применяем шаблон: при непустой корзине просим подтверждение, потом
  // TemplatesStore.apply и сводку с пропущенными.
  Future<void> _applyTemplate(PurchaseTemplate template) async {
    if (!mounted) return;

    if (_cartStore.totalPositions > 0) {
      final confirmed = await showApplyTemplateConfirmDialog(context);
      if (confirmed != true) return;
      if (!mounted) return;
    }

    final ApplyTemplateResult result;
    try {
      result = await TemplatesStore.instance.apply(
        templateId: template.id,
        resolver: ApiProductResolver(),
        cart: _cartStore,
      );
    } catch (e) {
      if (!mounted) return;
      showTopMessage(
        context,
        'Не удалось применить шаблон',
        backgroundColor: context.colorPalette.error,
      );
      return;
    }

    if (!mounted) return;

    if (!result.cartReplaced) {
      // Все позиции отвалились - корзина не тронута.
      showTopMessage(
        context,
        'Шаблон не применён: ни один товар не доступен',
        backgroundColor: context.colorPalette.error,
      );
      return;
    }

    // Закрываем sheet и показываем сводку.
    Navigator.of(context).maybePop();

    final summary = StringBuffer(
      'Корзина заменена шаблоном «${template.name}»: '
      'добавлено ${result.addedCount} товаров',
    );
    if (result.skippedCount > 0) {
      summary.write(', пропущено ${result.skippedCount}');
    }
    if (result.adjustedCount > 0) {
      summary.write(', скорректировано ${result.adjustedCount}');
    }

    final hasSkipped = result.skippedCount > 0;
    showTopMessage(
      context,
      summary.toString(),
      duration: const Duration(seconds: 4),
      maxLines: 2,
      // Action виден только при skipped > 0 - открывает модалку
      // со списком пропущенных позиций и причинами.
      actionText: hasSkipped ? 'Подробнее' : null,
      onAction: hasSkipped
          ? () => _showSkippedItemsDialog(result.skipped)
          : null,
    );
  }

  // Модалка со списком пропущенных позиций - Material 3.
  Future<void> _showSkippedItemsDialog(List<SkippedTemplateItem> items) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.colorPalette;
        final media = MediaQuery.of(dialogContext);
        final clampedScaler = TextScaler.linear(
          MediaQuery.textScalerOf(dialogContext).scale(1.0).clamp(1.0, 2.0),
        );
        return MediaQuery(
          data: media.copyWith(textScaler: clampedScaler),
          child: AlertDialog(
            backgroundColor: palette.card,
            title: Text(
              'Пропущено ${items.length} ${_skippedSuffix(items.length)}',
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
              child: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 12, color: palette.line),
                  itemBuilder: (context, index) {
                    final entry = items[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.item.productName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _skipReasonText(entry.reason),
                          style: TextStyle(fontSize: 12, color: palette.muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _skippedSuffix(int n) {
    // Простое склонение без подключения utils/ru_plural - кейс единичный.
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'позиция';
    if ((mod10 >= 2 && mod10 <= 4) && (mod100 < 12 || mod100 > 14)) {
      return 'позиции';
    }
    return 'позиций';
  }

  String _skipReasonText(SkipReason reason) {
    switch (reason) {
      case SkipReason.productMissing:
        return 'Товар недоступен';
      case SkipReason.supplierMissing:
        return 'Поставщик больше не предлагает товар';
    }
  }

  // Переименование: валидация в диалоге; rename в то же имя - no-op в сторе.
  Future<void> _renameTemplate(PurchaseTemplate template) async {
    final newName = await showRenameTemplateDialog(context, template: template);
    if (newName == null) return;
    if (!mounted) return;
    try {
      await TemplatesStore.instance.rename(
        templateId: template.id,
        newName: newName,
      );
    } on TemplateValidationException catch (e) {
      if (!mounted) return;
      showTopMessage(
        context,
        e.userMessage,
      );
      return;
    }
    if (!mounted) return;
    showTopMessage(
      context,
      'Шаблон переименован',
    );
  }

  // Снимок берём до remove, чтобы restore вернул шаблон с прежними
  // id, именем, составом и датами.
  Future<void> _deleteTemplate(PurchaseTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Удалить шаблон ${template.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorPalette.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final snapshot = template;
    await TemplatesStore.instance.remove(template.id);

    // Если страница уже не смонтирована - возвращаем шаблон автоматически.
    if (!mounted) {
      await TemplatesStore.instance.restore(snapshot);
      return;
    }
    showTopMessage(
      context,
      'Шаблон удалён',
      actionText: 'Отменить',
      onAction: () => TemplatesStore.instance.restore(snapshot),
      duration: const Duration(seconds: 5),
      showCountdown: true,
    );
  }

  // Сохраняет текущий состав корзины как шаблон (новый или перезапись).
  Future<void> _saveCurrentCartAsTemplate() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      showTopMessage(
        context,
        'Войдите, чтобы пользоваться шаблонами',
      );
      return;
    }

    // Защитный no-op - кнопка не должна быть видна при пустой корзине.
    final bySupplier = _cartItemsBySupplier;
    if (bySupplier.isEmpty) return;

    final cartItems = <CartItem>[
      for (final items in bySupplier.values) ...items,
    ];

    // Лимит позиций - до открытия диалога: смысла открывать нет.
    if (cartItems.length > 100) {
      showTopMessage(
        context,
        'В шаблоне может быть не более 100 позиций.',
      );
      return;
    }

    // Лимит шаблонов - только для create; перезапись лимит не нарушает,
    // поэтому решение принимаем после возврата из диалога.
    final templatesCount = TemplatesStore.instance.count;

    final defaultName = 'Шаблон от ${_formatTemplateDate(DateTime.now())}';
    final result = await showSaveTemplateDialog(
      context,
      defaultName: defaultName,
    );
    if (result == null) return;
    if (!mounted) return;

    final items = cartItems.map(TemplateItem.fromCartItem).toList();

    try {
      if (result.overwriteId != null) {
        await TemplatesStore.instance.overwrite(
          templateId: result.overwriteId!,
          items: items,
        );
      } else {
        if (templatesCount >= 20) {
          showTopMessage(
            context,
            'Достигнут лимит шаблонов: 20. Удалите ненужный шаблон.',
          );
          return;
        }
        await TemplatesStore.instance.create(name: result.name, items: items);
      }
    } on TemplateValidationException catch (e) {
      if (!mounted) return;
      showTopMessage(
        context,
        e.userMessage,
      );
      return;
    }

    if (!mounted) return;
    showTopMessage(
      context,
      'Шаблон сохранён',
    );
  }

  String _formatTemplateDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Widget _buildPayAllBar() {
    final canCheckout = _cartItemsBySupplier.isNotEmpty && !_isPlacingAllOrders;
    final hasItems = _cartItemsBySupplier.isNotEmpty;
    const buttonHeight = 48.0;
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canCheckout ? _placeAllOrders : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDark
                        ? context.colorPalette.accentMist
                        : context.colorPalette.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        (_isDark
                                ? context.colorPalette.accentMist
                                : context.colorPalette.accent)
                            .withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.8,
                    ),
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
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '· $_totalUnits шт.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
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
              if (hasItems) ...[
                const SizedBox(height: 6),
                _ClearCartLink(onTap: _confirmClearCart),
              ],
            ],
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
        color: _isDark
            ? context.colorPalette.accentMist
            : context.colorPalette.accent,
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
    final items = _cartItemsBySupplier.values
        .expand((supplier) => supplier)
        .toList();
    final shown = items.take(4).toList();
    final restCount = items.length - shown.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isDark
            ? _colorScheme.surfaceContainerHighest
            : context.colorPalette.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < shown.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${shown[i].product.name} - ${shown[i].quantity} шт.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isDark
                            ? _colorScheme.onSurface
                            : context.colorPalette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryRemoveButton(shown[i]),
                ],
              ),
            ),
            if (i < shown.length - 1)
              Divider(
                height: 8,
                thickness: 1,
                color: _colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
          ],
          if (restCount > 0)
            Text(
              '+$restCount еще в корзине',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _isDark ? _mutedText : context.colorPalette.muted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRemoveButton(CartItem item) {
    return SizedBox(
      width: 28,
      height: 28,
      child: _HoverIconButton(
        onTap: () => _removeSummaryItem(item),
        icon: Icons.delete_outline,
        size: 18,
        color: context.colorPalette.error,
        hoverColor: context.colorPalette.error.withValues(alpha: 0.12),
        pressedColor: context.colorPalette.error.withValues(alpha: 0.2),
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
              backgroundColor: context.colorPalette.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.colorPalette.accent.withValues(
                alpha: 0.55,
              ),
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
    final tags = _getSortedTags(item.product.id, item.product.categories);
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
              color: context.colorPalette.card,
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
                      child: SmartImage(
                        path: imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: Center(
                          child: Icon(
                            Icons.image,
                            size: 28,
                            color: context.colorPalette.muted,
                          ),
                        ),
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
                          'Дата доставки: ${_resolveDeliveryDateText(item.supplier)}',
                          style: TextStyle(fontSize: 12, color: _mutedText),
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
        color: context.colorPalette.accent,
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

  Widget _buildRemoveButton({required String supplierId, required int index}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: _HoverIconButton(
        onTap: () => _removeItem(supplierId, index),
        icon: Icons.delete_outline,
        size: 20,
        color: context.colorPalette.error,
        hoverColor: context.colorPalette.error.withValues(alpha: 0.12),
        pressedColor: context.colorPalette.error.withValues(alpha: 0.2),
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
        style: TextStyle(
          fontSize: 12,
          color: context.colorPalette.accent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum _CheckoutMethodAction { cash, card }

class _CheckoutPaymentChoice {
  const _CheckoutPaymentChoice({
    required this.method,
    required this.label,
    this.cardId,
  });

  final String method;
  final String label;
  final String? cardId;
}

class _HoverIconButton extends StatefulWidget {
  const _HoverIconButton({
    required this.onTap,
    required this.icon,
    this.color = Colors.white,
    this.size = 18,
    this.enableRepeat = false,
    this.hoverColor,
    this.pressedColor,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final double size;
  final bool enableRepeat;
  final Color? hoverColor;
  final Color? pressedColor;

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.semanticsLabel,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final String semanticsLabel;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasBadge = widget.badgeCount > 0;
    final overlay = _pressed
        ? widget.color.withValues(alpha: 0.16)
        : _hovered
        ? widget.color.withValues(alpha: 0.08)
        : Colors.transparent;

    final button = Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: overlay, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 22, color: widget.color),
        ),
        if (hasBadge)
          Positioned(
            right: 0,
            top: 0,
            child: _TemplatesBadge(count: widget.badgeCount),
          ),
      ],
    );

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: button,
          ),
        ),
      ),
    );
  }
}

class _ClearCartLink extends StatefulWidget {
  const _ClearCartLink({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ClearCartLink> createState() => _ClearCartLinkState();
}

class _ClearCartLinkState extends State<_ClearCartLink> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final color = _pressed
        ? palette.error
        : _hovered
        ? palette.error.withValues(alpha: 0.85)
        : palette.error.withValues(alpha: 0.9);
    return Semantics(
      button: true,
      label: 'Очистить корзину',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  'Очистить корзину',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplatesBadge extends StatelessWidget {
  const _TemplatesBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final text = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.card, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  static const _animationDuration = Duration(milliseconds: 120);
  static const _repeatInterval = Duration(milliseconds: 180);
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
    _repeatTimer = Timer.periodic(_repeatInterval, (_) {
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
    return Colors.transparent;
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
        onLongPressStart: widget.enableRepeat ? (_) => _startRepeat() : null,
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
            child: Icon(widget.icon, color: widget.color, size: widget.size),
          ),
        ),
      ),
    );
  }
}
