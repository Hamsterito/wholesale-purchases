import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:postgres/postgres.dart';

int _toPositiveInt(dynamic value, {int fallback = 0}) {
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

int? _toNullablePositiveInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value > 0 ? value : null;
  if (value is double) {
    final rounded = value.round();
    return rounded > 0 ? rounded : null;
  }
  final parsed = int.tryParse(value.toString());
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

Future<void> _ensureOrderSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.orders (
      id SERIAL PRIMARY KEY,
      status VARCHAR(50) NOT NULL,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');

  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.order_items (
      id SERIAL PRIMARY KEY,
      order_id INTEGER NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
      name VARCHAR(255) NOT NULL,
      volume VARCHAR(50),
      price INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      image_url VARCHAR(500),
      is_received BOOLEAN NOT NULL DEFAULT false
    );
  ''');

  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);',
  );
}
List<String> _parseCategories(Object? value) {
  final raw = value?.toString() ?? '';
  final parts = raw.split(RegExp(r'[;,|]'));
  final categories = parts
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  return categories.isEmpty ? ['Напитки'] : categories;
}

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

  print('Connected to PostgreSQL!');

  try {
    await _ensureOrderSchema(connection);
  } catch (e, st) {
    print('Order schema init error: $e\n$st');
    rethrow;
  }

  final router = Router();

  // Проверка соединения
  router.get('/', (Request request) {
    return Response.ok(
      'Бэкенд работает и подключен к PostgreSQL!',
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

  // Получение всех товаров
  router.get('/products', (Request request) async {
    try {
      final imagesByProductId = <int, List<String>>{};
      try {
        final imagesResult = await connection.execute(
          'SELECT product_id, image_url, sort_order, id FROM product_images ORDER BY product_id, sort_order, id;',
        );
        for (final row in imagesResult) {
          final imageMap = row.toColumnMap();
          final productId = imageMap['product_id'];
          final imageUrl = imageMap['image_url']?.toString() ?? '';
          if (productId is! int || imageUrl.isEmpty) {
            continue;
          }
          imagesByProductId.putIfAbsent(productId, () => []);
          imagesByProductId[productId]!.add(imageUrl);
        }
      } catch (e, st) {
        print('Ошибка при загрузке product_images: $e\n$st');
      }

      final result = await connection.execute('SELECT * FROM products;');
      final products = result.map((row) {
        final map = row.toColumnMap();
        final productId = map['id'] as int;
        final name = (map['name'] ?? '').toString();
        final description = (map['description'] ?? '').toString();
        final categories = _parseCategories(map['category']);
        final fallbackImage = map['image_url']?.toString() ?? '';
        final resolvedImages = imagesByProductId[productId];
        final imageUrls = resolvedImages != null && resolvedImages.isNotEmpty
            ? resolvedImages
            : [
                if (fallbackImage.isNotEmpty)
                  fallbackImage
                else
                  'assets/coca_cola.jpeg',
              ];
        final normalized = '$name $description'.toLowerCase();
        if (normalized.contains('газир') &&
            !categories.any((c) => c.toLowerCase() == 'газировка')) {
          categories.add('Газировка');
        }
        return {
          'id': productId.toString(),
          'name': name,
          'description': description,
          'imageUrls': imageUrls,
          'rating': double.tryParse(map['rating'].toString()) ?? 0.0,
          'reviewCount': map['review_count'] ?? 0,
          'categories': categories,
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
              'maxQuantity': _toNullablePositiveInt(
                map['max_quantity'] ?? map['limit_quantity'],
              ),
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
      print('Ошибка при получении товаров: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  // Получение всех заказов
  router.get('/orders', (Request request) async {
    try {
      final ordersResult =
          await connection.execute('SELECT * FROM orders ORDER BY created_at DESC;');
      final itemsResult = await connection.execute('SELECT * FROM order_items ORDER BY id;');

      final itemsByOrderId = <int, List<Map<String, dynamic>>>{};
      for (final row in itemsResult) {
        final map = row.toColumnMap();
        final orderId = map['order_id'] as int;
        itemsByOrderId.putIfAbsent(orderId, () => []);
        itemsByOrderId[orderId]!.add({
          'name': map['name'] ?? '',
          'volume': map['volume'] ?? '',
          'price': map['price'] ?? 0,
          'quantity': map['quantity'] ?? 0,
          'imageUrl': map['image_url'] ?? '',
          'isReceived': map['is_received'] ?? false,
        });
      }

      final orders = ordersResult.map((row) {
        final map = row.toColumnMap();
        final orderId = map['id'] as int;
        return {
          'id': orderId.toString(),
          'date': (map['created_at'] as DateTime).toIso8601String(),
          'status': map['status'] ?? '',
          'items': itemsByOrderId[orderId] ?? [],
        };
      }).toList();

      return Response.ok(
        jsonEncode(orders),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при получении заказов: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.post('/orders', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);

      if (decoded is! Map) {
        return Response.badRequest(
          body: 'Expected JSON object with status and items',
        );
      }

      final payload = Map<String, dynamic>.from(decoded as Map);
      final rawStatus = payload['status']?.toString().trim();
      final status = (rawStatus == null || rawStatus.isEmpty) ? 'Принят' : rawStatus;
      final rawItems = payload['items'];

      if (rawItems is! List || rawItems.isEmpty) {
        return Response.badRequest(body: 'Items are required');
      }

      final createdOrder = await connection.execute(
        Sql.named(
          'INSERT INTO orders (status) VALUES (@status) RETURNING id, status, created_at;',
        ),
        parameters: {'status': status},
      );

      final createdMap = createdOrder.first.toColumnMap();
      final orderId = createdMap['id'] as int;
      final normalizedItems = <Map<String, dynamic>>[];

      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          continue;
        }
        final item = Map<String, dynamic>.from(rawItem as Map);
        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty) {
          continue;
        }

        final volume = item['volume']?.toString() ?? '';
        final price = _toPositiveInt(item['price']);
        final quantity = _toPositiveInt(item['quantity'], fallback: 1);
        final imageUrl = item['imageUrl']?.toString() ?? '';
        final isReceived = item['isReceived'] == true;

        await connection.execute(
          Sql.named(
            '''
            INSERT INTO order_items (order_id, name, volume, price, quantity, image_url, is_received)
            VALUES (@order_id, @name, @volume, @price, @quantity, @image_url, @is_received);
            ''',
          ),
          parameters: {
            'order_id': orderId,
            'name': name,
            'volume': volume,
            'price': price,
            'quantity': quantity,
            'image_url': imageUrl,
            'is_received': isReceived,
          },
        );

        normalizedItems.add({
          'name': name,
          'volume': volume,
          'price': price,
          'quantity': quantity,
          'imageUrl': imageUrl,
          'isReceived': isReceived,
        });
      }

      if (normalizedItems.isEmpty) {
        await connection.execute(
          Sql.named('DELETE FROM orders WHERE id = @id'),
          parameters: {'id': orderId},
        );
        return Response.badRequest(body: 'At least one item with name is required');
      }

      return Response(
        201,
        body: jsonEncode({
          'id': orderId.toString(),
          'date': (createdMap['created_at'] as DateTime).toIso8601String(),
          'status': createdMap['status'] ?? status,
          'items': normalizedItems,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Invalid JSON body');
    } catch (e, st) {
      print('Ошибка при создании заказа: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  // Регистрация нового пользователя
  router.post('/register', (Request request) async {
    try {
      final body = await request.readAsString();
      print('Получено тело: $body');

      final data = Uri.splitQueryString(body);

      final name = data['name'];
      final email = data['email'];
      final password = data['password'];

      if (name == null || email == null || password == null) {
        return Response(400, body: 'Missing fields');
      }

      final existing = await connection.execute(
        Sql.named('SELECT * FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      if (existing.isNotEmpty) {
        return Response.forbidden('Email already registered');
      }

      await connection.execute(
        Sql.named('INSERT INTO users (name, email, password) VALUES (@name, @email, @password)'),
        parameters: {'name': name, 'email': email, 'password': password},
      );

      print('Новый пользователь добавлен: $email');
      return Response.ok('Registration successful');
    } catch (e, st) {
      print('Ошибка при регистрации: $e\n$st');
      return Response.internalServerError(body: 'Server error: $e');
    }
  });

  router.post('/login', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);

      final email = data['email'];
      final password = data['password'];

      if (email == null || password == null) {
        return Response.badRequest(body: 'Отсутствует email или пароль');
      }

      final result = await connection.execute(
        Sql.named('SELECT * FROM users WHERE email = @email AND password = @password'),
        parameters: {'email': email, 'password': password},
      );

      if (result.isEmpty) {
        return Response.forbidden('Неправильный логин или пароль');
      }

      final user = result.first.toColumnMap();
      return Response.ok(
        'Добро пожаловать, ${user['name']}!',
        headers: {'content-type': 'text/plain; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при авторизации: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера');
    }
  });

  // Middleware (CORS и логирование)
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router);

  // Запуск сервера
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('Сервер запущен: http://${server.address.host}:${server.port}');
}

