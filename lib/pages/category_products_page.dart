import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({
    super.key,
    required this.title,
    required this.keywords,
  });

  final String title;
  final List<String> keywords;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant.withValues(
        alpha: _isDark ? 0.9 : 0.7,
      );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final products = await ApiService.getProducts();

      setState(() {
        _products = _filterProducts(products);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки товаров: $e';
        _isLoading = false;
      });
    }
  }

  List<Product> _filterProducts(List<Product> source) {
    if (widget.keywords.isEmpty) return source;
    final keywords = widget.keywords
        .map((keyword) => keyword.trim().toLowerCase())
        .where((keyword) => keyword.isNotEmpty)
        .toList();
    if (keywords.isEmpty) return source;

    return source.where((product) {
      final name = product.name.toLowerCase();
      if (keywords.any(name.contains)) return true;
      for (final category in product.categories) {
        final normalized = category.toLowerCase();
        for (final keyword in keywords) {
          if (normalized == keyword ||
              normalized.contains(keyword) ||
              keyword.contains(normalized)) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          widget.title,
          style: _theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: _colorScheme.onSurface),
      ),
      body: _buildContent(),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6288D5),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: _mutedText),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: _mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6288D5),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Text(
          'В этой категории пока нет товаров',
          style: TextStyle(color: _mutedText, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF6288D5),
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ProductCard(
            product: product,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(
                    product: product,
                    similarProducts: _products
                        .where((p) => p.id != product.id)
                        .take(10)
                        .toList(),
                  ),
                ),
              );
            },
            onAddToCart: () {},
            showMessages: false,
          );
        },
      ),
    );
  }
}
