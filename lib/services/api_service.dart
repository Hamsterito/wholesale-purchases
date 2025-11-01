import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки товаров: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при получении товаров: $e');
      rethrow;
    }
  }
}