import 'package:flutter_project/services/localization/app_localizations.dart';
import '../../models/product.dart';
import 'api_service.dart';
import '../app_logger.dart';

/// Источник актуальных Product при применении шаблона. Абстракция нужна,
/// чтобы тестировать apply без сети.
abstract class ProductResolver {
  /// null - товар недоступен.
  Future<Product?> resolveProduct(String productId);
}

/// Резолвер поверх ApiService.getProducts. Кэш живёт в рамках одного apply:
/// первый вызов грузит каталог, остальные отвечают из памяти.
/// Если getProducts упал - все resolveProduct возвращают null.
class ApiProductResolver implements ProductResolver {
  ApiProductResolver({Future<List<Product>> Function()? fetchProducts})
    : _fetchProducts = fetchProducts ?? ApiService.getProducts;

  static const String _logScope = 'templates';

  final Future<List<Product>> Function() _fetchProducts;

  // Шарим один Future между параллельными вызовами resolveProduct, чтобы
  // не дёргать API дважды на одном применении шаблона.
  Future<Map<String, Product>?>? _loading;
  Map<String, Product>? _cache;
  bool _failed = false;

  @override
  Future<Product?> resolveProduct(String productId) async {
    if (_failed) return null;

    final cache = _cache ?? await _ensureLoaded();
    if (cache == null) return null;
    return cache[productId];
  }

  Future<Map<String, Product>?> _ensureLoaded() {
    return _loading ??= _loadCatalog();
  }

  Future<Map<String, Product>?> _loadCatalog() async {
    try {
      final products = await _fetchProducts();
      final map = <String, Product>{for (final p in products) p.id: p};
      _cache = map;
      return map;
    } catch (e, st) {
      AppLogger.error(
        AppLocalizations.current.getString('auto_apiproductresolver_ne_udalos_zagruz'),
        scope: _logScope,
        error: e,
        stackTrace: st,
      );
      _failed = true;
      return null;
    }
  }
}

/// Резолвер из готовой мапы id → Product, для тестов.
class InMemoryProductResolver implements ProductResolver {
  InMemoryProductResolver(Map<String, Product> products)
    : _products = Map<String, Product>.unmodifiable(products);

  final Map<String, Product> _products;

  @override
  Future<Product?> resolveProduct(String productId) async {
    return _products[productId];
  }
}
