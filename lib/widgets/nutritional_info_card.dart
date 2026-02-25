import 'package:flutter/material.dart';
import '../models/product.dart';

class NutritionalInfoCard extends StatelessWidget {
  final NutritionalInfo nutritionalInfo;

  const NutritionalInfoCard({super.key, required this.nutritionalInfo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = colorScheme.surface;
    final mutedText = colorScheme.onSurfaceVariant;

    return Container(
      color: cardBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Пищевая ценность',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'В 100 граммах:',
            style: TextStyle(fontSize: 12, color: mutedText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem(
                  context: context,
                  value: '${nutritionalInfo.calories.toStringAsFixed(0)} к',
                  label: 'Калории',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNutritionItem(
                  context: context,
                  value: '${nutritionalInfo.protein.toStringAsFixed(0)} г',
                  label: 'Белки',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNutritionItem(
                  context: context,
                  value: '${nutritionalInfo.fat.toStringAsFixed(0)} г',
                  label: 'Жиры',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNutritionItem(
                  context: context,
                  value:
                      '${nutritionalInfo.carbohydrates.toStringAsFixed(1)} г',
                  label: 'Углеводы',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required BuildContext context,
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final mutedText = colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: mutedText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
