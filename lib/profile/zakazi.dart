import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_color_palette.dart';

import '../models/message.dart';
import '../models/order.dart';
import '../pages/order_history_page.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import '../services/message/message_localization.dart';
import '../services/localization/app_localizations.dart';
import '../utils/auto_refresh.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../widgets/smart_image.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with AutoRefreshMixin<MyOrdersPage> {
  static const Duration _orderCancellationWindow = Duration(hours: 1);

  List<Order> _orders = [];
  bool _isLoading = true;
  final Set<String> _acceptingOrders = {};
  final Set<String> _cancelingOrders = {};

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => context.colorPalette.card;
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
    if (_isLoading ||
        _acceptingOrders.isNotEmpty ||
        _cancelingOrders.isNotEmpty) {
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
              _isAcceptedStatus(order.status) ||
              _isCancelledStatus(order.status),
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
           AppLocalizations.of(context).getString('zakazi_my_orders'),
           style: TextStyle(
             color: _colorScheme.onSurface,
             fontSize: 18,
             fontWeight: FontWeight.w600,
           ),
         ),
        centerTitle: true,
      ),
      body: _buildBody(context, activeOrders, historyCount),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Order> activeOrders,
    int historyCount,
  ) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.colorPalette.accent),
      );
    }

    return Column(
      children: [
        _buildHistoryButton(context, historyCount),
        Expanded(
          child: RefreshIndicator(
            color: context.colorPalette.accent,
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
              AppLocalizations.of(context).getString('zakazi_no_orders'),
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
        return RepaintBoundary(child: _buildOrderCard(orders[index]));
      },
    );
  }

  Widget _buildHistoryButton(BuildContext context, int historyCount) {
    final l10n = AppLocalizations.of(context);
    final label = historyCount > 0
        ? l10n.getString('zakazi_history_button_count', params: {'count': historyCount})
        : l10n.getString('zakazi_history_button');

    final historyBorderColor = context.colorPalette.accent.withValues(
      alpha: _isDark ? 0.98 : 0.9,
    );
    final historyBackground = context.colorPalette.accent.withValues(
      alpha: _isDark ? 0.1 : 0.04,
    );

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
                border: Border.all(color: historyBorderColor, width: 1.4),
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

  bool _isPendingStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == 'pending' ||
        normalized == 'new' ||
        normalized == 'новый' ||
        normalized == 'ожидает' ||
        normalized == context.l10n.getString('auto_novyy').toLowerCase() ||
        normalized == context.l10n.getString('auto_ozhidaet').toLowerCase();
  }

  bool _isDeliveredStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == context.l10n.getString('auto_dostavlen').toLowerCase() ||
        normalized == context.l10n.getString('auto_dostavlen_1').toLowerCase() ||
        normalized == context.l10n.getString('supplier_status_delivered').toLowerCase() ||
        normalized == context.l10n.getString('auto_dostavleno').toLowerCase() ||
        normalized == 'доставлен' ||
        normalized == 'доставлено' ||
        normalized == 'delivered';
  }

  bool _isInTransitStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains(context.l10n.getString('auto_vPuti').toLowerCase()) ||
        normalized.contains('в пути') ||
        normalized == 'in transit' ||
        normalized == 'on the way';
  }

  bool _isProcessingStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains(context.l10n.getString('auto_sobira').toLowerCase()) ||
        normalized.contains('собира') ||
        normalized.contains('подготовка') ||
        normalized == 'processing' ||
        normalized == 'assembling';
  }

  bool _isAcceptedStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == context.l10n.getString('auto_prinyat').toLowerCase() ||
        normalized == context.l10n.getString('auto_prinyata').toLowerCase() ||
        normalized == context.l10n.getString('auto_prinyato').toLowerCase() ||
        normalized == context.l10n.getString('auto_prinyaty').toLowerCase() ||
        normalized.contains('принят') ||
        normalized.contains('завершен') ||
        normalized == 'accepted' ||
        normalized == 'received';
  }

  bool _isCancelledStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized.contains(context.l10n.getString('auto_otmen').toLowerCase()) ||
        normalized.contains('отмен') ||
        normalized == 'cancelled' ||
        normalized == 'canceled';
  }

  bool _isWithinCancellationWindow(Order order) {
    return DateTime.now().isBefore(order.date.add(_orderCancellationWindow));
  }

  Duration _remainingCancellationTime(Order order) {
    final remaining = order.date
        .add(_orderCancellationWindow)
        .difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool _canCancelOrder(Order order) {
    if (_isAcceptedStatus(order.status) || _isCancelledStatus(order.status)) {
      return false;
    }
    return _isWithinCancellationWindow(order);
  }

  bool _isActiveStatus(String status) {
    return _isPendingStatus(status) ||
        _isInTransitStatus(status) ||
        _isProcessingStatus(status) ||
        _isDeliveredStatus(status);
  }

  Color _statusTextColor(String status) {
    if (_isDeliveredStatus(status)) {
      return context.colorPalette.statusDelivered;
    }
    if (_isInTransitStatus(status)) {
      return context.colorPalette.accent;
    }
    if (_isProcessingStatus(status)) {
      return context.colorPalette.statusPending;
    }
    if (_isAcceptedStatus(status)) {
      return context.colorPalette.success;
    }
    if (_isCancelledStatus(status)) {
      return context.colorPalette.statusCancelled;
    }
    return context.colorPalette.statusPending;
  }

  Color _statusBackgroundColor(String status) {
    final base = _statusTextColor(status);
    return base.withValues(alpha: _isDark ? 0.22 : 0.12);
  }

  String _statusLabel(String status) {
    final l10n = context.l10n;
    if (_isProcessingStatus(status)) return l10n.statusAssembling;
    if (_isInTransitStatus(status)) return l10n.statusInTransit;
    if (_isDeliveredStatus(status)) return l10n.statusDelivered;
    if (_isAcceptedStatus(status)) return l10n.statusAccepted;
    if (_isCancelledStatus(status)) return l10n.statusCancelled;
    return status;
  }

  Widget _buildOrderCard(Order order) {
    final l10n = AppLocalizations.of(context);
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
                      l10n.getString('zakazi_order_label', params: {'orderId': order.id}),
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
                    _statusLabel(order.status),
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
                l10n: l10n,
              );
            },
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: _borderColor),
          ),

          _buildOrderActions(
            order,
            isAccepting: isAccepting,
            isCancelling: isCancelling,
            l10n: l10n,
          ),

          Divider(height: 1, color: _borderColor),

          // Итого
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.getString('zakazi_total_amount_label'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  context.formatCurrency(order.totalAmount.toDouble(), decimalDigits: 0),
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
    required AppLocalizations l10n,
  }) {
    final canReceive = _isDeliveredStatus(orderStatus) && !isAccepting;

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
                      context.formatCurrency(item.price.toDouble(), decimalDigits: 0),
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
                        '${item.quantity} ${l10n.getString('zakazi_quantity_short')}',
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

          // Чекбокс подтверждения или бейдж блокировки
          SizedBox(
            width: 118,
            child: canReceive || item.isReceived || _isAcceptedStatus(orderStatus)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 1.3,
                        child: Checkbox(
                          value: _isAcceptedStatus(orderStatus) ? true : item.isReceived,
                          onChanged: canReceive
                              ? (bool? value) {
                                  setState(() {
                                    item.isReceived = value ?? false;
                                  });
                                }
                              : null,
                          activeColor: context.colorPalette.accent,
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
                              return context.colorPalette.accent;
                            }
                            return Colors.transparent;
                          }),
                        ),
                      ),
                      Text(
                        l10n.getString('zakazi_accepted_label'),
                        style: TextStyle(
                          fontSize: 13,
                          color: canReceive ? _colorScheme.onSurface : _mutedText,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.getString('zakazi_accepted_label'),
                              style: TextStyle(
                                fontSize: 13,
                                color: _mutedText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.lock_outline, size: 14, color: _mutedText),
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
                  context.l10n.zakaziQuantity(item.quantity),
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
    var raw = item.imageUrl.trim();
    if (raw.isEmpty) {
      return _buildOrderImageFallback();
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
        return _buildOrderImageFallback();
      }
    }

    final path = (isEncoded || _isNetworkUrl(raw) || raw.startsWith('assets/'))
        ? raw
        : 'assets/$raw';

    return SmartImage(
      path: path,
      fit: BoxFit.cover,
      placeholder: _buildOrderImageFallback(),
    );
  }

  Widget _buildOrderImageFallback() {
    return Container(
      color: _colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.shopping_bag_outlined, size: 24, color: _mutedText),
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
    required AppLocalizations l10n,
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
                    l10n: l10n,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, size: 18, color: _mutedText),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.getString('zakazi_can_accept_after_delivery'),
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
                      l10n.getString('zakazi_can_accept_after_delivery'),
                      style: TextStyle(fontSize: 14, color: _mutedText),
                    ),
                  ),
                ],
              ),
            if (!canCancel) ...[
              const SizedBox(height: 8),
              _buildCancelInfo(order, l10n),
            ],
          ],
        ),
      );
    }

    final allSelected = _areAllItemsSelected(order);
    final selectLabel = allSelected
        ? l10n.getString('zakazi_deselect_all')
        : l10n.getString('zakazi_select_all');

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
              l10n: l10n,
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
                  foregroundColor: context.colorPalette.accent,
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
                    backgroundColor: context.colorPalette.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isAccepting
                        ? l10n.getString('zakazi_accepting')
                        : l10n.getString('zakazi_accept_button'),
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
            _buildCancelInfo(order, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelOrderButton(
    Order order, {
    required bool isBusy,
    required bool isCancelling,
    required AppLocalizations l10n,
  }) {
    return OutlinedButton.icon(
      onPressed: isBusy ? null : () => _confirmCancelOrder(order),
      icon: const Icon(Icons.cancel_outlined, size: 18),
      label: Text(isCancelling
          ? l10n.getString('zakazi_cancelling')
          : l10n.getString('zakazi_cancel_button')),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colorPalette.statusCancelled,
        side: BorderSide(color: context.colorPalette.statusCancelled),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildCancelInfo(Order order, AppLocalizations l10n) {
    final remaining = _remainingCancellationTime(order);
    final hasTime = remaining > Duration.zero;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final timeLabel = hours > 0
        ? context.l10n.zakaziHoursMinutes(hours, (minutes).toString().padLeft(2, '0'))
        : context.l10n.zakaziMinutes(remaining.inMinutes);

    return Row(
      children: [
        Icon(Icons.schedule, size: 16, color: _mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            hasTime
                ? l10n.getString('zakazi_cancel_available', params: {'time': timeLabel})
                : l10n.getString('zakazi_cancel_only_first_hour'),
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

  // Хелпер для показа унифицированного SnackBar: тело - verbatim текст,
  // title пустой согласно ADR из decisions.md.
  void _showMessage(String body, MessageSeverity severity) {
    final message = Message(
      id: const Uuid().v4(),
      type: MessageType.notification,
      severity: severity,
      title: '',
      body: body,
      timestamp: DateTime.now(),
      language: MessageLocalizationManager.getCurrentLanguage(),
    );
    AppMessageSnackBar.show(context, message);
  }

  Future<void> _confirmAcceptOrder(Order order) async {
    if (!_areAllItemsSelected(order)) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _showMessage(
        l10n.getString('zakazi_mark_items_before_confirm'),
        MessageSeverity.warning,
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.getString('zakazi_confirm_acceptance'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.getString('zakazi_order_amount', params: {
                    'orderId': order.id,
                    'amount': context.formatCurrency(order.totalAmount.toDouble(), decimalDigits: 0),
                  }),
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
                        child: Text(l10n.getString('common_cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorPalette.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(l10n.getString('zakazi_accept_button')),
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
    final l10n = AppLocalizations.of(context);
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
      _showMessage(l10n.getString('zakazi_order_accepted'), MessageSeverity.info);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _acceptingOrders.remove(order.id);
      });
      _showMessage(
        l10n.getString('zakazi_accept_failed'),
        MessageSeverity.error,
      );
    }
  }

  Future<void> _confirmCancelOrder(Order order) async {
    final l10n = AppLocalizations.of(context);
    if (!_canCancelOrder(order)) {
      if (!mounted) return;
      _showMessage(
        l10n.getString('zakazi_cancel_only_first_hour'),
        MessageSeverity.warning,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.getString('zakazi_cancel_order_title')),
          content: Text(l10n.getString('zakazi_cancel_order_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.getString('zakazi_no')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.getString('zakazi_cancel_button')),
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
    final l10n = AppLocalizations.of(context);
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      if (!mounted) return;
      _showMessage(l10n.getString('auth_session_expired'), MessageSeverity.error);
      return;
    }
    if (_cancelingOrders.contains(order.id)) {
      return;
    }

    setState(() {
      _cancelingOrders.add(order.id);
    });

    try {
      final updatedOrder = await ApiService.cancelOrder(
        order.id,
        userId: userId,
      );
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
      _showMessage(l10n.getString('zakazi_order_cancelled'), MessageSeverity.info);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cancelingOrders.remove(order.id);
      });
      _showMessage(l10n.getString('zakazi_cancel_failed'), MessageSeverity.error);
    }
  }

  bool _areAllItemsSelected(Order order) {
    if (order.items.isEmpty) return false;
    return order.items.every((item) => item.isReceived);
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final months = [
      l10n.getString('zakazi_month_january'),
      l10n.getString('zakazi_month_february'),
      l10n.getString('zakazi_month_march'),
      l10n.getString('zakazi_month_april'),
      l10n.getString('zakazi_month_may'),
      l10n.getString('zakazi_month_june'),
      l10n.getString('zakazi_month_july'),
      l10n.getString('zakazi_month_august'),
      l10n.getString('zakazi_month_september'),
      l10n.getString('zakazi_month_october'),
      l10n.getString('zakazi_month_november'),
      l10n.getString('zakazi_month_december'),
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(date.year, date.month, date.day);

    if (orderDay == today) {
      return '${l10n.getString('zakazi_today')}, ${date.day} ${months[date.month - 1]}';
    } else if (orderDay == today.subtract(const Duration(days: 1))) {
      return '${l10n.getString('zakazi_yesterday')}, ${date.day} ${months[date.month - 1]}';
    } else if (orderDay == today.add(const Duration(days: 1))) {
      return '${l10n.getString('zakazi_tomorrow')}, ${date.day} ${months[date.month - 1]}';
    } else {
      return '${date.day} ${months[date.month - 1]}';
    }
  }


}
