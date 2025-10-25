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
      throw Exception('No suppliers available');
    }
    return suppliers.reduce((a, b) => 
      a.pricePerUnit < b.pricePerUnit ? a : b
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      categories: List<String>.from(json['categories'] ?? []),
      nutritionalInfo: NutritionalInfo.fromJson(json['nutritionalInfo'] ?? {}),
      ingredients: json['ingredients'] ?? '',
      characteristics: Map<String, String>.from(json['characteristics'] ?? {}),
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
    required this.deliveryDate,
    required this.deliveryInfo,
    required this.deliveryBadge,
  });

  int getTotalPrice(int quantity) {
    return pricePerUnit * quantity;
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      pricePerUnit: json['pricePerUnit'] ?? 0,
      minQuantity: json['minQuantity'] ?? 1,
      deliveryDate: json['deliveryDate'] ?? '',
      deliveryInfo: json['deliveryInfo'] ?? '',
      deliveryBadge: json['deliveryBadge'] ?? '',
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