class ReviewEntry {
  final String id;
  final String orderId;
  final String orderItemId;
  final String productId;
  final String productName;
  final String productImage;
  final String reviewerName;
  final int rating;
  final String reviewText;
  final DateTime createdAt;

  ReviewEntry({
    required this.id,
    required this.orderId,
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.reviewerName,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });

  factory ReviewEntry.fromJson(Map<String, dynamic> json) {
    return ReviewEntry(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderItemId: json['orderItemId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productImage: json['productImage']?.toString() ?? '',
      reviewerName: json['reviewerName']?.toString() ?? '',
      rating: _parseInt(json['rating']),
      reviewText: json['reviewText']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt'] ?? json['date']),
    );
  }

  ReviewEntry copyWith({int? rating, String? reviewText}) {
    return ReviewEntry(
      id: id,
      orderId: orderId,
      orderItemId: orderItemId,
      productId: productId,
      productName: productName,
      productImage: productImage,
      reviewerName: reviewerName,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed ?? 0;
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

class PendingReviewItem {
  final String orderId;
  final String orderItemId;
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final int price;
  final DateTime orderDate;
  final String supplierName;

  PendingReviewItem({
    required this.orderId,
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
    required this.orderDate,
    required this.supplierName,
  });

  factory PendingReviewItem.fromJson(Map<String, dynamic> json) {
    return PendingReviewItem(
      orderId: json['orderId']?.toString() ?? '',
      orderItemId: json['orderItemId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productImage: json['productImage']?.toString() ?? '',
      quantity: ReviewEntry._parseInt(json['quantity']),
      price: ReviewEntry._parseInt(json['price']),
      orderDate: ReviewEntry._parseDate(json['orderDate'] ?? json['date']),
      supplierName: json['supplierName']?.toString() ?? '',
    );
  }
}
