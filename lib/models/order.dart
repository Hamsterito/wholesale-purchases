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

  int get totalAmount {
    return items.fold<int>(0, (sum, item) => sum + (item.price * item.quantity));
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      date: _parseDate(json['date']),
      status: json['status'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    final asString = value.toString();
    try {
      return DateTime.parse(asString);
    } catch (_) {
      return DateTime.now();
    }
  }
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

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      volume: json['volume'] ?? '',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      isReceived: json['isReceived'] ?? false,
    );
  }
}
