enum RangeType {
  singleDay,
  intraMonth,
  interMonth,
  multiMonth,
}

enum Granularity {
  daily,
  monthly,
}

class RangeTypeResult {
  final RangeType type;
  final Granularity granularity;
  final int dayCount;
  final int monthCount;

  RangeTypeResult({
    required this.type,
    required this.granularity,
    required this.dayCount,
    required this.monthCount,
  });
}

class RangeTypeDetector {
  /// Определяет тип диапазона и его гранулярность
  static RangeTypeResult detectRangeType(DateTime startDate, DateTime endDate) {
    // Вычисляем количество дней
    final dayCount = endDate.difference(startDate).inDays + 1;

    // Вычисляем количество месяцев
    int monthCount = 0;
    DateTime current = DateTime(startDate.year, startDate.month);
    final endMonth = DateTime(endDate.year, endDate.month);

    while (!current.isAfter(endMonth)) {
      monthCount++;
      current = DateTime(current.year, current.month + 1);
    }

    // Определяем тип диапазона
    late RangeType type;
    late Granularity granularity;

    if (dayCount == 1) {
      type = RangeType.singleDay;
      granularity = Granularity.daily;
    } else if (startDate.year == endDate.year &&
        startDate.month == endDate.month) {
      type = RangeType.intraMonth;
      granularity = Granularity.daily;
    } else if (monthCount == 2) {
      type = RangeType.interMonth;
      granularity = Granularity.monthly;
    } else {
      type = RangeType.multiMonth;
      granularity = Granularity.monthly;
    }

    return RangeTypeResult(
      type: type,
      granularity: granularity,
      dayCount: dayCount,
      monthCount: monthCount,
    );
  }
}
