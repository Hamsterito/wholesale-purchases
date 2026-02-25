class SupplierOrder {
  final String id;
  final DateTime date;
  final String status;
  final String deliveryAddress;
  final List<SupplierOrderItem> items;

  SupplierOrder({
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

  factory SupplierOrder.fromJson(Map<String, dynamic> json) {
    return SupplierOrder(
      id: json['id']?.toString() ?? '',
      date: _parseDate(json['date']),
      status: json['status']?.toString() ?? '',
      deliveryAddress:
          json['deliveryAddress']?.toString() ??
          json['delivery_address']?.toString() ??
          '',
      items:
          (json['items'] as List?)
              ?.map((item) => SupplierOrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    final asString = value.toString();
    try {
      return DateTime.parse(asString);
    } catch (_) {
      return DateTime.now();
    }
  }
}

class SupplierOrderItem {
  final String name;
  final int price;
  final int quantity;
  final String imageUrl;
  final bool isReceived;

  SupplierOrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.isReceived,
  });

  factory SupplierOrderItem.fromJson(Map<String, dynamic> json) {
    return SupplierOrderItem(
      name: json['name']?.toString() ?? '',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      isReceived: json['isReceived'] ?? false,
    );
  }
}
