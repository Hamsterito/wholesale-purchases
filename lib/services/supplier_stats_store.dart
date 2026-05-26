import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// Кеш свежих агрегатов поставщика: rating и reviewCount.
/// Источник истины - ApiService.getSupplier. Когда Supplier приходит из
/// Product.suppliers или из других выборок, его рейтинг может отставать -
/// этот стор позволяет подмешать актуальные значения там, где они показываются.
class SupplierStatsStore extends ChangeNotifier {
  SupplierStatsStore._();

  static final SupplierStatsStore instance = SupplierStatsStore._();

  final Map<String, _SupplierStats> _stats = {};

  /// Сохраняет свежие rating/reviewCount для поставщика.
  /// Вызывается из мест, где загружается профиль: SupplierProfilePage и т.п.
  void update(Supplier supplier) {
    final id = supplier.id.trim();
    if (id.isEmpty) return;
    final next = _SupplierStats(
      rating: supplier.rating,
      reviewCount: supplier.reviewCount,
    );
    final prev = _stats[id];
    if (prev == next) return;
    _stats[id] = next;
    notifyListeners();
  }

  /// Возвращает актуальный rating, если он известен. Иначе - fallback.
  double rating(String supplierId, {required double fallback}) {
    return _stats[supplierId.trim()]?.rating ?? fallback;
  }

  /// Возвращает актуальный reviewCount, если он известен. Иначе - fallback.
  int reviewCount(String supplierId, {required int fallback}) {
    return _stats[supplierId.trim()]?.reviewCount ?? fallback;
  }
}

class _SupplierStats {
  const _SupplierStats({required this.rating, required this.reviewCount});

  final double rating;
  final int reviewCount;

  @override
  bool operator ==(Object other) =>
      other is _SupplierStats &&
      other.rating == rating &&
      other.reviewCount == reviewCount;

  @override
  int get hashCode => Object.hash(rating, reviewCount);
}
