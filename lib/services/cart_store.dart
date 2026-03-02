import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartStore extends ChangeNotifier {
  CartStore._();

  static final CartStore instance = CartStore._();

  final Map<String, List<CartItem>> _itemsBySupplier = {};

  Map<String, List<CartItem>> get itemsBySupplier {
    return _itemsBySupplier.map(
      (key, value) => MapEntry(key, List<CartItem>.unmodifiable(value)),
    );
  }

  int get totalPositions {
    int total = 0;
    _itemsBySupplier.forEach((_, items) {
      total += items.length;
    });
    return total;
  }

  int get totalAmount {
    int total = 0;
    _itemsBySupplier.forEach((_, items) {
      for (final item in items) {
        total += item.supplier.pricePerUnit * item.quantity;
      }
    });
    return total;
  }

  int get totalUnits {
    int total = 0;
    _itemsBySupplier.forEach((_, items) {
      for (final item in items) {
        total += item.quantity;
      }
    });
    return total;
  }

  int _applyQuantityBounds({
    required int quantity,
    required int min,
    int? max,
  }) {
    final safeMin = quantity < min ? min : quantity;
    if (max == null) return safeMin;
    final effectiveMax = max < min ? min : max;
    return safeMin > effectiveMax ? effectiveMax : safeMin;
  }

  bool contains({
    required String supplierId,
    required String productId,
  }) {
    final items = _itemsBySupplier[supplierId];
    if (items == null) return false;
    return items.any((item) => item.product.id == productId);
  }

  void addOrUpdate({
    required Product product,
    required Supplier supplier,
    required int quantity,
  }) {
    final safeQuantity = _applyQuantityBounds(
      quantity: quantity,
      min: supplier.minQuantity,
      max: supplier.maxQuantity,
    );
    final items = _itemsBySupplier.putIfAbsent(supplier.id, () => []);
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      items.add(
        CartItem(
          product: product,
          supplier: supplier,
          quantity: safeQuantity,
        ),
      );
    } else {
      items[index] = items[index].copyWith(quantity: safeQuantity);
    }
    notifyListeners();
  }

  void updateQuantity({
    required String supplierId,
    required String productId,
    required int quantity,
    int? minQuantity,
    int? maxQuantity,
  }) {
    final items = _itemsBySupplier[supplierId];
    if (items == null) return;
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;

    final minAllowed = minQuantity ?? 1;
    final safeQuantity = _applyQuantityBounds(
      quantity: quantity,
      min: minAllowed,
      max: maxQuantity,
    );
    items[index] = items[index].copyWith(quantity: safeQuantity);
    notifyListeners();
  }

  void removeItem({
    required String supplierId,
    required String productId,
  }) {
    final items = _itemsBySupplier[supplierId];
    if (items == null) return;
    items.removeWhere((item) => item.product.id == productId);
    if (items.isEmpty) {
      _itemsBySupplier.remove(supplierId);
    }
    notifyListeners();
  }

  void clear() {
    _itemsBySupplier.clear();
    notifyListeners();
  }
}
