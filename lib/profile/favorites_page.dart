import 'package:flutter/material.dart';
import '../services/favorites_store.dart';
import '../widgets/product_card.dart';
import '../widgets/main_bottom_nav.dart';
import '../pages/product_detail_page.dart';
import '../models/product.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FavoritesStore.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Избранное',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final items = store.items;
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Пока нет избранных товаров',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 20,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final product = items[index];
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(
                        product: product,
                        similarProducts: _buildSimilar(items, product),
                      ),
                    ),
                  );
                },
                onAddToCart: () {},
                showMessages: true,
                showFavoritesUndo: true,
              );
            },
          );
        },
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  List<Product> _buildSimilar(List<Product> items, Product current) {
    return items.where((product) => product.id != current.id).toList();
  }
}
