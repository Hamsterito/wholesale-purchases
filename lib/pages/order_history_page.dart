import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../widgets/main_bottom_nav.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  static const _periodDay = 'За день';
  static const _periodWeek = 'Неделя';
  static const _periodMonth = 'Месяц';
  static const _periodQuarter = 'Квартал';
  static const _periodCustom = '__custom__';

  String _selectedPeriod = _periodDay;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  final Map<int, bool> _expandedItems = {};
  List<Order> _orders = [];
  bool _isLoading = true;
  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;

  @override
  void initState() {
    super.initState();
    _applyPeriodSelection(_selectedPeriod, notify: false);
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
      debugPrint('OrderHistoryPage load error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'История заказов',
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Очистить все',
              style: TextStyle(fontSize: 14, color: Color(0xFF6288D5)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          const SizedBox(height: 8),
          _buildPeriodTabs(),
          Expanded(child: _buildHistoryContent()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Период',
            style: TextStyle(
              fontSize: 14,
              color: _colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDateBox(_rangeStart, onTap: () => _pickDateRange()),
              const SizedBox(width: 12),
              _buildDateBox(_rangeEnd, onTap: () => _pickDateRange()),
              const SizedBox(width: 12),
              _buildIconBox(onTap: () => _pickDateRange()),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _exportToExcel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6288D5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Экспортировать в .excel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white ,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(DateTime date, {VoidCallback? onTap}) {
    final text = _formatShortDate(date);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: _colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox({VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.tune, size: 20, color: _colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPeriodTab(_periodDay),
            const SizedBox(width: 16),
            _buildPeriodTab(_periodWeek),
            const SizedBox(width: 16),
            _buildPeriodTab(_periodMonth),
            const SizedBox(width: 16),
            _buildPeriodTab(_periodQuarter),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String text) {
    final isSelected = _selectedPeriod == text;
    return GestureDetector(
      onTap: () => _applyPeriodSelection(text),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? const Color(0xFF6288D5) : _mutedText,
        ),
      ),
    );
  }

  void _applyPeriodSelection(String period, {bool notify = true}) {
    final end = _startOfDay(DateTime.now());
    DateTime start;
    switch (period) {
      case _periodWeek:
        start = end.subtract(const Duration(days: 6));
        break;
      case _periodMonth:
        start = end.subtract(const Duration(days: 29));
        break;
      case _periodQuarter:
        start = end.subtract(const Duration(days: 89));
        break;
      case _periodDay:
      default:
        start = end;
        break;
    }

    if (notify) {
      setState(() {
        _selectedPeriod = period;
        _rangeStart = start;
        _rangeEnd = end;
      });
    } else {
      _selectedPeriod = period;
      _rangeStart = start;
      _rangeEnd = end;
    }
  }

  Future<void> _pickDateRange() async {
    final initialStart = _rangeStart;
    final initialEnd = _rangeEnd.isBefore(_rangeStart) ? _rangeStart : _rangeEnd;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _selectedPeriod = _periodCustom;
      _rangeStart = _startOfDay(picked.start);
      _rangeEnd = _startOfDay(picked.end);
    });
  }

  Widget _buildHistoryContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6288D5)),
      );
    }

    final orders = _filteredOrders();

    return RefreshIndicator(
      color: const Color(0xFF6288D5),
      onRefresh: _loadOrders,
      child: orders.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Text(
                    'Нету заказов',
                    style: TextStyle(color: _mutedText, fontSize: 15),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) => _buildOrderItem(orders[index], index),
            ),
    );
  }

  Widget _buildOrderItem(Order order, int index) {
    final isExpanded = _expandedItems[index] ?? false;
    final statusColor = _statusColor(order.status);
    final totalAmount = _formatMoney(order.totalAmount);
    final dateLabel = _formatShortDate(order.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedItems[index] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Дата: $dateLabel - ',
                            style: TextStyle(
                              fontSize: 14,
                              color: _colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: 'Заказ №${order.id}: $totalAmount ₸',
                            style: TextStyle(
                              fontSize: 14,
                              color: _colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.check_circle, color: statusColor, size: 16),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: _mutedText,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildExpandedDetails(order),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(Order order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: _borderColor),
          const SizedBox(height: 12),
          _buildOrderDetail('Статус:', order.status, _statusColor(order.status)),
          const SizedBox(height: 8),
          _buildOrderDetail('Дата заказа:', _formatShortDate(order.date), null),
          const SizedBox(height: 8),
          _buildOrderDetail('Товары:', _formatItems(order.items), null),
        ],
      ),
    );
  }

  String _normalizeStatus(String status) {
    return status.trim().toLowerCase();
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

  bool _isWithinSelectedRange(DateTime date) {
    final day = _startOfDay(date);
    if (day.isBefore(_rangeStart)) {
      return false;
    }
    if (day.isAfter(_rangeEnd)) {
      return false;
    }
    return true;
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<Order> _filteredOrders() {
    return _orders
        .where((order) => _isAcceptedStatus(order.status))
        .where((order) => _isWithinSelectedRange(order.date))
        .toList();
  }

  Future<void> _exportToExcel() async {
    final orders = _filteredOrders();
    final startLabel = _formatShortDate(_rangeStart);
    final endLabel = _formatShortDate(_rangeEnd);

    final buffer = StringBuffer()
      ..writeln('Дата,Заказ,Сумма,Статус,Товары');
    for (final order in orders) {
      buffer.writeln(
        [
          _csvEscape(_formatShortDate(order.date)),
          _csvEscape(order.id),
          _csvEscape(order.totalAmount.toString()),
          _csvEscape(order.status),
          _csvEscape(_formatItems(order.items)),
        ].join(','),
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Экспортировано $startLabel – $endLabel: ${orders.length} заказов (в буфер обмена).',
        ),
      ),
    );
  }

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  void _resetFilters() {
    setState(() {
      _expandedItems.clear();
      _applyPeriodSelection(_periodDay, notify: false);
    });
  }

  Color _statusColor(String status) {
    if (_isAcceptedStatus(status)) {
      return const Color(0xFF2E7D32);
    }
    final normalized = _normalizeStatus(status);
    if (normalized == 'доставлен' ||
        normalized == 'доставлено' ||
        normalized == 'delivered') {
      return const Color(0xFF4CAF50);
    }
    return const Color(0xFFFF9800);
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
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

  String _formatItems(List<OrderItem> items) {
    if (items.isEmpty) {
      return 'Нет товаров';
    }
    return items
        .map((item) => '${item.name} ${item.quantity} шт')
        .join(', ');
  }

  Widget _buildOrderDetail(String label, String value, Color? color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: _mutedText)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color ?? _colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
