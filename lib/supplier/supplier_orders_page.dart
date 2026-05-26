import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_project/widgets/app_message_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/supplier_order.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../theme/app_color_palette.dart';
import '../utils/auto_refresh.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/date_range_picker_dialog.dart' as custom_picker;
import '../widgets/smart_image.dart';

enum _SupplierOrderTab { active, history }

class SupplierOrdersPage extends StatefulWidget {
  const SupplierOrdersPage({super.key});

  @override
  State<SupplierOrdersPage> createState() => _SupplierOrdersPageState();
}

class _SupplierOrdersPageState extends State<SupplierOrdersPage>
    with AutoRefreshMixin<SupplierOrdersPage> {
  static const List<String> _supplierFlowStatuses = [
    'Собирается',
    'В пути',
    'Доставлен',
  ];

  static const _periodDay = 'За день';
  static const _periodWeek = 'Неделя';
  static const _periodMonth = 'Месяц';
  static const _periodQuarter = 'Квартал';
  static const _periodCustom = '__custom__';

  List<SupplierOrder> _orders = [];
  // Кэш разделения _orders на активные/историю - пересоздаётся лениво
  // в геттерах, инвалидируется в _invalidateOrdersCache при любой
  // мутации _orders. Иначе на каждом ребилде делаем два прохода
  // по списку.
  List<SupplierOrder>? _cachedActiveOrders;
  List<SupplierOrder>? _cachedHistoryOrders;
  // История дополнительно фильтруется по диапазону дат на клиенте,
  // активные показываем все - для них фильтр по датам бессмысленен.
  List<SupplierOrder>? _cachedFilteredHistoryOrders;
  late DateTime _historyRangeStart;
  late DateTime _historyRangeEnd;
  String _selectedPeriod = _periodMonth;
  bool _isExportingHistory = false;
  bool _isLoading = true;
  String? _error;
  final Set<String> _updatingOrderIds = {};
  _SupplierOrderTab _selectedTab = _SupplierOrderTab.active;

  void _invalidateOrdersCache() {
    _cachedActiveOrders = null;
    _cachedHistoryOrders = null;
    _cachedFilteredHistoryOrders = null;
  }

  int? get _userId => AuthStorage.userId;

  @override
  void initState() {
    super.initState();
    _applyPeriodSelection(_selectedPeriod, notify: false);
    _loadOrders();
    startAutoRefresh();
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    final userId = _userId;
    if (userId == null || userId == 0) {
      setState(() {
        _error = 'Вы не авторизованы. Пожалуйста, войдите.';
        _isLoading = false;
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final orders = await ApiService.getSupplierOrders(userId: userId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _invalidateOrdersCache();
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!showLoading) return;
      setState(() => _error = 'Не удалось загрузить заказы');
    }

    if (!mounted || !showLoading) return;
    setState(() => _isLoading = false);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
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

  String _normalizeStatus(String status) {
    return status.trim().toLowerCase();
  }

  bool _isAssemblingStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains('собира') ||
        normalized == 'assembling' ||
        normalized == 'processing';
  }

  bool _isInTransitStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains('в пути') ||
        normalized == 'in transit' ||
        normalized == 'on the way';
  }

  bool _isDeliveredStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains('достав') || normalized == 'delivered';
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

  int _statusStep(String status) {
    if (_isAssemblingStatus(status)) return 0;
    if (_isInTransitStatus(status)) return 1;
    if (_isDeliveredStatus(status)) return 2;
    if (_isAcceptedStatus(status)) return 3;
    if (_isCancelledStatus(status)) return 4;
    return -1;
  }

  String _statusLabel(String status) {
    if (_isAssemblingStatus(status)) return 'Собирается';
    if (_isInTransitStatus(status)) return 'В пути';
    if (_isDeliveredStatus(status)) return 'Доставлен';
    if (_isAcceptedStatus(status)) return 'Принят';
    if (_isCancelledStatus(status)) return 'Отменен';
    return status;
  }

  Color _statusColor(String status) {
    final palette = AppColorPalette.of(context);
    if (_isAssemblingStatus(status)) return palette.statusPending;
    if (_isInTransitStatus(status)) return palette.statusShipped;
    if (_isDeliveredStatus(status)) return palette.statusDelivered;
    if (_isAcceptedStatus(status)) return palette.statusDelivered;
    if (_isCancelledStatus(status)) return palette.statusCancelled;
    return palette.muted;
  }

  IconData _statusIcon(String status) {
    if (_isAssemblingStatus(status)) return Icons.inventory_2_outlined;
    if (_isInTransitStatus(status)) return Icons.local_shipping_outlined;
    if (_isDeliveredStatus(status)) return Icons.check_circle_outline_rounded;
    if (_isAcceptedStatus(status)) return Icons.verified_rounded;
    if (_isCancelledStatus(status)) return Icons.cancel_outlined;
    return Icons.info_outline_rounded;
  }

  double _statusProgressValue(String status) {
    final step = _statusStep(status);
    if (step < 0) return 0;
    if (step == 0) return 0.34;
    if (step == 1) return 0.67;
    return 1;
  }

  bool _canMoveToStatus(String currentStatus, String targetStatus) {
    final currentStep = _statusStep(currentStatus);
    final targetStep = _statusStep(targetStatus);
    if (targetStep < 0 || targetStep > 2) {
      return false;
    }
    if (currentStep < 0) {
      return true;
    }
    if (currentStep >= 3) {
      return false;
    }
    if (targetStep == currentStep) {
      return true;
    }
    return targetStep == currentStep + 1;
  }

  bool _isHistoryStatus(String status) {
    return _isAcceptedStatus(status) || _isCancelledStatus(status);
  }

  List<SupplierOrder> get _activeOrders {
    return _cachedActiveOrders ??= _orders
        .where((order) => !_isHistoryStatus(order.status))
        .toList(growable: false);
  }

  List<SupplierOrder> get _historyOrders {
    return _cachedHistoryOrders ??= _orders
        .where((order) => _isHistoryStatus(order.status))
        .toList(growable: false);
  }

  /// История, дополнительно ограниченная диапазоном дат, выбранным
  /// поставщиком. Используется и в UI, и в счётчике вкладки «История»,
  /// чтобы число рядом с названием соответствовало видимому списку.
  List<SupplierOrder> get _filteredHistoryOrders {
    return _cachedFilteredHistoryOrders ??= _historyOrders
        .where(_isInHistoryRange)
        .toList(growable: false);
  }

  bool _isInHistoryRange(SupplierOrder order) {
    final orderDay = _startOfDay(order.date);
    if (orderDay.isBefore(_historyRangeStart)) return false;
    if (orderDay.isAfter(_historyRangeEnd)) return false;
    return true;
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _emptyOrdersMessage({
    required List<SupplierOrder> activeOrders,
    required List<SupplierOrder> historyOrders,
    required List<SupplierOrder> filteredHistoryOrders,
  }) {
    if (_orders.isEmpty) {
      return 'Пока нет заказов';
    }
    if (_selectedTab == _SupplierOrderTab.active) {
      return 'Активных заказов пока нет';
    }
    // На вкладке "История" различаем два пустых случая: история вообще
    // пуста или просто отфильтрованный диапазон ничего не вернул - чтобы
    // подсказать поставщику, что фильтр "съел" заказы.
    if (historyOrders.isEmpty) {
      if (activeOrders.isNotEmpty) {
        return 'История заказов пока пустая';
      }
      return 'Пока нет заказов';
    }
    if (filteredHistoryOrders.isEmpty) {
      return 'За выбранный период заказов нет';
    }
    return 'Пока нет заказов';
  }

  Future<void> _updateOrderStatus(SupplierOrder order, String status) async {
    final userId = _userId;
    if (userId == null || userId == 0) {
      _showSnack('Сессия недействительна', severity: MessageSeverity.error);
      return;
    }
    if (_updatingOrderIds.contains(order.id)) {
      return;
    }
    if (!_canMoveToStatus(order.status, status)) {
      _showSnack(
        'Доступен только следующий шаг статуса',
        severity: MessageSeverity.warning,
      );
      return;
    }

    setState(() => _updatingOrderIds.add(order.id));
    try {
      final updatedOrder = await ApiService.updateSupplierOrderStatus(
        orderId: order.id,
        userId: userId,
        status: status,
      );

      if (!mounted) return;
      setState(() {
        _orders = _orders
            .map(
              (existing) =>
                  existing.id == updatedOrder.id ? updatedOrder : existing,
            )
            .toList();
        _invalidateOrdersCache();
      });
      _showSnack('Статус обновлен: ${_statusLabel(updatedOrder.status)}');
    } catch (e) {
      _showSnack('Не удалось обновить статус', severity: MessageSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(order.id));
      }
    }
  }

  Future<void> _confirmStatusChange(
    SupplierOrder order,
    String nextStatus,
  ) async {
    if (_statusLabel(order.status) == _statusLabel(nextStatus)) {
      return;
    }

    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Подтвердите смену статуса'),
          content: Text(
            'Изменить статус заказа №${order.id}\n'
            'с "${_statusLabel(order.status)}" на "${_statusLabel(nextStatus)}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Подтвердить'),
            ),
          ],
        );
      },
    );

    if (shouldUpdate == true) {
      await _updateOrderStatus(order, nextStatus);
    }
  }

  void _showSnack(
    String message, {
    MessageSeverity severity = MessageSeverity.info,
  }) {
    final msg = Message(
      id: const Uuid().v4(),
      type: MessageType.notification,
      severity: severity,
      title: '',
      body: message,
      timestamp: DateTime.now(),
      language: 'ru',
    );
    AppMessageSnackBar.show(context, msg);
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
        _historyRangeStart = start;
        _historyRangeEnd = end;
        _cachedFilteredHistoryOrders = null;
      });
    } else {
      _selectedPeriod = period;
      _historyRangeStart = start;
      _historyRangeEnd = end;
    }
  }

  Future<void> _pickHistoryRange() async {
    final initialRange = DateTimeRange(
      start: _historyRangeStart,
      end: _historyRangeEnd,
    );
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) =>
          custom_picker.CustomDateRangePickerDialog(initialRange: initialRange),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedPeriod = _periodCustom;
      _historyRangeStart = _startOfDay(picked.start);
      _historyRangeEnd = _startOfDay(picked.end);
      _cachedFilteredHistoryOrders = null;
    });
  }

  Future<void> _exportHistoryToExcel() async {
    if (_isExportingHistory) return;
    final userId = _userId;
    if (userId == null || userId == 0) {
      _showSnack('Требуется авторизация', severity: MessageSeverity.error);
      return;
    }

    setState(() => _isExportingHistory = true);
    try {
      final bytes = await ApiService.exportSupplierOrdersExcel(
        userId: userId,
        startDate: _historyRangeStart,
        endDate: _historyRangeEnd,
      );

      final fileName =
          'supplier_orders_${_formatDate(_historyRangeStart)}_to_${_formatDate(_historyRangeEnd)}.xlsx';

      // На вебе saveAs не реализован (UnimplementedError) - используем
      // saveFile, который инициирует обычное скачивание через браузер.
      // На мобильных оставляем saveAs, чтобы открывался системный диалог
      // выбора места сохранения.
      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        await FileSaver.instance.saveAs(
          name: fileName,
          bytes: bytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }

      if (!mounted) return;
      _showSnack('Файл загружен');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Ошибка экспорта: $e', severity: MessageSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _isExportingHistory = false);
      }
    }
  }

  @override
  Future<void> onAutoRefresh() async {
    if (_isLoading || _updatingOrderIds.isNotEmpty) return;
    await _loadOrders(showLoading: false);
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _activeOrders;
    final historyOrders = _historyOrders;
    final filteredHistoryOrders = _filteredHistoryOrders;
    final isHistoryTab = _selectedTab == _SupplierOrderTab.history;
    final visibleOrders = isHistoryTab ? filteredHistoryOrders : activeOrders;
    final emptyMessage = _emptyOrdersMessage(
      activeOrders: activeOrders,
      historyOrders: historyOrders,
      filteredHistoryOrders: filteredHistoryOrders,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Заказы покупателей')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _buildOrdersTabSelector(
                    activeCount: activeOrders.length,
                    historyCount: filteredHistoryOrders.length,
                  ),
                ),
                if (isHistoryTab) ...[
                  _buildHistoryFilterSection(),
                  const SizedBox(height: 8),
                  _buildHistoryPeriodTabs(),
                ],
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: visibleOrders.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              Center(child: Text(emptyMessage)),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: visibleOrders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final order = visibleOrders[index];
                              final isUpdating = _updatingOrderIds.contains(
                                order.id,
                              );
                              return RepaintBoundary(
                                child: _buildOrderCard(
                                  order,
                                  isUpdating: isUpdating,
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildHistoryFilterSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppColorPalette.of(context);
    final rangeLabel =
        '${_formatDate(_historyRangeStart)} - ${_formatDate(_historyRangeEnd)}';

    return Container(
      color: palette.card,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Фильтр',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickHistoryRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rangeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: colorScheme.onSurface,
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
              onPressed: _isExportingHistory ? null : _exportHistoryToExcel,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isExportingHistory
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
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

  Widget _buildHistoryPeriodTabs() {
    final palette = AppColorPalette.of(context);
    return Container(
      color: palette.card,
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
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppColorPalette.of(context);
    final isSelected = _selectedPeriod == text;
    return GestureDetector(
      onTap: () => _applyPeriodSelection(text),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? palette.accent : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildOrdersTabSelector({
    required int activeCount,
    required int historyCount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: _buildOrdersTabButton(
              title: 'Активные',
              count: activeCount,
              selected: _selectedTab == _SupplierOrderTab.active,
              onTap: () {
                if (_selectedTab == _SupplierOrderTab.active) return;
                setState(() => _selectedTab = _SupplierOrderTab.active);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildOrdersTabButton(
              title: 'История',
              count: historyCount,
              selected: _selectedTab == _SupplierOrderTab.history,
              onTap: () {
                if (_selectedTab == _SupplierOrderTab.history) return;
                setState(() => _selectedTab = _SupplierOrderTab.history);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTabButton({
    required String title,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppColorPalette.of(context);
    final selectedColor = palette.primary;
    final unselectedBorderColor = colorScheme.outlineVariant.withValues(
      alpha: 0.85,
    );
    final backgroundColor = selected
        ? selectedColor.withValues(alpha: 0.16)
        : colorScheme.surface.withValues(alpha: 0.82);
    final textColor = selected ? selectedColor : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? selectedColor.withValues(alpha: 0.8)
                  : unselectedBorderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? selectedColor.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? selectedColor : colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(SupplierOrder order, {required bool isUpdating}) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppColorPalette.of(context);
    final statusColor = _statusColor(order.status);
    final isHistoryOrder = _isHistoryStatus(order.status);
    final surfaceColor = palette.card;
    final cardRadius = isHistoryOrder ? 18.0 : 20.0;
    final borderColor = isHistoryOrder
        ? statusColor.withValues(alpha: 0.24)
        : statusColor.withValues(alpha: 0.22);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: isHistoryOrder ? 10 : 14,
            offset: isHistoryOrder ? const Offset(0, 4) : const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: statusColor,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          title: isHistoryOrder
              ? _buildHistoryTitle(order)
              : Text(
                  'Заказ №${order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: isHistoryOrder
                ? _buildHistoryMetaBadges(order, statusColor)
                : _buildActiveMetaBadges(order, statusColor),
          ),
          children: isHistoryOrder
              ? [
                  _buildHistoryInsights(order),
                  const SizedBox(height: 12),
                  _buildItemsBlock(order, showReceiptState: true),
                ]
              : [
                  _buildItemsBlock(order),
                  const SizedBox(height: 12),
                  _buildDeliveryAddressBlock(order),
                  const SizedBox(height: 12),
                  _buildStatusProgress(order),
                  const SizedBox(height: 12),
                  _buildStatusControls(order, isUpdating: isUpdating),
                ],
        ),
      ),
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String text,
    Color? textColor,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor ?? colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMetaBadges(SupplierOrder order, Color statusColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetaBadge(
          icon: Icons.calendar_today_rounded,
          text: _formatDate(order.date),
        ),
        _buildMetaBadge(
          icon: Icons.shopping_bag_outlined,
          text: '${order.items.length} поз.',
        ),
        _buildMetaBadge(
          icon: _statusIcon(order.status),
          text: _statusLabel(order.status),
          textColor: statusColor,
          backgroundColor: statusColor.withValues(alpha: 0.12),
          borderColor: statusColor.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildHistoryTitle(SupplierOrder order) {
    final amountText = '${_formatMoney(order.totalAmount)} ₸';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Заказ №${order.id}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _buildPriceBadge(amountText),
      ],
    );
  }

  Widget _buildPriceBadge(String amountText) {
    final palette = AppColorPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.primary.withValues(alpha: 0.92)),
      ),
      child: Text(
        amountText,
        textAlign: TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: TextStyle(
          color: palette.card,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildHistoryMetaBadges(SupplierOrder order, Color statusColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetaBadge(
          icon: Icons.calendar_today_rounded,
          text: _formatDate(order.date),
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
          icon: _statusIcon(order.status),
          text: _statusLabel(order.status),
          textColor: statusColor,
          backgroundColor: statusColor.withValues(alpha: 0.12),
          borderColor: statusColor.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildHistoryInsights(SupplierOrder order) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(order.status);
    final hasAddress = order.deliveryAddress.trim().isNotEmpty;
    final receivedSummary = order.items.isEmpty
        ? 'нет товаров'
        : '${order.receivedItemsCount}/${order.items.length} поз.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistoryDetailRow(
            icon: Icons.verified_rounded,
            label: 'Статус',
            value: _statusLabel(order.status),
            valueColor: statusColor,
          ),
          const SizedBox(height: 10),
          _buildHistoryDetailRow(
            icon: Icons.inventory_2_outlined,
            label: 'Товарных позиций',
            value: '${order.items.length}',
          ),
          const SizedBox(height: 10),
          _buildHistoryDetailRow(
            icon: Icons.widgets_outlined,
            label: 'Единиц товара',
            value: '${order.totalUnits} шт.',
          ),
          const SizedBox(height: 10),
          _buildHistoryDetailRow(
            icon: Icons.task_alt_rounded,
            label: 'Подтверждено',
            value: receivedSummary,
          ),
          if (hasAddress) ...[
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            _buildHistoryDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Адрес доставки',
              value: order.deliveryAddress.trim(),
              multilineValue: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool multilineValue = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    final valueStyle = TextStyle(
      color: valueColor ?? colorScheme.onSurface,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    );

    if (multilineValue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
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
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildDeliveryAddressBlock(SupplierOrder order) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(order.status);
    final address = order.deliveryAddress.trim();
    final hasAddress = address.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAddress
              ? statusColor.withValues(alpha: 0.26)
              : colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: hasAddress ? statusColor : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Адрес доставки',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasAddress ? address : 'Не указан',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasAddress
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsBlock(
    SupplierOrder order, {
    bool showReceiptState = false,
  }) {
    if (showReceiptState) {
      return _buildHistoryItemsBlock(order);
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.items.isEmpty)
            Text(
              'Список товаров пуст',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else
            ...order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final lineTotal = item.price * item.quantity;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == order.items.length - 1 ? 0 : 10,
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${item.quantity} × ${_formatMoney(item.price)} ₸',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_formatMoney(lineTotal)} ₸',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (index != order.items.length - 1) ...[
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.colorPalette.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Итого',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_formatMoney(order.totalAmount)} ₸',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItemsBlock(SupplierOrder order) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.72),
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
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (order.items.isEmpty)
            Text(
              'Список товаров пуст',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else
            ...order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final lineTotal = item.price * item.quantity;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == order.items.length - 1 ? 0 : 10,
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: _buildSupplierItemImage(item),
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatMoney(lineTotal)} ₸',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (index != order.items.length - 1) ...[
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.7,
                        ),
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

  Widget _buildSupplierItemImage(SupplierOrderItem item) {
    var raw = item.imageUrl.trim();
    if (raw.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildSupplierItemImageFallback(),
      );
    }

    // SmartImage сам различает data:image / base64: / http(s) / asset, поэтому
    // достаточно нормализовать CSV и достроить префикс assets/ для локальных путей.
    final isEncoded = raw.startsWith('base64:') || raw.startsWith('data:image');
    if (!isEncoded && raw.contains(',')) {
      raw = raw
          .split(',')
          .map((value) => value.trim())
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      if (raw.isEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildSupplierItemImageFallback(),
        );
      }
    }

    final path = (isEncoded || _isNetworkUrl(raw) || raw.startsWith('assets/'))
        ? raw
        : 'assets/$raw';

    return SmartImage(
      path: path,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(10),
      placeholder: _buildSupplierItemImageFallback(),
    );
  }

  Widget _buildSupplierItemImageFallback() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 22,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  bool _isNetworkUrl(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  Widget _buildStatusProgress(SupplierOrder order) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _statusProgressValue(order.status);
    final currentStep = _statusStep(order.status);
    final currentColor = _statusColor(order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Прогресс заказа',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: currentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(currentColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _supplierFlowStatuses.map((statusOption) {
            final step = _statusStep(statusOption);
            final isReached = currentStep >= step && step >= 0;
            final labelColor = isReached
                ? _statusColor(statusOption)
                : colorScheme.onSurfaceVariant;

            return Expanded(
              child: Column(
                children: [
                  Icon(_statusIcon(statusOption), size: 14, color: labelColor),
                  const SizedBox(height: 4),
                  Text(
                    _statusLabel(statusOption),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isReached ? FontWeight.w700 : FontWeight.w500,
                      color: labelColor.withValues(alpha: isReached ? 1 : 0.85),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusControls(SupplierOrder order, {required bool isUpdating}) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentStep = _statusStep(order.status);
    final statusColor = _statusColor(order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_statusIcon(order.status), size: 18, color: statusColor),
            const SizedBox(width: 6),
            Text(
              'Текущий статус: ${_statusLabel(order.status)}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _supplierFlowStatuses.map((statusOption) {
            final optionStep = _statusStep(statusOption);
            final optionColor = _statusColor(statusOption);
            final isSelected = currentStep == optionStep;
            final canSelect =
                !isUpdating &&
                !isSelected &&
                _canMoveToStatus(order.status, statusOption);

            return ChoiceChip(
              avatar: Icon(
                _statusIcon(statusOption),
                size: 16,
                color: isSelected
                    ? optionColor
                    : canSelect
                    ? optionColor
                    : colorScheme.onSurfaceVariant,
              ),
              label: Text(statusOption),
              selected: isSelected,
              onSelected: canSelect
                  ? (_) => _confirmStatusChange(order, statusOption)
                  : null,
              selectedColor: optionColor.withValues(alpha: 0.16),
              backgroundColor: colorScheme.surface,
              disabledColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.72,
              ),
              showCheckmark: false,
              side: BorderSide(
                color: isSelected
                    ? optionColor
                    : canSelect
                    ? optionColor.withValues(alpha: 0.45)
                    : colorScheme.outlineVariant,
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? optionColor
                    : canSelect
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            );
          }).toList(),
        ),
        if (isUpdating) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 3),
        ] else if (_isAcceptedStatus(order.status)) ...[
          const SizedBox(height: 8),
          Text(
            'Заказ уже подтвержден покупателем',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ] else if (_isDeliveredStatus(order.status)) ...[
          const SizedBox(height: 8),
          Text(
            'Ожидается подтверждение покупателем',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
