import 'dart:convert';

class SupplierProduct {
  final String id;
  final String name;
  final String description;
  final List<String> categories;
  final List<String> imageUrls;
  final int pricePerUnit;
  final int minQuantity;
  final int? maxQuantity;
  final int stockQuantity;
  final String ingredients;
  final SupplierNutritionalInfo nutritionalInfo;
  final Map<String, String> characteristics;
  final String supplierName;
  final String deliveryDate;
  final String deliveryBadge;
  final String moderationStatus;
  final String moderationComment;

  SupplierProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.categories,
    required this.imageUrls,
    required this.pricePerUnit,
    required this.minQuantity,
    required this.maxQuantity,
    this.stockQuantity = 0,
    this.ingredients = '',
    SupplierNutritionalInfo? nutritionalInfo,
    Map<String, String>? characteristics,
    required this.supplierName,
    required this.deliveryDate,
    required this.deliveryBadge,
    required this.moderationStatus,
    required this.moderationComment,
  }) : nutritionalInfo = nutritionalInfo ?? const SupplierNutritionalInfo(),
       characteristics = characteristics ?? const <String, String>{};

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      if (value is String) {
        return value
            .split(RegExp(r'[;,|]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return [];
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value.toString());
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    Map<String, String> parseCharacteristics(dynamic value) {
      if (value is Map) {
        final result = <String, String>{};
        value.forEach((key, rawValue) {
          final normalizedKey = key.toString().trim();
          final normalizedValue = rawValue?.toString().trim() ?? '';
          if (normalizedKey.isNotEmpty && normalizedValue.isNotEmpty) {
            result[normalizedKey] = normalizedValue;
          }
        });
        return result;
      }
      if (value is String && value.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) {
            return parseCharacteristics(decoded);
          }
        } catch (_) {}
      }
      return <String, String>{};
    }

    final nutritionSource = json['nutritionalInfo'];
    final nutritionMap = nutritionSource is Map
        ? Map<String, dynamic>.from(nutritionSource)
        : <String, dynamic>{};
    final stockQuantity =
        parseInt(
          json['stockQuantity'] ??
              json['stock_quantity'] ??
              json['maxQuantity'],
        ) ??
        0;

    return SupplierProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categories: parseList(json['categories'] ?? json['category']),
      imageUrls: parseList(json['imageUrls'] ?? json['image_url']),
      pricePerUnit:
          parseInt(json['pricePerUnit'] ?? json['price_per_unit']) ?? 0,
      minQuantity: parseInt(json['minQuantity'] ?? json['min_quantity']) ?? 1,
      maxQuantity: parseInt(json['maxQuantity'] ?? json['max_quantity']),
      stockQuantity: stockQuantity < 0 ? 0 : stockQuantity,
      ingredients: json['ingredients']?.toString() ?? '',
      nutritionalInfo: SupplierNutritionalInfo(
        calories: parseDouble(
          nutritionMap['calories'] ?? json['nutrition_calories'],
        ),
        protein: parseDouble(
          nutritionMap['protein'] ?? json['nutrition_protein'],
        ),
        fat: parseDouble(nutritionMap['fat'] ?? json['nutrition_fat']),
        carbohydrates: parseDouble(
          nutritionMap['carbohydrates'] ?? json['nutrition_carbohydrates'],
        ),
      ),
      characteristics: parseCharacteristics(json['characteristics']),
      supplierName: json['supplierName']?.toString() ?? '',
      deliveryDate: json['deliveryDate']?.toString() ?? '',
      deliveryBadge: json['deliveryBadge']?.toString() ?? '',
      moderationStatus: json['moderationStatus']?.toString() ?? 'pending',
      moderationComment: json['moderationComment']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toRequestPayload({required int userId}) {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'category': categories,
      'imageUrls': imageUrls,
      'pricePerUnit': pricePerUnit,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'stockQuantity': stockQuantity,
      'ingredients': ingredients,
      'nutritionalInfo': nutritionalInfo.toJson(),
      'characteristics': characteristics,
      'deliveryDate': deliveryDate,
      'deliveryBadge': deliveryBadge,
    };
  }

  SupplierProduct copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? categories,
    List<String>? imageUrls,
    int? pricePerUnit,
    int? minQuantity,
    int? maxQuantity,
    int? stockQuantity,
    String? ingredients,
    SupplierNutritionalInfo? nutritionalInfo,
    Map<String, String>? characteristics,
    String? supplierName,
    String? deliveryDate,
    String? deliveryBadge,
    String? moderationStatus,
    String? moderationComment,
  }) {
    return SupplierProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      imageUrls: imageUrls ?? this.imageUrls,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      ingredients: ingredients ?? this.ingredients,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      characteristics: characteristics ?? this.characteristics,
      supplierName: supplierName ?? this.supplierName,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryBadge: deliveryBadge ?? this.deliveryBadge,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderationComment: moderationComment ?? this.moderationComment,
    );
  }
}

class SupplierNutritionalInfo {
  final double calories;
  final double protein;
  final double fat;
  final double carbohydrates;

  const SupplierNutritionalInfo({
    this.calories = 0.0,
    this.protein = 0.0,
    this.fat = 0.0,
    this.carbohydrates = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbohydrates': carbohydrates,
    };
  }
}
