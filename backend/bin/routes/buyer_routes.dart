part of '../backend.dart';

// Роуты для роли buyer (покупатель):
// адреса доставки, заказы, отзывы, вопросы, экспорт своих заказов.

void _registerBuyerAddressRoutes(Router router, Connection connection) {
  router.post('/users/<id>/addresses', (Request request, String id) async {
    try {
      final userId = int.tryParse(id);
      if (userId == null) {
        return Response.badRequest(body: 'Неверный id пользователя');
      }

      final userResult = await connection.execute(
        Sql.named('SELECT id FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound('Пользователь не найден');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }

      final payload = Map<String, dynamic>.from(decoded);
      final normalizedAddress = _normalizeAddressPayload(payload);
      final addressError = _validateAddressPayload(normalizedAddress);
      if (addressError != null) {
        return Response.badRequest(body: addressError);
      }
      final label = normalizedAddress.label;
      final addressLine = normalizedAddress.addressLine;
      if (addressLine.isEmpty) {
        return Response.badRequest(body: 'Поле адреса обязательно');
      }

      final street = normalizedAddress.street;
      final zip = normalizedAddress.zip;
      final apartment = normalizedAddress.apartment;

      final created = await connection.execute(
        Sql.named('''
          INSERT INTO addresses (
            user_id,
            label,
            address_line,
            street,
            zip,
            apartment
          )
          VALUES (
            @user_id,
            @label,
            @address_line,
            @street,
            @zip,
            @apartment
          )
          RETURNING *;
        '''),
        parameters: {
          'user_id': userId,
          'label': label,
          'address_line': addressLine,
          'street': street,
          'zip': zip,
          'apartment': apartment,
        },
      );

      final createdMap = created.first.toColumnMap();
      return Response(
        201,
        body: jsonEncode(_addressRowToDto(createdMap)),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при создании адреса: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.put('/users/<id>/addresses/<addressId>', (
    Request request,
    String id,
    String addressId,
  ) async {
    try {
      final userId = int.tryParse(id);
      final addressRowId = int.tryParse(addressId);
      if (userId == null || addressRowId == null) {
        return Response.badRequest(body: 'Неверный id адреса');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }

      final payload = Map<String, dynamic>.from(decoded);
      final normalizedAddress = _normalizeAddressPayload(payload);
      final addressError = _validateAddressPayload(normalizedAddress);
      if (addressError != null) {
        return Response.badRequest(body: addressError);
      }
      final label = normalizedAddress.label;
      final addressLine = normalizedAddress.addressLine;
      if (addressLine.isEmpty) {
        return Response.badRequest(body: 'Поле адреса обязательно');
      }

      final street = normalizedAddress.street;
      final zip = normalizedAddress.zip;
      final apartment = normalizedAddress.apartment;

      final updated = await connection.execute(
        Sql.named('''
          UPDATE addresses
          SET label = @label,
              address_line = @address_line,
              street = @street,
              zip = @zip,
              apartment = @apartment
          WHERE id = @id AND user_id = @user_id
          RETURNING *;
        '''),
        parameters: {
          'id': addressRowId,
          'user_id': userId,
          'label': label,
          'address_line': addressLine,
          'street': street,
          'zip': zip,
          'apartment': apartment,
        },
      );

      if (updated.isEmpty) {
        return Response.notFound('Адрес не найден');
      }

      final updatedMap = updated.first.toColumnMap();
      return Response.ok(
        jsonEncode(_addressRowToDto(updatedMap)),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при обновлении адреса: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.delete('/users/<id>/addresses/<addressId>', (
    Request request,
    String id,
    String addressId,
  ) async {
    final userId = int.tryParse(id);
    final addressRowId = int.tryParse(addressId);
    if (userId == null || addressRowId == null) {
      return Response.badRequest(body: 'Неверный id адреса');
    }

    final deleted = await connection.execute(
      Sql.named(
        'DELETE FROM addresses WHERE id = @id AND user_id = @user_id RETURNING id;',
      ),
      parameters: {'id': addressRowId, 'user_id': userId},
    );

    if (deleted.isEmpty) {
      return Response.notFound('Адрес не найден');
    }

    return Response.ok(
      jsonEncode({'deleted': true}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

void _registerBuyerOrderRoutes(Router router, Connection connection) {
  router.post('/orders', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);

      if (decoded is! Map) {
        return Response.badRequest(
          body: 'Ожидается JSON объект со статусом и товарами',
        );
      }

      final payload = Map<String, dynamic>.from(decoded);
      final rawStatus = payload['status']?.toString().trim();
      final status = (rawStatus == null || rawStatus.isEmpty)
          ? 'Принят'
          : rawStatus;
      final deliveryAddress = payload['deliveryAddress']?.toString().trim();
      final rawItems = payload['items'];

      final userId = _toPositiveInt(payload['userId']);
      if (userId == 0) {
        return Response.badRequest(
          body: 'Идентификатор пользователя обязателен',
        );
      }

      if (rawItems is! List || rawItems.isEmpty) {
        return Response.badRequest(body: 'Список товаров обязателен');
      }

      final productIds = <int>{};
      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          continue;
        }
        final item = Map<String, dynamic>.from(rawItem);
        final productId = _toNullablePositiveInt(
          item['productId'] ?? item['product_id'],
        );
        if (productId != null) {
          productIds.add(productId);
        }
      }

      final productById = <int, Map<String, dynamic>>{};
      if (productIds.isNotEmpty) {
        final productResult = await connection.execute(
          Sql.named('''
            SELECT p.id,
                   p.supplier_user_id,
                   p.supplier_name,
                   p.stock_quantity,
                   p.max_quantity,
                   p.name,
                   p.image_url,
                   EXISTS(
                     SELECT 1
                     FROM order_items oi
                     WHERE oi.product_id = p.id
                   ) AS has_orders
            FROM products p
            WHERE p.id = ANY(@ids);
            '''),
          parameters: {'ids': productIds.toList()},
        );
        for (final row in productResult) {
          final map = row.toColumnMap();
          final productId = map['id'] as int;
          productById[productId] = map;
        }
      }

      final validationErrors = <String>[];
      final stockErrors = <String>[];
      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          continue;
        }
        final item = Map<String, dynamic>.from(rawItem);
        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty) {
          continue;
        }
        final quantity = _toPositiveInt(item['quantity'], fallback: 1);
        final productId = _toNullablePositiveInt(
          item['productId'] ?? item['product_id'],
        );
        if (productId == null) {
          validationErrors.add('Для товара "$name" не указан productId');
          continue;
        }
        final productRow = productById[productId];
        if (productRow == null) {
          validationErrors.add('Товар "$name" недоступен');
          continue;
        }
        final hasOrders = productRow['has_orders'] == true;
        final rawStockQuantity = _toPositiveInt(productRow['stock_quantity']);
        final legacyMaxQuantity = _toPositiveInt(productRow['max_quantity']);
        final stockQuantity = rawStockQuantity > 0
            ? rawStockQuantity
            : (!hasOrders ? legacyMaxQuantity : 0);
        if (stockQuantity < quantity) {
          final productName = productRow['name']?.toString().trim();
          final resolvedName = (productName == null || productName.isEmpty)
              ? name
              : productName;
          stockErrors.add('$resolvedName: доступно $stockQuantity шт.');
        }
      }

      if (validationErrors.isNotEmpty) {
        return Response.badRequest(
          body: validationErrors.join(' '),
          headers: _utf8TextHeaders,
        );
      }

      if (stockErrors.isNotEmpty) {
        return Response(
          409,
          body: 'Недостаточно товара на складе: ${stockErrors.join(' ')}',
          headers: _utf8TextHeaders,
        );
      }

      final createdOrder = await connection.execute(
        Sql.named('''
          INSERT INTO orders (status, delivery_address, user_id)
          VALUES (@status, @delivery_address, @user_id)
          RETURNING id, status, created_at, delivery_address, user_id;
          '''),
        parameters: {
          'status': status,
          'delivery_address': deliveryAddress,
          'user_id': userId,
        },
      );

      final createdMap = createdOrder.first.toColumnMap();
      final orderId = createdMap['id'] as int;
      final normalizedItems = <Map<String, dynamic>>[];
      final deductedByProduct = <int, int>{};

      Future<void> rollbackCreatedOrder() async {
        for (final entry in deductedByProduct.entries) {
          await connection.execute(
            Sql.named('''
              UPDATE products
              SET stock_quantity = stock_quantity + @quantity
              WHERE id = @id;
            '''),
            parameters: {'id': entry.key, 'quantity': entry.value},
          );
        }
        await connection.execute(
          Sql.named('DELETE FROM order_items WHERE order_id = @id'),
          parameters: {'id': orderId},
        );
        await connection.execute(
          Sql.named('DELETE FROM orders WHERE id = @id'),
          parameters: {'id': orderId},
        );
      }

      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          continue;
        }
        final item = Map<String, dynamic>.from(rawItem);
        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty) {
          continue;
        }

        final price = _toPositiveInt(item['price']);
        final quantity = _toPositiveInt(item['quantity'], fallback: 1);
        final parsedProductId = _toNullablePositiveInt(
          item['productId'] ?? item['product_id'],
        );
        if (parsedProductId == null) {
          await rollbackCreatedOrder();
          return Response.badRequest(
            body: 'Для товара "$name" не указан productId',
            headers: _utf8TextHeaders,
          );
        }
        final productId = parsedProductId;
        final productRow = productById[productId];
        if (productRow == null) {
          await rollbackCreatedOrder();
          return Response.badRequest(
            body: 'Товар "$name" недоступен',
            headers: _utf8TextHeaders,
          );
        }
        final imageUrl =
            item['imageUrl']?.toString() ??
            productRow['image_url']?.toString() ??
            '';
        final isReceived = item['isReceived'] == true;
        final supplierUserId =
            _toNullablePositiveInt(item['supplierUserId']) ??
            _toNullablePositiveInt(productRow['supplier_user_id']);
        var supplierName = item['supplierName']?.toString().trim() ?? '';
        if (supplierName.isEmpty) {
          supplierName = productRow['supplier_name']?.toString() ?? '';
        }

        final updatedStock = await connection.execute(
          Sql.named('''
            UPDATE products
            SET stock_quantity = CASE
              WHEN stock_quantity > 0 THEN stock_quantity - @quantity
              WHEN (stock_quantity <= 0 OR stock_quantity IS NULL)
                   AND max_quantity IS NOT NULL
                   AND max_quantity > 0
                   AND NOT EXISTS (
                     SELECT 1
                     FROM order_items oi
                     WHERE oi.product_id = @id
                   )
                THEN max_quantity - @quantity
              ELSE stock_quantity
            END
            WHERE id = @id
              AND (
                stock_quantity >= @quantity
                OR (
                  (stock_quantity <= 0 OR stock_quantity IS NULL)
                  AND max_quantity IS NOT NULL
                  AND max_quantity >= @quantity
                  AND NOT EXISTS (
                    SELECT 1
                    FROM order_items oi
                    WHERE oi.product_id = @id
                  )
                )
              )
            RETURNING stock_quantity;
          '''),
          parameters: {'id': productId, 'quantity': quantity},
        );

        if (updatedStock.isEmpty) {
          await rollbackCreatedOrder();
          return Response(
            409,
            body: 'Недостаточно товара на складе',
            headers: _utf8TextHeaders,
          );
        }

        final remainingStock = _toPositiveInt(
          updatedStock.first.toColumnMap()['stock_quantity'],
        );
        deductedByProduct.update(
          productId,
          (value) => value + quantity,
          ifAbsent: () => quantity,
        );

        final createdItem = await connection.execute(
          Sql.named('''
            INSERT INTO order_items (
              order_id,
              product_id,
              name,
              price,
              quantity,
              image_url,
              is_received,
              supplier_name,
              supplier_user_id
            )
            VALUES (
              @order_id,
              @product_id,
              @name,
              @price,
              @quantity,
              @image_url,
              @is_received,
              @supplier_name,
              @supplier_user_id
            )
            RETURNING id;
            '''),
          parameters: {
            'order_id': orderId,
            'product_id': productId,
            'name': name,
            'price': price,
            'quantity': quantity,
            'image_url': imageUrl,
            'is_received': isReceived,
            'supplier_name': supplierName,
            'supplier_user_id': supplierUserId,
          },
        );

        final itemMap = createdItem.first.toColumnMap();
        final orderItemId = itemMap['id']?.toString() ?? '';
        normalizedItems.add({
          'id': orderItemId,
          'productId': productId.toString(),
          'name': name,
          'price': price,
          'quantity': quantity,
          'imageUrl': imageUrl,
          'isReceived': isReceived,
          'supplierName': supplierName,
          'remainingStock': remainingStock,
        });
      }

      if (normalizedItems.isEmpty) {
        await rollbackCreatedOrder();
        return Response.badRequest(
          body: 'Нужен минимум один товар с названием',
        );
      }

      return Response(
        201,
        body: jsonEncode({
          'id': orderId.toString(),
          'date': (createdMap['created_at'] as DateTime).toIso8601String(),
          'status': createdMap['status'] ?? status,
          'deliveryAddress': createdMap['delivery_address'] ?? '',
          'items': normalizedItems,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при создании заказа: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.patch('/orders/<id>/accept', (Request request, String id) async {
    try {
      final orderId = int.tryParse(id);
      if (orderId == null) {
        return Response.badRequest(body: 'Неверный id заказа');
      }

      final existing = await connection.execute(
        Sql.named('SELECT * FROM orders WHERE id = @id;'),
        parameters: {'id': orderId},
      );
      if (existing.isEmpty) {
        return Response.notFound('Заказ не найден');
      }

      await connection.execute(
        Sql.named("UPDATE orders SET status = 'Принят' WHERE id = @id;"),
        parameters: {'id': orderId},
      );
      await connection.execute(
        Sql.named(
          'UPDATE order_items SET is_received = true WHERE order_id = @id;',
        ),
        parameters: {'id': orderId},
      );

      final itemsResult = await connection.execute(
        Sql.named(
          'SELECT * FROM order_items WHERE order_id = @id ORDER BY id;',
        ),
        parameters: {'id': orderId},
      );

      final items = itemsResult.map((row) {
        final map = row.toColumnMap();
        return {
          'id': map['id']?.toString() ?? '',
          'productId': map['product_id']?.toString() ?? '',
          'name': map['name'] ?? '',
          'price': map['price'] ?? 0,
          'quantity': map['quantity'] ?? 0,
          'imageUrl': map['image_url'] ?? '',
          'supplierName': map['supplier_name'] ?? '',
          'isReceived': map['is_received'] ?? false,
        };
      }).toList();

      final orderMap = existing.first.toColumnMap();
      return Response.ok(
        jsonEncode({
          'id': orderId.toString(),
          'date': (orderMap['created_at'] as DateTime).toIso8601String(),
          'status': 'Принят',
          'deliveryAddress': orderMap['delivery_address'] ?? '',
          'items': items,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при принятии заказа: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.patch("/orders/<id>/cancel", (Request request, String id) async {
    try {
      final orderId = int.tryParse(id);
      if (orderId == null || orderId <= 0) {
        return Response.badRequest(body: "Неверный id заказа");
      }

      final body = await request.readAsString();
      final trimmedBody = body.trim();
      Map<String, dynamic> payload = const {};
      if (trimmedBody.isNotEmpty) {
        final decoded = jsonDecode(trimmedBody);
        if (decoded is! Map) {
          return Response.badRequest(body: "Ожидается JSON объект");
        }
        payload = Map<String, dynamic>.from(decoded);
      }

      final userId =
          _toNullablePositiveInt(payload["userId"] ?? payload["user_id"]) ??
          _toNullablePositiveInt(request.url.queryParameters["userId"]);
      if (userId == null) {
        return Response.badRequest(body: "userId обязателен");
      }

      final existing = await connection.execute(
        Sql.named("SELECT * FROM orders WHERE id = @id;"),
        parameters: {"id": orderId},
      );
      if (existing.isEmpty) {
        return Response.notFound("Заказ не найден");
      }

      final orderMap = existing.first.toColumnMap();
      final orderUserId = _toNullablePositiveInt(orderMap["user_id"]);
      if (orderUserId == null || orderUserId != userId) {
        return Response.forbidden("Недостаточно прав для отмены заказа");
      }

      final currentStatus = orderMap["status"];
      if (_isAcceptedOrderStatus(currentStatus)) {
        return Response(
          409,
          body: "Нельзя отменить подтвержденный заказ",
          headers: _utf8TextHeaders,
        );
      }
      if (_isCancelledOrderStatus(currentStatus)) {
        return Response(
          409,
          body: "Заказ уже отменен",
          headers: _utf8TextHeaders,
        );
      }

      final createdAt =
          _toNullableDateTime(orderMap["created_at"]) ?? DateTime.now();
      final cancellationDeadline = createdAt.add(_orderCancellationWindow);
      if (DateTime.now().isAfter(cancellationDeadline)) {
        return Response(
          409,
          body:
              "Отмена доступна только в течение первого часа после оформления",
          headers: _utf8TextHeaders,
        );
      }

      final itemsForRestock = await connection.execute(
        Sql.named("""
          SELECT product_id, quantity
          FROM order_items
          WHERE order_id = @id AND product_id IS NOT NULL;
        """),
        parameters: {"id": orderId},
      );

      for (final row in itemsForRestock) {
        final item = row.toColumnMap();
        final productId = _toNullablePositiveInt(item["product_id"]);
        final quantity = _toPositiveInt(item["quantity"]);
        if (productId == null || quantity <= 0) {
          continue;
        }

        try {
          await connection.execute(
            Sql.named("""
              UPDATE products
              SET stock_quantity = COALESCE(stock_quantity, 0) + @quantity
              WHERE id = @id;
            """),
            parameters: {"id": productId, "quantity": quantity},
          );
        } catch (e, st) {
          print("Не удалось вернуть остаток товара $productId: $e\n$st");
        }
      }

      await connection.execute(
        Sql.named("UPDATE orders SET status = @status WHERE id = @id;"),
        parameters: {"status": _cancelledOrderStatus, "id": orderId},
      );

      final updatedOrderResult = await connection.execute(
        Sql.named("SELECT * FROM orders WHERE id = @id;"),
        parameters: {"id": orderId},
      );
      if (updatedOrderResult.isEmpty) {
        return Response.notFound("Заказ не найден");
      }

      final updatedOrder = updatedOrderResult.first.toColumnMap();
      final itemsResult = await connection.execute(
        Sql.named(
          "SELECT * FROM order_items WHERE order_id = @id ORDER BY id;",
        ),
        parameters: {"id": orderId},
      );

      final items = itemsResult.map((row) {
        final map = row.toColumnMap();
        return {
          "id": map["id"]?.toString() ?? "",
          "productId": map["product_id"]?.toString() ?? "",
          "name": map["name"] ?? "",
          "price": map["price"] ?? 0,
          "quantity": map["quantity"] ?? 0,
          "imageUrl": map["image_url"] ?? "",
          "supplierName": map["supplier_name"] ?? "",
          "isReceived": map["is_received"] ?? false,
        };
      }).toList();

      return Response.ok(
        jsonEncode({
          "id": orderId.toString(),
          "date": _toIso8601OrNow(updatedOrder["created_at"]),
          "status": updatedOrder["status"] ?? _cancelledOrderStatus,
          "deliveryAddress": updatedOrder["delivery_address"] ?? "",
          "items": items,
        }),
        headers: {"content-type": "application/json; charset=utf-8"},
      );
    } on FormatException {
      return Response.badRequest(body: "Неверный JSON");
    } catch (e, st) {
      print("Ошибка при отмене заказа: $e\n$st");
      return Response.internalServerError(body: "Ошибка сервера: $e");
    }
  });
}

void _registerBuyerReviewRoutes(Router router, Connection connection) {
  router.post("/reviews", (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);
      final userId = _toNullablePositiveInt(payload['userId']);
      final orderId = _toPositiveInt(payload['orderId']);
      final orderItemId = _toPositiveInt(payload['orderItemId']);
      final rating = _toPositiveInt(payload['rating']);
      final reviewText = payload['reviewText']?.toString().trim();
      final payloadProductId = _toNullablePositiveInt(payload['productId']);

      if (userId == null || orderId == 0 || orderItemId == 0) {
        return Response.badRequest(
          body: 'userId, orderId, orderItemId обязательны',
        );
      }
      if (rating < 1 || rating > 5) {
        return Response.badRequest(body: 'Оценка должна быть от 1 до 5');
      }

      final orderResult = await connection.execute(
        Sql.named('SELECT id, status, user_id FROM orders WHERE id = @id'),
        parameters: {'id': orderId},
      );
      if (orderResult.isEmpty) {
        return Response.notFound('Заказ не найден');
      }
      final order = orderResult.first.toColumnMap();
      if (!_isAcceptedOrderStatus(order['status'])) {
        return Response.badRequest(
          body: 'Отзыв можно оставить после принятия заказа',
        );
      }
      final orderUserId = order['user_id'];
      if (orderUserId != null && orderUserId != userId) {
        return Response.forbidden('Недостаточно прав');
      }

      final itemResult = await connection.execute(
        Sql.named(
          'SELECT id, order_id, product_id FROM order_items WHERE id = @id AND order_id = @order_id;',
        ),
        parameters: {'id': orderItemId, 'order_id': orderId},
      );
      if (itemResult.isEmpty) {
        return Response.notFound('Товар заказа не найден');
      }
      final item = itemResult.first.toColumnMap();
      final orderItemProductId = _toNullablePositiveInt(item['product_id']);
      if (orderItemProductId == null) {
        return Response.badRequest(
          body: 'У позиции заказа отсутствует productId',
        );
      }
      if (payloadProductId != null && payloadProductId != orderItemProductId) {
        return Response.badRequest(
          body: 'productId не соответствует товару в заказе',
        );
      }
      final resolvedProductId = orderItemProductId;

      final existingReview = await connection.execute(
        Sql.named(
          'SELECT id FROM reviews WHERE order_item_id = @order_item_id;',
        ),
        parameters: {'order_item_id': orderItemId},
      );
      if (existingReview.isNotEmpty) {
        return Response(409, body: 'Отзыв уже оставлен');
      }

      final created = await connection.execute(
        Sql.named('''
          INSERT INTO reviews (
            order_id,
            order_item_id,
            product_id,
            user_id,
            rating,
            review_text
          )
          VALUES (
            @order_id,
            @order_item_id,
            @product_id,
            @user_id,
            @rating,
            @review_text
          )
          RETURNING id;
          '''),
        parameters: {
          'order_id': orderId,
          'order_item_id': orderItemId,
          'product_id': resolvedProductId,
          'user_id': userId,
          'rating': rating,
          'review_text': reviewText,
        },
      );

      final reviewId = created.first.toColumnMap()['id'] as int;

      await _recalculateProductRating(connection, resolvedProductId);

      final reviewResult = await connection.execute(
        Sql.named('''
          SELECT r.*,
                 COALESCE(p.name, oi.name) AS product_name,
                 COALESCE(p.image_url, oi.image_url) AS product_image,
                 oi.name AS order_item_name,
                 oi.image_url AS order_item_image,
                 u.avatar_url AS user_avatar_url
          FROM reviews r
          LEFT JOIN order_items oi ON oi.id = r.order_item_id
          LEFT JOIN products p ON p.id = r.product_id
          LEFT JOIN users u ON u.id = r.user_id
          WHERE r.id = @id;
          '''),
        parameters: {'id': reviewId},
      );

      final dto = _reviewRowToDto(reviewResult.first.toColumnMap(), request);
      return Response(
        201,
        body: jsonEncode(dto),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при создании отзыва: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.patch('/reviews/<id>', (Request request, String id) async {
    try {
      final reviewId = int.tryParse(id);
      if (reviewId == null) {
        return Response.badRequest(body: 'Неверный id отзыва');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);
      final userId = _toNullablePositiveInt(payload['userId']);
      final rating = _toPositiveInt(payload['rating']);
      final reviewText = payload['reviewText']?.toString().trim();

      if (userId == null) {
        return Response.badRequest(
          body: 'Идентификатор пользователя обязателен',
        );
      }
      if (rating < 1 || rating > 5) {
        return Response.badRequest(body: 'Оценка должна быть от 1 до 5');
      }

      final existing = await connection.execute(
        Sql.named('SELECT * FROM reviews WHERE id = @id;'),
        parameters: {'id': reviewId},
      );
      if (existing.isEmpty) {
        return Response.notFound('Отзыв не найден');
      }

      final review = existing.first.toColumnMap();
      final reviewUserId = review['user_id'];
      if (reviewUserId != null && reviewUserId != userId) {
        return Response.forbidden('Недостаточно прав');
      }

      await connection.execute(
        Sql.named('''
          UPDATE reviews
          SET rating = @rating,
              review_text = @review_text,
              updated_at = NOW()
          WHERE id = @id;
          '''),
        parameters: {
          'id': reviewId,
          'rating': rating,
          'review_text': reviewText,
        },
      );

      final productId = review['product_id'];
      if (productId != null) {
        await _recalculateProductRating(connection, productId as int);
      }

      final reviewResult = await connection.execute(
        Sql.named('''
          SELECT r.*,
                 COALESCE(p.name, oi.name) AS product_name,
                 COALESCE(p.image_url, oi.image_url) AS product_image,
                 oi.name AS order_item_name,
                 oi.image_url AS order_item_image,
                 u.avatar_url AS user_avatar_url
          FROM reviews r
          LEFT JOIN order_items oi ON oi.id = r.order_item_id
          LEFT JOIN products p ON p.id = r.product_id
          LEFT JOIN users u ON u.id = r.user_id
          WHERE r.id = @id;
          '''),
        parameters: {'id': reviewId},
      );

      final dto = _reviewRowToDto(reviewResult.first.toColumnMap(), request);
      return Response.ok(
        jsonEncode(dto),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при обновлении отзыва: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.delete('/reviews/<id>', (Request request, String id) async {
    try {
      final reviewId = int.tryParse(id);
      if (reviewId == null) {
        return Response.badRequest(body: 'Неверный id отзыва');
      }

      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null) {
        return Response.badRequest(
          body: 'Идентификатор пользователя обязателен',
        );
      }

      final existing = await connection.execute(
        Sql.named('SELECT * FROM reviews WHERE id = @id;'),
        parameters: {'id': reviewId},
      );
      if (existing.isEmpty) {
        return Response.notFound('Отзыв не найден');
      }

      final review = existing.first.toColumnMap();
      final reviewUserId = review['user_id'];
      if (reviewUserId != null && reviewUserId != userId) {
        return Response.forbidden('Недостаточно прав');
      }

      await connection.execute(
        Sql.named('DELETE FROM reviews WHERE id = @id;'),
        parameters: {'id': reviewId},
      );

      final productId = review['product_id'];
      if (productId != null) {
        await _recalculateProductRating(connection, productId as int);
      }

      return Response.ok(
        jsonEncode({'deleted': true}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при удалении отзыва: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });
}

void _registerBuyerExportRoute(Router router, Connection connection) {
  router.post('/export/orders/excel', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return _jsonError('Ожидается JSON объект', 400);
      }
      final payload = Map<String, dynamic>.from(decoded);

      final userId = _toPositiveInt(payload['userId']);
      final startDateRaw = payload['startDate'];
      final endDateRaw = payload['endDate'];

      if (userId == 0) {
        return _jsonError('userId обязателен', 400);
      }
      if (startDateRaw == null || endDateRaw == null) {
        return _jsonError('startDate и endDate обязательны', 400);
      }

      final startDateRawDt = _toNullableDateTime(startDateRaw);
      final endDateRawDt = _toNullableDateTime(endDateRaw);

      if (startDateRawDt == null || endDateRawDt == null) {
        return _jsonError('Неверный формат дат', 400);
      }

      final startDate = startDateRawDt;
      final endDate = endDateRawDt;

      if (startDate.isAfter(endDate)) {
        return _jsonError('startDate не может быть позже endDate', 400);
      }

      // Расширяем диапазон: start к 00:00:00, end к 23:59:59 - иначе
      // заказы за endDate в течение дня выпадут из выборки.
      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );
      final endDateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      // Берём только финально закрытые заказы покупателя - статус "Принят".
      // Поставщик строки берём из order_items: либо supplier_user_id (новые
      // позиции), либо fallback на supplier_name (исторические данные без id).
      final result = await connection.execute(
        Sql.named('''
          SELECT
            o.id as order_id,
            o.created_at as order_date,
            o.status as order_status,
            oi.name as service_name,
            oi.price as price,
            oi.quantity as quantity,
            COALESCE(NULLIF(su.name, ''), NULLIF(su.supplier_name, ''), oi.supplier_name, '') as supplier_name
          FROM orders o
          JOIN order_items oi ON o.id = oi.order_id
          LEFT JOIN users su ON su.id = oi.supplier_user_id
          WHERE o.user_id = @user_id
            AND o.created_at >= @start_date
            AND o.created_at <= @end_date
            AND LOWER(TRIM(o.status)) IN (
              'принят', 'принята', 'принято', 'приняты', 'accepted', 'received'
            )
          ORDER BY o.id, oi.id
        '''),
        parameters: {
          'user_id': userId,
          'start_date': startDateTime.toIso8601String(),
          'end_date': endDateTime.toIso8601String(),
        },
      );

      final excel = Excel.createExcel();
      final sheet = excel['Orders'];

      const headers = <String>[
        'ID заказа',
        'Поставщик',
        'Товар',
        'Количество',
        'Цена',
        'Сумма',
        'Дата',
        'Статус',
      ];
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontFamily: getFontFamily(FontFamily.Calibri),
        );
      }

      for (var i = 0; i < result.length; i++) {
        final row = result[i].toColumnMap();
        final orderId = row['order_id'].toString();
        final supplierName = row['supplier_name'] ?? '';
        final serviceName = row['service_name'] ?? '';
        final price = _toPositiveInt(row['price']);
        final quantity = _toPositiveInt(row['quantity'], fallback: 1);
        final total = price * quantity;
        final orderDate = row['order_date'];
        final orderStatus = row['order_status'] ?? '';

        String formattedDate = '';
        if (orderDate is DateTime) {
          formattedDate =
              '${orderDate.day.toString().padLeft(2, '0')}.${orderDate.month.toString().padLeft(2, '0')}.${orderDate.year}';
        }

        final rowIndex = i + 1;
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          orderId,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          supplierName.toString(),
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          serviceName.toString(),
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = IntCellValue(
          quantity,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = IntCellValue(
          price,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .value = IntCellValue(
          total,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          formattedDate,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          orderStatus.toString(),
        );
      }

      for (var col = 0; col < headers.length; col++) {
        sheet.setColumnAutoFit(col);
      }

      final bytes = excel.encode();

      return Response(
        200,
        body: bytes,
        headers: {
          'content-type':
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'content-disposition': 'attachment; filename="orders_export.xlsx"',
        },
      );
    } catch (e, st) {
      print('Ошибка экспорта заказов: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });
}

void _registerBuyerQuestionRoute(Router router, Connection connection) {
  router.post('/products/<productId>/questions', (
    Request request,
    String productId,
  ) async {
    try {
      final pid = int.tryParse(productId);
      if (pid == null) return Response.badRequest(body: 'Invalid product id');

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) return Response.badRequest(body: 'Expected JSON');
      final payload = Map<String, dynamic>.from(decoded);

      final userId = _toPositiveInt(payload['userId']);
      final questionText = payload['questionText']?.toString().trim() ?? '';
      if (questionText.length < 10 || questionText.length > 500) {
        return Response.badRequest(
          body: 'Question text must be 10-500 characters',
        );
      }

      // Проверка существования товара
      final prodCheck = await connection.execute(
        Sql.named('SELECT id FROM products WHERE id = @id'),
        parameters: {'id': pid},
      );
      if (prodCheck.isEmpty) return Response(404, body: 'Product not found');

      // Ограничение частоты: не более 5 вопросов от пользователя за последний час на товар
      final recentCheck = await connection.execute(
        Sql.named('''SELECT COUNT(*) as cnt FROM questions
          WHERE user_id = @uid AND product_id = @pid AND created_at > NOW() - INTERVAL '1 hour'
        '''),
        parameters: {'uid': userId, 'pid': pid},
      );
      final recentCount = _toPositiveInt(
        recentCheck.first.toColumnMap()['cnt'],
      );
      if (recentCount >= 5) {
        return Response(
          429,
          body: 'Too many questions. Please wait.',
          headers: _utf8TextHeaders,
        );
      }

      final inserted = await connection.execute(
        Sql.named('''INSERT INTO questions (product_id, user_id, question_text)
          VALUES (@pid, @uid, @text) RETURNING id, created_at'''),
        parameters: {'pid': pid, 'uid': userId, 'text': questionText},
      );
      final map = inserted.first.toColumnMap();
      final id = map['id'].toString();
      final createdAt = (map['created_at'] as DateTime).toIso8601String();

      return Response(
        201,
        body: jsonEncode({'questionId': id, 'createdAt': createdAt}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Invalid JSON');
    } catch (e, st) {
      print('Error creating question: $e\n$st');
      return Response.internalServerError(body: 'Server error');
    }
  });
}

// Публичные GET-роуты: ping, пользователи, адреса.

void _registerPublicUserRoutes(Router router, Connection connection) {
  router.get('/', (Request request) {
    return Response.ok(
      'Сервер запущен и работает.',
      headers: {'content-type': 'text/plain; charset=utf-8'},
    );
  });

  router.get('/users', (Request request) async {
    final result = await connection.execute('SELECT * FROM users;');
    final users = result.map((row) => row.toColumnMap()).toList();

    return Response.ok(
      jsonEncode(users),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  router.get('/users/<id>', (Request request, String id) async {
    final userId = int.tryParse(id);
    if (userId == null) {
      return Response.badRequest(
        body: 'Идентификатор пользователя указан некорректно',
      );
    }

    // Если столбца avatar_url ещё нет в БД (миграция не накатилась) -
    // SELECT упадёт. Тогда читаем без avatar_url и возвращаем avatarUrl: null,
    // чтобы остальные поля профиля всё равно ушли клиенту.
    Map<String, dynamic>? user;
    Object? rawAvatarUrl;
    try {
      final result = await connection.execute(
        Sql.named(
          'SELECT id, name, email, role, supplier_name, phone, avatar_url '
          'FROM users WHERE id = @id',
        ),
        parameters: {'id': userId},
      );
      if (result.isEmpty) {
        return Response.notFound('Ресурс не найден');
      }
      user = result.first.toColumnMap();
      rawAvatarUrl = user['avatar_url'];
    } catch (_) {
      final result = await connection.execute(
        Sql.named(
          'SELECT id, name, email, role, supplier_name, phone FROM users WHERE id = @id',
        ),
        parameters: {'id': userId},
      );
      if (result.isEmpty) {
        return Response.notFound('Ресурс не найден');
      }
      user = result.first.toColumnMap();
      rawAvatarUrl = null;
    }

    final role = user['role'] ?? _defaultRole;
    return Response.ok(
      jsonEncode({
        'id': user['id'],
        'name': user['name'] ?? '',
        'email': user['email'] ?? '',
        'role': role,
        'supplierName': _supplierNameForRole(role, user['supplier_name']),
        'phone': user['phone'] ?? '',
        'avatarUrl': _avatarUrlOrNull(request, rawAvatarUrl),
      }),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  router.get('/users/<id>/addresses', (Request request, String id) async {
    final userId = int.tryParse(id);
    if (userId == null) {
      return Response.badRequest(
        body: 'Идентификатор пользователя указан некорректно',
      );
    }

    final userResult = await connection.execute(
      Sql.named('SELECT id FROM users WHERE id = @id'),
      parameters: {'id': userId},
    );
    if (userResult.isEmpty) {
      return Response.notFound('Ресурс не найден');
    }

    final result = await connection.execute(
      Sql.named(
        'SELECT * FROM addresses WHERE user_id = @user_id ORDER BY id DESC;',
      ),
      parameters: {'user_id': userId},
    );

    final addresses = result
        .map((row) => _addressRowToDto(row.toColumnMap()))
        .toList();

    return Response.ok(
      jsonEncode(addresses),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

// GET-роуты каталога: категории и tree, товары для покупателя.

void _registerCatalogRoutes(Router router, Connection connection) {
  router.get('/categories', (Request request) async {
    try {
      final includeInactive =
          request.url.queryParameters['includeInactive'] == 'true';
      final result = includeInactive
          ? await connection.execute('''
              SELECT
                id,
                name,
                parent_id,
                subtitle,
                image_path,
                keywords,
                sort_order,
                is_active
              FROM public.categories
              ORDER BY parent_id NULLS FIRST, sort_order ASC, id ASC;
            ''')
          : await connection.execute('''
              SELECT
                id,
                name,
                parent_id,
                subtitle,
                image_path,
                keywords,
                sort_order,
                is_active
              FROM public.categories
              WHERE is_active = true
              ORDER BY parent_id NULLS FIRST, sort_order ASC, id ASC;
            ''');

      final entries = result
          .map((row) => _categoryRowToDto(row.toColumnMap()))
          .toList();

      return Response.ok(
        jsonEncode(entries),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/categories/tree', (Request request) async {
    try {
      final includeInactive =
          request.url.queryParameters['includeInactive'] == 'true';
      final result = includeInactive
          ? await connection.execute('''
              SELECT
                id,
                name,
                parent_id,
                subtitle,
                image_path,
                keywords,
                sort_order,
                is_active
              FROM public.categories
              ORDER BY sort_order ASC, id ASC;
            ''')
          : await connection.execute('''
              SELECT
                id,
                name,
                parent_id,
                subtitle,
                image_path,
                keywords,
                sort_order,
                is_active
              FROM public.categories
              WHERE is_active = true
              ORDER BY sort_order ASC, id ASC;
            ''');

      final rows = result.map((row) => row.toColumnMap()).toList();
      final byParent = <int?, List<Map<String, dynamic>>>{};

      for (final row in rows) {
        final parentId = _toNullablePositiveInt(row['parent_id']);
        byParent.putIfAbsent(parentId, () => <Map<String, dynamic>>[]).add(row);
      }

      int bySortThenId(Map<String, dynamic> a, Map<String, dynamic> b) {
        final sortCompare = _toPositiveInt(
          a['sort_order'],
        ).compareTo(_toPositiveInt(b['sort_order']));
        if (sortCompare != 0) {
          return sortCompare;
        }
        return _toPositiveInt(a['id']).compareTo(_toPositiveInt(b['id']));
      }

      final rootRows = (byParent[null] ?? <Map<String, dynamic>>[])
        ..sort(bySortThenId);
      final tree = <Map<String, dynamic>>[];

      for (final root in rootRows) {
        final rootId = _toPositiveInt(root['id']);
        if (rootId <= 0) {
          continue;
        }
        final children = (byParent[rootId] ?? <Map<String, dynamic>>[])
          ..sort(bySortThenId);
        final leafRows = children.isEmpty
            ? <Map<String, dynamic>>[root]
            : children;

        final imagePath =
            _normalizeOptionalText(root['image_path']) ??
            (_normalizeOptionalText(leafRows.first['image_path']) ?? '');
        final subtitle =
            _normalizeOptionalText(root['subtitle']) ??
            (root['name']?.toString() ?? '');

        tree.add({
          'id': rootId,
          'name': (root['name'] ?? '').toString(),
          'subtitle': subtitle,
          'imagePath': imagePath,
          'sortOrder': _toPositiveInt(root['sort_order']),
          'isActive': root['is_active'] == true,
          'subcategories': leafRows.map((child) {
            final childName = (child['name'] ?? '').toString();
            final parsedKeywords = _parseCategoryKeywords(child['keywords']);
            return {
              'id': _toPositiveInt(child['id']),
              'name': childName,
              'imagePath': _normalizeOptionalText(child['image_path']) ?? '',
              'keywords': parsedKeywords.isEmpty
                  ? <String>[childName]
                  : parsedKeywords,
              'sortOrder': _toPositiveInt(child['sort_order']),
              'isActive': child['is_active'] == true,
            };
          }).toList(),
        });
      }

      return Response.ok(
        jsonEncode(tree),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/products', (Request request) async {
    try {
      final result = await connection.execute('''
        SELECT p.*,
               u.avatar_url AS supplier_avatar_url,
               EXISTS(
                 SELECT 1
                 FROM order_items oi
                 WHERE oi.product_id = p.id
               ) AS has_orders
        FROM products p
        LEFT JOIN users u ON u.id = p.supplier_user_id
        WHERE p.moderation_status = 'approved' OR p.moderation_status IS NULL;
      ''');
      final rows = result.map((row) => row.toColumnMap()).toList();
      if (rows.isEmpty) {
        return Response.ok(
          jsonEncode(const <Map<String, dynamic>>[]),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final productIds = rows
          .map((row) => _toPositiveInt(row['id']))
          .where((id) => id > 0)
          .toList();

      final distributionByProduct = <int, Map<int, int>>{};
      if (productIds.isNotEmpty) {
        final distributionRows = await connection.execute(
          Sql.named('''
            SELECT product_id, rating, COUNT(*) AS count
            FROM reviews
            WHERE product_id = ANY(@ids)
            GROUP BY product_id, rating;
          '''),
          parameters: {'ids': productIds},
        );

        for (final row in distributionRows) {
          final map = row.toColumnMap();
          final productId = _toPositiveInt(map['product_id']);
          final rating = _toPositiveInt(map['rating']);
          final count = _toPositiveInt(map['count']);
          if (productId <= 0 || rating <= 0 || rating > 5) {
            continue;
          }
          final bucket = distributionByProduct.putIfAbsent(
            productId,
            () => <int, int>{},
          );
          bucket[rating] = count;
        }
      }

      // Считаем количество вопросов одним запросом - чтобы вкладка
      // «Вопросы (N)» на детальной странице не моргала нулём, пока
      // подгружается список.
      final questionCountByProduct = <int, int>{};
      if (productIds.isNotEmpty) {
        final questionRows = await connection.execute(
          Sql.named('''
            SELECT product_id, COUNT(*) AS count
            FROM questions
            WHERE product_id = ANY(@ids)
            GROUP BY product_id;
          '''),
          parameters: {'ids': productIds},
        );

        for (final row in questionRows) {
          final map = row.toColumnMap();
          final productId = _toPositiveInt(map['product_id']);
          final count = _toPositiveInt(map['count']);
          if (productId <= 0) continue;
          questionCountByProduct[productId] = count;
        }
      }

      final products = rows.map((map) {
        final productId = _toPositiveInt(map['id']);
        final name = (map['name'] ?? '').toString();
        final description = (map['description'] ?? '').toString();
        final categories = _parseCategories(map['category']);
        final parsedImages = _parseImageUrls(map['image_url']);
        final imageUrls = parsedImages.isNotEmpty
            ? parsedImages
            : ['assets/coca_cola.jpeg'];

        final distribution = distributionByProduct[productId] ?? <int, int>{};
        final reviewCount = distribution.values.fold<int>(
          0,
          (sum, value) => sum + value,
        );
        final rating = reviewCount > 0
            ? distribution.entries.fold<double>(
                    0,
                    (sum, entry) => sum + (entry.key * entry.value),
                  ) /
                  reviewCount
            : 0.0;

        final characteristics = _parseCharacteristics(map['characteristics']);
        final hasOrders = map['has_orders'] == true;
        final rawStockQuantity = _toPositiveInt(map['stock_quantity']);
        final legacyMaxQuantity = _toPositiveInt(map['max_quantity']);
        final stockQuantity = rawStockQuantity > 0
            ? rawStockQuantity
            : (!hasOrders ? legacyMaxQuantity : 0);
        var minQuantity = _toPositiveInt(map['min_quantity'], fallback: 1);
        if (stockQuantity > 0 && minQuantity > stockQuantity) {
          minQuantity = stockQuantity;
        }

        final supplierUserId = _toPositiveInt(map['supplier_user_id']);
        final supplierId = supplierUserId > 0
            ? supplierUserId.toString()
            : 'product_$productId';

        return {
          'id': productId.toString(),
          'name': name,
          'description': description,
          'imageUrls': imageUrls,
          'rating': rating,
          'reviewCount': reviewCount,
          'questionCount': questionCountByProduct[productId] ?? 0,
          'categories': categories,
          'nutritionalInfo': {
            'calories': _toNonNegativeDouble(map['nutrition_calories']),
            'protein': _toNonNegativeDouble(map['nutrition_protein']),
            'fat': _toNonNegativeDouble(map['nutrition_fat']),
            'carbohydrates': _toNonNegativeDouble(
              map['nutrition_carbohydrates'],
            ),
          },
          'ingredients': map['ingredients']?.toString() ?? '',
          'characteristics': characteristics,
          'suppliers': [
            {
              'id': supplierId,
              'name': map['supplier_name'] ?? 'Поставщик',
              'rating': rating,
              'reviewCount': reviewCount,
              'pricePerUnit': _toPositiveInt(map['price_per_unit']),
              'minQuantity': minQuantity,
              'maxQuantity': stockQuantity > 0 ? stockQuantity : null,
              'stockQuantity': stockQuantity,
              'deliveryDate': map['delivery_date'] ?? '',
              'deliveryInfo': 'Доставка по согласованию',
              'deliveryBadge': map['delivery_badge'] ?? '',
              'avatarUrl': _avatarUrlOrNull(request, map['supplier_avatar_url']),
            },
          ],
          'similarProducts': const <Map<String, dynamic>>[],
          'ratingDistribution': List.generate(5, (index) {
            final stars = 5 - index;
            return {'stars': stars, 'count': distribution[stars] ?? 0};
          }),
        };
      }).toList();

      return Response.ok(
        jsonEncode(products),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });
}

// GET-роуты заказов и отзывов покупателя.

void _registerBuyerReadRoutes(Router router, Connection connection) {
  router.get('/orders', (Request request) async {
    final params = request.url.queryParameters;
    final userIdRaw = params['userId'];
    final startDateStr = params['startDate'];
    final endDateStr = params['endDate'];

    final userId = _toPositiveInt(userIdRaw);
    if (userId == 0) {
      return Response.badRequest(body: 'userId must be a positive integer');
    }

    String query = '''
      SELECT
        o.id,
        o.created_at,
        o.status,
        o.delivery_address,
        o.user_id,
        COALESCE(
          json_agg(
            json_build_object(
              'id', oi.id,
              'order_id', oi.order_id,
              'name', oi.name,
              'price', oi.price,
              'quantity', oi.quantity,
              'image_url', oi.image_url,
              'supplier_name', oi.supplier_name,
              'is_received', oi.is_received
            )
          ) FILTER (WHERE oi.id IS NOT NULL),
          '[]'::json
        ) as items
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.user_id = @user_id::int
    ''';
    final Map<String, dynamic> parameters = <String, dynamic>{
      'user_id': userId,
    };

    if (startDateStr != null && endDateStr != null) {
      // Расширяем диапазон: start к 00:00:00, end к 23:59:59 - иначе
      // заказы за endDate в течение дня выпадут из выборки.
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);
      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );
      final endDateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      query += '''
        AND o.created_at >= @start_date::timestamp
        AND o.created_at <= @end_date::timestamp
      ''';
      parameters['start_date'] = startDateTime.toIso8601String();
      parameters['end_date'] = endDateTime.toIso8601String();
    }

    query += '''
      GROUP BY o.id, o.created_at, o.status, o.delivery_address, o.user_id
      ORDER BY o.created_at DESC
    ''';

    final result = await connection.execute(
      Sql.named(query),
      parameters: parameters,
    );

    final orders = result.map((row) {
      final map = row.toColumnMap();

      final items = (map['items'] as List<dynamic>? ?? []).map((item) {
        final m = Map<String, dynamic>.from(item);

        // image_url → всегда строка или null
        m['image_url'] = m['image_url']?.toString();

        // is_received приходит из json_build_object строкой - приводим к bool
        m['is_received'] = m['is_received'] == true;

        return m;
      }).toList();

      map['items'] = items;

      // jsonEncode не умеет сериализовать DateTime - конвертируем в ISO
      if (map['created_at'] is DateTime) {
        map['created_at'] = (map['created_at'] as DateTime).toIso8601String();
      }

      return map;
    }).toList();

    return Response.ok(
      jsonEncode(orders),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  router.get('/reviews', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final productIdRaw = request.url.queryParameters['productId'];
      final userId = int.tryParse(userIdRaw ?? '');
      final productId = int.tryParse(productIdRaw ?? '');

      if (userIdRaw != null && userId == null) {
        return Response.badRequest(
          body: 'Идентификатор пользователя указан некорректно',
        );
      }
      if (productIdRaw != null && productId == null) {
        return Response.badRequest(body: 'Некорректный запрос');
      }

      final List<String> filters = <String>[];
      final Map<String, dynamic> parameters = <String, dynamic>{};
      if (userId != null) {
        filters.add('r.user_id = @user_id');
        parameters['user_id'] = userId;
      }
      if (productId != null) {
        filters.add('r.product_id = @product_id');
        parameters['product_id'] = productId;
      }

      final whereClause = filters.isEmpty
          ? ''
          : 'WHERE ${filters.join(' AND ')}';
      final result = await connection.execute(
        Sql.named('''
          SELECT r.*,
                 COALESCE(p.name, oi.name) AS product_name,
                 COALESCE(p.image_url, oi.image_url) AS product_image,
                 oi.name AS order_item_name,
                 oi.image_url AS order_item_image,
                 oi.supplier_name,
                 u.name AS reviewer_name,
                 u.avatar_url AS user_avatar_url,
                 srr.id AS response_id,
                 srr.response_text,
                 srr.created_at AS response_created_at,
                 supplier_user.id AS response_supplier_id,
                 supplier_user.supplier_name AS response_supplier_name
          FROM reviews r
          LEFT JOIN order_items oi ON oi.id = r.order_item_id
          LEFT JOIN products p ON p.id = r.product_id
          LEFT JOIN users u ON u.id = r.user_id
          LEFT JOIN supplier_review_responses srr ON srr.review_id = r.id
          LEFT JOIN users supplier_user ON oi.supplier_user_id = supplier_user.id
          $whereClause
          ORDER BY r.created_at DESC;
        '''),
        parameters: parameters,
      );

      final reviews = result
          .map((row) => _reviewRowToDto(row.toColumnMap(), request))
          .toList();

      return Response.ok(
        jsonEncode(reviews),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/reviews/<reviewId>/response', (
    Request request,
    String reviewId,
  ) async {
    try {
      final reviewIdInt = int.tryParse(reviewId);
      if (reviewIdInt == null || reviewIdInt <= 0) {
        return Response.badRequest(body: 'Invalid review ID');
      }

      final result = await connection.execute(
        Sql.named('''
          SELECT
            srr.id,
            srr.review_id,
            srr.response_text,
            srr.created_at,
            srr.updated_at,
            u.supplier_name
          FROM supplier_review_responses srr
          JOIN reviews r ON srr.review_id = r.id
          JOIN order_items oi ON r.order_item_id = oi.id
          JOIN users u ON oi.supplier_user_id = u.id
          WHERE srr.review_id = @review_id
          LIMIT 1;
        '''),
        parameters: {'review_id': reviewIdInt},
      );

      if (result.isEmpty) {
        return Response.ok(
          jsonEncode(null),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final responseMap = result.first.toColumnMap();
      return Response.ok(
        jsonEncode({
          'id': responseMap['id'].toString(),
          'reviewId': responseMap['review_id'].toString(),
          'responseText': responseMap['response_text'] ?? '',
          'supplierName': responseMap['supplier_name'] ?? '',
          'createdAt': (responseMap['created_at'] as DateTime)
              .toIso8601String(),
          'updatedAt': (responseMap['updated_at'] as DateTime)
              .toIso8601String(),
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при получении ответа на отзыв: $e\n$st');
      return Response.internalServerError(body: 'Server error');
    }
  });

  router.get('/reviews/pending', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null) {
        return Response.badRequest(
          body: 'Идентификатор пользователя указан некорректно',
        );
      }

      final result = await connection.execute(
        Sql.named('''
          SELECT oi.id AS order_item_id,
                 o.id AS order_id,
                 o.created_at AS order_date,
                 oi.product_id,
                 oi.name AS order_item_name,
                 oi.image_url AS order_item_image,
                 oi.price,
                 oi.quantity,
                 oi.supplier_name,
                 COALESCE(p.name, oi.name) AS product_name,
                 COALESCE(p.image_url, oi.image_url) AS product_image
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          LEFT JOIN reviews r ON r.order_item_id = oi.id
          LEFT JOIN products p ON p.id = oi.product_id
          WHERE r.id IS NULL
            AND lower(o.status) = ANY(@accepted_statuses)
            AND o.user_id = @user_id
          ORDER BY o.created_at DESC, oi.id DESC;
          '''),
        parameters: {
          'accepted_statuses': _acceptedOrderStatuses.toList(),
          'user_id': userId,
        },
      );

      final items = result.map((row) {
        final map = row.toColumnMap();
        final orderDate = map['order_date'];
        return {
          'orderId': map['order_id']?.toString() ?? '',
          'orderItemId': map['order_item_id']?.toString() ?? '',
          'productId': map['product_id']?.toString() ?? '',
          'productName': map['product_name'] ?? map['order_item_name'] ?? '',
          'productImage': map['product_image'] ?? map['order_item_image'] ?? '',
          'quantity': map['quantity'] ?? 0,
          'price': map['price'] ?? 0,
          'supplierName': map['supplier_name'] ?? '',
          if (orderDate is DateTime) 'orderDate': orderDate.toIso8601String(),
        };
      }).toList();

      return Response.ok(
        jsonEncode(items),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/products/<productId>/questions', (
    Request request,
    String productId,
  ) async {
    final pid = int.tryParse(productId);
    if (pid == null) return Response.badRequest(body: 'Invalid product id');

    final page = int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '20') ?? 20;
    final offset = (page - 1) * limit;

    try {
      final result = await connection.execute(
        Sql.named('''
          SELECT
            q.id, q.product_id, q.user_id, q.question_text, q.created_at, q.is_answered,
            u.name as user_name, u.email as user_email, u.avatar_url as user_avatar_url,
            qa.id as answer_id, qa.answer_text, qa.answered_at,
            us.supplier_name as supplier_name, us.id as supplier_id
          FROM questions q
          JOIN users u ON q.user_id = u.id
          LEFT JOIN question_answers qa ON q.id = qa.question_id
          LEFT JOIN users us ON qa.supplier_user_id = us.id
          WHERE q.product_id = @product_id
          ORDER BY q.created_at DESC
          LIMIT @limit OFFSET @offset
        '''),
        parameters: {'product_id': pid, 'limit': limit, 'offset': offset},
      );

      final countResult = await connection.execute(
        Sql.named('SELECT COUNT(*) FROM questions WHERE product_id = @pid'),
        parameters: {'pid': pid},
      );
      final total = _toPositiveInt(countResult.first.toColumnMap()['count']);

      final questions = result.map((row) {
        final map = row.toColumnMap();
        final createdAt = map['created_at'];
        String? createdAtIso = (createdAt is DateTime)
            ? createdAt.toIso8601String()
            : null;
        final answeredAt = map['answered_at'];
        String? answeredAtIso = (answeredAt is DateTime)
            ? answeredAt.toIso8601String()
            : null;

        final answerDto = map['answer_id'] != null
            ? {
                'id': map['answer_id'].toString(),
                'questionId': map['id'].toString(),
                'supplierId': map['supplier_id']?.toString(),
                'supplierName': map['supplier_name'] ?? '',
                'answerText': map['answer_text'] ?? '',
                'answeredAt': answeredAtIso,
              }
            : null;

        return {
          'id': map['id'].toString(),
          'productId': map['product_id'].toString(),
          'userId': map['user_id'].toString(),
          'userName': map['user_name'] ?? 'Пользователь',
          'userAvatarUrl': _avatarUrlOrNull(request, map['user_avatar_url']),
          'questionText': map['question_text'] ?? '',
          'createdAt': createdAtIso,
          'isAnswered': map['is_answered'] == true,
          'answer': answerDto,
        };
      }).toList();

      return Response.ok(
        jsonEncode({
          'questions': questions,
          'total': total,
          'page': page,
          'limit': limit,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error fetching questions: $e\n$st');
      return Response.internalServerError(body: 'Server error');
    }
  });

  router.post('/products/<productId>/questions', (
    Request request,
    String productId,
  ) async {
    try {
      final pid = int.tryParse(productId);
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      final userId = data['userId'];
      final text = data['questionText']?.toString().trim();

      if (pid == null || userId == null || text == null || text.isEmpty) {
        return Response.badRequest(
          body: 'Missing required fields',
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      await connection.execute(
        Sql.named(
          'INSERT INTO questions (product_id, user_id, question_text) VALUES (@pid, @uid, @text)',
        ),
        parameters: {'pid': pid, 'uid': userId, 'text': text},
      );

      return Response.ok(
        jsonEncode({'message': 'Question added successfully'}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, stack) {
      print('Error posting question: $e\n$stack');
      return Response.internalServerError(
        body: 'Failed to add question',
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
  });
}

/// Регистрация роута для получения курсов валют.
void _registerExchangeRatesRoutes(Router router, Connection connection) {
  router.get('/exchange-rates', (Request request) async {
    try {
      final result = await connection.execute(
        'SELECT currency_code, rate FROM public.exchange_rates;'
      );
      
      final rates = <String, double>{
        'KZT': 1.0, // Базовая валюта приложения
      };

      for (final row in result) {
        final map = row.toColumnMap();
        final code = map['currency_code']?.toString() ?? '';
        final rateVal = double.tryParse(map['rate']?.toString() ?? '') ?? 0.0;
        if (code.isNotEmpty && rateVal > 0) {
          rates[code] = rateVal;
        }
      }

      return Response.ok(
        jsonEncode(rates),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при обработке запроса курсов валют: $e\n$st');
      return Response.internalServerError(
        body: 'Внутренняя ошибка сервера при получении курсов валют',
        headers: {'content-type': 'text/plain; charset=utf-8'},
      );
    }
  });
}
