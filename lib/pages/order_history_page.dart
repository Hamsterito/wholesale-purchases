import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../utils/auto_refresh.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/date_range_picker_dialog.dart' as custom_picker;
import 'dart:convert';
import 'package:file_saver/file_saver.dart';
// ignore: deprecated_member_use
import 'dart:html' as html;

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with AutoRefreshMixin<OrderHistoryPage> {
  static const Color _brandBlue = Color(0xFF6288D5);
  static const _periodDay = 'За день';
  static const _periodWeek = 'Неделя';
  static const _periodMonth = 'Месяц';
  static const _periodQuarter = 'Квартал';
  static const _periodCustom = '__custom__';

  String _selectedPeriod = _periodDay;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  final Map<String, bool> _expandedItems = {};
  List<Order> _orders = [];
  bool _isLoading = true;
  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;

  @override
  void initState() {
    super.initState();
    _applyPeriodSelection(_selectedPeriod, notify: false);
    _loadOrders();
    startAutoRefresh();
  }

  Future<void> _loadOrders({
    bool showLoading = true,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

      final orders = await ApiService.getOrders(
        userId: userId,
        startDate: startDate ?? _rangeStart,
        endDate: endDate ?? _rangeEnd,
      );
      if (!mounted) return;

      setState(() {
        _orders = orders;
        if (showLoading) {
          _isLoading = false;
        }
      });
    } catch (e) {
      debugPrint('Ошибка загрузки истории заказов: $e');
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
    if (_isLoading) return;
    await _loadOrders(showLoading: false);
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
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
          icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
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
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatShortDate(_rangeStart)} - ${_formatShortDate(_rangeEnd)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: _colorScheme.onSurface,
                  ),
                ],
              ),
            ),
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
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
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
      _loadOrders();
    } else {
      _selectedPeriod = period;
      _rangeStart = start;
      _rangeEnd = end;
    }
  }

  Future<void> _pickDateRange() async {
    final initialRange = DateTimeRange(start: _rangeStart, end: _rangeEnd);
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) =>
          custom_picker.CustomDateRangePickerDialog(initialRange: initialRange),
    );
    if (!mounted || picked == null) {
      return;
    }
    final newStart = _startOfDay(picked.start);
    final newEnd = _startOfDay(picked.end);
    setState(() {
      _selectedPeriod = _periodCustom;
      _rangeStart = newStart;
      _rangeEnd = newEnd;
    });
    _loadOrders(startDate: newStart, endDate: newEnd);
  }

  Widget _buildHistoryContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _brandBlue));
    }

    final orders = _orders;

    return RefreshIndicator(
      color: _brandBlue,
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              itemCount: orders.length,
              itemBuilder: (context, index) => _buildOrderItem(orders[index]),
            ),
    );
  }

  Widget _buildOrderItem(Order order) {
    final isExpanded = _expandedItems[order.id] ?? false;
    final statusColor = _statusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: _colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('order-history-${order.id}'),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedItems[order.id] = expanded;
            });
          },
          tilePadding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: statusColor,
          collapsedIconColor: _mutedText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: _buildHistoryTitle(order),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildHistoryMetaBadges(order, statusColor),
          ),
          children: [
            _buildExpandedDetails(order),
            const SizedBox(height: 12),
            _buildItemsBlock(order),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTitle(Order order) {
    final amountText = '${_formatMoney(order.totalAmount)} ₸';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Заказ №${order.id}',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _buildPriceBadge(amountText),
      ],
    );
  }

  Widget _buildPriceBadge(String amountText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _brandBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brandBlue.withValues(alpha: 0.92)),
      ),
      child: Text(
        amountText,
        textAlign: TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildHistoryMetaBadges(Order order, Color statusColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetaBadge(
          icon: Icons.calendar_today_rounded,
          text: _formatShortDate(order.date),
        ),
        _buildMetaBadge(
          icon: Icons.view_agenda_outlined,
          text: '${order.items.length} поз.',
        ),
        _buildMetaBadge(
          icon: Icons.shopping_cart_outlined,
          text: '${order.totalUnits} шт.',
        ),
        _buildMetaBadge(
          icon: _isCancelledStatus(order.status)
              ? Icons.cancel_outlined
              : Icons.verified_rounded,
          text: order.status,
          textColor: statusColor,
          backgroundColor: statusColor.withValues(alpha: 0.12),
          borderColor: statusColor.withValues(alpha: 0.34),
        ),
      ],
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String text,
    Color? textColor,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            _colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? _borderColor.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor ?? _mutedText),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(Order order) {
    final statusColor = _statusColor(order.status);
    final hasAddress = order.deliveryAddress.trim().isNotEmpty;
    final canAccept =
        !_isAcceptedStatus(order.status) && !_isCancelledStatus(order.status);
    final effectiveReceived = _isAcceptedStatus(order.status)
        ? order.items.length
        : order.receivedItemsCount;
    final receivedSummary = order.items.isEmpty
        ? 'нет товаров'
        : '$effectiveReceived/${order.items.length} поз.';

    final children = <Widget>[
      _buildOrderDetailRow(
        icon: _isCancelledStatus(order.status)
            ? Icons.cancel_outlined
            : Icons.verified_rounded,
        label: 'Статус',
        value: order.status,
        valueColor: statusColor,
      ),
      const SizedBox(height: 10),
      _buildOrderDetailRow(
        icon: Icons.calendar_month_rounded,
        label: 'Дата заказа',
        value: _formatShortDate(order.date),
      ),
      const SizedBox(height: 10),
      _buildOrderDetailRow(
        icon: Icons.list_alt_rounded,
        label: 'Товарных позиций',
        value: '${order.items.length}',
      ),
      const SizedBox(height: 10),
      _buildOrderDetailRow(
        icon: Icons.widgets_outlined,
        label: 'Единиц товара',
        value: '${order.totalUnits} шт.',
      ),
      const SizedBox(height: 10),
      _buildOrderDetailRow(
        icon: Icons.task_alt_rounded,
        label: 'Подтверждено',
        value: receivedSummary,
      ),
    ];

    if (hasAddress) {
      children.addAll([
        const SizedBox(height: 10),
        Divider(height: 1, color: _borderColor.withValues(alpha: 0.8)),
        const SizedBox(height: 10),
        _buildOrderDetailRow(
          icon: Icons.location_on_outlined,
          label: 'Адрес доставки',
          value: order.deliveryAddress.trim(),
          multilineValue: true,
        ),
      ]);
    }

    if (canAccept) {
      children.addAll([
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await ApiService.acceptOrder(order.id.toString());
              await _loadOrders();
            },
            child: Text('Подтвердить получение'),
          ),
        ),
      ]);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildOrderDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool multilineValue = false,
  }) {
    final labelStyle = TextStyle(
      color: _mutedText,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    final valueStyle = TextStyle(
      color: valueColor ?? _colorScheme.onSurface,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    );

    if (multilineValue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _mutedText),
              const SizedBox(width: 6),
              Text(label, style: labelStyle),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: valueStyle),
        ],
      );
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: _mutedText),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildItemsBlock(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _colorScheme.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Товары в заказе',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (order.items.isEmpty)
            Text('Список товаров пуст', style: TextStyle(color: _mutedText))
          else
            ...order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final lineTotal = item.price * item.quantity;
              final supplierName = item.supplierName.trim();

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == order.items.length - 1 ? 0 : 10,
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: _buildItemImage(item),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              if (supplierName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Поставщик: $supplierName',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _mutedText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatMoney(lineTotal)} ₸',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (index != order.items.length - 1) ...[
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: _borderColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildItemImage(OrderItem item) {
    var raw = item.imageUrl.trim();
    if (raw.isEmpty) return _buildItemImageFallback();

    if (raw.startsWith('base64:') || raw.startsWith('data:image')) {
      try {
        String base64Part = raw;

        if (raw.startsWith('data:image')) {
          final comma = raw.indexOf(',');
          if (comma != -1) base64Part = raw.substring(comma + 1);
        } else {
          base64Part = raw.substring('base64:'.length);

          final colon = base64Part.indexOf(':');
          if (colon != -1) {
            base64Part = base64Part.substring(colon + 1);
          }
        }

        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildItemImageFallback(),
        );
      } catch (_) {
        return _buildItemImageFallback();
      }
    }

    if (raw.contains(',')) {
      raw = raw
          .split(',')
          .map((e) => e.trim())
          .firstWhere((e) => e.isNotEmpty, orElse: () => '');
      if (raw.isEmpty) return _buildItemImageFallback();
    }

    if (_isNetworkUrl(raw)) {
      return Image.network(
        raw,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildItemImageFallback(),
      );
    }

    // 🔥 если это просто base64 без префикса
    if (raw.isNotEmpty && !raw.startsWith('assets/')) {
      try {
        final bytes = base64Decode(raw);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildItemImageFallback(),
        );
      } catch (_) {}
    }

    if (raw.isEmpty) return _buildItemImageFallback();

    final assetPath = raw.startsWith('assets/') ? raw : 'assets/$raw';
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildItemImageFallback(),
    );
  }

  Widget _buildItemImageFallback() {
    return Container(
      color: _colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.shopping_bag_outlined, size: 22, color: _mutedText),
    );
  }

  bool _isNetworkUrl(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
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

  bool _isCancelledStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains('отмен') ||
        normalized == 'cancelled' ||
        normalized == 'canceled';
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _exportToExcel() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Необходимо авторизоваться')),
      );
      return;
    }

    try {
      final bytes = await ApiService.exportOrdersExcel(
        userId: userId,
        startDate: _rangeStart,
        endDate: _rangeEnd,
      );

      final fileName =
          'orders_export_${_formatShortDate(_rangeStart)}_to_${_formatShortDate(_rangeEnd)}.xlsx';

      if (kIsWeb) {
        // Для веба используем загрузку через браузер
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Для мобильных устройств используем file_saver
        await FileSaver.instance.saveAs(
          name: fileName,
          bytes: bytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Файл сохранён')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
    }
  }

  Color _statusColor(String status) {
    if (_isAcceptedStatus(status)) {
      return const Color(0xFF2E7D32);
    }
    if (_isCancelledStatus(status)) {
      return const Color(0xFFD32F2F);
    }
    final normalized = _normalizeStatus(status);
    if (normalized == 'доставлен' ||
        normalized == 'доставлено' ||
        normalized == 'delivered') {
      return const Color(0xFF4CAF50);
    }
    return const Color(0xFFFF9800);
  }

  String _formatMoney(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final positionFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(' ');
      }
    }
    final formatted = buffer.toString();
    return value < 0 ? '-$formatted' : formatted;
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}
