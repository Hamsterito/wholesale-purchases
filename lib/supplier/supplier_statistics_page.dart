import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/supplier_stats.dart';
import '../models/chart_data.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/ai_service.dart';
import '../services/revenue_chart_service.dart';
import '../services/statistics_cache_service.dart';
import '../widgets/date_range_picker_dialog.dart';
import '../utils/month_year_parser.dart';
import '../widgets/main_bottom_nav.dart';
import '../theme/app_color_palette.dart';

// Вспомогательные классы данных

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _MetricData(this.label, this.value, this.icon, this.color, this.bg);
}

class _StatusData {
  final String label;
  final int count;
  final Color color;
  const _StatusData(this.label, this.count, this.color);
}

// WIDGET

class SupplierStatisticsPage extends StatefulWidget {
  const SupplierStatisticsPage({super.key});

  @override
  State<SupplierStatisticsPage> createState() => _SupplierStatisticsPageState();
}

class _SupplierStatisticsPageState extends State<SupplierStatisticsPage>
    with SingleTickerProviderStateMixin {
  // Данные
  SupplierStatsSummary? _statsSummary;
  List<RevenueHistory> _revenueHistory = [];
  List<TopProduct> _topProducts = [];
  OrderStats? _orderStats;
  BuyerStats? _buyerStats;
  RatingStats? _ratingStats;
  String? _aiSummary;
  ChartData? _chartData;

  // Состояние UI
  bool _isLoading = true;
  bool _isLoadingAiSummary = false;
  String? _error;
  String? _aiSummaryError;
  DateTimeRange? _selectedDateRange;

  // Анимация
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int? get _userId => AuthStorage.userId;

  // Геттеры для дат из выбранного диапазона
  DateTime? get _startDate => _selectedDateRange?.start;
  DateTime? get _endDate => _selectedDateRange?.end;

  /// Возвращает диапазон по умолчанию (последние 6 месяцев)
  DateTimeRange _getDefaultDateRange() {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
    return DateTimeRange(start: sixMonthsAgo, end: now);
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadAllStatistics();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Загрузка

  Future<void> _loadAllStatistics({bool showLoading = true}) async {
    final userId = _userId;
    if (userId == null || userId == 0) {
      setState(() {
        _error = 'Вы не авторизованы. Пожалуйста, войдите.';
        _isLoading = false;
      });
      return;
    }

    // Показываем индикатор загрузки, только если это запрошено (не для pull‑to‑refresh)
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Пытаемся загрузить из кэша сначала
      final cachedSummary = await StatisticsCacheService.getStatsSummary(
        userId,
      );
      if (cachedSummary != null && showLoading) {
        setState(() {
          _statsSummary = cachedSummary;
        });
      }

      // Загружаем все статистики параллельно
      final results = await Future.wait([
        ApiService.fetchSupplierStatsSummary(
          userId: userId,
          startDate: _startDate,
          endDate: _endDate,
        ),
        ApiService.fetchSupplierRevenueHistory(userId: userId),
        ApiService.fetchSupplierTopProducts(
          userId: userId,
          startDate: _startDate,
          endDate: _endDate,
        ),
        ApiService.fetchSupplierOrderStats(
          userId: userId,
          startDate: _startDate,
          endDate: _endDate,
        ),
        ApiService.fetchSupplierBuyerStats(
          userId: userId,
          startDate: _startDate,
          endDate: _endDate,
        ),
        ApiService.fetchSupplierRatingStats(
          userId: userId,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ]);

      if (!mounted) return;

      // Парсим результаты
      final summaryData = results[0] as Map<String, dynamic>;
      final revenueData = results[1] as List<Map<String, dynamic>>;
      final topProductsData = results[2] as List<Map<String, dynamic>>;
      final orderStatsData = results[3] as Map<String, dynamic>;
      final buyerStatsData = results[4] as Map<String, dynamic>;
      final ratingStatsData = results[5] as Map<String, dynamic>;
      // Обрабатываем историю выручки с использованием продвинутого парсера
      final processedRevenue = <RevenueHistory>[];
      for (final item in revenueData) {
        final revenue = RevenueHistory.fromJson(item);
        final parsed = MonthYearParser.parse(revenue.month);
        if (parsed != null) {
          processedRevenue.add(
            RevenueHistory(
              month: revenue.month,
              revenue: revenue.revenue,
              date: parsed,
            ),
          );
        }
      }

      final summary = SupplierStatsSummary.fromJson(summaryData);

      setState(() {
        _statsSummary = summary;
        _revenueHistory = processedRevenue;
        _topProducts = topProductsData
            .map((json) => TopProduct.fromJson(json))
            .toList();
        _orderStats = OrderStats.fromJson(orderStatsData);
        _buyerStats = BuyerStats.fromJson(buyerStatsData);
        _ratingStats = RatingStats.fromJson(ratingStatsData);
        _error = null;
      });

      // Кэшируем сводку
      await StatisticsCacheService.cacheStatsSummary(userId, summary);

      // Определяем нужна ли дневная детализация (диапазон ≤ 31 дня)
      final effectiveRange = _selectedDateRange ?? _getDefaultDateRange();
      final daysDiff = effectiveRange.end
          .difference(effectiveRange.start)
          .inDays;
      final needsDailyGranularity = daysDiff <= 31;

      // Загружаем данные графика в зависимости от детализации
      if (needsDailyGranularity) {
        // Загружаем дневные данные с бэкенда
        final dailyData = await ApiService.fetchSupplierRevenueDaily(
          userId: userId,
          startDate: effectiveRange.start,
          endDate: effectiveRange.end,
        );
        final dailyRevenues = dailyData
            .map((json) => DailyRevenue.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            _chartData = RevenueChartService.buildChartDataFromDaily(
              dailyRevenues,
            );
          });
        }
      } else {
        // Используем месячные данные
        if (mounted) {
          setState(() {
            _chartData = RevenueChartService.buildChartDataFromMonthly(
              processedRevenue,
            );
          });
        }
      }

      // Загружаем AI резюме отдельно (не блокирует показ статистики)
      // Запускаем в фоне без await
      _loadAiSummary();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить статистику';
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeCtrl.forward(from: 0);
      }
    }
  }

  Future<void> _loadAiSummary() async {
    if (_statsSummary == null) return;

    // Устанавливаем состояние загрузки в начале
    setState(() {
      _isLoadingAiSummary = true;
      _aiSummaryError = null;
    });

    try {
      final stats = {
        'totalRevenue': _statsSummary!.totalRevenue,
        'monthlyRevenue': _statsSummary!.monthlyRevenue,
        'totalOrders': _statsSummary!.totalOrders,
        'averageOrderValue': _statsSummary!.averageOrderValue,
        'averageRating': _ratingStats?.averageRating ?? 0.0,
        'totalReviews': _ratingStats?.totalReviews ?? 0,
        'repeatBuyersPercentage': _buyerStats?.repeatBuyersPercentage ?? 0,
        'newBuyersThisMonth': _buyerStats?.newBuyersThisMonth ?? 0,
        'topProductsCount': _topProducts.length,
        'averageFulfillmentDays': _orderStats?.averageFulfillmentDays ?? 0,
        'cancelledOrdersPercentage':
            _orderStats != null && _orderStats!.totalOrders > 0
            ? ((_orderStats!.cancelledCount / _orderStats!.totalOrders) * 100)
                  .toInt()
            : 0,
      };

      // Генерируем AI-резюме с обработкой ошибок
      final summary = await AiService.generateSupplierSummary(stats);

      if (!mounted) return;
      setState(() {
        _aiSummary = summary;
        _aiSummaryError = null;
      });
    } catch (e) {
      if (!mounted) return;

      // Обрабатываем специфичные типы ошибок от AiService
      String? errorMessage;

      if (e is AiException) {
        // Используем пользовательское сообщение об ошибке, если оно доступно
        // Если userMessage null (например, при ошибке лимита), не показываем ошибку
        errorMessage = e.userMessage;
      } else {
        errorMessage = 'Не удалось сформировать AI-резюме';
      }

      setState(() {
        _aiSummaryError = errorMessage;
      });
    } finally {
      // Гарантируем, что состояние загрузки сбрасывается в конце (успех или ошибка)
      if (mounted) {
        setState(() => _isLoadingAiSummary = false);
      }
    }
  }

  Future<void> _handleDateRangeChange(DateTimeRange? newRange) async {
    setState(() {
      _selectedDateRange = newRange;
    });
    await _loadAllStatistics();
  }

  Future<void> _handleRefresh() async {
    await _loadAllStatistics(showLoading: false);
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (_) =>
          CustomDateRangePickerDialog(initialRange: _selectedDateRange),
    );
    if (result != null) await _handleDateRangeChange(result);
  }

  // Построение

  @override
  Widget build(BuildContext context) {
    final palette = AppColorPalette.of(context);
    return Scaffold(
      backgroundColor: palette.bgTop,
      appBar: _buildAppBar(palette),
      body: RefreshIndicator(
        color: palette.primary,
        onRefresh: _handleRefresh,
        child: _buildBody(),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  PreferredSizeWidget _buildAppBar(AppColorPalette palette) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: isDark ? palette.accentMist : palette.card,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статистика',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: palette.ink,
            ),
          ),
          Text(
            'Аналитика продаж',
            style: TextStyle(
              fontSize: 12,
              color: palette.ink.withValues(alpha: 0.45),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: palette.primary),
          onPressed: _handleRefresh,
          tooltip: 'Обновить',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    if (_error != null && _isLoading) return _buildErrorState();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateFilter(),
          const SizedBox(height: 20),
          if (_isLoading)
            _buildSkeletons()
          else
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroMetrics(),
                  const SizedBox(height: 20),
                  _buildRevenueChart(),
                  const SizedBox(height: 20),
                  _buildOrderStatusCard(),
                  const SizedBox(height: 20),
                  _buildTopProductsCard(),
                  const SizedBox(height: 20),
                  _buildBuyersRatingRow(),
                  const SizedBox(height: 20),
                  _buildRecentOrdersCard(),
                  const SizedBox(height: 20),
                  _buildRecentReviewsCard(),
                  const SizedBox(height: 20),
                  _buildAiSummaryCard(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Состояние ошибки

  Widget _buildErrorState() {
    final palette = AppColorPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: palette.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: palette.ink.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadAllStatistics,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  // Фильтр по дате

  Widget _buildDateFilter() {
    final palette = AppColorPalette.of(context);
    final hasRange = _selectedDateRange != null;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.date_range_rounded,
              size: 15,
              color: palette.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasRange
                  ? '${_fmtDate(_selectedDateRange!.start)} — ${_fmtDate(_selectedDateRange!.end)}'
                  : 'Все время',
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasRange ? FontWeight.w500 : FontWeight.normal,
                color: hasRange
                    ? palette.primary
                    : palette.ink.withValues(alpha: 0.55),
              ),
            ),
          ),
          _chipButton('Выбрать', onTap: _showDateRangePicker),
          // Приводим к тернарному spread для устранения предупреждения стиля
          ...(hasRange
              ? [
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _handleDateRangeChange(null),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: palette.bgTop,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: palette.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ]
              : <Widget>[]),
        ],
      ),
    );
  }

  Widget _chipButton(String label, {required VoidCallback onTap}) {
    final palette = AppColorPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: palette.primary,
          ),
        ),
      ),
    );
  }

  // Виджет

  Widget _buildSkeletons() {
    return Column(
      children: [
        _skeleton(110),
        const SizedBox(height: 16),
        _skeleton(220),
        const SizedBox(height: 16),
        _skeleton(180),
        const SizedBox(height: 16),
        _skeleton(200),
      ],
    );
  }

  Widget _skeleton(double h) {
    final palette = AppColorPalette.of(context);
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: palette.bgBottom,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // Основные метрики

  Widget _buildHeroMetrics() {
    if (_statsSummary == null) return const SizedBox.shrink();
    final s = _statsSummary!;

    final palette = AppColorPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Цвета подобраны под брендовую палитру приложения
    final metrics = [
      _MetricData(
        'Общая выручка',
        _fmtCurrency(s.totalRevenue),
        Icons.payments_rounded,
        palette.primary,
        isDark ? palette.accentMist : palette.accentSoft,
      ),
      _MetricData(
        'Выручка за месяц',
        _fmtCurrency(s.monthlyRevenue),
        Icons.trending_up_rounded,
        palette.tertiary,
        isDark ? palette.accentMist : Color(0xFFD1F4E8),
      ),
      _MetricData(
        'За неделю',
        _fmtCurrency(s.weeklyRevenue),
        Icons.bar_chart_rounded,
        palette.warning,
        isDark ? palette.accentMist : Color(0xFFFDF8E8),
      ),
      _MetricData(
        'Всего заказов',
        s.totalOrders.toString(),
        Icons.shopping_bag_rounded,
        palette.secondary,
        isDark ? palette.accentMist : Color(0xFFEDE9FE),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Обзор', Icons.analytics_rounded),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.65,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: metrics.length,
          itemBuilder: (_, i) => _buildMetricCard(metrics[i]),
        ),
        // Показываем средний чек только если он имеет смысл
        ...(s.averageOrderValue > 0
            ? [
                const SizedBox(height: 10),
                _buildWideMetricStrip(
                  'Средний чек',
                  _fmtCurrency(s.averageOrderValue),
                  Icons.receipt_long_rounded,
                  palette.error,
                ),
              ]
            : <Widget>[]),
      ],
    );
  }

  Widget _buildMetricCard(_MetricData m) {
    // Adapt colors for dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? m.color.withValues(alpha: 0.15) : m.bg;
    final iconBg = m.color.withValues(alpha: isDark ? 0.25 : 0.12);
    final textColor = isDark ? m.color.withValues(alpha: 0.9) : m.color;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(m.icon, size: 18, color: m.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.label,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                m.value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideMetricStrip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.08);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withValues(alpha: 0.75),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // График выручки

  Widget _buildRevenueChart() {
    // Проверяем, пуста ли история выручки
    if (_revenueHistory.isEmpty) {
      return _buildEmptyStateCard(
        title: 'Динамика выручки',
        icon: Icons.show_chart_rounded,
        message: 'Нет данных',
      );
    }

    // Если данные графика не обработаны, показываем пустое состояние
    if (_chartData == null || _chartData!.spots.isEmpty) {
      return _buildEmptyStateCard(
        title: 'Динамика выручки',
        icon: Icons.show_chart_rounded,
        message: 'Нет данных',
      );
    }

    final palette = AppColorPalette.of(context);
    final chartData = _chartData!;

    return _card(
      title: 'Динамика выручки',
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 190,
        // Изолируем тяжёлый LineChart в отдельный слой - свайпы и
        // ребилды соседних карточек не будут триггерить перерисовку графика
        child: RepaintBoundary(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: chartData.maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: chartData.maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: palette.line.withValues(alpha: 0.25),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= chartData.labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          chartData.labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            color: palette.ink.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (v, _) => Text(
                      _formatYAxis(v, chartData.maxY),
                      style: TextStyle(
                        fontSize: 10,
                        color: palette.ink.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: palette.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4,
                      color: palette.card,
                      strokeWidth: 2.5,
                      strokeColor: palette.primary,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.primary.withValues(alpha: 0.18),
                        palette.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Вспомогательный виджет для отображения пустого состояния
  Widget _buildEmptyStateCard({
    required String title,
    required IconData icon,
    required String message,
  }) {
    final palette = AppColorPalette.of(context);
    return _card(
      title: title,
      icon: icon,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: palette.ink.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }

  // Статусы заказов

  Widget _buildOrderStatusCard() {
    if (_orderStats == null) return const SizedBox.shrink();
    final o = _orderStats!;
    final total = o.totalOrders > 0 ? o.totalOrders : 1;
    final palette = AppColorPalette.of(context);

    // Цвета статусов соответствуют смысловой нагрузке и палитре
    final statuses = [
      _StatusData('Доставлены', o.deliveredCount, palette.statusDelivered),
      _StatusData('Отправлены', o.shippedCount, palette.statusShipped),
      _StatusData('Подтверждены', o.confirmedCount, palette.secondary),
      _StatusData('Ожидают', o.pendingCount, palette.statusPending),
      _StatusData('Отменены', o.cancelledCount, palette.statusCancelled),
    ];

    return _card(
      title: 'Статусы заказов',
      icon: Icons.donut_large_rounded,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 128,
                height: 128,
                // Изолируем PieChart - перерисовка соседних карточек
                // не должна триггерить переотрисовку диаграммы
                child: RepaintBoundary(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2.5,
                      centerSpaceRadius: 36,
                      sections: statuses.map((s) {
                        return PieChartSectionData(
                          color: s.count > 0 ? s.color : Colors.transparent,
                          value: s.count > 0 ? s.count.toDouble() : 0,
                          showTitle: false,
                          radius: s.count > 0 ? 30 : 0,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: statuses.map((s) {
                    final pct = (s.count / total * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.5),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.label,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            s.count.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 10,
                                color: palette.ink.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: palette.bgBottom,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Этот месяц', o.thisMonthCount.toString()),
                _vertDivider(),
                _miniStat('Прошлый месяц', o.lastMonthCount.toString()),
                _vertDivider(),
                _miniStat('Ср. доставка', '${o.averageFulfillmentDays} дн.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    final palette = AppColorPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: palette.ink.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _vertDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }

  // Топ товары

  Widget _buildTopProductsCard() {
    if (_topProducts.isEmpty) return const SizedBox.shrink();
    final palette = AppColorPalette.of(context);

    final maxRevenue = _topProducts.isNotEmpty
        ? _topProducts.map((p) => p.revenue).reduce(math.max).toDouble()
        : 1.0;

    return _card(
      title: 'Топ товары',
      icon: Icons.emoji_events_rounded,
      child: Column(
        children: _topProducts.take(5).toList().asMap().entries.map((e) {
          final rank = e.key + 1;
          final p = e.value;
          final pct = maxRevenue > 0
              ? (p.revenue / maxRevenue).clamp(0.0, 1.0)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rankBadge(rank),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.productName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fmtCurrency(p.revenue),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: palette.bgBottom,
                          valueColor: AlwaysStoppedAnimation(
                            rank == 1
                                ? palette.star
                                : rank == 2
                                ? palette.muted
                                : rank == 3
                                ? palette.warning
                                : palette.primary.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.unitsSold} шт. продано',
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.ink.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _rankBadge(int rank) {
    final palette = AppColorPalette.of(context);
    // Используем палитру для всех рангов: золото, серебро, бронза (warning)
    final data = {
      1: [palette.star, palette.accentMist],
      2: [palette.muted, palette.accentMist],
      3: [palette.warning, palette.accentMist],
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = data[rank] ?? [palette.primary, palette.accentMist];
    final bg = isDark ? c[0].withValues(alpha: 0.2) : c[1];

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        rank.toString(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: c[0],
        ),
      ),
    );
  }

  // Покупатели и рейтинг

  Widget _buildBuyersRatingRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_buyerStats != null) Expanded(child: _buildBuyersCard()),
          if (_buyerStats != null && _ratingStats != null)
            const SizedBox(width: 10),
          if (_ratingStats != null) Expanded(child: _buildRatingCard()),
        ],
      ),
    );
  }

  Widget _buildBuyersCard() {
    final b = _buyerStats!;
    final palette = AppColorPalette.of(context);

    return _surfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Покупатели', Icons.people_alt_rounded, palette.primary),
          const SizedBox(height: 14),
          _row2('Всего', b.totalBuyers.toString()),
          const SizedBox(height: 7),
          _row2('Постоянные', '${b.repeatBuyers}'),
          const SizedBox(height: 7),
          _row2('Новые / мес.', b.newBuyersThisMonth.toString()),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (b.repeatBuyersPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: palette.bgBottom,
              valueColor: AlwaysStoppedAnimation(palette.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${b.repeatBuyersPercentage}% постоянных',
            style: TextStyle(
              fontSize: 10,
              color: palette.ink.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    final r = _ratingStats!;
    final palette = AppColorPalette.of(context);

    return _surfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Рейтинг', Icons.star_rounded, palette.star),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                r.totalReviews > 0 ? r.averageRating.toStringAsFixed(1) : '—',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: palette.star,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 3),
                child: Text(
                  '/5',
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.ink.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${r.totalReviews} отзывов',
            style: TextStyle(
              fontSize: 11,
              color: palette.ink.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          ...[5, 4, 3, 2, 1].map((star) {
            final counts = [
              r.fiveStarCount,
              r.fourStarCount,
              r.threeStarCount,
              r.twoStarCount,
              r.oneStarCount,
            ];
            final count = counts[5 - star];
            final pct = r.totalReviews > 0
                ? (count / r.totalReviews).clamp(0.0, 1.0)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 10,
                    child: Text(
                      '$star',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.star_rounded, size: 9, color: palette.star),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: palette.bgBottom,
                        valueColor: AlwaysStoppedAnimation(palette.star),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 18,
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: palette.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Последние заказы

  Widget _buildRecentOrdersCard() {
    if (_orderStats == null || _orderStats!.recentOrders.isEmpty) {
      return const SizedBox.shrink();
    }
    final palette = AppColorPalette.of(context);

    return _card(
      title: 'Последние заказы',
      icon: Icons.receipt_rounded,
      child: Column(
        children: _orderStats!.recentOrders.take(5).map((order) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.bgTop,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.line.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.local_shipping_rounded,
                    size: 16,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Заказ #${order.orderId}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _fmtDate(order.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.ink.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmtCurrency(order.totalAmount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.primary,
                      ),
                    ),
                    _statusBadge(order.status),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Цвета статусов синхронизированы с основной палитрой
  Widget _statusBadge(String status) {
    final palette = AppColorPalette.of(context);
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'доставлен':
        color = palette.statusDelivered;
        break;
      case 'shipped':
      case 'отправлен':
        color = palette.statusShipped;
        break;
      case 'cancelled':
      case 'отменён':
        color = palette.statusCancelled;
        break;
      case 'pending':
      case 'ожидает':
        color = palette.statusPending;
        break;
      default:
        color = palette.secondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Последние отзывы

  Widget _buildRecentReviewsCard() {
    if (_ratingStats == null || _ratingStats!.recentReviews.isEmpty) {
      return const SizedBox.shrink();
    }
    final palette = AppColorPalette.of(context);

    return _card(
      title: 'Последние отзывы',
      icon: Icons.reviews_rounded,
      child: Column(
        children: _ratingStats!.recentReviews.take(3).map((review) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.bgTop,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.line.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        review.productName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 13,
                          color: palette.star,
                        ),
                      ),
                    ),
                  ],
                ),
                if (review.commentSnippet.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    review.commentSnippet.length > 130
                        ? '${review.commentSnippet.substring(0, 130)}…'
                        : review.commentSnippet,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: palette.ink.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // AI-резюме

  Widget _buildAiSummaryCard() {
    // Не показываем карточку, если нет ни резюме, ни ошибки, ни загрузки
    if (!_isLoadingAiSummary && _aiSummary == null && _aiSummaryError == null) {
      return const SizedBox.shrink();
    }

    final palette = AppColorPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: palette.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AI-анализ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoadingAiSummary) ...[
            // Анимированная загрузка
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Генерирую AI-анализ…',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Skeleton loader для текста
                _buildSkeletonLine(width: double.infinity),
                const SizedBox(height: 8),
                _buildSkeletonLine(width: double.infinity),
                const SizedBox(height: 8),
                _buildSkeletonLine(width: 250),
              ],
            ),
          ] else if (_aiSummaryError != null) ...[
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: palette.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _aiSummaryError!,
                    style: TextStyle(fontSize: 13, color: palette.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadAiSummary,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Повторить', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ] else if (_aiSummary != null && _aiSummary!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.accentSoft.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                _aiSummary!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: palette.ink.withValues(alpha: 0.87),
                  letterSpacing: 0.2,
                ),
              ),
            )
          // Если нет ни резюме, ни ошибки — ничего не показываем
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // Вспомогательные функции разметки

  Widget _buildSkeletonLine({required double width}) {
    final palette = AppColorPalette.of(context);
    return Container(
      height: 14,
      width: width,
      decoration: BoxDecoration(
        color: palette.bgBottom.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final palette = AppColorPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, icon),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _surfaceContainer({required Widget child}) {
    final palette = AppColorPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    final palette = AppColorPalette.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: palette.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
      ],
    );
  }

  Widget _cardHeader(String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _row2(String label, String value) {
    final palette = AppColorPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: palette.ink.withValues(alpha: 0.55),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Утилиты форматирования

  /// Форматирует значения оси Y графика
  String _formatYAxis(double value, double maxY) {
    if (maxY < 1000) {
      return value.toInt().toString();
    } else if (maxY < 1000000) {
      final thousands = value / 1000;
      if (thousands < 10) {
        return '${thousands.toStringAsFixed(1)}K';
      }
      return '${thousands.toInt()}K';
    } else {
      final millions = value / 1000000;
      if (millions < 10) {
        return '${millions.toStringAsFixed(1)}M';
      }
      return '${millions.toInt()}M';
    }
  }

  String _fmtCurrency(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buf.write('\u202F'); // narrow no-break space
      }
      buf.write(s[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()} ₸';
  }

  String _fmtDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}
