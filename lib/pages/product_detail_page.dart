import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_image_carousel.dart';
import '../widgets/rating_section.dart';
import '../widgets/category_tags.dart';
import '../widgets/supplier_card.dart';
import '../widgets/nutritional_info_card.dart';
import '../widgets/info_section.dart';
import '../widgets/ratings_breakdown.dart';
import '../widgets/similar_products_carousel.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final List<Product> similarProducts;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.similarProducts = const [],
  });


  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final Map<String, int> _supplierQuantities = {};

  @override
  void initState() {
    super.initState();
    for (var supplier in widget.product.suppliers) {
      _supplierQuantities[supplier.id] = supplier.minQuantity;
    }
  }

  void _updateQuantity(String supplierId, int delta) {
    setState(() {
      final supplier = widget.product.suppliers.firstWhere((s) => s.id == supplierId);
      final currentQty = _supplierQuantities[supplierId] ?? supplier.minQuantity;
      final newQty = currentQty + delta;
      if (newQty >= supplier.minQuantity) {
        _supplierQuantities[supplierId] = newQty;
      }
    });
  }

  void _addToCart(Supplier supplier) {
    final quantity = _supplierQuantities[supplier.id] ?? supplier.minQuantity;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Добавлено в корзину: ${widget.product.name} x$quantity от ${supplier.name}',
        ),
        backgroundColor: const Color(0xFF6288D5),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageCarousel(imageUrls: widget.product.imageUrls),
                RatingSection(
                  rating: widget.product.rating,
                  reviewCount: widget.product.reviewCount,
                  onTap: () {},
                ),
                _buildProductTitle(),
                CategoryTags(categories: widget.product.categories),
                const SizedBox(height: 16),
                _buildSuppliersSection(),
                NutritionalInfoCard(
                  nutritionalInfo: widget.product.nutritionalInfo,
                ),
                InfoSection(
                  title: 'Состав',
                  content: widget.product.ingredients,
                ),
                InfoSection(
                  title: 'Описание',
                  content: widget.product.description,
                ),
                _buildCharacteristicsSection(),
                RatingsBreakdown(
                  rating: widget.product.rating,
                  reviewCount: widget.product.reviewCount,
                  distribution: widget.product.ratingDistribution,
                  onReadAll: () {},
                ),
                if (widget.similarProducts.isNotEmpty)
                  SimilarProductsCarousel(
                    products: widget.similarProducts,
                    onProductTap: (product) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(
                            product: product,
                            similarProducts: widget.similarProducts
                                .where((p) => p.id != product.id)
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.black),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProductTitle() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
      child: Text(
        widget.product.name,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

Widget _buildSuppliersSection() {
  return Container(
    color: Colors.white,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Поставщики',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.product.suppliers.asMap().entries.map((entry) {
          final index = entry.key;
          final supplier = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < widget.product.suppliers.length - 1 ? 12 : 0,
            ),
            child: SupplierCard(
              supplier: supplier,
              quantity: _supplierQuantities[supplier.id] ?? supplier.minQuantity,
              onQuantityChanged: (delta) => _updateQuantity(supplier.id, delta),
              onAddToCart: () => _addToCart(supplier),
            ),
          );
        }),
      ],
    ),
  );
}


  Widget _buildCharacteristicsSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Общие характеристики',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.product.characteristics.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}