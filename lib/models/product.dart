import '../utils/text_normalizer.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  final List<String> categories;
  final NutritionalInfo nutritionalInfo;
  final String ingredients;
  final Map<String, String> characteristics;
  final List<Supplier> suppliers;
  final List<Product> similarProducts;
  final List<RatingDistribution> ratingDistribution;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    required this.categories,
    required this.nutritionalInfo,
    required this.ingredients,
    required this.characteristics,
    required this.suppliers,
    required this.similarProducts,
    required this.ratingDistribution,
  });

  Supplier get bestSupplier {
    if (suppliers.isEmpty) {
      throw Exception('Нет доступных поставщиков');
    }
    return suppliers.reduce((a, b) => 
      a.pricePerUnit < b.pricePerUnit ? a : b
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final normalize = TextNormalizer.normalize;
    final rawCategories = json['categories'];
    final categories = rawCategories is List
        ? rawCategories.map((item) => normalize(item.toString())).toList()
        : <String>[];
    final rawCharacteristics = json['characteristics'];
    final characteristics = <String, String>{};
    if (rawCharacteristics is Map) {
      rawCharacteristics.forEach((key, value) {
        characteristics[normalize(key.toString())] =
            normalize(value.toString());
      });
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: normalize(json['name']?.toString() ?? ''),
      description: normalize(json['description']?.toString() ?? ''),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      categories: categories,
      nutritionalInfo: NutritionalInfo.fromJson(json['nutritionalInfo'] ?? {}),
      ingredients: normalize(json['ingredients']?.toString() ?? ''),
      characteristics: characteristics,
      suppliers: (json['suppliers'] as List?)
              ?.map((s) => Supplier.fromJson(s))
              .toList() ??
          [],
      similarProducts: (json['similarProducts'] as List?)
              ?.map((p) => Product.fromJson(p))
              .toList() ??
          [],
      ratingDistribution: (json['ratingDistribution'] as List?)
              ?.map((r) => RatingDistribution.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class NutritionalInfo {
  final double calories;
  final double protein;
  final double fat;
  final double carbohydrates;

  NutritionalInfo({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbohydrates,
  });

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) {
    return NutritionalInfo(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
    );
  }
}

class Supplier {
  final String id;
  final String name;
  final double rating;
  final int reviewCount;
  final int pricePerUnit;
  final int minQuantity;
  final int? maxQuantity;
  final int stockQuantity;
  final String deliveryDate;
  final String deliveryInfo;
  final String deliveryBadge;

  Supplier({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.pricePerUnit,
    required this.minQuantity,
    this.maxQuantity,
    required this.stockQuantity,
    required this.deliveryDate,
    required this.deliveryInfo,
    required this.deliveryBadge,
  });

  int getTotalPrice(int quantity) {
    return pricePerUnit * quantity;
  }

  bool get isAvailable => stockQuantity > 0;

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final normalize = TextNormalizer.normalize;
    int? parsePositiveInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value > 0 ? value : null;
      if (value is double) {
        final rounded = value.round();
        return rounded > 0 ? rounded : null;
      }
      final parsed = int.tryParse(value.toString());
      return parsed != null && parsed > 0 ? parsed : null;
    }

    int parseNonNegativeInt(dynamic value, {int fallback = 0}) {
      if (value is int) {
        return value < 0 ? fallback : value;
      }
      if (value is double) {
        final rounded = value.round();
        return rounded < 0 ? fallback : rounded;
      }
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed == null || parsed < 0) {
        return fallback;
      }
      return parsed;
    }

    final stockQuantity = parseNonNegativeInt(
      json['stockQuantity'] ??
          json['stock_quantity'] ??
          json['availableQuantity'] ??
          json['maxQuantity'],
    );
    var minQuantity = parseNonNegativeInt(
      json['minQuantity'] ?? json['min_quantity'],
      fallback: 1,
    );
    if (minQuantity <= 0) {
      minQuantity = 1;
    }
    if (stockQuantity > 0 && minQuantity > stockQuantity) {
      minQuantity = stockQuantity;
    }
    final maxQuantity = stockQuantity > 0
        ? stockQuantity
        : parsePositiveInt(
            json['maxQuantity'] ??
                json['max_quantity'] ??
                json['limit_quantity'],
          );

    return Supplier(
      id: json['id']?.toString() ?? '',
      name: normalize(json['name']?.toString() ?? ''),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      pricePerUnit: json['pricePerUnit'] ?? 0,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
      stockQuantity: stockQuantity,
      deliveryDate: normalize(json['deliveryDate']?.toString() ?? ''),
      deliveryInfo: normalize(json['deliveryInfo']?.toString() ?? ''),
      deliveryBadge: normalize(json['deliveryBadge']?.toString() ?? ''),
    );
  }
}

class RatingDistribution {
  final int stars;
  final int count;

  RatingDistribution({
    required this.stars,
    required this.count,
  });

  factory RatingDistribution.fromJson(Map<String, dynamic> json) {
    return RatingDistribution(
      stars: json['stars'] ?? 0,
      count: json['count'] ?? 0,
    );
  }
}

