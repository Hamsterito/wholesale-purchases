import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Главная',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.black),
          ],
        ),
      ),
      body: Column(
        children: [
          // Поиск
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Фильтры
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.sort, size: 20, color: Colors.black),
                SizedBox(width: 8),
                Icon(Icons.tune, size: 20, color: Colors.black),
                SizedBox(width: 16),
                Text('Все', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                SizedBox(width: 16),
                Text('Напитки', style: TextStyle(color: Colors.grey)),
                SizedBox(width: 16),
                Text('Овощи фрукты', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          // Список товаров
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  imageUrl: 'assets/cart_home/CocaCola.png',
                  title: 'Напиток Coca-Cola газированный 1.5 л',
                  minQuantity: 'Минимум: 4 упаковок',
                  warehouse: 'Склад "Аскар"',
                  rating: 4.7,
                  reviews: 13,
                  price: 815,
                  oldPrice: 19560,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required String imageUrl,
    required String title,
    required String minQuantity,
    required String warehouse,
    required double rating,
    required int reviews,
    required int price,
    required int oldPrice,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение товара
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
          ),

          // Информация о товаре
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    minQuantity,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 9,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    warehouse,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 9,
                    ),
                  ),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 12),
                      SizedBox(width: 2),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$reviews отзывов',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$price ₸',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$oldPrice ₸',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.add,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}