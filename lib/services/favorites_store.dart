import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import 'app_logger.dart';
import 'shared_prefs_provider.dart';

class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();

  static final FavoritesStore instance = FavoritesStore._();

  static const String _productsKey = 'favorites_products';
  static const String _suppliersKey = 'favorites_suppliers';

  final Map<String, Product> _items = {};

  // Избранные поставщики - хранятся полностью, чтобы отображать без запроса к API
  final Map<String, Supplier> _supplierItems = {};

  // Геттеры возвращают неизменяемые копии, чтобы внешний код не мог изменить состояние напрямую

  List<Product> get items => List<Product>.unmodifiable(_items.values);

  List<Supplier> get suppliers =>
      List<Supplier>.unmodifiable(_supplierItems.values);

  // Методы для товаров

  bool contains(String productId) {
    return _items.containsKey(productId);
  }

  void add(Product product) {
    _items[product.id] = product;
    notifyListeners();
    saveToStorage();
  }

  void remove(String productId) {
    if (_items.remove(productId) != null) {
      notifyListeners();
      saveToStorage();
    }
  }

  /// Возвращает true если товар добавлен, false если удалён.
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
    saveToStorage();
  }

  // Методы для поставщиков

  bool containsSupplier(String supplierId) {
    return _supplierItems.containsKey(supplierId);
  }

  void addSupplier(Supplier supplier) {
    _supplierItems[supplier.id] = supplier;
    notifyListeners();
    saveToStorage();
  }

  void removeSupplier(String supplierId) {
    if (_supplierItems.remove(supplierId) != null) {
      notifyListeners();
      saveToStorage();
    }
  }

  /// Возвращает true если поставщик добавлен, false если удалён.
  bool toggleSupplier(Supplier supplier) {
    if (containsSupplier(supplier.id)) {
      removeSupplier(supplier.id);
      return false;
    }
    addSupplier(supplier);
    return true;
  }

  // Персистентность

  /// Загружает избранные товары и поставщиков из SharedPreferences.
  /// Вызывается при инициализации приложения.
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();

      // Товары хранятся только по ID; полные данные недоступны без API,
      // поэтому при загрузке из хранилища список остаётся пустым до первого
      // обращения к API. Это поведение сохранено из исходной реализации.

      // Загружаем поставщиков - хранятся как JSON-массив полных объектов
      final suppliersJson = prefs.getString(_suppliersKey);
      if (suppliersJson != null && suppliersJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(suppliersJson);
        for (final item in decoded) {
          try {
            final supplier = Supplier.fromJson(item as Map<String, dynamic>);
            if (supplier.id.isNotEmpty) {
              _supplierItems[supplier.id] = supplier;
            }
          } catch (e) {
            AppLogger.warning(
              'Не удалось восстановить поставщика из хранилища',
              scope: 'favorites',
            );
          }
        }
      }

      if (_supplierItems.isNotEmpty) {
        notifyListeners();
      }
    } catch (e, st) {
      AppLogger.error(
        'Ошибка загрузки избранного из хранилища',
        scope: 'favorites',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Сохраняет текущее состояние избранного в SharedPreferences.
  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();

      // Сохраняем ID товаров
      await prefs.setStringList(_productsKey, _items.keys.toList());

      // Сохраняем полные данные поставщиков - нужны для отображения без API
      final suppliersJson = jsonEncode(
        _supplierItems.values.map(_supplierToJson).toList(),
      );
      await prefs.setString(_suppliersKey, suppliersJson);
    } catch (e, st) {
      AppLogger.error(
        'Ошибка сохранения избранного в хранилище',
        scope: 'favorites',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Сериализует поставщика в JSON для хранения.
  Map<String, dynamic> _supplierToJson(Supplier s) {
    return {
      'id': s.id,
      'name': s.name,
      'rating': s.rating,
      'reviewCount': s.reviewCount,
      'pricePerUnit': s.pricePerUnit,
      'minQuantity': s.minQuantity,
      'maxQuantity': s.maxQuantity,
      'stockQuantity': s.stockQuantity,
      'deliveryDate': s.deliveryDate,
      'deliveryInfo': s.deliveryInfo,
      'deliveryBadge': s.deliveryBadge,
      'logoUrl': s.logoUrl,
      'description': s.description,
      'address': s.address,
      'phone': s.phone,
      'email': s.email,
    };
  }
}
