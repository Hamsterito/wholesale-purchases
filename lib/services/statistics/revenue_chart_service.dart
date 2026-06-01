import 'package:fl_chart/fl_chart.dart';
import '../../models/supplier_stats.dart';
import '../../models/chart_data.dart';

/// Главный сервис для обработки данных выручки и построения графиков
class RevenueChartService {
  /// Строит данные графика из дневных данных
  static ChartData buildChartDataFromDaily(List<DailyRevenue> dailyRevenues) {
    final now = DateTime.now();
    final filtered = dailyRevenues.where((r) => !r.date.isAfter(now)).toList();

    final spots = filtered
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble()))
        .toList();

    final labels = filtered.map((r) => r.formattedDate).toList();

    final maxY = filtered.isEmpty
        ? 0.0
        : (filtered.map((r) => r.revenue).reduce((a, b) => a > b ? a : b) *
                1.25)
            .toDouble();

    return ChartData(
      spots: spots,
      labels: labels,
      granularity: Granularity.daily,
      maxY: maxY,
    );
  }

  /// Строит данные графика из месячных данных
  static ChartData buildChartDataFromMonthly(
    List<RevenueHistory> monthlyRevenues,
  ) {
    final now = DateTime.now();
    final filtered = monthlyRevenues
        .where((r) => r.date == null || !r.date!.isAfter(DateTime(now.year, now.month + 1)))
        .toList();

    final spots = filtered
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble()))
        .toList();

    final labels = filtered.map((r) => r.month).toList();

    final maxY = filtered.isEmpty
        ? 0.0
        : (filtered
                .map((r) => r.revenue)
                .reduce((a, b) => a > b ? a : b) *
                1.25)
            .toDouble();

    return ChartData(
      spots: spots,
      labels: labels,
      granularity: Granularity.monthly,
      maxY: maxY,
    );
  }
}