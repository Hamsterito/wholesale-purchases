import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_color_palette.dart';
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
    final palette = context.colorPalette;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
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
                        color: palette.ink,
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
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...List.generate(
                          5,
                          (index) =>
                              Icon(Icons.star, size: 12, color: palette.star),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reviewsLabel(supplier.reviewCount),
                          style: TextStyle(fontSize: 11, color: palette.muted),
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
                    backgroundColor: isSelected
                        ? palette.success
                        : palette.accent,
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
                  color: palette.ink,
                ),
              ),
              const SizedBox(width: 4),
              Text('шт', style: TextStyle(fontSize: 12, color: palette.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalPrice \u20B8',
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$quantity шт.',
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 14,
                color: palette.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${supplier.deliveryInfo}, ${supplier.deliveryDate}',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
