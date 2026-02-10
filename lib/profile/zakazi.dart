import 'package:flutter/material.dart';
import '../models/order.dart';
import '../pages/order_history_page.dart';
import '../services/api_service.dart';
import '../widgets/main_bottom_nav.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  static const Color _brandBlue = Color(0xFF6288D5);
  static const String _fallbackOrderImage = 'assets/coca_cola.jpeg';

  List<Order> _orders = [];
  bool _isLoading = true;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;
  Color get _shadowColor =>
      _isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.05);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final orders = await ApiService.getOrders();

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('MyOrdersPage load error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders =
        _orders.where((order) => _isActiveStatus(order.status)).toList();
    final historyCount =
        _orders.where((order) => _isAcceptedStatus(order.status)).length;

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

    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
              );
            },
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6288D5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6288D5),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Color(0xFF6288D5)),
                ],
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
    return const Color(0xFFFF9800);
  }

  Color _statusBackgroundColor(String status) {
    final base = _statusTextColor(status);
    return base.withValues(alpha: _isDark ? 0.22 : 0.12);
  }

  Widget _buildOrderCard(Order order) {
    final totalAmount = _formatMoney(order.totalAmount);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заказ ${order.id}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: _mutedText,
                      ),
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
                      fontSize: 12,
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
              return _buildOrderItem(order.items[index], order.status);
            },
            separatorBuilder: (context, index) => Divider(height: 1, color: _borderColor),
          ),

          _buildOrderActions(order),

          Divider(height: 1, color: _borderColor),

          // Итого
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Общая сумма:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$totalAmount ₸',
                  style: TextStyle(
                    fontSize: 18,
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

  Widget _buildOrderItem(OrderItem item, String orderStatus) {
    final canReceive = _isDeliveredStatus(orderStatus);
    final volumeLabel =
        item.volume.isNotEmpty ? item.volume : '${item.quantity} шт.';
    final priceLabel = _formatMoney(item.price);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение товара
          _buildOrderImage(item),

          const SizedBox(width: 12),

          // Информация о товаре
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  volumeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: _mutedText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$priceLabel ₸ x ${item.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Чекбокс подтверждения
          SizedBox(
            width: 104,
            child: Column(
              children: [
                Transform.scale(
                  scale: 1.15,
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
                    visualDensity: VisualDensity.standard,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    fillColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return _borderColor;
                      }
                      if (states.contains(MaterialState.selected)) {
                        return _brandBlue;
                      }
                      return Colors.transparent;
                    }),
                  ),
                ),
                Text(
                  'Принят',
                  style: TextStyle(
                    fontSize: 12,
                    color: canReceive ? _colorScheme.onSurface : _mutedText,
                  ),
                ),
                if (!canReceive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: _mutedText),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'После доставки',
                            style: TextStyle(
                              fontSize: 10,
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
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: _colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildOrderImageContent(item),
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
        errorBuilder: (context, error, stackTrace) => _buildOrderImageFallback(),
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

  Widget _buildOrderActions(Order order) {
    final canReceive = _isDeliveredStatus(order.status);
    if (!canReceive) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 16, color: _mutedText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Принять можно после доставки',
                style: TextStyle(
                  fontSize: 13,
                  color: _mutedText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final allSelected = _areAllItemsSelected(order);
    final selectLabel = allSelected ? 'Снять все' : 'Выбрать все';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: order.items.isEmpty ? null : () => _toggleSelectAll(order),
            icon: Icon(
              allSelected ? Icons.remove_done : Icons.done_all,
              size: 18,
            ),
            label: Text(selectLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandBlue,
              side: BorderSide(color: _borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: order.items.isEmpty ? null : () => _acceptOrder(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Принять',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
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

  void _acceptOrder(Order order) {
    if (order.items.isEmpty) return;
    setState(() {
      for (final item in order.items) {
        item.isReceived = true;
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Товары отмечены как принятые.')),
    );
  }

  bool _areAllItemsSelected(Order order) {
    if (order.items.isEmpty) return false;
    return order.items.every((item) => item.isReceived);
  }

  String _formatDate(DateTime date) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
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

