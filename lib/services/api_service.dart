import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import '../services/api_config.dart';
import '../models/supplier_order.dart';
import '../models/supplier_product.dart';
import '../models/user_profile.dart';
import '../models/user_address.dart';
import '../models/review_entry.dart';
import '../models/support_message.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Не удалось загрузить данные: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке данных: $e');
      rethrow;
    }
  }

  static Future<List<String>> getCatalogCategories({
    bool includeInactive = false,
  }) async {
    try {
      final query = includeInactive ? '?includeInactive=true' : '';
      final response = await http.get(Uri.parse('$baseUrl/categories$query'));

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is! List) {
          return const <String>[];
        }

        final categories = <String>[];
        final seen = <String>{};

        for (final item in decoded) {
          String rawName = '';
          if (item is String) {
            rawName = item;
          } else if (item is Map) {
            rawName = item['name']?.toString() ?? '';
          }

          final normalized = rawName.trim();
          if (normalized.isEmpty) {
            continue;
          }

          final dedupeKey = normalized.toLowerCase();
          if (seen.add(dedupeKey)) {
            categories.add(normalized);
          }
        }

        return categories;
      } else {
        throw Exception(
          'Не удалось загрузить категории: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при загрузке категорий: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getCatalogCategoryTree({
    bool includeInactive = false,
  }) async {
    try {
      final query = includeInactive ? '?includeInactive=true' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/categories/tree$query'),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Не удалось загрузить список категорий: ${response.statusCode}',
        );
      }

      final body = _decodeBody(response.bodyBytes);
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        return const <Map<String, dynamic>>[];
      }

      final tree = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        final row = Map<String, dynamic>.from(item);
        final subRows = row['subcategories'];
        final subcategories = <Map<String, dynamic>>[];
        if (subRows is List) {
          for (final child in subRows) {
            if (child is! Map) {
              continue;
            }
            final childMap = Map<String, dynamic>.from(child);
            final childName = childMap['name']?.toString().trim() ?? '';
            if (childName.isEmpty) {
              continue;
            }

            final rawKeywords = childMap['keywords'];
            final keywords = <String>[];
            if (rawKeywords is List) {
              for (final keyword in rawKeywords) {
                final normalized = keyword.toString().trim();
                if (normalized.isNotEmpty) {
                  keywords.add(normalized);
                }
              }
            } else if (rawKeywords != null) {
              for (final keyword in rawKeywords.toString().split(
                RegExp(r'[;,|]'),
              )) {
                final normalized = keyword.trim();
                if (normalized.isNotEmpty) {
                  keywords.add(normalized);
                }
              }
            }

            subcategories.add({
              'id': childMap['id'],
              'name': childName,
              'imagePath': childMap['imagePath']?.toString() ?? '',
              'keywords': keywords.isEmpty ? <String>[childName] : keywords,
              'sortOrder': childMap['sortOrder'] ?? childMap['sort_order'] ?? 0,
              'isActive': childMap['isActive'] ?? childMap['is_active'] ?? true,
            });
          }
        }

        final name = row['name']?.toString().trim() ?? '';
        if (name.isEmpty) {
          continue;
        }

        tree.add({
          'id': row['id'],
          'name': name,
          'subtitle': row['subtitle']?.toString() ?? '',
          'imagePath': row['imagePath']?.toString() ?? '',
          'sortOrder': row['sortOrder'] ?? row['sort_order'] ?? 0,
          'isActive': row['isActive'] ?? row['is_active'] ?? true,
          'subcategories': subcategories,
        });
      }

      return tree;
    } catch (e) {
      print('Ошибка при загрузке списка категорий: $e');
      rethrow;
    }
  }

  static Future<List<Order>> getOrders({int? userId}) async {
    try {
      final uri = (userId != null && userId > 0)
          ? Uri.parse('$baseUrl/orders?userId=$userId')
          : Uri.parse('$baseUrl/orders');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Не удалось загрузить данные: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке данных: $e');
      rethrow;
    }
  }

  static Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    String status = 'Собирается',
    String? deliveryAddress,
    required int userId,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Список товаров не должен быть пустым');
    }
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'status': status,
          'items': items,
          if (deliveryAddress != null && deliveryAddress.trim().isNotEmpty)
            'deliveryAddress': deliveryAddress.trim(),
          'userId': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _decodeBody(response.bodyBytes);
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        return Order.fromJson(jsonMap);
      } else {
        throw Exception(
          'Не удалось выполнить операцию: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при выполнении операции: $e');
      rethrow;
    }
  }

  static Future<UserProfile> getUserProfile({required int userId}) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        return UserProfile.fromJson(jsonMap);
      } else {
        throw Exception(
          'Не удалось загрузить профиль пользователя: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при загрузке профиля пользователя: $e');
      rethrow;
    }
  }

  static Future<UserProfile> updateUserProfile({
    required int userId,
    String? name,
    String? email,
    String? phone,
    String? supplierName,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    final payload = <String, dynamic>{};
    if (name != null) {
      payload['name'] = name.trim();
    }
    if (email != null) {
      payload['email'] = email.trim();
    }
    if (phone != null) {
      payload['phone'] = phone;
    }
    if (supplierName != null) {
      payload['supplierName'] = supplierName.trim();
    }

    if (payload.isEmpty) {
      throw ArgumentError(
        'Необходимо передать хотя бы одно поле для обновления',
      );
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        return UserProfile.fromJson(jsonMap);
      }

      final body = _decodeBody(response.bodyBytes).trim();
      if (body.isNotEmpty) {
        throw Exception(body);
      }

      throw Exception('Не удалось обновить профиль: ${response.statusCode}');
    } catch (e) {
      print('Ошибка при обновлении профиля: $e');
      rethrow;
    }
  }

  static Future<void> changeUserPassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    final normalizedCurrentPassword = currentPassword.trim();
    final normalizedNewPassword = newPassword.trim();
    final normalizedConfirmPassword = confirmPassword?.trim();

    if (normalizedCurrentPassword.isEmpty || normalizedNewPassword.isEmpty) {
      throw ArgumentError('Текущий и новый пароль обязательны');
    }
    if (normalizedCurrentPassword.length < 6 ||
        normalizedNewPassword.length < 6) {
      throw ArgumentError('Пароль должен содержать минимум 6 символов');
    }
    if (normalizedCurrentPassword == normalizedNewPassword) {
      throw ArgumentError('Новый пароль должен отличаться от текущего');
    }
    if (normalizedConfirmPassword != null &&
        normalizedConfirmPassword != normalizedNewPassword) {
      throw ArgumentError('Подтверждение пароля не совпадает');
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/password'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'currentPassword': normalizedCurrentPassword,
          'newPassword': normalizedNewPassword,
          if (normalizedConfirmPassword != null)
            'confirmPassword': normalizedConfirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        return;
      }

      final errorMessage = _extractResponseErrorMessage(response);
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }

      throw Exception('Не удалось обновить пароль: ${response.statusCode}');
    } catch (e) {
      print('Ошибка при смене пароля: $e');
      rethrow;
    }
  }

  static Future<List<UserAddress>> getUserAddresses({
    required int userId,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/addresses'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList
            .map((json) => UserAddress.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Не удалось загрузить данные: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке данных: $e');
      rethrow;
    }
  }

  static Future<UserAddress> createUserAddress({
    required int userId,
    required AddressDraft draft,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/addresses'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode(draft.toRequestPayload()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _decodeBody(response.bodyBytes);
        return UserAddress.fromJson(jsonDecode(body) as Map<String, dynamic>);
      } else {
        throw Exception(
          'Не удалось выполнить операцию: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при выполнении операции: $e');
      rethrow;
    }
  }

  static Future<UserAddress> updateUserAddress({
    required int userId,
    required int addressId,
    required AddressDraft draft,
  }) async {
    if (userId <= 0 || addressId <= 0) {
      throw ArgumentError('userId и addressId должны быть положительными');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode(draft.toRequestPayload()),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return UserAddress.fromJson(jsonDecode(body) as Map<String, dynamic>);
      } else {
        throw Exception('Не удалось обновить запись: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при обновлении записи: $e');
      rethrow;
    }
  }

  static Future<void> deleteUserAddress({
    required int userId,
    required int addressId,
  }) async {
    if (userId <= 0 || addressId <= 0) {
      throw ArgumentError('userId и addressId должны быть положительными');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId'),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Не удалось выполнить операцию: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при выполнении операции: $e');
      rethrow;
    }
  }

  static Future<Order> acceptOrder(String orderId) async {
    if (orderId.isEmpty) {
      throw ArgumentError('orderId не должен быть пустым');
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/accept'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        return Order.fromJson(jsonMap);
      } else {
        throw Exception('Не удалось принять заказ: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при принятии заказа: $e');
      rethrow;
    }
  }

  static Future<Order> cancelOrder(
    String orderId, {
    required int userId,
  }) async {
    if (orderId.isEmpty) {
      throw ArgumentError('orderId не должен быть пустым');
    }
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/cancel'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({'userId': userId}),
      );
      final body = _decodeBody(response.bodyBytes);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        return Order.fromJson(jsonMap);
      }

      final details = body.trim();
      if (details.isNotEmpty) {
        throw Exception('Не удалось отменить заказ: $details');
      }
      throw Exception('Не удалось отменить заказ: ${response.statusCode}');
    } catch (e) {
      print('Ошибка при отмене заказа: $e');
      rethrow;
    }
  }

  static Future<List<ReviewEntry>> getUserReviews({required int userId}) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList.map((json) => ReviewEntry.fromJson(json)).toList();
      } else {
        throw Exception('Не удалось загрузить данные: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке данных: $e');
      rethrow;
    }
  }

  static Future<List<ReviewEntry>> getProductReviews({
    required String productId,
  }) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      throw ArgumentError('productId не должен быть пустым');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews?productId=$normalizedProductId'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList
            .map((json) => ReviewEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Не удалось загрузить отзывы товара: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при загрузке отзывов товара: $e');
      rethrow;
    }
  }

  static Future<List<PendingReviewItem>> getPendingReviews({
    required int userId,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/pending?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList
            .map((json) => PendingReviewItem.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Не удалось загрузить товары, ожидающие отзыва: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при загрузке товаров, ожидающих отзыва: $e');
      rethrow;
    }
  }

  static Future<ReviewEntry> createReview({
    required int userId,
    required String orderId,
    required String orderItemId,
    required String productId,
    required int rating,
    required String reviewText,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'userId': userId,
          'orderId': orderId,
          'orderItemId': orderItemId,
          'productId': productId,
          'rating': rating,
          'reviewText': reviewText,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _decodeBody(response.bodyBytes);
        return ReviewEntry.fromJson(jsonDecode(body));
      } else {
        throw Exception(
          'Не удалось выполнить операцию: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при выполнении операции: $e');
      rethrow;
    }
  }

  static Future<ReviewEntry> updateReview({
    required String reviewId,
    required int userId,
    required int rating,
    required String reviewText,
  }) async {
    if (reviewId.isEmpty) {
      throw ArgumentError('reviewId не должен быть пустым');
    }
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'userId': userId,
          'rating': rating,
          'reviewText': reviewText,
        }),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return ReviewEntry.fromJson(jsonDecode(body));
      } else {
        throw Exception('Не удалось обновить запись: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при обновлении записи: $e');
      rethrow;
    }
  }

  static Future<void> deleteReview({
    required String reviewId,
    required int userId,
  }) async {
    if (reviewId.isEmpty) {
      throw ArgumentError('reviewId не должен быть пустым');
    }
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId?userId=$userId'),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Не удалось выполнить операцию: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при выполнении операции: $e');
      rethrow;
    }
  }

  static Future<List<SupplierProduct>> getSupplierProducts({
    required int userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/supplier/products?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList.map((json) => SupplierProduct.fromJson(json)).toList();
      } else {
        throw Exception(
          'Не удалось загрузить товары поставщика: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при загрузке данных поставщика: $e');
      rethrow;
    }
  }

  static Future<SupplierProduct> createSupplierProduct({
    required SupplierProduct product,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/supplier/products'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode(product.toRequestPayload(userId: userId)),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _decodeBody(response.bodyBytes);
        return SupplierProduct.fromJson(jsonDecode(body));
      }

      final errorMessage = _extractResponseErrorMessage(response);
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }

      throw Exception(
        'Не удалось создать товар поставщика: ${response.statusCode}',
      );
    } catch (e) {
      print('Ошибка при создании товара поставщика: $e');
      rethrow;
    }
  }

  static Future<SupplierProduct> updateSupplierProduct({
    required SupplierProduct product,
    required int userId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/supplier/products/${product.id}'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode(product.toRequestPayload(userId: userId)),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return SupplierProduct.fromJson(jsonDecode(body));
      }

      final errorMessage = _extractResponseErrorMessage(response);
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }

      throw Exception(
        'Не удалось обновить товар поставщика: ${response.statusCode}',
      );
    } catch (e) {
      print('Ошибка при обновлении товара поставщика: $e');
      rethrow;
    }
  }

  static Future<void> deleteSupplierProduct({
    required String productId,
    required int userId,
  }) async {
    if (productId.trim().isEmpty) {
      throw ArgumentError('productId не должен быть пустым');
    }
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/supplier/products/$productId?userId=$userId'),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Не удалось выполнить операцию: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при удалении товара поставщика: $e');
      rethrow;
    }
  }

  static Future<List<SupplierOrder>> getSupplierOrders({
    required int userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/supplier/orders?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList.map((json) => SupplierOrder.fromJson(json)).toList();
      } else {
        throw Exception(
          'Не удалось загрузить товары поставщика: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при загрузке данных поставщика: $e');
      rethrow;
    }
  }

  static Future<SupplierOrder> updateSupplierOrderStatus({
    required String orderId,
    required int userId,
    required String status,
  }) async {
    if (orderId.trim().isEmpty) {
      throw ArgumentError('orderId не должен быть пустым');
    }
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }
    if (status.trim().isEmpty) {
      throw ArgumentError('status не должен быть пустым');
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/supplier/orders/$orderId/status'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({'userId': userId, 'status': status}),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return SupplierOrder.fromJson(jsonDecode(body));
      } else {
        final errorBody = _decodeBody(response.bodyBytes).trim();
        final suffix = errorBody.isEmpty ? '' : ': $errorBody';
        throw Exception(
          'Не удалось обновить статус заказа поставщика: ${response.statusCode}$suffix',
        );
      }
    } catch (e) {
      print('Ошибка при обновлении статуса заказа поставщика: $e');
      rethrow;
    }
  }

  static Future<List<SupplierProduct>> getModerationProducts({
    String status = 'pending',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/moderation/products?status=$status'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList.map((json) => SupplierProduct.fromJson(json)).toList();
      } else {
        throw Exception(
          'Не удалось загрузить товары на модерации: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при загрузке товаров на модерации: $e');
      rethrow;
    }
  }

  static Future<SupplierProduct> updateModerationStatus({
    required String productId,
    required String status,
    String? comment,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/moderation/products/$productId'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({'status': status, 'comment': comment}),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return SupplierProduct.fromJson(jsonDecode(body));
      }

      final errorMessage = _extractResponseErrorMessage(response);
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }

      throw Exception(
        'Не удалось обновить статус модерации: ${response.statusCode}',
      );
    } catch (e) {
      print('Ошибка при обновлении статуса модерации: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> deleteModerationProduct({
    required String productId,
    required int moderatorId,
    required String reason,
  }) async {
    final normalizedProductId = productId.trim();
    final normalizedReason = reason.trim();

    if (normalizedProductId.isEmpty) {
      throw ArgumentError('productId не должен быть пустым');
    }
    if (moderatorId <= 0) {
      throw ArgumentError('moderatorId должен быть положительным');
    }
    if (normalizedReason.isEmpty) {
      throw ArgumentError('reason не должен быть пустым');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/moderation/products/$normalizedProductId'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({'moderatorId': moderatorId, 'reason': normalizedReason}),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes).trim();
        if (body.isEmpty) {
          return const <String, dynamic>{'deleted': true};
        }
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        return const <String, dynamic>{'deleted': true};
      }
      if (response.statusCode == 204) {
        return const <String, dynamic>{'deleted': true};
      }

      final errorMessage = _extractResponseErrorMessage(response);
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }

      throw Exception(
        'Не удалось удалить товар модератором: ${response.statusCode}',
      );
    } catch (e) {
      print('Ошибка при удалении товара модератором: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getModerationCategories({
    bool includeInactive = true,
  }) async {
    try {
      final query = includeInactive ? '?includeInactive=true' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/moderation/categories$query'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is! List) {
          return const <Map<String, dynamic>>[];
        }
        return decoded.whereType<Map>().map((row) {
          final rawKeywords = row['keywords'];
          final keywords = <String>[];
          if (rawKeywords is List) {
            for (final keyword in rawKeywords) {
              final normalized = keyword.toString().trim();
              if (normalized.isNotEmpty) {
                keywords.add(normalized);
              }
            }
          } else if (rawKeywords != null) {
            for (final keyword in rawKeywords.toString().split(
              RegExp(r'[;,|]'),
            )) {
              final normalized = keyword.trim();
              if (normalized.isNotEmpty) {
                keywords.add(normalized);
              }
            }
          }
          return {
            'id': row['id'],
            'name': row['name']?.toString() ?? '',
            'parentId': row['parentId'] ?? row['parent_id'],
            'subtitle': row['subtitle']?.toString() ?? '',
            'imagePath': row['imagePath']?.toString() ?? '',
            'keywords': keywords,
            'sortOrder': row['sortOrder'] ?? row['sort_order'] ?? 0,
            'isActive': row['isActive'] ?? row['is_active'] ?? true,
          };
        }).toList();
      } else {
        throw Exception(
          'Не удалось загрузить категории модерации: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при работе с категориями модерации: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createModerationCategory({
    required String name,
    int? parentId,
    String? subtitle,
    String? imagePath,
    List<String>? keywords,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('name не должен быть пустым');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/moderation/categories'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'name': name.trim(),
          'parentId': parentId,
          'subtitle': subtitle?.trim(),
          'imagePath': imagePath?.trim(),
          'keywords': keywords,
          'sortOrder': sortOrder,
          'isActive': isActive,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        return Map<String, dynamic>.from(decoded as Map);
      } else {
        throw Exception(
          'Не удалось создать категорию модерации: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при работе с категориями модерации: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateModerationCategory({
    required int id,
    String? name,
    int? parentId,
    String? subtitle,
    String? imagePath,
    List<String>? keywords,
    int? sortOrder,
    bool? isActive,
  }) async {
    if (id <= 0) {
      throw ArgumentError('id должен быть положительным');
    }

    final payload = <String, dynamic>{};
    if (name != null) {
      payload['name'] = name.trim();
    }
    if (parentId != null) {
      payload['parentId'] = parentId;
    }
    if (subtitle != null) {
      payload['subtitle'] = subtitle.trim();
    }
    if (imagePath != null) {
      payload['imagePath'] = imagePath.trim();
    }
    if (keywords != null) {
      payload['keywords'] = keywords;
    }
    if (sortOrder != null) {
      payload['sortOrder'] = sortOrder;
    }
    if (isActive != null) {
      payload['isActive'] = isActive;
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/moderation/categories/$id'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        return Map<String, dynamic>.from(decoded as Map);
      } else {
        throw Exception(
          'Не удалось обновить категорию модерации: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при обновлении категории модерации: $e');
      rethrow;
    }
  }

  static Future<void> deleteModerationCategory({required int id}) async {
    if (id <= 0) {
      throw ArgumentError('id должен быть положительным');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/moderation/categories/$id'),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Не удалось удалить категорию модерации: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при удалении категории модерации: $e');
      rethrow;
    }
  }

  static Future<SupportChatThread> getSupportThread({
    required int userId,
    int? chatId,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }
    if (chatId != null && chatId <= 0) {
      throw ArgumentError('chatId должен быть положительным');
    }

    try {
      final query = <String, String>{'userId': '$userId'};
      if (chatId != null) {
        query['chatId'] = '$chatId';
      }
      final uri = Uri.parse(
        '$baseUrl/support/thread',
      ).replace(queryParameters: query);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return SupportChatThread.fromJson(
          jsonDecode(body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Не удалось загрузить тред поддержки: ${response.statusCode}',
      );
    } catch (e) {
      print('Ошибка при загрузке треда поддержки: $e');
      rethrow;
    }
  }

  static Future<List<SupportMessage>> getSupportMessages({
    required int userId,
    int? chatId,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }
    if (chatId != null && chatId <= 0) {
      throw ArgumentError('chatId должен быть положительным');
    }

    try {
      final query = <String, String>{'userId': '$userId'};
      if (chatId != null) {
        query['chatId'] = '$chatId';
      }
      final uri = Uri.parse(
        '$baseUrl/support/messages',
      ).replace(queryParameters: query);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList
            .map(
              (json) => SupportMessage.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      throw Exception(
        'Не удалось загрузить сообщения поддержки: ${response.statusCode}',
      );
    } catch (e) {
      print('Ошибка при загрузке сообщений поддержки: $e');
      rethrow;
    }
  }

  static Future<SupportMessage> sendSupportMessage({
    required int userId,
    required String senderRole,
    required String text,
    int? chatId,
    int? senderUserId,
    String? category,
    String? subject,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }
    if (text.trim().isEmpty) {
      throw ArgumentError('text не должен быть пустым');
    }
    if (chatId != null && chatId <= 0) {
      throw ArgumentError('chatId должен быть положительным');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/support/messages'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'userId': userId,
          'senderRole': senderRole,
          'chatId': chatId,
          'senderUserId': senderUserId,
          'category': category,
          'subject': subject,
          'text': text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _decodeBody(response.bodyBytes);
        return SupportMessage.fromJson(
          jsonDecode(body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Не удалось отправить сообщение в поддержку: ${response.statusCode}',
      );
    } catch (e) {
      print('Ошибка при отправке сообщения в поддержку: $e');
      rethrow;
    }
  }

  static Future<List<SupportChatSummary>> getModeratorSupportChats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/moderation/support/chats'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList
            .map(
              (json) =>
                  SupportChatSummary.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Не удалось загрузить список чатов модерации: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при загрузке чатов модерации: $e');
      rethrow;
    }
  }

  static Future<List<SupportMessage>> getModeratorSupportMessages({
    required int chatId,
  }) async {
    if (chatId <= 0) {
      throw ArgumentError('chatId должен быть положительным');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/moderation/support/messages/$chatId'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList
            .map(
              (json) => SupportMessage.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      throw Exception(
        'Не удалось загрузить сообщения чата модерации: ${response.statusCode}',
      );
    } catch (e) {
      print('Ошибка при загрузке сообщений чата модерации: $e');
      rethrow;
    }
  }

  static Future<SupportChatThread> getModeratorSupportThread({
    required int chatId,
  }) async {
    if (chatId <= 0) {
      throw ArgumentError('chatId должен быть положительным');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/moderation/support/thread/$chatId'),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return SupportChatThread.fromJson(
          jsonDecode(body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Не удалось загрузить тред чата модерации: ${response.statusCode}',
      );
    } catch (e) {
      print('Ошибка при загрузке треда чата модерации: $e');
      rethrow;
    }
  }

  static Future<SupportChat> closeModeratorSupportChat({
    required int chatId,
    required int moderatorId,
    String? reason,
  }) async {
    if (chatId <= 0) {
      throw ArgumentError('chatId должен быть положительным');
    }
    if (moderatorId <= 0) {
      throw ArgumentError('moderatorId должен быть положительным');
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/moderation/support/chats/$chatId/close'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({'moderatorId': moderatorId, 'reason': reason}),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return SupportChat.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }
      throw Exception('Не удалось закрыть чат: ${response.statusCode}');
    } catch (e) {
      print('Ошибка при закрытии чата поддержки: $e');
      rethrow;
    }
  }

  static Stream<Map<String, dynamic>> supportEvents({
    required int userId,
    int? chatId,
  }) {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }
    if (chatId != null && chatId <= 0) {
      throw ArgumentError('chatId должен быть положительным');
    }

    final query = <String, String>{'userId': '$userId'};
    if (chatId != null) {
      query['chatId'] = '$chatId';
    }
    final uri = Uri.parse(
      '$baseUrl/support/events',
    ).replace(queryParameters: query);
    return _supportEventsStream(uri, streamLabel: 'пользователь');
  }

  static Stream<Map<String, dynamic>> moderatorSupportEvents({int? chatId}) {
    if (chatId != null && chatId <= 0) {
      throw ArgumentError('chatId должен быть положительным');
    }

    final query = <String, String>{};
    if (chatId != null) {
      query['chatId'] = '$chatId';
    }
    final uri = Uri.parse(
      '$baseUrl/moderation/support/events',
    ).replace(queryParameters: query.isEmpty ? null : query);
    return _supportEventsStream(uri, streamLabel: 'модератор');
  }

  static Stream<Map<String, dynamic>> _supportEventsStream(
    Uri uri, {
    required String streamLabel,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request('GET', uri)
        ..headers['accept'] = 'text/event-stream';
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = _decodeBody(await response.stream.toBytes());
        final suffix = body.trim().isEmpty ? '' : ': ${body.trim()}';
        throw Exception(
          'Не удалось подключиться к SSE ($streamLabel), код ${response.statusCode}$suffix',
        );
      }

      final dataLines = <String>[];
      String? eventName;

      Map<String, dynamic>? flushFrame() {
        if (dataLines.isEmpty) {
          eventName = null;
          return null;
        }

        final rawPayload = dataLines.join('\n');
        dataLines.clear();
        final currentEvent = eventName;
        eventName = null;

        final parsedPayload = _parseSsePayload(rawPayload);
        if (parsedPayload == null) {
          return null;
        }
        if (currentEvent != null && currentEvent.isNotEmpty) {
          parsedPayload['event'] = currentEvent;
        }
        return parsedPayload;
      }

      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.isEmpty) {
          final frame = flushFrame();
          if (frame != null) {
            yield frame;
          }
          continue;
        }

        if (line.startsWith(':')) {
          continue;
        }
        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
          continue;
        }
        if (line.startsWith('data:')) {
          dataLines.add(line.substring(5).trimLeft());
        }
      }

      final trailingFrame = flushFrame();
      if (trailingFrame != null) {
        yield trailingFrame;
      }
    } catch (e) {
      print('Ошибка SSE-подписки ($streamLabel): $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  static Map<String, dynamic>? _parseSsePayload(String rawPayload) {
    if (rawPayload.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {'kind': 'message', 'payload': decoded};
    } catch (_) {
      return {'kind': 'message', 'payload': rawPayload};
    }
  }

  static String? _extractResponseErrorMessage(http.Response response) {
    final body = _decodeBody(response.bodyBytes).trim();
    if (body.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is String) {
        final text = decoded.trim();
        return text.isEmpty ? null : text;
      }
      if (decoded is Map) {
        final data = Map<String, dynamic>.from(decoded);
        const keys = <String>[
          'message',
          'error',
          'detail',
          'description',
          'reason',
        ];
        for (final key in keys) {
          final value = data[key]?.toString().trim();
          if (value != null && value.isNotEmpty) {
            return value;
          }
        }
      }
    } catch (_) {
      // Ignore JSON parsing and fallback to plain-text body.
    }

    return body;
  }

  static String _decodeBody(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }
}


