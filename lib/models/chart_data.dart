import 'package:fl_chart/fl_chart.dart';

/// Перечисление для типов детализации графика
enum Granularity { daily, monthly }

/// Модель данных для графика выручки
class ChartData {
  /// Точки данных для графика
  final List<FlSpot> spots;

  /// Метки для оси X
  final List<String> labels;

  /// Тип детализации (дневная или месячная)
  final Granularity granularity;

  /// Максимальное значение на оси Y для масштабирования
  final double maxY;

  ChartData({
    required this.spots,
    required this.labels,
    required this.granularity,
    required this.maxY,
  });
}

/// Модель для дневной выручки
class DailyRevenue {
  /// Дата
  final DateTime date;

  /// Выручка за день
  final int revenue;

  /// Форматированная дата для отображения (например, "14.05")
  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  DailyRevenue({required this.date, required this.revenue});

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: DateTime.parse(json['date']),
      revenue: json['revenue'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'revenue': revenue};
  }
}
