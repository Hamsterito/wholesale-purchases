import 'package:flutter/material.dart';

import 'package:flutter_project/services/localization/app_localizations.dart';
import '../models/language.dart';
import '../services/localization/localization_extension.dart';
import '../utils/text_normalizer.dart';

class Product {
  final String id;
  final String name;
  final String nameKk;
  final String description;
  final String descriptionKk;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  // Кол-во вопросов по товару из каталога - чтобы вкладка «Вопросы (N)»
  // на странице товара не моргала нулём, пока подгружается список.
  final int questionCount;
  final List<String> categories;
  final String categoryKk;
  final NutritionalInfo nutritionalInfo;
  final String ingredients;
  final String ingredientsKk;
  final Map<String, String> characteristics;
  final Map<String, String> characteristicsKk;
  final List<Supplier> suppliers;
  final List<Product> similarProducts;
  final List<RatingDistribution> ratingDistribution;

  Product({
    required this.id,
    required this.name,
    this.nameKk = '',
    required this.description,
    this.descriptionKk = '',
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    this.questionCount = 0,
    required this.categories,
    this.categoryKk = '',
    required this.nutritionalInfo,
    required this.ingredients,
    this.ingredientsKk = '',
    required this.characteristics,
    this.characteristicsKk = const {},
    required this.suppliers,
    required this.similarProducts,
    required this.ratingDistribution,
  });

  Supplier get bestSupplier {
    if (suppliers.isEmpty) {
      throw Exception(AppLocalizations.current.getString('product_auto_9'));
    }
    return suppliers.reduce((a, b) => a.pricePerUnit < b.pricePerUnit ? a : b);
  }

  bool get isAvailable {
    return suppliers.any((s) => s.isAvailable);
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
        characteristics[normalize(key.toString())] = normalize(
          value.toString(),
        );
      });
    }

    final rawCharacteristicsKk = json['characteristicsKk'];
    final characteristicsKk = <String, String>{};
    if (rawCharacteristicsKk is Map) {
      rawCharacteristicsKk.forEach((key, value) {
        characteristicsKk[normalize(key.toString())] = normalize(
          value.toString(),
        );
      });
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: normalize(json['name']?.toString() ?? ''),
      nameKk: normalize(json['nameKk']?.toString() ?? ''),
      description: normalize(json['description']?.toString() ?? ''),
      descriptionKk: normalize(json['descriptionKk']?.toString() ?? ''),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      questionCount: json['questionCount'] ?? 0,
      categories: categories,
      categoryKk: normalize(json['categoryKk']?.toString() ?? ''),
      nutritionalInfo: NutritionalInfo.fromJson(json['nutritionalInfo'] ?? {}),
      ingredients: normalize(json['ingredients']?.toString() ?? ''),
      ingredientsKk: normalize(json['ingredientsKk']?.toString() ?? ''),
      characteristics: characteristics,
      characteristicsKk: characteristicsKk,
      suppliers:
          (json['suppliers'] as List?)
              ?.map((s) => Supplier.fromJson(s))
              .toList() ??
          [],
      similarProducts:
          (json['similarProducts'] as List?)
              ?.map((p) => Product.fromJson(p))
              .toList() ??
          [],
      ratingDistribution:
          (json['ratingDistribution'] as List?)
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

  // Поля профиля поставщика - могут отсутствовать в старых ответах API
  final String? logoUrl;
  final String? description;
  final String? address;
  final String? phone;
  final String? email;
  final String? avatarUrl;

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
    this.logoUrl,
    this.description,
    this.address,
    this.phone,
    this.email,
    this.avatarUrl,
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
      // Новые поля профиля - null если отсутствуют в JSON (обратная совместимость)
      logoUrl: json['logoUrl']?.toString(),
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: _normalizeAvatarUrl(json['avatarUrl']),
    );
  }
}

// Пустую строку считаем за «нет аватарки» - сервер может прислать "" вместо null.
String? _normalizeAvatarUrl(dynamic value) {
  final str = value?.toString().trim() ?? '';
  return str.isEmpty ? null : str;
}

class RatingDistribution {
  final int stars;
  final int count;

  RatingDistribution({required this.stars, required this.count});

  factory RatingDistribution.fromJson(Map<String, dynamic> json) {
    return RatingDistribution(
      stars: json['stars'] ?? 0,
      count: json['count'] ?? 0,
    );
  }
}

// Ответ API для полного профиля поставщика - объединяет данные компании и её товары
class SupplierProfile {
  final Supplier supplier;
  final List<Product> products;

  SupplierProfile({required this.supplier, required this.products});

  factory SupplierProfile.fromJson(Map<String, dynamic> json) {
    return SupplierProfile(
      supplier: Supplier.fromJson(json['supplier']),
      products:
          (json['products'] as List?)
              ?.map((p) => Product.fromJson(p))
              .toList() ??
          [],
    );
  }
}

extension ProductLocalization on Product {
  String localizedName(BuildContext context) {
    if (context.currentLanguage == LanguageCode.kazakh && nameKk.trim().isNotEmpty) {
      return nameKk.trim();
    }
    return name;
  }

  String localizedDescription(BuildContext context) {
    if (context.currentLanguage == LanguageCode.kazakh && descriptionKk.trim().isNotEmpty) {
      return descriptionKk.trim();
    }
    return description;
  }

  List<String> localizedCategories(BuildContext context) {
    if (context.currentLanguage == LanguageCode.kazakh && categoryKk.trim().isNotEmpty) {
      return categoryKk.split(RegExp(r'[;,|]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return categories;
  }

  String localizedCategory(BuildContext context) {
    final locCats = localizedCategories(context);
    return locCats.isNotEmpty ? locCats.first : '';
  }

  String localizedIngredients(BuildContext context) {
    if (context.currentLanguage == LanguageCode.kazakh && ingredientsKk.trim().isNotEmpty) {
      return ingredientsKk.trim();
    }
    return ingredients;
  }

  Map<String, String> localizedCharacteristics(BuildContext context) {
    final Map<String, String> sourceMap = (context.currentLanguage == LanguageCode.kazakh && characteristicsKk.isNotEmpty)
        ? characteristicsKk
        : characteristics;

    if (context.currentLanguage == LanguageCode.kazakh) {
      final result = <String, String>{};
      sourceMap.forEach((key, value) {
        String newKey = key;
        String newValue = value;

        if (key == 'Страна производителя') {
          newKey = context.l10n.getString('auto_stranaProizvoditelya');
          if (value == 'Казахстан') {
            newValue = 'Қазақстан';
          } else if (value == 'Россия') {
            newValue = 'Ресей';
          }
        } else if (key == 'Срок годности') {
          newKey = context.l10n.getString('auto_srokGodnosti');
          newValue = newValue.replaceAll('суток', 'тәулік');
          newValue = newValue.replaceAll('сутки', 'тәулік');
          newValue = newValue.replaceAll('месяцев', 'ай');
          newValue = newValue.replaceAll('мес.', 'ай.');
          newValue = newValue.replaceAll('дней', 'күн');
        } else if (key == 'Температура хранения') {
          newKey = context.l10n.getString('auto_temperaturaHraneniya');
          newValue = newValue.replaceAll('от', 'бастап');
          newValue = newValue.replaceAll('до', 'дейін');
        }

        result[newKey] = newValue;
      });
      return result;
    }

    return sourceMap;
  }
}

