import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../../theme/app_color_palette.dart';
import '../product/product_card.dart';

class SimilarProductsCarousel extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTap;

  const SimilarProductsCarousel({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final palette = context.colorPalette;

    return Container(
      color: palette.card,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gridPadding = 16.0;
          const gridSpacing = 15.0;
          const cardHeight = 323.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: gridPadding),
                child: Text(
                  context.l10n.similarProducts,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: gridPadding),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: gridSpacing,
                  mainAxisSpacing: gridSpacing,
                  mainAxisExtent: cardHeight,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    compact: false,
                    enableImageSwipe: false,
                    onTap: () => onProductTap(product),
                    onAddToCart: () {},
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
