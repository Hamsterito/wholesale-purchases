import 'package:flutter/foundation.dart';
import '../models/product.dart';

class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();

  static final FavoritesStore instance = FavoritesStore._();

  final Map<String, Product> _items = {};

  List<Product> get items => List<Product>.unmodifiable(_items.values);

  bool contains(String productId) {
    return _items.containsKey(productId);
  }

  void add(Product product) {
    _items[product.id] = product;
    notifyListeners();
  }

  void remove(String productId) {
    if (_items.remove(productId) != null) {
      notifyListeners();
    }
  }

  /// Returns true if added, false if removed.
  bool toggle(Product product) {
    if (contains(product.id)) {
      remove(product.id);
      return false;
    }
    add(product);
    return true;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
