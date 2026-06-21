part of '../backend.dart';

// Хелперы для товаров и категорий: валидация payload поставщика, разбор
// диагностики БД, парсинг категорий/характеристик/изображений и DTO-мапперы.

String? _validateSupplierProductPayload({
  required int pricePerUnit,
  required int minQuantity,
  required int? maxQuantity,
  required int stockQuantity,
  required double nutritionCalories,
  required double nutritionProtein,
  required double nutritionFat,
  required double nutritionCarbohydrates,
}) {
  if (pricePerUnit <= 0) {
    return 'Цена за единицу должна быть больше 0.';
  }
  if (pricePerUnit > _postgresIntMaxValue) {
    return 'Цена за единицу не должна превышать $_postgresIntMaxValue.';
  }

  if (minQuantity <= 0) {
    return 'Минимальное количество должно быть больше 0.';
  }
  if (minQuantity > _postgresIntMaxValue) {
    return 'Минимальное количество не должно превышать $_postgresIntMaxValue.';
  }

  if (maxQuantity != null) {
    if (maxQuantity <= 0) {
      return 'Максимальное количество должно быть больше 0.';
    }
    if (maxQuantity > _postgresIntMaxValue) {
      return 'Максимальное количество не должно превышать $_postgresIntMaxValue.';
    }
    if (maxQuantity < minQuantity) {
      return 'Максимальное количество не может быть меньше минимального.';
    }
  }

  if (stockQuantity < 0) {
    return 'Остаток на складе не может быть отрицательным.';
  }
  if (stockQuantity > _postgresIntMaxValue) {
    return 'Остаток на складе не должен превышать $_postgresIntMaxValue.';
  }
  if (stockQuantity > 0 && stockQuantity < minQuantity) {
    return 'Остаток на складе не может быть меньше минимального количества.';
  }

  final caloriesError = _validateNumeric10Scale2Field(
    value: nutritionCalories,
    fieldLabel: 'Калории',
  );
  if (caloriesError != null) {
    return caloriesError;
  }

  final proteinError = _validateNumeric10Scale2Field(
    value: nutritionProtein,
    fieldLabel: 'Белки',
  );
  if (proteinError != null) {
    return proteinError;
  }

  final fatError = _validateNumeric10Scale2Field(
    value: nutritionFat,
    fieldLabel: 'Жиры',
  );
  if (fatError != null) {
    return fatError;
  }

  final carbohydratesError = _validateNumeric10Scale2Field(
    value: nutritionCarbohydrates,
    fieldLabel: 'Углеводы',
  );
  if (carbohydratesError != null) {
    return carbohydratesError;
  }

  return null;
}

String? _validateNumeric10Scale2Field({
  required double value,
  required String fieldLabel,
}) {
  if (!value.isFinite || value < 0) {
    return 'Поле "$fieldLabel" должно быть неотрицательным числом.';
  }

  final roundedToScale = (value * 100).round() / 100;
  if (roundedToScale >= _numeric10Scale2Bound) {
    return 'Поле "$fieldLabel" превышает допустимый предел NUMERIC(10,2): максимум $_numeric10Scale2MaxValue.';
  }

  return null;
}

String? _supplierProductDbConstraintMessage(Object error) {
  final text = error.toString().toLowerCase();
  if (!text.contains('22003') || !text.contains('numeric')) {
    return null;
  }
  return 'Одно из числовых полей превышает допустимый предел NUMERIC(10,2): максимум $_numeric10Scale2MaxValue.';
}

String? _supplierProductDeleteConstraintMessage(Object error) {
  final text = error.toString().toLowerCase();
  final isForeignKeyViolation =
      text.contains('23503') || text.contains('foreign key');
  if (!isForeignKeyViolation) {
    return null;
  }

  return 'Нельзя удалить товар из-за связанных записей.';
}

Map<String, dynamic> _productRowToModerationDto(Map<String, dynamic> map) {
  final categories = _parseCategories(map['category']);
  final imageUrls = _parseImageUrls(map['image_url']);
  final characteristics = _parseCharacteristics(map['characteristics']);
  final stockQuantity = _toPositiveInt(
    map['stock_quantity'] ?? map['max_quantity'],
  );
  return {
    'id': (map['id'] ?? '').toString(),
    'name': map['name'] ?? '',
    'nameKk': map['name_kk'] ?? '',
    'description': map['description'] ?? '',
    'descriptionKk': map['description_kk'] ?? '',
    'categories': categories,
    'categoryKk': map['category_kk'] ?? '',
    'imageUrls': imageUrls,
    'pricePerUnit': map['price_per_unit'] ?? 0,
    'minQuantity': map['min_quantity'] ?? 1,
    'maxQuantity': _toNullablePositiveInt(map['max_quantity']),
    'stockQuantity': stockQuantity,
    'supplierName': map['supplier_name'] ?? '',
    'deliveryDate': map['delivery_date'] ?? '',
    'deliveryBadge': map['delivery_badge'] ?? '',
    'ingredients': map['ingredients'] ?? '',
    'ingredientsKk': map['ingredients_kk'] ?? '',
    'nutritionalInfo': {
      'calories': _toNonNegativeDouble(map['nutrition_calories']),
      'protein': _toNonNegativeDouble(map['nutrition_protein']),
      'fat': _toNonNegativeDouble(map['nutrition_fat']),
      'carbohydrates': _toNonNegativeDouble(map['nutrition_carbohydrates']),
    },
    'characteristics': characteristics,
    'characteristicsKk': map['characteristics_kk'] ?? '',
    'moderationStatus': map['moderation_status'] ?? 'approved',
    'moderationComment': map['moderation_comment'] ?? '',
    'supplierUserId': map['supplier_user_id'],
  };
}

// request нужен, чтобы собрать абсолютный URL аватарки автора отзыва.
// Если в карте нет user_avatar_url (например, без JOIN на users) -
// userAvatarUrl будет null, фронт корректно интерпретирует как «аватарки нет».
Map<String, dynamic> _reviewRowToDto(
  Map<String, dynamic> map,
  Request request,
) {
  String? createdAtIso;
  final createdAt = map['created_at'];
  if (createdAt is DateTime) {
    createdAtIso = createdAt.toIso8601String();
  }

  // Подготавливаем данные ответа поставщика, если они есть
  Map<String, dynamic>? responseData;
  if (map['response_id'] != null) {
    String? respondedAtIso;
    final respondedAt = map['response_created_at'];
    if (respondedAt is DateTime) {
      respondedAtIso = respondedAt.toIso8601String();
    }

    responseData = {
      'id': map['response_id']?.toString() ?? '',
      'reviewId': map['id']?.toString() ?? '',
      'supplierId': map['response_supplier_id']?.toString() ?? '',
      'supplierName': map['response_supplier_name'] ?? '',
      'responseText': map['response_text'] ?? '',
      if (respondedAtIso != null) 'respondedAt': respondedAtIso,
    };
  }

  return {
    'id': map['id']?.toString() ?? '',
    'orderId': map['order_id']?.toString() ?? '',
    'orderItemId': map['order_item_id']?.toString() ?? '',
    'productId': map['product_id']?.toString() ?? '',
    'productName': map['product_name'] ?? map['order_item_name'] ?? '',
    'productNameKk': map['product_name_kk'] ?? map['order_item_name_kk'] ?? '',
    'productImage': map['product_image'] ?? map['order_item_image'] ?? '',
    'rating': map['rating'] ?? 0,
    'reviewText': map['review_text'] ?? '',
    'reviewerName': map['reviewer_name'] ?? '',
    'userAvatarUrl': _avatarUrlOrNull(request, map['user_avatar_url']),
    'supplierName': map['supplier_name'] ?? '',
    if (createdAtIso != null) 'createdAt': createdAtIso,
    if (responseData != null) 'response': responseData,
  };
}

List<String> _parseCategories(Object? value, {bool includeFallback = true}) {
  final raw = value?.toString() ?? '';
  final parts = raw.split(RegExp(r'[;,|]'));
  final categories = parts
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (categories.isNotEmpty) {
    return categories;
  }
  if (!includeFallback) {
    return const <String>[];
  }
  return ['Без категории'];
}





String _normalizeCategoryName(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}



Map<String, String> _parseCharacteristics(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return const <String, String>{};
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final result = <String, String>{};
      decoded.forEach((key, val) {
        final normalizedKey = key.toString().trim();
        final normalizedValue = val?.toString().trim() ?? '';
        if (normalizedKey.isNotEmpty && normalizedValue.isNotEmpty) {
          result[normalizedKey] = normalizedValue;
        }
      });
      if (result.isNotEmpty) {
        return result;
      }
    }
  } catch (_) {
    // Откат к простому парсингу key:value ниже
  }

  final result = <String, String>{};
  for (final part in raw.split(RegExp(r'[;\n]+'))) {
    final normalized = part.trim();
    if (normalized.isEmpty) {
      continue;
    }
    final delimiterIndex = normalized.indexOf(':');
    if (delimiterIndex <= 0 || delimiterIndex >= normalized.length - 1) {
      continue;
    }
    final key = normalized.substring(0, delimiterIndex).trim();
    final val = normalized.substring(delimiterIndex + 1).trim();
    if (key.isEmpty || val.isEmpty) {
      continue;
    }
    result[key] = val;
  }
  return result;
}

String _serializeCharacteristics(Object? value) {
  if (value is Map) {
    final normalized = <String, String>{};
    value.forEach((key, val) {
      final k = key.toString().trim();
      final v = val?.toString().trim() ?? '';
      if (k.isNotEmpty && v.isNotEmpty) {
        normalized[k] = v;
      }
    });
    if (normalized.isNotEmpty) {
      return jsonEncode(normalized);
    }
    return '';
  }
  if (value is String) {
    final parsed = _parseCharacteristics(value);
    if (parsed.isNotEmpty) {
      return jsonEncode(parsed);
    }
    return '';
  }
  return '';
}

Future<List<String>> _resolvePayloadCategories(
  Connection connection,
  Object? payloadValue,
) async {
  final selected = <String>[];
  if (payloadValue is List) {
    for (final item in payloadValue) {
      final normalized = _normalizeCategoryName(item.toString());
      if (normalized.isNotEmpty) {
        selected.add(normalized);
      }
    }
  } else if (payloadValue != null) {
    selected.addAll(_parseCategories(payloadValue, includeFallback: false));
  }

  return selected;
}



List<String> _parseImageUrls(Object? value) {
  final raw = value?.toString() ?? '';
  final parts = raw.split(RegExp(r'[;,|]'));
  return parts
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}
