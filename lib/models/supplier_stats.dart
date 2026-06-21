class SupplierStatsSummary {
  final int totalRevenue;
  final int monthlyRevenue;
  final int weeklyRevenue;
  final int totalOrders;
  final int averageOrderValue;

  SupplierStatsSummary({
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.weeklyRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
  });

  factory SupplierStatsSummary.fromJson(Map<String, dynamic> json) {
    return SupplierStatsSummary(
      totalRevenue: json['totalRevenue'] as int? ?? 0,
      monthlyRevenue: json['monthlyRevenue'] as int? ?? 0,
      weeklyRevenue: json['weeklyRevenue'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      averageOrderValue: json['averageOrderValue'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'monthlyRevenue': monthlyRevenue,
      'weeklyRevenue': weeklyRevenue,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
    };
  }
}

class RevenueHistory {
  final String month;
  final int revenue;
  final DateTime? date;

  RevenueHistory({required this.month, required this.revenue, this.date});

  factory RevenueHistory.fromJson(Map<String, dynamic> json) {
    return RevenueHistory(
      month: json['month'] as String? ?? '',
      revenue: json['revenue'] as int? ?? 0,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'revenue': revenue,
      if (date != null) 'date': date!.toIso8601String(),
    };
  }
}

class TopProduct {
  final String productName;
  final String productNameKk;
  final int revenue;
  final int unitsSold;

  TopProduct({
    required this.productName,
    this.productNameKk = '',
    required this.revenue,
    required this.unitsSold,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productName: json['productName'] as String? ?? '',
      productNameKk: json['productNameKk'] as String? ?? '',
      revenue: json['revenue'] as int? ?? 0,
      unitsSold: json['unitsSold'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'productNameKk': productNameKk,
      'revenue': revenue,
      'unitsSold': unitsSold,
    };
  }
}

class OrderStats {
  final int totalOrders;
  final int deliveredCount;
  final int shippedCount;
  final int confirmedCount;
  final int pendingCount;
  final int cancelledCount;
  final int thisMonthCount;
  final int lastMonthCount;
  final int averageFulfillmentDays;
  final List<RecentOrder> recentOrders;

  OrderStats({
    required this.totalOrders,
    required this.deliveredCount,
    required this.shippedCount,
    required this.confirmedCount,
    required this.pendingCount,
    required this.cancelledCount,
    required this.thisMonthCount,
    required this.lastMonthCount,
    required this.averageFulfillmentDays,
    required this.recentOrders,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    final recentOrdersList = json['recentOrders'] as List<dynamic>? ?? [];
    return OrderStats(
      totalOrders: json['totalOrders'] as int? ?? 0,
      deliveredCount: json['deliveredCount'] as int? ?? 0,
      shippedCount: json['shippedCount'] as int? ?? 0,
      confirmedCount: json['confirmedCount'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
      cancelledCount: json['cancelledCount'] as int? ?? 0,
      thisMonthCount: json['thisMonthCount'] as int? ?? 0,
      lastMonthCount: json['lastMonthCount'] as int? ?? 0,
      averageFulfillmentDays: json['averageFulfillmentDays'] as int? ?? 0,
      recentOrders: recentOrdersList
          .map((item) => RecentOrder.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'deliveredCount': deliveredCount,
      'shippedCount': shippedCount,
      'confirmedCount': confirmedCount,
      'pendingCount': pendingCount,
      'cancelledCount': cancelledCount,
      'thisMonthCount': thisMonthCount,
      'lastMonthCount': lastMonthCount,
      'averageFulfillmentDays': averageFulfillmentDays,
      'recentOrders': recentOrders.map((o) => o.toJson()).toList(),
    };
  }
}

class RecentOrder {
  final String orderId;
  final DateTime date;
  final int totalAmount;
  final String status;

  RecentOrder({
    required this.orderId,
    required this.date,
    required this.totalAmount,
    required this.status,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    final orderIdRaw = json['orderId'];
    final orderId = orderIdRaw is int
        ? orderIdRaw.toString()
        : (orderIdRaw as String? ?? '');

    return RecentOrder(
      orderId: orderId,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      totalAmount: json['totalAmount'] as int? ?? 0,
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
    };
  }
}

class BuyerStats {
  final int totalBuyers;
  final int repeatBuyers;
  final int newBuyersThisMonth;
  final int repeatBuyersPercentage;

  BuyerStats({
    required this.totalBuyers,
    required this.repeatBuyers,
    required this.newBuyersThisMonth,
    required this.repeatBuyersPercentage,
  });

  factory BuyerStats.fromJson(Map<String, dynamic> json) {
    return BuyerStats(
      totalBuyers: json['totalBuyers'] as int? ?? 0,
      repeatBuyers: json['repeatBuyers'] as int? ?? 0,
      newBuyersThisMonth: json['newBuyersThisMonth'] as int? ?? 0,
      repeatBuyersPercentage: json['repeatBuyersPercentage'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBuyers': totalBuyers,
      'repeatBuyers': repeatBuyers,
      'newBuyersThisMonth': newBuyersThisMonth,
      'repeatBuyersPercentage': repeatBuyersPercentage,
    };
  }
}

class RatingStats {
  final double averageRating;
  final int totalReviews;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final List<RecentReview> recentReviews;

  RatingStats({
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
    required this.recentReviews,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    final recentReviewsList = json['recentReviews'] as List<dynamic>? ?? [];
    return RatingStats(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      fiveStarCount: json['fiveStarCount'] as int? ?? 0,
      fourStarCount: json['fourStarCount'] as int? ?? 0,
      threeStarCount: json['threeStarCount'] as int? ?? 0,
      twoStarCount: json['twoStarCount'] as int? ?? 0,
      oneStarCount: json['oneStarCount'] as int? ?? 0,
      recentReviews: recentReviewsList
          .map((item) => RecentReview.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'fiveStarCount': fiveStarCount,
      'fourStarCount': fourStarCount,
      'threeStarCount': threeStarCount,
      'twoStarCount': twoStarCount,
      'oneStarCount': oneStarCount,
      'recentReviews': recentReviews.map((r) => r.toJson()).toList(),
    };
  }
}

class RecentReview {
  final String productName;
  final String productNameKk;
  final int rating;
  final String commentSnippet;

  RecentReview({
    required this.productName,
    this.productNameKk = '',
    required this.rating,
    required this.commentSnippet,
  });

  factory RecentReview.fromJson(Map<String, dynamic> json) {
    return RecentReview(
      productName: json['productName'] as String? ?? '',
      productNameKk: json['productNameKk'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      commentSnippet: json['commentSnippet'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'productNameKk': productNameKk,
      'rating': rating,
      'commentSnippet': commentSnippet,
    };
  }
}

extension TopProductLocalization on TopProduct {
  String localizedProductName(dynamic context) {
    try {
      final lang = (context as dynamic).currentLanguage;
      if (lang?.toString() == 'LanguageCode.kazakh' && productNameKk.trim().isNotEmpty) {
        return productNameKk;
      }
    } catch (_) {}
    return productName;
  }
}

extension RecentReviewLocalization on RecentReview {
  String localizedProductName(dynamic context) {
    try {
      final lang = (context as dynamic).currentLanguage;
      if (lang?.toString() == 'LanguageCode.kazakh' && productNameKk.trim().isNotEmpty) {
        return productNameKk;
      }
    } catch (_) {}
    return productName;
  }
}
