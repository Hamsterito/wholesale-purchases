import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

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
    final pageBg = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: pageBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gridPadding = 16.0;
          const gridSpacing = 12.0;
          const gridAspectRatio = 0.55;
          const listEndPadding = 32.0;

          final cardWidth =
              (constraints.maxWidth - gridPadding * 2 - gridSpacing) / 2;
          final cardHeight = cardWidth / gridAspectRatio;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: gridPadding),
                child: Text(
                  'Похожие товары',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: gridPadding,
                    right: listEndPadding,
                  ),
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: gridSpacing),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return SizedBox(
                      width: cardWidth,
                      child: ProductCard(
                        product: product,
                        compact: false,
                        enableImageSwipe: false,
                        onTap: () => onProductTap(product),
                        onAddToCart: () {},
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

