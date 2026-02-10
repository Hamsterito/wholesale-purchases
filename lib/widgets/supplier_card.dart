import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/ru_plural.dart';

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final int quantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onSelect;
  final bool isSelected;

  const SupplierCard({
    super.key,
    required this.supplier,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onSelect,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = supplier.pricePerUnit * quantity;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBg = colorScheme.surface;
    final mutedText = colorScheme.onSurfaceVariant;
    final borderColor = colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          supplier.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 12,
                            color: Color(0xFFF5B400),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reviewsLabel(supplier.reviewCount),
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? const Color(0xFF22C55E) : const Color(0xFF6288D5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isSelected ? 'Выбран' : 'Выбрать',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${supplier.pricePerUnit} \u20B8',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'шт',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6288D5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalPrice \u20B8',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6288D5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${quantity} шт.',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 14,
                color: mutedText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${supplier.deliveryInfo}, ${supplier.deliveryDate}',
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


