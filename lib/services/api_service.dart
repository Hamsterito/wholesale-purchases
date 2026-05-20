import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http_package;
import '../models/product.dart';
import '../models/order.dart';
import '../services/api_config.dart';
import 'app_http_client.dart';
import '../models/supplier_order.dart';
import '../models/supplier_product.dart';
import '../models/user_profile.dart';
import '../models/user_address.dart';
import '../models/review_entry.dart';
import '../models/support_message.dart';
import '../models/notification.dart';

final http = AppHttpClient.instance;

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
      debugPrint('Ошибка при загрузке данных: $e');
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
      debugPrint('Ошибка при загрузке категорий: $e');
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
      debugPrint('Ошибка при загрузке списка категорий: $e');
      rethrow;
    }
  }

  static Future<List<Order>> getOrders({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null && userId > 0) {
        queryParams['userId'] = userId.toString();
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      final uri = Uri.parse(
        '$baseUrl/orders',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Не удалось загрузить данные: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке данных: $e');
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
      debugPrint('Ошибка при выполнении операции: $e');
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
      debugPrint('Ошибка при загрузке профиля пользователя: $e');
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
      debugPrint('Ошибка при обновлении профиля: $e');
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
      debugPrint('Ошибка при смене пароля: $e');
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
      debugPrint('Ошибка при загрузке данных: $e');
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
      debugPrint('Ошибка при выполнении операции: $e');
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
      debugPrint('Ошибка при обновлении записи: $e');
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
      debugPrint('Ошибка при выполнении операции: $e');
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
      debugPrint('Ошибка при принятии заказа: $e');
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
      debugPrint('Ошибка при отмене заказа: $e');
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
      debugPrint('Ошибка при загрузке данных: $e');
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
      debugPrint('Ошибка при загрузке отзывов товара: $e');
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
      debugPrint('Ошибка при загрузке товаров, ожидающих отзыва: $e');
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
      debugPrint('Ошибка при выполнении операции: $e');
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
      debugPrint('Ошибка при обновлении записи: $e');
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
      debugPrint('Ошибка при выполнении операции: $e');
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
      debugPrint('Ошибка при загрузке данных поставщика: $e');
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
      debugPrint('Ошибка при создании товара поставщика: $e');
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
      debugPrint('Ошибка при обновлении товара поставщика: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> deleteSupplierProduct({
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
      } else {
        final errorMessage = _extractResponseErrorMessage(response);
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
        throw Exception(
          'Не удалось выполнить операцию: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при удалении товара поставщика: $e');
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
      debugPrint('Ошибка при загрузке данных поставщика: $e');
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
      debugPrint('Ошибка при обновлении статуса заказа поставщика: $e');
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
      debugPrint('Ошибка при загрузке товаров на модерации: $e');
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
      debugPrint('Ошибка при обновлении статуса модерации: $e');
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
        body: jsonEncode({
          'moderatorId': moderatorId,
          'reason': normalizedReason,
        }),
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
      debugPrint('Ошибка при удалении товара модератором: $e');
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
      debugPrint('Ошибка при работе с категориями модерации: $e');
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
      debugPrint('Ошибка при работе с категориями модерации: $e');
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
      debugPrint('Ошибка при обновлении категории модерации: $e');
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
      debugPrint('Ошибка при удалении категории модерации: $e');
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
      debugPrint('Ошибка при загрузке треда поддержки: $e');
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
      debugPrint('Ошибка при загрузке сообщений поддержки: $e');
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
      debugPrint('Ошибка при отправке сообщения в поддержку: $e');
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
      debugPrint('Ошибка при загрузке чатов модерации: $e');
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
      debugPrint('Ошибка при загрузке сообщений чата модерации: $e');
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
      debugPrint('Ошибка при загрузке треда чата модерации: $e');
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
      debugPrint('Ошибка при закрытии чата поддержки: $e');
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
    final client = AppHttpClient.create();
    try {
      final request = http_package.Request('GET', uri)
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
      debugPrint('Ошибка SSE-подписки ($streamLabel): $e');
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

  static String? _extractResponseErrorMessage(http_package.Response response) {
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

  static Future<Uint8List> exportOrdersExcel({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/export/orders/excel'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.bodyBytes);
      } else {
        throw Exception(
          'Не удалось экспортировать заказы: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при экспорте заказов: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getProductQuestions({
    required String productId,
    int page = 1,
    int limit = 20,
  }) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      throw ArgumentError('productId не должен быть пустым');
    }

    try {
      final uri = Uri.parse(
        '$baseUrl/products/$normalizedProductId/questions?page=$page&limit=$limit',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body) as Map<String, dynamic>;

        // Validate response structure
        if (!decoded.containsKey('questions') ||
            !decoded.containsKey('total')) {
          throw Exception(
            'Неверный формат ответа сервера: отсутствуют поля questions или total',
          );
        }

        final questions = decoded['questions'];
        if (questions is! List) {
          throw Exception(
            'Неверный формат ответа сервера: questions должен быть списком',
          );
        }

        final total = decoded['total'];
        if (total is! int) {
          throw Exception(
            'Неверный формат ответа сервера: total должен быть числом',
          );
        }

        return decoded;
      } else {
        final errorMessage = _extractResponseErrorMessage(response);
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
        throw Exception('Не удалось загрузить вопросы: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке вопросов: $e');
      rethrow;
    }
  }

  static Future<void> askQuestion({
    required String productId,
    required int userId,
    required String questionText,
  }) async {
    final normalizedProductId = productId.trim();
    final normalizedQuestionText = questionText.trim();

    if (normalizedProductId.isEmpty) {
      throw ArgumentError('productId не должен быть пустым');
    }
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }
    if (normalizedQuestionText.isEmpty) {
      throw ArgumentError('Вопрос не должен быть пустым');
    }
    if (normalizedQuestionText.length < 10) {
      throw ArgumentError('Вопрос должен содержать минимум 10 символов');
    }

    try {
      final uri = Uri.parse('$baseUrl/products/$normalizedProductId/questions');
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'userId': userId,
          'questionText': normalizedQuestionText,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      }

      final errorMessage = _extractResponseErrorMessage(response);
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }

      throw Exception('Не удалось задать вопрос: ${response.statusCode}');
    } catch (e) {
      debugPrint('Ошибка при отправке вопроса: $e');
      rethrow;
    }
  }

  static Future<void> answerQuestion({
    required int questionId,
    required int supplierUserId,
    required String answerText,
  }) async {
    final uri = Uri.parse('$baseUrl/questions/$questionId/answer');
    final response = await http.post(
      uri,
      body: jsonEncode({
        'supplierUserId': supplierUserId,
        'answerText': answerText,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Не удалось ответить');
    }
  }

  static Future<Map<String, dynamic>> getSupplierQuestions({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final queryParams = <String, String>{
        'userId': userId.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };
      final uri = Uri.parse(
        '$baseUrl/supplier/questions',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        return {
          'questions': decoded['questions'] ?? [],
          'total': decoded['total'] ?? 0,
        };
      } else {
        throw Exception('Не удалось загрузить вопросы: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке вопросов: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getSupplierReviews({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final queryParams = <String, String>{
        'userId': userId.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };
      final uri = Uri.parse(
        '$baseUrl/supplier/reviews',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        return {
          'reviews': decoded['reviews'] ?? [],
          'total': decoded['total'] ?? 0,
        };
      } else {
        throw Exception('Не удалось загрузить отзывы: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке отзывов: $e');
      rethrow;
    }
  }

  static Future<void> updateQuestionAnswer({
    required String questionId,
    required int supplierUserId,
    required String answerText,
  }) async {
    final normalizedQuestionId = questionId.trim();
    if (normalizedQuestionId.isEmpty) {
      throw ArgumentError('questionId не должен быть пустым');
    }
    if (supplierUserId <= 0) {
      throw ArgumentError('supplierUserId должен быть положительным');
    }
    final normalizedAnswerText = answerText.trim();
    if (normalizedAnswerText.isEmpty) {
      throw ArgumentError('answerText не должен быть пустым');
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/questions/$normalizedQuestionId/answer'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'supplierUserId': supplierUserId,
          'answerText': normalizedAnswerText,
        }),
      );

      if (response.statusCode != 200) {
        final errorMessage = _extractResponseErrorMessage(response);
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
        throw Exception('Не удалось обновить ответ: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении ответа: $e');
      rethrow;
    }
  }

  static Future<void> respondToReview({
    required String reviewId,
    required int supplierUserId,
    required String responseText,
  }) async {
    final normalizedReviewId = reviewId.trim();
    if (normalizedReviewId.isEmpty) {
      throw ArgumentError('reviewId не должен быть пустым');
    }
    if (supplierUserId <= 0) {
      throw ArgumentError('supplierUserId должен быть положительным');
    }
    final normalizedResponseText = responseText.trim();
    if (normalizedResponseText.isEmpty) {
      throw ArgumentError('responseText не должен быть пустым');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/$normalizedReviewId/response'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'supplierUserId': supplierUserId,
          'responseText': normalizedResponseText,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorMessage = _extractResponseErrorMessage(response);
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
        throw Exception('Не удалось отправить ответ: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при отправке ответа на отзыв: $e');
      rethrow;
    }
  }

  static Future<void> updateReviewResponse({
    required String reviewId,
    required int supplierUserId,
    required String responseText,
  }) async {
    final normalizedReviewId = reviewId.trim();
    if (normalizedReviewId.isEmpty) {
      throw ArgumentError('reviewId не должен быть пустым');
    }
    if (supplierUserId <= 0) {
      throw ArgumentError('supplierUserId должен быть положительным');
    }
    final normalizedResponseText = responseText.trim();
    if (normalizedResponseText.isEmpty) {
      throw ArgumentError('responseText не должен быть пустым');
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/reviews/$normalizedReviewId/response'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'supplierUserId': supplierUserId,
          'responseText': normalizedResponseText,
        }),
      );

      if (response.statusCode != 200) {
        final errorMessage = _extractResponseErrorMessage(response);
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
        throw Exception('Не удалось обновить ответ: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении ответа на отзыв: $e');
      rethrow;
    }
  }

  static String _decodeBody(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  // Флаг для использования mock-данных при разработке.
  // Выключен — бэкенд реализует /suppliers/{id} эндпоинты.
  static bool _useMockData = false;

  /// Включает/отключает использование mock-данных для разработки и тестирования.
  /// Когда включено, API возвращает реалистичные mock-данные вместо 404 ошибок.
  static void setUseMockData(bool enabled) {
    _useMockData = enabled;
    debugPrint(
      'Mock data для поставщиков: ${enabled ? 'включены' : 'отключены'}',
    );
  }

  /// Возвращает mock-данные поставщика для разработки и тестирования.
  static Supplier _getMockSupplier(String supplierId) {
    // Создаём реалистичные mock-данные на основе ID поставщика
    final mockSuppliers = {
      'supplier_123': Supplier(
        id: 'supplier_123',
        name: 'ООО Оптовая Компания',
        rating: 4.5,
        reviewCount: 128,
        pricePerUnit: 1500,
        minQuantity: 10,
        maxQuantity: 1000,
        stockQuantity: 500,
        deliveryDate: '2024-01-15',
        deliveryInfo: 'Доставка по России',
        deliveryBadge: 'Быстрая доставка',
        logoUrl: 'https://via.placeholder.com/200?text=Supplier123',
        description: 'Поставщик качественных товаров оптом с 10-летним опытом',
        address: 'г. Москва, ул. Примерная, д. 1',
        phone: '+7 (495) 123-45-67',
        email: 'info@supplier123.ru',
      ),
      'supplier_456': Supplier(
        id: 'supplier_456',
        name: 'ООО Торговый Дом',
        rating: 4.2,
        reviewCount: 95,
        pricePerUnit: 2000,
        minQuantity: 5,
        maxQuantity: 500,
        stockQuantity: 300,
        deliveryDate: '2024-01-16',
        deliveryInfo: 'Доставка по России и СНГ',
        deliveryBadge: 'Надёжный партнёр',
        logoUrl: 'https://via.placeholder.com/200?text=Supplier456',
        description: 'Крупный оптовый поставщик с широким ассортиментом',
        address: 'г. Санкт-Петербург, пр. Невский, д. 50',
        phone: '+7 (812) 456-78-90',
        email: 'sales@torgovydom.ru',
      ),
      'supplier_789': Supplier(
        id: 'supplier_789',
        name: 'ООО Экспресс Поставки',
        rating: 4.8,
        reviewCount: 256,
        pricePerUnit: 1200,
        minQuantity: 20,
        maxQuantity: 2000,
        stockQuantity: 1500,
        deliveryDate: '2024-01-14',
        deliveryInfo: 'Экспресс-доставка 24 часа',
        deliveryBadge: 'Быстрая доставка',
        logoUrl: 'https://via.placeholder.com/200?text=Supplier789',
        description: 'Специализируемся на быстрой доставке товаров оптом',
        address: 'г. Екатеринбург, ул. Главная, д. 100',
        phone: '+7 (343) 789-01-23',
        email: 'express@dostavka.ru',
      ),
    };

    // Если есть точное совпадение — возвращаем его
    if (mockSuppliers.containsKey(supplierId)) {
      return mockSuppliers[supplierId]!;
    }

    // Иначе создаём generic mock-поставщика на основе ID
    return Supplier(
      id: supplierId,
      name: 'Поставщик $supplierId',
      rating: 4.0,
      reviewCount: 50,
      pricePerUnit: 1500,
      minQuantity: 10,
      maxQuantity: 1000,
      stockQuantity: 500,
      deliveryDate: '2024-01-15',
      deliveryInfo: 'Доставка по России',
      deliveryBadge: 'Стандартная доставка',
      logoUrl: 'https://via.placeholder.com/200?text=$supplierId',
      description: 'Надёжный поставщик оптовых товаров',
      address: 'Россия',
      phone: '+7 (000) 000-00-00',
      email: 'info@supplier.ru',
    );
  }

  /// Возвращает mock-каталог товаров поставщика для разработки и тестирования.
  static Map<String, dynamic> _getMockSupplierCatalog(String supplierId) {
    // Создаём mock-товары для каждого поставщика
    final mockProducts = <String, List<Map<String, dynamic>>>{
      'supplier_123': [
        {
          'id': 'product_1',
          'name': 'Товар 1 от поставщика 123',
          'price': 1500,
          'rating': 4.5,
          'reviewCount': 50,
          'imageUrl': 'https://via.placeholder.com/200?text=Product1',
          'category': 'Категория 1',
          'suppliers': [
            {
              'id': 'supplier_123',
              'name': 'ООО Оптовая Компания',
              'rating': 4.5,
              'reviewCount': 128,
              'pricePerUnit': 1500,
              'minQuantity': 10,
              'maxQuantity': 1000,
              'stockQuantity': 500,
              'deliveryDate': '2024-01-15',
              'deliveryInfo': 'Доставка по России',
              'deliveryBadge': 'Быстрая доставка',
            },
          ],
        },
        {
          'id': 'product_2',
          'name': 'Товар 2 от поставщика 123',
          'price': 2000,
          'rating': 4.2,
          'reviewCount': 30,
          'imageUrl': 'https://via.placeholder.com/200?text=Product2',
          'category': 'Категория 2',
          'suppliers': [
            {
              'id': 'supplier_123',
              'name': 'ООО Оптовая Компания',
              'rating': 4.5,
              'reviewCount': 128,
              'pricePerUnit': 2000,
              'minQuantity': 10,
              'maxQuantity': 1000,
              'stockQuantity': 500,
              'deliveryDate': '2024-01-15',
              'deliveryInfo': 'Доставка по России',
              'deliveryBadge': 'Быстрая доставка',
            },
          ],
        },
      ],
      'supplier_456': [
        {
          'id': 'product_3',
          'name': 'Товар 1 от поставщика 456',
          'price': 2000,
          'rating': 4.2,
          'reviewCount': 40,
          'imageUrl': 'https://via.placeholder.com/200?text=Product3',
          'category': 'Категория 1',
          'suppliers': [
            {
              'id': 'supplier_456',
              'name': 'ООО Торговый Дом',
              'rating': 4.2,
              'reviewCount': 95,
              'pricePerUnit': 2000,
              'minQuantity': 5,
              'maxQuantity': 500,
              'stockQuantity': 300,
              'deliveryDate': '2024-01-16',
              'deliveryInfo': 'Доставка по России и СНГ',
              'deliveryBadge': 'Надёжный партнёр',
            },
          ],
        },
      ],
      'supplier_789': [
        {
          'id': 'product_4',
          'name': 'Товар 1 от поставщика 789',
          'price': 1200,
          'rating': 4.8,
          'reviewCount': 100,
          'imageUrl': 'https://via.placeholder.com/200?text=Product4',
          'category': 'Категория 1',
          'suppliers': [
            {
              'id': 'supplier_789',
              'name': 'ООО Экспресс Поставки',
              'rating': 4.8,
              'reviewCount': 256,
              'pricePerUnit': 1200,
              'minQuantity': 20,
              'maxQuantity': 2000,
              'stockQuantity': 1500,
              'deliveryDate': '2024-01-14',
              'deliveryInfo': 'Экспресс-доставка 24 часа',
              'deliveryBadge': 'Быстрая доставка',
            },
          ],
        },
        {
          'id': 'product_5',
          'name': 'Товар 2 от поставщика 789',
          'price': 1800,
          'rating': 4.6,
          'reviewCount': 80,
          'imageUrl': 'https://via.placeholder.com/200?text=Product5',
          'category': 'Категория 2',
          'suppliers': [
            {
              'id': 'supplier_789',
              'name': 'ООО Экспресс Поставки',
              'rating': 4.8,
              'reviewCount': 256,
              'pricePerUnit': 1800,
              'minQuantity': 20,
              'maxQuantity': 2000,
              'stockQuantity': 1500,
              'deliveryDate': '2024-01-14',
              'deliveryInfo': 'Экспресс-доставка 24 часа',
              'deliveryBadge': 'Быстрая доставка',
            },
          ],
        },
      ],
    };

    final products = mockProducts[supplierId] ?? [];
    return {
      'products': products.map((p) => Product.fromJson(p)).toList(),
      'total': products.length,
    };
  }

  // Загрузка профиля поставщика по ID
  static Future<Supplier> getSupplier(String supplierId) async {
    final normalizedId = supplierId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError('supplierId не должен быть пустым');
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/suppliers/$normalizedId'))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Время ожидания истекло'),
          );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return Supplier.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        // Если включены mock-данные, возвращаем их вместо ошибки
        if (_useMockData) {
          debugPrint('Возвращаем mock-данные для поставщика: $normalizedId');
          return _getMockSupplier(normalizedId);
        }
        throw Exception('Поставщик не найден');
      }

      final errorMessage = _extractResponseErrorMessage(response);
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }

      throw Exception(
        'Не удалось загрузить профиль поставщика: ${response.statusCode}',
      );
    } catch (e) {
      // Если включены mock-данные и произошла ошибка сети, возвращаем mock-данные
      if (_useMockData && e is! ArgumentError) {
        debugPrint(
          'Ошибка сети, возвращаем mock-данные для поставщика: $normalizedId',
        );
        return _getMockSupplier(normalizedId);
      }
      debugPrint('Ошибка при загрузке профиля поставщика: $e');
      rethrow;
    }
  }

  // Загрузка каталога товаров поставщика по его ID с пагинацией
  static Future<Map<String, dynamic>> getSupplierCatalog(
    String supplierId, {
    int page = 1,
    int limit = 20,
  }) async {
    final normalizedId = supplierId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError('supplierId не должен быть пустым');
    }

    try {
      final uri = Uri.parse('$baseUrl/suppliers/$normalizedId/products')
          .replace(
            queryParameters: {
              'page': page.toString(),
              'limit': limit.toString(),
            },
          );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Время ожидания истекло'),
          );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body) as Map<String, dynamic>;

        final rawProducts = decoded['products'];
        final products = rawProducts is List
            ? rawProducts.map((p) => Product.fromJson(p)).toList()
            : <Product>[];

        return {
          'products': products,
          'total': decoded['total'] ?? products.length,
        };
      }

      if (response.statusCode == 404) {
        // Если включены mock-данные, возвращаем их вместо ошибки
        if (_useMockData) {
          debugPrint('Возвращаем mock-каталог для поставщика: $normalizedId');
          return _getMockSupplierCatalog(normalizedId);
        }
        throw Exception('Поставщик не найден');
      }

      final errorMessage = _extractResponseErrorMessage(response);
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }

      throw Exception(
        'Не удалось загрузить товары поставщика: ${response.statusCode}',
      );
    } catch (e) {
      // Если включены mock-данные и произошла ошибка сети, возвращаем mock-данные
      if (_useMockData && e is! ArgumentError) {
        debugPrint(
          'Ошибка сети, возвращаем mock-каталог для поставщика: $normalizedId',
        );
        return _getMockSupplierCatalog(normalizedId);
      }
      debugPrint('Ошибка при загрузке товаров поставщика: $e');
      rethrow;
    }
  }

  // Методы для статистики поставщика
  static Future<Map<String, dynamic>> fetchSupplierStatsSummary({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final queryParams = <String, String>{'userId': userId.toString()};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse(
        '$baseUrl/supplier/statistics/summary',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Не удалось загрузить сводку статистики: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке сводки статистики: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSupplierRevenueHistory({
    required int userId,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final queryParams = <String, String>{'userId': userId.toString()};

      final uri = Uri.parse(
        '$baseUrl/supplier/statistics/revenue-history',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        return [];
      } else {
        throw Exception(
          'Не удалось загрузить историю выручки: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке истории выручки: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSupplierRevenueDaily({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final queryParams = <String, String>{
        'userId': userId.toString(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse(
        '$baseUrl/supplier/statistics/revenue-daily',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        return [];
      } else {
        throw Exception(
          'Не удалось загрузить дневную выручку: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке дневной выручки: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSupplierTopProducts({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final queryParams = <String, String>{'userId': userId.toString()};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse(
        '$baseUrl/supplier/statistics/top-products',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        return [];
      } else {
        throw Exception(
          'Не удалось загрузить топ товаров: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке топ товаров: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchSupplierOrderStats({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final queryParams = <String, String>{'userId': userId.toString()};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse(
        '$baseUrl/supplier/statistics/order-stats',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Не удалось загрузить статистику заказов: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке статистики заказов: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchSupplierBuyerStats({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final queryParams = <String, String>{'userId': userId.toString()};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse(
        '$baseUrl/supplier/statistics/buyer-stats',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Не удалось загрузить статистику покупателей: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке статистики покупателей: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchSupplierRatingStats({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    try {
      final queryParams = <String, String>{'userId': userId.toString()};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse(
        '$baseUrl/supplier/statistics/rating-stats',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        return jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Не удалось загрузить статистику рейтингов: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке статистики рейтингов: $e');
      rethrow;
    }
  }

  // Методы для работы с уведомлениями

  /// Загружает счётчики уведомлений, собирая данные из существующих эндпоинтов параллельно.
  /// Отдельного эндпоинта /notifications/counts на бэкенде нет.
  /// [role] — роль пользователя ('buyer', 'supplier', 'moderator') для фильтрации запросов.
  static Future<NotificationCounts> getNotificationCounts({
    required int userId,
    String role = '',
  }) async {
    if (userId <= 0) {
      throw ArgumentError('userId должен быть положительным');
    }

    // Запускаем только те запросы, которые нужны для роли пользователя
    final futures = await Future.wait([
      _fetchUnreadMessagesCount(userId),
      // У покупателя и поставщика заказы лежат в разных эндпоинтах,
      // поэтому используем разные методы загрузки
      role == 'buyer'
          ? _fetchPendingOrdersCount(userId)
          : role == 'supplier'
          ? _fetchPendingSupplierOrdersCount(userId)
          : Future.value(0),
      role == 'buyer' ? _fetchPendingReviewsCount(userId) : Future.value(0),
      role == 'supplier' || role == 'moderator'
          ? _fetchPendingModerationsCount()
          : Future.value(0),
      // Доставленные заказы — только для покупателя
      role == 'buyer' ? _fetchDeliveredOrdersCount(userId) : Future.value(0),
    ]);

    return NotificationCounts(
      unreadMessages: futures[0],
      pendingOrders: futures[1],
      pendingReviews: futures[2],
      pendingModerations: futures[3],
      deliveredOrders: futures[4],
    );
  }

  /// Считает открытые чаты поддержки, где последнее сообщение от модератора
  /// (т.е. пользователь ещё не ответил — есть что прочитать).
  static Future<int> _fetchUnreadMessagesCount(int userId) async {
    try {
      final thread = await getSupportThread(userId: userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Таймаут'),
      );
      if (thread.chat == null || !thread.chat!.isOpen) return 0;
      // Если последнее сообщение от модератора — значит пользователь не ответил
      if (thread.messages.isEmpty) return 0;
      final lastMsg = thread.messages.last;
      return lastMsg.isFromModerator ? 1 : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Считает заказы в активных статусах (не завершены и не отменены).
  /// Принятые заказы ("Принят", "accepted", "received") считаются финальными
  /// и не попадают в счётчик ожидающих.
  static Future<int> _fetchPendingOrdersCount(int userId) async {
    try {
      final orders = await getOrders(userId: userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Таймаут'),
      );
      return orders.where((o) {
        final s = o.status.trim().toLowerCase();
        final isDone =
            s == 'доставлен' ||
            s == 'получено' ||
            s == 'delivered' ||
            s == 'принят' ||
            s == 'принята' ||
            s == 'принято' ||
            s == 'приняты' ||
            s == 'accepted' ||
            s == 'received' ||
            s == 'завершено' ||
            s == 'completed';
        final isCancelled =
            s.contains('отмена') ||
            s == 'cancelled' ||
            s == 'отменён' ||
            s == 'отменен';
        return !isDone && !isCancelled;
      }).length;
    } catch (_) {
      return 0;
    }
  }

  /// Считает заказы поставщика, ожидающие действия:
  /// заказы со статусом "Собирается" / "В пути" / etc.
  /// (не завершённые покупателем и не отменённые).
  /// Использует /supplier/orders, а не /orders — это разные эндпоинты.
  static Future<int> _fetchPendingSupplierOrdersCount(int userId) async {
    try {
      final orders = await getSupplierOrders(userId: userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Таймаут'),
      );
      return orders.where((o) {
        final s = o.status.trim().toLowerCase();
        // "Принят" покупателем = заказ закрыт для поставщика
        final isDone =
            s == 'доставлен' ||
            s == 'получено' ||
            s == 'delivered' ||
            s == 'принят' ||
            s == 'принята' ||
            s == 'принято' ||
            s == 'приняты' ||
            s == 'accepted' ||
            s == 'received' ||
            s == 'завершено' ||
            s == 'completed';
        final isCancelled =
            s.contains('отмена') ||
            s == 'cancelled' ||
            s == 'отменён' ||
            s == 'отменен';
        return !isDone && !isCancelled;
      }).length;
    } catch (_) {
      return 0;
    }
  }

  /// Считает доставленные заказы покупателя, которые ещё не подтверждены как полученные.
  /// Статус "Доставлен" означает, что товар привезли, но покупатель ещё не нажал "Получил".
  static Future<int> _fetchDeliveredOrdersCount(int userId) async {
    try {
      final orders = await getOrders(userId: userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Таймаут'),
      );
      return orders.where((o) {
        final s = o.status.trim().toLowerCase();
        return s == 'доставлен' || s == 'delivered';
      }).length;
    } catch (_) {
      return 0;
    }
  }

  /// Считает товары, ожидающие отзыва от покупателя.
  static Future<int> _fetchPendingReviewsCount(int userId) async {
    try {
      final items = await getPendingReviews(userId: userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Таймаут'),
      );
      return items.length;
    } catch (_) {
      return 0;
    }
  }

  /// Считает товары на модерации со статусом pending.
  static Future<int> _fetchPendingModerationsCount() async {
    try {
      final products = await getModerationProducts(status: 'pending').timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Таймаут'),
      );
      return products.length;
    } catch (_) {
      return 0;
    }
  }

  /// Отмечает сообщение поддержки как прочитанное.
  /// Бэкенд не поддерживает этот эндпоинт — счётчик обновляется локально в NotificationService.
  static Future<void> markMessageAsRead({
    required int userId,
    required int messageId,
  }) async {
    // no-op: отдельного эндпоинта нет, локальное уменьшение счётчика делает NotificationService
  }

  /// Отмечает заказ как просмотренный.
  /// Бэкенд не поддерживает этот эндпоинт — счётчик обновляется локально в NotificationService.
  static Future<void> markOrderAsReviewed({
    required int userId,
    required String orderId,
  }) async {
    // no-op: отдельного эндпоинта нет, локальное уменьшение счётчика делает NotificationService
  }

  /// Скрывает уведомление определённого типа.
  /// Бэкенд не поддерживает этот эндпоинт — счётчик обновляется локально в NotificationService.
  static Future<void> dismissNotification({
    required int userId,
    required String notificationType,
  }) async {
    // no-op: отдельного эндпоинта нет, локальное уменьшение счётчика делает NotificationService
  }
}
