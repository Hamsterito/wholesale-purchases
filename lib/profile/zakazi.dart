import 'package:flutter/material.dart';
import '../models/order.dart';
import '../pages/order_history_page.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../utils/auto_refresh.dart';
import '../widgets/main_bottom_nav.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with AutoRefreshMixin<MyOrdersPage> {
  static const Color _brandBlue = Color(0xFF6288D5);
  static const String _fallbackOrderImage = 'assets/coca_cola.jpeg';
  static const Duration _orderCancellationWindow = Duration(hours: 1);

  List<Order> _orders = [];
  bool _isLoading = true;
  final Set<String> _acceptingOrders = {};
  final Set<String> _cancelingOrders = {};

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;
  Color get _shadowColor => _isDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.05);

  @override
  void initState() {
    super.initState();
    _loadOrders();
    startAutoRefresh();
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    try {
      final userId = AuthStorage.userId;
      if (userId == null || userId == 0) {
        if (!mounted) return;
        setState(() {
          _orders = [];
          if (showLoading) {
            _isLoading = false;
          }
        });
        return;
      }

      if (showLoading) {
        setState(() {
          _isLoading = true;
        });
      }

      final orders = await ApiService.getOrders(userId: userId);
      if (!mounted) return;

      setState(() {
        _orders = orders;
        if (showLoading) {
          _isLoading = false;
        }
      });
    } catch (e) {
      debugPrint('Ошибка загрузки заказов: $e');
      if (!mounted) return;
      setState(() {
        if (showLoading) {
          _isLoading = false;
        }
      });
    }
  }

  @override
  Future<void> onAutoRefresh() async {
    if (_isLoading || _acceptingOrders.isNotEmpty || _cancelingOrders.isNotEmpty) {
      return;
    }
    await _loadOrders(showLoading: false);
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _orders
        .where((order) => _isActiveStatus(order.status))
        .toList();
    final historyCount = _orders
        .where(
          (order) =>
              _isAcceptedStatus(order.status) || _isCancelledStatus(order.status),
        )
        .length;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Мои заказы',
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(context, activeOrders, historyCount),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Order> activeOrders,
    int historyCount,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6288D5)),
      );
    }

    return Column(
      children: [
        _buildHistoryButton(context, historyCount),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF6288D5),
            onRefresh: _loadOrders,
            child: _buildOrdersList(activeOrders),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Text(
              'Нету заказов',
              style: TextStyle(color: _mutedText, fontSize: 15),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildHistoryButton(BuildContext context, int historyCount) {
    final label = historyCount > 0
        ? 'История заказов ($historyCount)'
        : 'История заказов';

    final historyBorderColor = _brandBlue.withValues(
      alpha: _isDark ? 0.98 : 0.9,
    );
    final historyBackground = _brandBlue.withValues(alpha: _isDark ? 0.1 : 0.04);

    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryPage(),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                color: historyBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: historyBorderColor,
                  width: 1.4,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: historyBorderColor,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: historyBorderColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _normalizeStatus(String status) {
    return status.trim().toLowerCase();
  }

  bool _isDeliveredStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == 'доставлен' ||
        normalized == 'доставлено' ||
        normalized == 'delivered';
  }

  bool _isInTransitStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains('в пути') ||
        normalized == 'in transit' ||
        normalized == 'on the way';
  }

  bool _isProcessingStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains('собира') ||
        normalized == 'processing' ||
        normalized == 'assembling';
  }

  bool _isAcceptedStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == 'принят' ||
        normalized == 'принята' ||
        normalized == 'принято' ||
        normalized == 'приняты' ||
        normalized == 'accepted' ||
        normalized == 'received';
  }

  bool _isCancelledStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains('отмен') ||
        normalized == 'cancelled' ||
        normalized == 'canceled';
  }

  bool _isWithinCancellationWindow(Order order) {
    return DateTime.now().isBefore(order.date.add(_orderCancellationWindow));
  }

  Duration _remainingCancellationTime(Order order) {
    final remaining = order.date.add(_orderCancellationWindow).difference(
      DateTime.now(),
    );
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool _canCancelOrder(Order order) {
    if (_isAcceptedStatus(order.status) || _isCancelledStatus(order.status)) {
      return false;
    }
    return _isWithinCancellationWindow(order);
  }

  bool _isActiveStatus(String status) {
    return _isInTransitStatus(status) ||
        _isProcessingStatus(status) ||
        _isDeliveredStatus(status);
  }

  Color _statusTextColor(String status) {
    if (_isDeliveredStatus(status)) {
      return const Color(0xFF4CAF50);
    }
    if (_isInTransitStatus(status)) {
      return const Color(0xFF6288D5);
    }
    if (_isProcessingStatus(status)) {
      return const Color(0xFFF59E0B);
    }
    if (_isAcceptedStatus(status)) {
      return const Color(0xFF2E7D32);
    }
    if (_isCancelledStatus(status)) {
      return const Color(0xFFD32F2F);
    }
    return const Color(0xFFFF9800);
  }

  Color _statusBackgroundColor(String status) {
    final base = _statusTextColor(status);
    return base.withValues(alpha: _isDark ? 0.22 : 0.12);
  }

  Widget _buildOrderCard(Order order) {
    final totalAmount = _formatMoney(order.totalAmount);
    final isAccepting = _acceptingOrders.contains(order.id);
    final isCancelling = _cancelingOrders.contains(order.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок заказа
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заказ ${order.id}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.date),
                      style: TextStyle(fontSize: 14, color: _mutedText),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBackgroundColor(order.status),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _statusTextColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: _borderColor),

          // Список товаров
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            itemBuilder: (context, index) {
              return _buildOrderItem(
                order.items[index],
                order.status,
                isAccepting: isAccepting || isCancelling,
              );
            },
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: _borderColor),
          ),

          _buildOrderActions(
            order,
            isAccepting: isAccepting,
            isCancelling: isCancelling,
          ),

          Divider(height: 1, color: _borderColor),

          // Итого
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Общая сумма:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$totalAmount ₸',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    OrderItem item,
    String orderStatus, {
    required bool isAccepting,
  }) {
    final canReceive = _isDeliveredStatus(orderStatus) && !isAccepting;
    final priceLabel = _formatMoney(item.price);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Изображение товара
          _buildOrderImage(item),

          const SizedBox(width: 12),

          // Информация о товаре
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '$priceLabel ₸',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Text(
                        '${item.quantity} шт',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Чекбокс подтверждения
          SizedBox(
            width: 118,
            child: Column(
              children: [
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: item.isReceived,
                    onChanged: canReceive
                        ? (bool? value) {
                            setState(() {
                              item.isReceived = value ?? false;
                            });
                          }
                        : null,
                    activeColor: _brandBlue,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(color: _borderColor),
                    visualDensity: VisualDensity.comfortable,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return _borderColor;
                      }
                      if (states.contains(WidgetState.selected)) {
                        return _brandBlue;
                      }
                      return Colors.transparent;
                    }),
                  ),
                ),
                Text(
                  'Принят',
                  style: TextStyle(
                    fontSize: 13,
                    color: canReceive ? _colorScheme.onSurface : _mutedText,
                  ),
                ),
                if (!canReceive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 15, color: _mutedText),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'После доставки',
                            style: TextStyle(
                              fontSize: 11,
                              color: _mutedText,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderImage(OrderItem item) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: _colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildOrderImageContent(item),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${item.quantity} шт.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderImageContent(OrderItem item) {
    final url = item.imageUrl.trim();
    if (url.isEmpty) {
      return _buildOrderImageFallback();
    }
    if (_isNetworkUrl(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildOrderImageFallback(),
      );
    }
    final assetPath = url.startsWith('assets/') ? url : 'assets/$url';
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildOrderImageFallback(),
    );
  }

  Widget _buildOrderImageFallback() {
    return Image.asset(
      _fallbackOrderImage,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(Icons.local_drink, size: 32, color: _mutedText),
        );
      },
    );
  }

  bool _isNetworkUrl(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  Widget _buildOrderActions(
    Order order, {
    required bool isAccepting,
    required bool isCancelling,
  }) {
    final canReceive = _isDeliveredStatus(order.status);
    final canCancel = _canCancelOrder(order);
    final isBusy = isAccepting || isCancelling;

    if (!canReceive) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 7, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canCancel)
              Row(
                children: [
                  _buildCancelOrderButton(
                    order,
                    isBusy: isBusy,
                    isCancelling: isCancelling,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, size: 18, color: _mutedText),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Принять можно после доставки',
                            style: TextStyle(fontSize: 14, color: _mutedText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: _mutedText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Принять можно после доставки',
                      style: TextStyle(fontSize: 14, color: _mutedText),
                    ),
                  ),
                ],
              ),
            if (!canCancel) ...[
              const SizedBox(height: 8),
              _buildCancelInfo(order),
            ],
          ],
        ),
      );
    }

    final allSelected = _areAllItemsSelected(order);
    final selectLabel = allSelected ? 'Снять все' : 'Выбрать все';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canCancel)
            _buildCancelOrderButton(
              order,
              isBusy: isBusy,
              isCancelling: isCancelling,
            ),
          if (canCancel) const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: order.items.isEmpty || isBusy
                    ? null
                    : () => _toggleSelectAll(order),
                icon: Icon(
                  allSelected ? Icons.remove_done : Icons.done_all,
                  size: 20,
                ),
                label: Text(selectLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _brandBlue,
                  side: BorderSide(color: _borderColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: order.items.isEmpty || isBusy
                      ? null
                      : () => _confirmAcceptOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isAccepting ? 'Принимаем...' : 'Принять',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!canCancel) ...[
            const SizedBox(height: 8),
            _buildCancelInfo(order),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelOrderButton(
    Order order, {
    required bool isBusy,
    required bool isCancelling,
  }) {
    return OutlinedButton.icon(
      onPressed: isBusy ? null : () => _confirmCancelOrder(order),
      icon: const Icon(Icons.cancel_outlined, size: 18),
      label: Text(isCancelling ? 'Отменяем...' : 'Отменить заказ'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD32F2F),
        side: const BorderSide(color: Color(0xFFD32F2F)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildCancelInfo(Order order) {
    final remaining = _remainingCancellationTime(order);
    final hasTime = remaining > Duration.zero;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final timeLabel = hours > 0
        ? '$hours ч ${minutes.toString().padLeft(2, '0')} мин'
        : '${remaining.inMinutes} мин';

    return Row(
      children: [
        Icon(Icons.schedule, size: 16, color: _mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            hasTime
                ? 'Отмена доступна ещё $timeLabel'
                : 'Отмена доступна только в течение первого часа',
            style: TextStyle(fontSize: 12, color: _mutedText),
          ),
        ),
      ],
    );
  }

  void _toggleSelectAll(Order order) {
    if (order.items.isEmpty) return;
    final nextValue = !_areAllItemsSelected(order);
    setState(() {
      for (final item in order.items) {
        item.isReceived = nextValue;
      }
    });
  }

  Future<void> _confirmAcceptOrder(Order order) async {
    if (!_areAllItemsSelected(order)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отметьте все товары перед подтверждением.'),
        ),
      );
      return;
    }

    final confirmed = await _showAcceptDialog(order);
    if (!confirmed) {
      return;
    }

    await _acceptOrder(order);
  }

  Future<bool> _showAcceptDialog(Order order) async {
    final totalAmount = _formatMoney(order.totalAmount);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Подтвердите принятие',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Заказ ${order.id} на сумму $totalAmount ₸',
                  style: TextStyle(fontSize: 14, color: _mutedText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _colorScheme.onSurface,
                          side: BorderSide(color: _borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Принять'),
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
    return result ?? false;
  }

  Future<void> _acceptOrder(Order order) async {
    if (order.items.isEmpty) return;
    if (_acceptingOrders.contains(order.id)) return;

    setState(() {
      _acceptingOrders.add(order.id);
    });

    try {
      final updatedOrder = await ApiService.acceptOrder(order.id);
      if (!mounted) return;
      setState(() {
        _orders = _orders
            .map(
              (existing) =>
                  existing.id == updatedOrder.id ? updatedOrder : existing,
            )
            .toList();
        _acceptingOrders.remove(order.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заказ принят.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _acceptingOrders.remove(order.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось принять заказ. Попробуйте еще раз.'),
        ),
      );
    }
  }

  Future<void> _confirmCancelOrder(Order order) async {
    if (!_canCancelOrder(order)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отмена доступна только в течение первого часа.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Отменить заказ?'),
          content: const Text(
            'Заказ будет отменён, а товары вернутся на склад.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Нет'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Отменить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _cancelOrder(order);
  }

  Future<void> _cancelOrder(Order order) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сессия истекла. Войдите снова.')),
      );
      return;
    }
    if (_cancelingOrders.contains(order.id)) {
      return;
    }

    setState(() {
      _cancelingOrders.add(order.id);
    });

    try {
      final updatedOrder = await ApiService.cancelOrder(order.id, userId: userId);
      if (!mounted) return;
      setState(() {
        _orders = _orders
            .map(
              (existing) =>
                  existing.id == updatedOrder.id ? updatedOrder : existing,
            )
            .toList();
        _cancelingOrders.remove(order.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заказ отменён.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cancelingOrders.remove(order.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cancelOrderErrorMessage(e))),
      );
    }
  }

  String _cancelOrderErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('первого часа')) {
      return 'Отмена доступна только в течение первого часа.';
    }
    if (message.contains('уже отмен')) {
      return 'Этот заказ уже отменён.';
    }
    if (message.contains('подтвержден')) {
      return 'Подтверждённый заказ отменить нельзя.';
    }
    return 'Не удалось отменить заказ. Попробуйте ещё раз.';
  }

  bool _areAllItemsSelected(Order order) {
    if (order.items.isEmpty) return false;
    return order.items.every((item) => item.isReceived);
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(date.year, date.month, date.day);

    if (orderDay == today) {
      return 'Сегодня, ${date.day} ${months[date.month - 1]}';
    } else if (orderDay == today.subtract(const Duration(days: 1))) {
      return 'Вчера, ${date.day} ${months[date.month - 1]}';
    } else if (orderDay == today.add(const Duration(days: 1))) {
      return 'Завтра, ${date.day} ${months[date.month - 1]}';
    } else {
      return '${date.day} ${months[date.month - 1]}';
    }
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
}
