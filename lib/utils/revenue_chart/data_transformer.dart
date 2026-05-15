import 'package:flutter/material.dart';
import '../../models/supplier_stats.dart';

class DailyRevenue {
  final DateTime date;
  final int revenue;
  final String formattedDate;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.formattedDate,
  });
}

class DataTransformer {
  /// Преобразует месячную выручку в дневную выручку
  /// Распределяет месячную выручку равномерно по дням в диапазоне
  static List<DailyRevenue> transformMonthlyToDailyRevenue(
    List<RevenueHistory> monthlyEntries,
    DateTimeRange selectedRange,
  ) {
    final result = <DailyRevenue>[];

    for (final entry in monthlyEntries) {
      if (entry.date == null) continue;

      final monthDate = entry.date!;
      final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
      final dailyRevenue = (entry.revenue / daysInMonth).toInt();

      // Генерируем дни для этого месяца
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(monthDate.year, monthDate.month, day);

        // Проверяем, находится ли день в выбранном диапазоне
        if (!date.isBefore(selectedRange.start) &&
            !date.isAfter(selectedRange.end)) {
          result.add(
            DailyRevenue(
              date: date,
              revenue: dailyRevenue,
              formattedDate: day.toString(),
            ),
          );
        }
      }
    }

    return result;
  }
}
