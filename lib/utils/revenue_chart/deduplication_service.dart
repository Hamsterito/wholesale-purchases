import '../../models/supplier_stats.dart';

class DeduplicationService {
  /// Удаляет дубликаты по месяцу, оставляя первое вхождение
  static List<RevenueHistory> deduplicateByMonth(
    List<RevenueHistory> entries,
  ) {
    final seen = <String>{};
    final result = <RevenueHistory>[];

    for (final entry in entries) {
      if (seen.add(entry.month)) {
        result.add(entry);
      }
    }

    return result;
  }
}
