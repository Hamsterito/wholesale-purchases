import 'package:flutter/material.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  // Пример данных заказов
  final List<Order> orders = [
    Order(
      id: '№12345',
      date: DateTime(2025, 10, 30),
      status: 'В пути',
      items: [
        OrderItem(
          name: 'Напиток Coca-Cola газированный',
          volume: '1.5 л',
          price: 3160,
          quantity: 2,
          imageUrl: 'https://via.placeholder.com/80',
          isReceived: false,
        ),
        OrderItem(
          name: 'Вода питьевая Nestle Pure Life',
          volume: '5 л',
          price: 1200,
          quantity: 1,
          imageUrl: 'https://via.placeholder.com/80',
          isReceived: false,
        ),
      ],
    ),
    Order(
      id: '№12344',
      date: DateTime(2025, 10, 29),
      status: 'Доставлен',
      items: [
        OrderItem(
          name: 'Напиток Fanta газированный',
          volume: '1.5 л',
          price: 2900,
          quantity: 3,
          imageUrl: 'https://via.placeholder.com/80',
          isReceived: true,
        ),
      ],
    ),
    Order(
      id: '№12343',
      date: DateTime(2025, 10, 28),
      status: 'Доставлен',
      items: [
        OrderItem(
          name: 'Напиток Sprite газированный',
          volume: '1.5 л',
          price: 3000,
          quantity: 1,
          imageUrl: 'https://via.placeholder.com/80',
          isReceived: true,
        ),
        OrderItem(
          name: 'Сок Rich апельсиновый',
          volume: '1 л',
          price: 1500,
          quantity: 2,
          imageUrl: 'https://via.placeholder.com/80',
          isReceived: true,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Мои заказы',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final totalAmount = order.items.fold<int>(
      0,
          (sum, item) => sum + (item.price * item.quantity),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок заказа
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заказ ${order.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.date),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: order.status == 'Доставлен'
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: order.status == 'Доставлен'
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF9800),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Список товаров
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            itemBuilder: (context, index) {
              return _buildOrderItem(order.items[index], order.status);
            },
          ),

          const Divider(height: 1),

          // Итого
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Общая сумма:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$totalAmount ₸',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5B8DEE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item, String orderStatus) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение товара
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.local_drink, size: 40, color: Colors.grey);
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Информация о товаре
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.volume,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${item.price} ₸',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Чекбокс подтверждения
          Column(
            children: [
              Checkbox(
                value: item.isReceived,
                onChanged: orderStatus == 'Доставлен'
                    ? (bool? value) {
                  setState(() {
                    item.isReceived = value ?? false;
                  });
                }
                    : null,
                activeColor: const Color(0xFF5B8DEE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text(
                'Принят',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(date.year, date.month, date.day);

    if (orderDay == today) {
      return 'Сегодня, ${date.day} ${months[date.month - 1]}';
    } else if (orderDay == today.subtract(const Duration(days: 1))) {
      return 'Вчера, ${date.day} ${months[date.month - 1]}';
    } else if (orderDay == today.add(const Duration(days: 1))) {
      return 'Завтра, ${date.day} ${months[date.month - 1]}';
    } else {
      return '${date.day} ${months[date.month - 1]}';
    }
  }
}

// Модели данных
class Order {
  final String id;
  final DateTime date;
  final String status;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.date,
    required this.status,
    required this.items,
  });
}

class OrderItem {
  final String name;
  final String volume;
  final int price;
  final int quantity;
  final String imageUrl;
  bool isReceived;

  OrderItem({
    required this.name,
    required this.volume,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.isReceived,
  });
}