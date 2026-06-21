import 'package:flutter/widgets.dart';
import '../services/localization/localization_extension.dart';
import '../models/language.dart';

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
  final String nameKk;
  final int price;
  final int quantity;
  final String imageUrl;
  final bool isReceived;

  SupplierOrderItem({
    required this.name,
    this.nameKk = '',
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.isReceived,
  });

  factory SupplierOrderItem.fromJson(Map<String, dynamic> json) {
    return SupplierOrderItem(
      name: json['name']?.toString() ?? '',
      nameKk: json['nameKk']?.toString() ?? json['name_kk']?.toString() ?? '',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      isReceived: json['isReceived'] ?? false,
    );
  }
}

extension SupplierOrderItemLocalization on SupplierOrderItem {
  String localizedName(BuildContext context) {
    if (context.currentLanguage == LanguageCode.kazakh && nameKk.trim().isNotEmpty) {
      return nameKk.trim();
    }
    return name.trim();
  }
}
