import 'package:flutter/material.dart';
import '../../models/supplier_stats.dart';
import 'range_type_detector.dart';

class FilteringService {
  /// Фильтрует записи по диапазону дат
  static List<RevenueHistory> filterByDateRange(
    List<RevenueHistory> entries,
    DateTimeRange selectedRange,
    RangeType rangeType,
  ) {
    final result = <RevenueHistory>[];

    for (final entry in entries) {
      if (entry.date == null) continue;

      final entryDate = entry.date!;

      // Для межмесячного и многомесячного диапазонов проверяем пересечение месяцев
      if (rangeType == RangeType.interMonth || rangeType == RangeType.multiMonth) {
        // Проверяем, пересекается ли месяц с диапазоном
        final monthStart = DateTime(entryDate.year, entryDate.month, 1);
        final monthEnd = DateTime(entryDate.year, entryDate.month + 1, 0);

        // Месяц пересекается с диапазоном, если:
        // - начало месяца <= конец диапазона И
        // - конец месяца >= начало диапазона
        if (!monthStart.isAfter(selectedRange.end) &&
            !monthEnd.isBefore(selectedRange.start)) {
          result.add(entry);
        }
      } else {
        // Для внутримесячного и однодневного диапазонов проверяем точное совпадение дня
        if (!entryDate.isBefore(selectedRange.start) &&
            !entryDate.isAfter(selectedRange.end)) {
          result.add(entry);
        }
      }
    }

    return result;
  }
}
