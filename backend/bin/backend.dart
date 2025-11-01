import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:postgres/postgres.dart';

void main() async {
  // Подключение к PostgreSQL
  final connection = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'shop_db',
      username: 'postgres',
      password: '123',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  print('✅ Подключено к PostgreSQL!');

  final router = Router();

  // Проверка соединения
  router.get('/', (Request request) {
    return Response.ok(
      '✅ Бекенд работает и подключен к PostgreSQL!',
      headers: {'content-type': 'text/plain; charset=utf-8'},
    );
  });

  // Получение всех пользователей
  router.get('/users', (Request request) async {
    final result = await connection.execute('SELECT * FROM users;');
    final users = result.map((row) => row.toColumnMap()).toList();

    return Response.ok(
      jsonEncode(users),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  // 🛒 Получение всех товаров
  router.get('/products', (Request request) async {
    try {
      final result = await connection.execute('SELECT * FROM products;');
      final products = result.map((row) {
        final map = row.toColumnMap();
        return {
          'id': map['id'].toString(),
          'name': map['name'],
          'description': map['description'] ?? '',
          'imageUrls': [map['image_url'] ?? 'assets/coca_cola.jpeg'],
          'rating': double.tryParse(map['rating'].toString()) ?? 0.0,
          'reviewCount': map['review_count'] ?? 0,
          'categories': [map['category'] ?? 'Напитки'],
          'nutritionalInfo': {
            'calories': 42.0,
            'protein': 0.0,
            'fat': 0.0,
            'carbohydrates': 10.6,
          },
          'ingredients': 'Состав продукта',
          'characteristics': {
            'Страна производителя': 'Казахстан',
          },
          'suppliers': [
            {
              'id': '1',
              'name': map['supplier_name'] ?? 'Склад',
              'rating': double.tryParse(map['rating'].toString()) ?? 0.0,
              'reviewCount': map['review_count'] ?? 0,
              'pricePerUnit': map['price_per_unit'] ?? 0,
              'minQuantity': map['min_quantity'] ?? 1,
              'deliveryDate': map['delivery_date'] ?? 'завтра',
              'deliveryInfo': 'Доставка мегаполис',
              'deliveryBadge': map['delivery_badge'] ?? 'Четверг 17:00',
            }
          ],
          'similarProducts': [],
          'ratingDistribution': [
            {'stars': 5, 'count': 7},
            {'stars': 4, 'count': 3},
            {'stars': 3, 'count': 1},
            {'stars': 2, 'count': 1},
            {'stars': 1, 'count': 1},
          ],
        };
      }).toList();

      return Response.ok(
        jsonEncode(products),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('❌ Ошибка при получении товаров: $e\n$st');
      return Response.internalServerError(body: '⚠️ Ошибка сервера: $e');
    }
  });

  // 🔹 Регистрация нового пользователя
  router.post('/register', (Request request) async {
    try {
      final body = await request.readAsString();
      print('📥 Получено тело: $body');

      final data = Uri.splitQueryString(body);

      final name = data['name'];
      final email = data['email'];
      final password = data['password'];

      if (name == null || email == null || password == null) {
        return Response(400, body: '❌ Missing fields');
      }

      final existing = await connection.execute(
        Sql.named('SELECT * FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      if (existing.isNotEmpty) {
        return Response.forbidden('⚠️ Email already registered');
      }

      await connection.execute(
        Sql.named('INSERT INTO users (name, email, password) VALUES (@name, @email, @password)'),
        parameters: {'name': name, 'email': email, 'password': password},
      );

      print('✅ Новый пользователь добавлен: $email');
      return Response.ok('✅ Registration successful');
    } catch (e, st) {
      print('❌ Ошибка при регистрации: $e\n$st');
      return Response.internalServerError(body: '⚠️ Server error: $e');
    }
  });

  // 🔐 Авторизация
  router.post('/login', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);

      final email = data['email'];
      final password = data['password'];

      if (email == null || password == null) {
        return Response.badRequest(body: '❌ Отсутствует email или пароль');
      }

      final result = await connection.execute(
        Sql.named('SELECT * FROM users WHERE email = @email AND password = @password'),
        parameters: {'email': email, 'password': password},
      );

      if (result.isEmpty) {
        return Response.forbidden('❌ Неправильный логин или пароль');
      }

      final user = result.first.toColumnMap();
      return Response.ok(
        '✅ Добро пожаловать, ${user['name']}!',
        headers: {'content-type': 'text/plain; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при авторизации: $e\n$st');
      return Response.internalServerError(body: '⚠️ Ошибка сервера');
    }
  });

  // Middleware (CORS и логирование)
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router);

  // Запуск сервера
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('🚀 Сервер запущен: http://${server.address.host}:${server.port}');
}