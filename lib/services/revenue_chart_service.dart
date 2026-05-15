import 'package:fl_chart/fl_chart.dart';
import '../models/supplier_stats.dart';
import '../models/chart_data.dart';

/// Главный сервис для обработки данных выручки и построения графиков
class RevenueChartService {
  /// Строит данные графика из дневных данных
  static ChartData buildChartDataFromDaily(List<DailyRevenue> dailyRevenues) {
    final spots = dailyRevenues
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble()))
        .toList();

    final labels = dailyRevenues.map((r) => r.formattedDate).toList();

    final maxY = dailyRevenues.isEmpty
        ? 0.0
        : (dailyRevenues.map((r) => r.revenue).reduce((a, b) => a > b ? a : b) *
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
    final spots = monthlyRevenues
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble()))
        .toList();

    final labels = monthlyRevenues.map((r) => r.month).toList();

    final maxY = monthlyRevenues.isEmpty
        ? 0.0
        : (monthlyRevenues
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
