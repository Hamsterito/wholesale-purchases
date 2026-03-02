class Order {
  final String id;
  final DateTime date;
  final String status;
  final String deliveryAddress;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.date,
    required this.status,
    this.deliveryAddress = '',
    required this.items,
  });

  int get totalAmount {
    return items.fold<int>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  int get totalUnits {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  int get receivedItemsCount {
    return items.fold<int>(0, (sum, item) => sum + (item.isReceived ? 1 : 0));
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      date: _parseDate(json['date']),
      status: json['status'] ?? '',
      deliveryAddress:
          json['deliveryAddress']?.toString() ??
          json['delivery_address']?.toString() ??
          '',
      items:
          (json['items'] as List?)
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
  final String id;
  final String productId;
  final String name;
  final String supplierName;
  final int price;
  final int quantity;
  final String imageUrl;
  bool isReceived;

  OrderItem({
    this.id = '',
    this.productId = '',
    required this.name,
    this.supplierName = '',
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.isReceived,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      name: json['name'] ?? '',
      supplierName:
          json['supplierName']?.toString() ??
          json['supplier_name']?.toString() ??
          '',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      isReceived: json['isReceived'] ?? false,
    );
  }
}
