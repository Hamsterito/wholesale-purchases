import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final supplier = product.bestSupplier;
    final totalPrice = supplier.getTotalPrice(supplier.minQuantity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(supplier),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeliveryInfo(supplier),
                    const SizedBox(height: 2),
                    _buildProductTitle(),
                    const SizedBox(height: 2),
                    _buildMinOrder(supplier),
                    const SizedBox(height: 1),
                    _buildWarehouse(supplier),
                    const SizedBox(height: 1),
                    _buildRating(),
                    const Spacer(),
                    _buildPriceSection(supplier, totalPrice),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(Supplier supplier) {
    return Stack(
      children: [
        Container(
          height: 140,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(
            product.imageUrls.first,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image, size: 60, color: Colors.grey);
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6288D5).withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Text(
              supplier.deliveryBadge,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo(Supplier supplier) {
    return Text(
      'Доставка: ${supplier.deliveryDate}',
      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
    );
  }

  Widget _buildProductTitle() {
    return Text(
      product.name,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMinOrder(Supplier supplier) {
    return Text(
      'Минимум: ${supplier.minQuantity} упаковок',
      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
    );
  }

  Widget _buildWarehouse(Supplier supplier) {
    return Text(
      supplier.name,
      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        Text(
          product.rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 12, color: Colors.amber),
        const Icon(Icons.star, size: 12, color: Colors.amber),
        const Icon(Icons.star, size: 12, color: Colors.amber),
        const Icon(Icons.star, size: 12, color: Colors.amber),
        const Icon(Icons.star, size: 12, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          '${product.reviewCount} отзывов',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPriceSection(Supplier supplier, int totalPrice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${supplier.pricePerUnit} ₸',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6288D5).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$totalPrice ₸',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6288D5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6288D5)),
            onPressed: onAddToCart,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            iconSize: 26,
          ),
        ),
      ],
    );
  }
}
