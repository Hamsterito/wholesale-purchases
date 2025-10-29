import 'package:flutter/material.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Ваши отзывы',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReviewCard(
            productName: 'Напиток Coca-Cola газированный 1.5 л',
            productImage: 'assets/cart_home/CocaCola.png',
            rating: 5,
            date: '15.10.2025',
            reviewText: 'Отличный напиток! Всегда свежий и вкусный. Доставка быстрая, упаковка надежная. Рекомендую!',
          ),
          const SizedBox(height: 12),
          _buildReviewCard(
            productName: 'Молоко кисломолочное 2.5%',
            productImage: 'assets/cart_home/CocaCola.png',
            rating: 4,
            date: '12.10.2025',
            reviewText: 'Хорошее качество, но цена немного завышена. В целом доволен покупкой.',
          ),
          const SizedBox(height: 12),
          _buildReviewCard(
            productName: 'Хлеб белый нарезной',
            productImage: 'assets/cart_home/CocaCola.png',
            rating: 5,
            date: '10.10.2025',
            reviewText: 'Свежий хлеб, мягкий и вкусный. Всегда беру здесь!',
          ),
          const SizedBox(height: 12),
          _buildReviewCard(
            productName: 'Яблоки Голден',
            productImage: 'assets/cart_home/CocaCola.png',
            rating: 3,
            date: '08.10.2025',
            reviewText: 'Яблоки неплохие, но попались немного мятые. Надеюсь в следующий раз будут получше.',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String productName,
    required String productImage,
    required int rating,
    required String date,
    required String reviewText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Продукт с изображением
          Row(
            children: [
              // Изображение товара
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    productImage,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.shopping_bag_outlined,
                        size: 30,
                        color: Colors.grey[400],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Название товара
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Рейтинг
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),

          const SizedBox(height: 12),

          // Текст отзыва
          Text(
            reviewText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Кнопки действий
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  // Редактировать отзыв
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Редактировать'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  // Удалить отзыв
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Удалить'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}