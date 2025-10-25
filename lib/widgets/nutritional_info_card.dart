import 'package:flutter/material.dart';
import '../models/product.dart';

class NutritionalInfoCard extends StatelessWidget {
  final NutritionalInfo nutritionalInfo;

  const NutritionalInfoCard({super.key, required this.nutritionalInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Пищевая ценность',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'В 100 граммах',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildNutritionItem(
                '${nutritionalInfo.calories.toStringAsFixed(0)} кк',
                'Калории',
              ),
              _buildNutritionItem(
                '${nutritionalInfo.protein.toStringAsFixed(0)} г',
                'Белки',
              ),
              _buildNutritionItem(
                '${nutritionalInfo.fat.toStringAsFixed(0)} г',
                'Жиры',
              ),
              _buildNutritionItem(
                '${nutritionalInfo.carbohydrates.toStringAsFixed(1)} г',
                'Углеводы',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
