import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import '../services/api_config.dart';

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
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while loading products: $e');
      rethrow;
    }
  }

  static Future<List<Order>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while loading orders: $e');
      rethrow;
    }
  }

  static Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    String status = 'Принят',
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('items must not be empty');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: const {
          'content-type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'status': status,
          'items': items,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _decodeBody(response.bodyBytes);
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        return Order.fromJson(jsonMap);
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while creating order: $e');
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
}
