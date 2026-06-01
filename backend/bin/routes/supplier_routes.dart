part of '../backend.dart';

// Роуты для роли supplier (поставщик):
// управление товарами, обновление статусов заказов, ответы на вопросы и отзывы,
// экспорт заказов поставщика.

void _registerSupplierProductRoutes(Router router, Connection connection) {
  router.post('/supplier/products', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);
      final userId = _toPositiveInt(payload['userId']);
      if (userId == 0) {
        return Response.badRequest(
          body: 'Идентификатор пользователя обязателен',
        );
      }

      final userResult = await connection.execute(
        Sql.named('SELECT id, role, supplier_name FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound('Пользователь не найден');
      }
      final user = userResult.first.toColumnMap();
      if ((user['role'] ?? _defaultRole) != 'supplier') {
        return Response.forbidden('Доступ только для поставщика');
      }

      final name = payload['name']?.toString().trim() ?? '';
      if (name.isEmpty) {
        return Response.badRequest(body: 'Название товара обязательно');
      }

      final description = payload['description']?.toString() ?? '';
      final categories = await _resolvePayloadCategories(
        connection,
        payload['category'],
      );
      if (categories.isEmpty) {
        return Response.badRequest(
          body: 'Выберите категорию из каталога',
          headers: _utf8TextHeaders,
        );
      }
      final category = categories.join(', ');
      final pricePerUnit = _toPositiveInt(payload['pricePerUnit']);
      final minQuantity = _toPositiveInt(payload['minQuantity'], fallback: 1);
      final maxQuantity = _toNullablePositiveInt(payload['maxQuantity']);
      final deliveryDate = payload['deliveryDate']?.toString();
      final deliveryBadge = payload['deliveryBadge']?.toString();
      final stockQuantity = _toPositiveInt(
        payload['stockQuantity'] ?? payload['stock_quantity'] ?? maxQuantity,
      );
      final ingredients = payload['ingredients']?.toString() ?? '';
      final nutritionalInfo = payload['nutritionalInfo'];
      final nutritionMap = nutritionalInfo is Map
          ? Map<String, dynamic>.from(nutritionalInfo)
          : <String, dynamic>{};
      final nutritionCalories = _toNonNegativeDouble(
        nutritionMap['calories'] ?? payload['calories'],
      );
      final nutritionProtein = _toNonNegativeDouble(
        nutritionMap['protein'] ?? payload['protein'],
      );
      final nutritionFat = _toNonNegativeDouble(
        nutritionMap['fat'] ?? payload['fat'],
      );
      final nutritionCarbohydrates = _toNonNegativeDouble(
        nutritionMap['carbohydrates'] ?? payload['carbohydrates'],
      );
      final productValidationError = _validateSupplierProductPayload(
        pricePerUnit: pricePerUnit,
        minQuantity: minQuantity,
        maxQuantity: maxQuantity,
        stockQuantity: stockQuantity,
        nutritionCalories: nutritionCalories,
        nutritionProtein: nutritionProtein,
        nutritionFat: nutritionFat,
        nutritionCarbohydrates: nutritionCarbohydrates,
      );
      if (productValidationError != null) {
        return Response.badRequest(
          body: productValidationError,
          headers: _utf8TextHeaders,
        );
      }
      final characteristics = _serializeCharacteristics(
        payload['characteristics'],
      );

      String imageUrl = '';
      final imageValue = payload['imageUrls'] ?? payload['image_url'];
      if (imageValue is List) {
        imageUrl = imageValue.map((e) => e.toString()).join(',');
      } else if (imageValue != null) {
        imageUrl = imageValue.toString();
      }

      final created = await connection.execute(
        Sql.named('''
          INSERT INTO products (
            name,
            description,
            image_url,
            ingredients,
            nutrition_calories,
            nutrition_protein,
            nutrition_fat,
            nutrition_carbohydrates,
            characteristics,
            stock_quantity,
            rating,
            review_count,
            category,
            price_per_unit,
            min_quantity,
            max_quantity,
            supplier_name,
            delivery_date,
            delivery_badge,
            supplier_user_id,
            moderation_status,
            moderation_comment
          )
          VALUES (
            @name,
            @description,
            @image_url,
            @ingredients,
            @nutrition_calories,
            @nutrition_protein,
            @nutrition_fat,
            @nutrition_carbohydrates,
            @characteristics,
            @stock_quantity,
            0.0,
            0,
            @category,
            @price_per_unit,
            @min_quantity,
            @max_quantity,
            @supplier_name,
            @delivery_date,
            @delivery_badge,
            @supplier_user_id,
            'pending',
            NULL
          )
          RETURNING *;
        '''),
        parameters: {
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'ingredients': ingredients,
          'nutrition_calories': nutritionCalories,
          'nutrition_protein': nutritionProtein,
          'nutrition_fat': nutritionFat,
          'nutrition_carbohydrates': nutritionCarbohydrates,
          'characteristics': characteristics,
          'stock_quantity': stockQuantity,
          'category': category,
          'price_per_unit': pricePerUnit,
          'min_quantity': minQuantity,
          'max_quantity': maxQuantity,
          'supplier_name': user['supplier_name'] ?? '',
          'delivery_date': deliveryDate,
          'delivery_badge': deliveryBadge,
          'supplier_user_id': userId,
        },
      );

      final createdMap = created.first.toColumnMap();
      return Response(
        201,
        body: jsonEncode(_productRowToModerationDto(createdMap)),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      final constraintError = _supplierProductDbConstraintMessage(e);
      if (constraintError != null) {
        return Response.badRequest(
          body: constraintError,
          headers: _utf8TextHeaders,
        );
      }
      print('Ошибка при создании товара поставщика: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.put('/supplier/products/<id>', (Request request, String id) async {
    try {
      final productId = int.tryParse(id);
      if (productId == null) {
        return Response.badRequest(body: 'Неверный id товара');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);
      final userId = _toPositiveInt(payload['userId']);
      if (userId == 0) {
        return Response.badRequest(
          body: 'Идентификатор пользователя обязателен',
        );
      }

      final userResult = await connection.execute(
        Sql.named('SELECT id, role, supplier_name FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound('Пользователь не найден');
      }
      final user = userResult.first.toColumnMap();
      if ((user['role'] ?? _defaultRole) != 'supplier') {
        return Response.forbidden('Доступ только для поставщика');
      }

      final existing = await connection.execute(
        Sql.named(
          'SELECT * FROM products WHERE id = @id AND supplier_user_id = @user_id',
        ),
        parameters: {'id': productId, 'user_id': userId},
      );
      if (existing.isEmpty) {
        return Response.notFound('Товар не найден');
      }

      final name = payload['name']?.toString().trim() ?? '';
      if (name.isEmpty) {
        return Response.badRequest(body: 'Название товара обязательно');
      }
      final description = payload['description']?.toString() ?? '';
      final categories = await _resolvePayloadCategories(
        connection,
        payload['category'],
      );
      if (categories.isEmpty) {
        return Response.badRequest(
          body: 'Выберите категорию из каталога',
          headers: _utf8TextHeaders,
        );
      }
      final category = categories.join(', ');
      final pricePerUnit = _toPositiveInt(payload['pricePerUnit']);
      final minQuantity = _toPositiveInt(payload['minQuantity'], fallback: 1);
      final maxQuantity = _toNullablePositiveInt(payload['maxQuantity']);
      final deliveryDate = payload['deliveryDate']?.toString();
      final deliveryBadge = payload['deliveryBadge']?.toString();
      final stockQuantity = _toPositiveInt(
        payload['stockQuantity'] ?? payload['stock_quantity'] ?? maxQuantity,
      );
      final ingredients = payload['ingredients']?.toString() ?? '';
      final nutritionalInfo = payload['nutritionalInfo'];
      final nutritionMap = nutritionalInfo is Map
          ? Map<String, dynamic>.from(nutritionalInfo)
          : <String, dynamic>{};
      final nutritionCalories = _toNonNegativeDouble(
        nutritionMap['calories'] ?? payload['calories'],
      );
      final nutritionProtein = _toNonNegativeDouble(
        nutritionMap['protein'] ?? payload['protein'],
      );
      final nutritionFat = _toNonNegativeDouble(
        nutritionMap['fat'] ?? payload['fat'],
      );
      final nutritionCarbohydrates = _toNonNegativeDouble(
        nutritionMap['carbohydrates'] ?? payload['carbohydrates'],
      );
      final productValidationError = _validateSupplierProductPayload(
        pricePerUnit: pricePerUnit,
        minQuantity: minQuantity,
        maxQuantity: maxQuantity,
        stockQuantity: stockQuantity,
        nutritionCalories: nutritionCalories,
        nutritionProtein: nutritionProtein,
        nutritionFat: nutritionFat,
        nutritionCarbohydrates: nutritionCarbohydrates,
      );
      if (productValidationError != null) {
        return Response.badRequest(
          body: productValidationError,
          headers: _utf8TextHeaders,
        );
      }
      final characteristics = _serializeCharacteristics(
        payload['characteristics'],
      );

      String imageUrl = '';
      final imageValue = payload['imageUrls'] ?? payload['image_url'];
      if (imageValue is List) {
        imageUrl = imageValue.map((e) => e.toString()).join(',');
      } else if (imageValue != null) {
        imageUrl = imageValue.toString();
      }

      final updated = await connection.execute(
        Sql.named('''
          UPDATE products
          SET name = @name,
              description = @description,
              image_url = @image_url,
              ingredients = @ingredients,
              nutrition_calories = @nutrition_calories,
              nutrition_protein = @nutrition_protein,
              nutrition_fat = @nutrition_fat,
              nutrition_carbohydrates = @nutrition_carbohydrates,
              characteristics = @characteristics,
              stock_quantity = @stock_quantity,
              category = @category,
              price_per_unit = @price_per_unit,
              min_quantity = @min_quantity,
              max_quantity = @max_quantity,
              supplier_name = @supplier_name,
              delivery_date = @delivery_date,
              delivery_badge = @delivery_badge,
              moderation_status = 'pending',
              moderation_comment = NULL
          WHERE id = @id AND supplier_user_id = @supplier_user_id
          RETURNING *;
        '''),
        parameters: {
          'id': productId,
          'supplier_user_id': userId,
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'ingredients': ingredients,
          'nutrition_calories': nutritionCalories,
          'nutrition_protein': nutritionProtein,
          'nutrition_fat': nutritionFat,
          'nutrition_carbohydrates': nutritionCarbohydrates,
          'characteristics': characteristics,
          'stock_quantity': stockQuantity,
          'category': category,
          'price_per_unit': pricePerUnit,
          'min_quantity': minQuantity,
          'max_quantity': maxQuantity,
          'supplier_name': user['supplier_name'] ?? '',
          'delivery_date': deliveryDate,
          'delivery_badge': deliveryBadge,
        },
      );

      final updatedMap = updated.first.toColumnMap();
      return Response.ok(
        jsonEncode(_productRowToModerationDto(updatedMap)),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      final constraintError = _supplierProductDbConstraintMessage(e);
      if (constraintError != null) {
        return Response.badRequest(
          body: constraintError,
          headers: _utf8TextHeaders,
        );
      }
      print('Ошибка при обновлении товара поставщика: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.delete('/supplier/products/<id>', (Request request, String id) async {
    try {
      final productId = int.tryParse(id);
      if (productId == null) {
        return Response.badRequest(body: 'Неверный id товара');
      }

      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(
          body: 'Идентификатор пользователя обязателен',
        );
      }

      final userResult = await connection.execute(
        Sql.named('SELECT id, role FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound('Пользователь не найден');
      }
      final user = userResult.first.toColumnMap();
      if ((user['role'] ?? _defaultRole) != 'supplier') {
        return Response.forbidden('Только поставщик может удалить свой товар');
      }

      final deleted = await connection.execute(
        Sql.named('''
          DELETE FROM products
          WHERE id = @id AND supplier_user_id = @supplier_user_id
          RETURNING id;
        '''),
        parameters: {'id': productId, 'supplier_user_id': userId},
      );

      if (deleted.isEmpty) {
        return Response.notFound('Товар не найден');
      }

      return Response.ok(
        jsonEncode({
          'deleted': true,
          'id': productId.toString(),
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      final constraintError = _supplierProductDeleteConstraintMessage(e);
      if (constraintError != null) {
        return Response(409, body: constraintError, headers: _utf8TextHeaders);
      }
      print('Ошибка удаления товара поставщика: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.patch('/supplier/orders/<id>/status', (
    Request request,
    String id,
  ) async {
    try {
      final orderId = int.tryParse(id);
      if (orderId == null) {
        return Response.badRequest(body: 'Неверный id заказа');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);
      final userId = _toPositiveInt(payload['userId']);
      if (userId == 0) {
        return Response.badRequest(
          body: 'Идентификатор пользователя обязателен',
        );
      }

      final status = _normalizeSupplierOrderStatus(payload['status']);
      if (status == null) {
        return Response.badRequest(
          body: 'Недопустимый статус. Доступно: Собирается, В пути, Доставлен',
        );
      }

      final userResult = await connection.execute(
        Sql.named('SELECT id, role, supplier_name FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound('Пользователь не найден');
      }
      final user = userResult.first.toColumnMap();
      if ((user['role'] ?? _defaultRole) != 'supplier') {
        return Response.forbidden('Доступ только для поставщика');
      }
      final supplierName = (user['supplier_name'] ?? '').toString();

      final supplierAccessResult = await connection.execute(
        Sql.named('''
          SELECT 1
          FROM order_items
          WHERE order_id = @order_id
            AND (
              supplier_user_id = @supplier_user_id
              OR (supplier_user_id IS NULL AND supplier_name = @supplier_name)
            )
          LIMIT 1;
          '''),
        parameters: {
          'order_id': orderId,
          'supplier_user_id': userId,
          'supplier_name': supplierName,
        },
      );
      if (supplierAccessResult.isEmpty) {
        return Response.forbidden('У вас нет доступа к этому заказу');
      }

      final existingOrderResult = await connection.execute(
        Sql.named('SELECT * FROM orders WHERE id = @id'),
        parameters: {'id': orderId},
      );
      if (existingOrderResult.isEmpty) {
        return Response.notFound('Заказ не найден');
      }

      final existingOrder = existingOrderResult.first.toColumnMap();
      final currentStatus = existingOrder['status']?.toString();

      if (_isAcceptedOrderStatus(currentStatus)) {
        return Response(
          409,
          body:
              'Заказ уже подтвержден покупателем и больше не может быть изменен',
        );
      }

      if (!_canSupplierUpdateOrderStatus(currentStatus, status)) {
        return Response(
          409,
          body:
              'Недопустимый переход статуса. Разрешен только следующий шаг в цепочке',
        );
      }

      final hasStatusChanged = currentStatus?.trim() != status;
      if (hasStatusChanged) {
        await connection.execute(
          Sql.named('UPDATE orders SET status = @status WHERE id = @id'),
          parameters: {'status': status, 'id': orderId},
        );
      }

      final orderResult = await connection.execute(
        Sql.named('SELECT * FROM orders WHERE id = @id'),
        parameters: {'id': orderId},
      );
      final orderMap = orderResult.first.toColumnMap();

      final itemsResult = await connection.execute(
        Sql.named('''
          SELECT name, price, quantity, image_url, is_received
          FROM order_items
          WHERE order_id = @order_id
            AND (
              supplier_user_id = @supplier_user_id
              OR (supplier_user_id IS NULL AND supplier_name = @supplier_name)
            )
          ORDER BY id;
          '''),
        parameters: {
          'order_id': orderId,
          'supplier_user_id': userId,
          'supplier_name': supplierName,
        },
      );

      final items = itemsResult.map((row) {
        final map = row.toColumnMap();
        return {
          'name': map['name'] ?? '',
          'price': map['price'] ?? 0,
          'quantity': map['quantity'] ?? 0,
          'imageUrl': map['image_url'] ?? '',
          'isReceived': map['is_received'] ?? false,
        };
      }).toList();

      return Response.ok(
        jsonEncode({
          'id': orderId.toString(),
          'date': (orderMap['created_at'] as DateTime).toIso8601String(),
          'status': orderMap['status'] ?? status,
          'deliveryAddress': orderMap['delivery_address'] ?? '',
          'items': items,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при обновлении статуса заказа поставщика: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });
}

void _registerSupplierExportRoute(Router router, Connection connection) {
  router.post('/export/supplier/orders/excel', (Request request) async {
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
      if (startDateRawDt.isAfter(endDateRawDt)) {
        return _jsonError('startDate не может быть позже endDate', 400);
      }

      final startDateTime = DateTime(
        startDateRawDt.year,
        startDateRawDt.month,
        startDateRawDt.day,
        0,
        0,
        0,
      );
      final endDateTime = DateTime(
        endDateRawDt.year,
        endDateRawDt.month,
        endDateRawDt.day,
        23,
        59,
        59,
      );

      // Проверяем, что пользователь существует и это именно поставщик.
      // Без этого любой userId смог бы выгрузить чужие позиции.
      final userResult = await connection.execute(
        Sql.named('SELECT id, role, supplier_name FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return _jsonError('Пользователь не найден', 404);
      }
      final user = userResult.first.toColumnMap();
      if ((user['role'] ?? _defaultRole) != 'supplier') {
        return Response.forbidden('Доступ только для поставщика');
      }
      final supplierName = (user['supplier_name'] ?? '').toString();

      // В одном заказе могут быть позиции разных поставщиков - выгружаем
      // только свои. Историческим позициям без supplier_user_id матчимся
      // по supplier_name (тот же fallback используется в /supplier/orders).
      final result = await connection.execute(
        Sql.named('''
          SELECT
            o.id as order_id,
            o.created_at as order_date,
            o.status as order_status,
            COALESCE(NULLIF(bu.name, ''), '') as buyer_name,
            oi.name as service_name,
            oi.price as price,
            oi.quantity as quantity
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          LEFT JOIN users bu ON bu.id = o.user_id
          WHERE (
              oi.supplier_user_id = @supplier_user_id
              OR (oi.supplier_user_id IS NULL AND oi.supplier_name = @supplier_name)
            )
            AND o.created_at >= @start_date
            AND o.created_at <= @end_date
            AND LOWER(TRIM(o.status)) IN (
              'принят', 'принята', 'принято', 'приняты', 'accepted', 'received'
            )
          ORDER BY o.id, oi.id
        '''),
        parameters: {
          'supplier_user_id': userId,
          'supplier_name': supplierName,
          'start_date': startDateTime.toIso8601String(),
          'end_date': endDateTime.toIso8601String(),
        },
      );

      final excel = Excel.createExcel();
      final sheet = excel['SupplierOrders'];

      const headers = <String>[
        'ID заказа',
        'Покупатель',
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
        final buyerName = (row['buyer_name'] ?? '').toString();
        final serviceName = (row['service_name'] ?? '').toString();
        final price = _toPositiveInt(row['price']);
        final quantity = _toPositiveInt(row['quantity'], fallback: 1);
        final total = price * quantity;
        final orderDate = row['order_date'];
        final orderStatus = (row['order_status'] ?? '').toString();

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
          buyerName,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          serviceName,
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
          orderStatus,
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
          'content-disposition':
              'attachment; filename="supplier_orders_export.xlsx"',
        },
      );
    } catch (e, st) {
      print('Ошибка экспорта заказов поставщика: $e\n$st');
      return _jsonError('Ошибка сервера', 500);
    }
  });
}

void _registerSupplierQuestionAnswerRoute(
  Router router,
  Connection connection,
) {
  router.post('/questions/<id>/answer', (Request request, String id) async {
    try {
      final questionId = int.tryParse(id);
      if (questionId == null) {
        return Response.badRequest(body: 'Invalid question id');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) return Response.badRequest(body: 'Expected JSON');
      final payload = Map<String, dynamic>.from(decoded);

      final supplierUserId = _toPositiveInt(payload['supplierUserId']);
      final answerText = payload['answerText']?.toString().trim() ?? '';
      if (answerText.length < 10 || answerText.length > 1000) {
        return Response.badRequest(
          body: 'Answer text must be 10-1000 characters',
        );
      }

      // Проверка, что вопрос относится к продукту данного поставщика
      final check = await connection.execute(
        Sql.named('''SELECT q.id FROM questions q
          JOIN products p ON q.product_id = p.id
          WHERE q.id = @qid AND p.supplier_user_id = @suid
        '''),
        parameters: {'qid': questionId, 'suid': supplierUserId},
      );
      if (check.isEmpty) return Response(403, body: 'Forbidden');

      // Вставка ответа (используем ON CONFLICT для безопасности)
      await connection.execute(
        Sql.named(
          '''INSERT INTO question_answers (question_id, supplier_user_id, answer_text)
          VALUES (@qid, @suid, @text)
          ON CONFLICT (question_id) DO UPDATE SET answer_text = EXCLUDED.answer_text, answered_at = NOW()
        ''',
        ),
        parameters: {
          'qid': questionId,
          'suid': supplierUserId,
          'text': answerText,
        },
      );

      // Обновить флаг is_answered
      await connection.execute(
        Sql.named('UPDATE questions SET is_answered = true WHERE id = @qid'),
        parameters: {'qid': questionId},
      );

      final result = await connection.execute(
        Sql.named(
          '''SELECT id, answered_at FROM question_answers WHERE question_id = @qid''',
        ),
        parameters: {'qid': questionId},
      );
      final map = result.first.toColumnMap();
      return Response(
        201,
        body: jsonEncode({
          'answerId': map['id'].toString(),
          'answeredAt': (map['answered_at'] as DateTime).toIso8601String(),
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Invalid JSON');
    } catch (e, st) {
      print('Error answering: $e\n$st');
      return Response.internalServerError(body: 'Server error');
    }
  });
}

void _registerSupplierReviewResponseRoutes(
  Router router,
  Connection connection,
) {
  router.post('/reviews/<reviewId>/response', (
    Request request,
    String reviewId,
  ) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Expected JSON object');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final supplierUserId = _toPositiveInt(payload['supplierUserId']);
      if (supplierUserId == 0) {
        return Response.badRequest(body: 'Supplier user ID is required');
      }

      final responseText = (payload['responseText'] ?? '').toString().trim();
      if (responseText.isEmpty) {
        return Response.badRequest(body: 'Response text is required');
      }

      final reviewIdInt = int.tryParse(reviewId);
      if (reviewIdInt == null || reviewIdInt <= 0) {
        return Response.badRequest(body: 'Invalid review ID');
      }

      // Проверяем, что отзыв принадлежит товару поставщика
      final reviewResult = await connection.execute(
        Sql.named('''
          SELECT r.id, oi.supplier_user_id
          FROM reviews r
          JOIN order_items oi ON r.order_item_id = oi.id
          WHERE r.id = @review_id
          LIMIT 1;
        '''),
        parameters: {'review_id': reviewIdInt},
      );

      if (reviewResult.isEmpty) {
        return Response.notFound('Review not found');
      }

      final review = reviewResult.first.toColumnMap();
      if (_toPositiveInt(review['supplier_user_id']) != supplierUserId) {
        return Response.forbidden('You cannot respond to this review');
      }

      // Добавляем или обновляем ответ поставщика
      final created = await connection.execute(
        Sql.named('''
          INSERT INTO supplier_review_responses (review_id, response_text, created_at, updated_at)
          VALUES (@review_id, @response_text, NOW(), NOW())
          ON CONFLICT (review_id) DO UPDATE SET
            response_text = EXCLUDED.response_text,
            updated_at = NOW()
          RETURNING id, created_at, updated_at;
        '''),
        parameters: {'review_id': reviewIdInt, 'response_text': responseText},
      );

      if (created.isEmpty) {
        return Response.internalServerError(body: 'Failed to create response');
      }

      final responseMap = created.first.toColumnMap();
      return Response(
        201,
        body: jsonEncode({
          'id': responseMap['id'].toString(),
          'reviewId': reviewIdInt.toString(),
          'responseText': responseText,
          'createdAt': (responseMap['created_at'] as DateTime)
              .toIso8601String(),
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Invalid JSON');
    } catch (e, st) {
      print('Error creating review response: $e\n$st');
      return Response.internalServerError(body: 'Server error: $e');
    }
  });

  router.patch('/reviews/<reviewId>/response', (
    Request request,
    String reviewId,
  ) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Expected JSON object');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final supplierUserId = _toPositiveInt(payload['supplierUserId']);
      if (supplierUserId == 0) {
        return Response.badRequest(body: 'Supplier user ID is required');
      }

      final responseText = (payload['responseText'] ?? '').toString().trim();
      if (responseText.isEmpty) {
        return Response.badRequest(body: 'Response text is required');
      }

      final reviewIdInt = int.tryParse(reviewId);
      if (reviewIdInt == null || reviewIdInt <= 0) {
        return Response.badRequest(body: 'Invalid review ID');
      }

      // Проверяем, что отзыв принадлежит товару поставщика
      final reviewResult = await connection.execute(
        Sql.named('''
          SELECT r.id, oi.supplier_user_id
          FROM reviews r
          JOIN order_items oi ON r.order_item_id = oi.id
          WHERE r.id = @review_id
          LIMIT 1;
        '''),
        parameters: {'review_id': reviewIdInt},
      );

      if (reviewResult.isEmpty) {
        return Response.notFound('Review not found');
      }

      final review = reviewResult.first.toColumnMap();
      if (_toPositiveInt(review['supplier_user_id']) != supplierUserId) {
        return Response.forbidden('You cannot update this response');
      }

      // Обновляем ответ поставщика
      final updated = await connection.execute(
        Sql.named('''
          UPDATE supplier_review_responses
          SET response_text = @response_text
          WHERE review_id = @review_id
          RETURNING id, created_at;
        '''),
        parameters: {'review_id': reviewIdInt, 'response_text': responseText},
      );

      if (updated.isEmpty) {
        return Response.notFound('Response not found');
      }

      final responseMap = updated.first.toColumnMap();
      return Response.ok(
        jsonEncode({
          'id': responseMap['id'].toString(),
          'reviewId': reviewIdInt.toString(),
          'responseText': responseText,
          'createdAt': (responseMap['created_at'] as DateTime)
              .toIso8601String(),
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Invalid JSON');
    } catch (e, st) {
      print('Error updating review response: $e\n$st');
      return Response.internalServerError(body: 'Server error: $e');
    }
  });
}

// GET-роуты профиля поставщика и его товаров (для покупателя).

void _registerSupplierPublicRoutes(Router router, Connection connection) {
  // GET /suppliers/<id> — профиль поставщика для покупателя
  router.get('/suppliers/<id>', (Request request, String id) async {
    final supplierId = int.tryParse(id);
    if (supplierId == null || supplierId <= 0) {
      return _jsonError('Некорректный идентификатор поставщика', 400);
    }

    try {
      final result = await connection.execute(
        Sql.named('''
          SELECT u.id, u.name, u.supplier_name, u.email, u.phone,
                 COALESCE(AVG(r.rating), 0) AS rating,
                 COUNT(DISTINCT r.id) AS review_count
          FROM users u
          LEFT JOIN products p ON p.supplier_user_id = u.id
          LEFT JOIN reviews r ON r.product_id = p.id
          WHERE u.id = @id AND u.role = 'supplier'
          GROUP BY u.id, u.name, u.supplier_name, u.email, u.phone;
        '''),
        parameters: {'id': supplierId},
      );

      if (result.isEmpty) {
        return _jsonError('Поставщик не найден', 404);
      }

      final row = result.first.toColumnMap();
      final displayName = (row['supplier_name']?.toString() ?? '').isNotEmpty
          ? row['supplier_name'].toString()
          : (row['name']?.toString() ?? 'Поставщик');

      final dto = {
        'id': supplierId.toString(),
        'name': displayName,
        'rating': _toNonNegativeDouble(row['rating']),
        'reviewCount': _toPositiveInt(row['review_count']),
        'logoUrl': null,
        'description': null,
        'address': null,
        'phone': row['phone']?.toString(),
        'email': row['email']?.toString(),
        'pricePerUnit': 0,
        'minQuantity': 1,
        'maxQuantity': null,
        'stockQuantity': 0,
        'deliveryDate': '',
        'deliveryInfo': 'Доставка по согласованию',
        'deliveryBadge': '',
      };

      return Response.ok(
        jsonEncode(dto),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при загрузке профиля поставщика: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера');
    }
  });

  // GET /suppliers/<id>/products — товары поставщика для покупателя
  router.get('/suppliers/<id>/products', (Request request, String id) async {
    final supplierId = int.tryParse(id);
    if (supplierId == null || supplierId <= 0) {
      return _jsonError('Некорректный идентификатор поставщика', 400);
    }

    final page = int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '20') ?? 20;
    final offset = (page - 1) * limit;

    try {
      // Проверяем что поставщик существует
      final supplierCheck = await connection.execute(
        Sql.named(
          "SELECT id FROM users WHERE id = @id AND role = 'supplier' LIMIT 1;",
        ),
        parameters: {'id': supplierId},
      );
      if (supplierCheck.isEmpty) {
        return _jsonError('Поставщик не найден', 404);
      }

      // Считаем общее количество товаров
      final countResult = await connection.execute(
        Sql.named('''
          SELECT COUNT(*) AS total
          FROM products
          WHERE supplier_user_id = @supplier_id
            AND (moderation_status = 'approved' OR moderation_status IS NULL);
        '''),
        parameters: {'supplier_id': supplierId},
      );
      final total = _toPositiveInt(countResult.first.toColumnMap()['total']);

      // Загружаем товары с пагинацией
      final productsResult = await connection.execute(
        Sql.named('''
          SELECT p.*,
                 EXISTS(
                   SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
                 ) AS has_orders,
                 COALESCE(AVG(r.rating), 0) AS avg_rating,
                 COUNT(DISTINCT r.id) AS review_count,
                 COUNT(DISTINCT q.id) AS question_count
          FROM products p
          LEFT JOIN reviews r ON r.product_id = p.id
          LEFT JOIN questions q ON q.product_id = p.id
          WHERE p.supplier_user_id = @supplier_id
            AND (p.moderation_status = 'approved' OR p.moderation_status IS NULL)
          GROUP BY p.id
          ORDER BY p.id DESC
          LIMIT @limit OFFSET @offset;
        '''),
        parameters: {
          'supplier_id': supplierId,
          'limit': limit,
          'offset': offset,
        },
      );

      final products = productsResult.map((row) {
        final map = row.toColumnMap();
        final productId = _toPositiveInt(map['id']);
        final parsedImages = _parseImageUrls(map['image_url']);
        final imageUrls = parsedImages.isNotEmpty
            ? parsedImages
            : ['assets/coca_cola.jpeg'];
        final hasOrders = map['has_orders'] == true;
        final rawStock = _toPositiveInt(map['stock_quantity']);
        final legacyMax = _toPositiveInt(map['max_quantity']);
        final stockQuantity = rawStock > 0
            ? rawStock
            : (!hasOrders ? legacyMax : 0);
        var minQuantity = _toPositiveInt(map['min_quantity'], fallback: 1);
        if (stockQuantity > 0 && minQuantity > stockQuantity) {
          minQuantity = stockQuantity;
        }
        final avgRating = _toNonNegativeDouble(map['avg_rating']);
        final reviewCount = _toPositiveInt(map['review_count']);
        final questionCount = _toPositiveInt(map['question_count']);

        return {
          'id': productId.toString(),
          'name': (map['name'] ?? '').toString(),
          'description': (map['description'] ?? '').toString(),
          'imageUrls': imageUrls,
          'rating': avgRating,
          'reviewCount': reviewCount,
          'questionCount': questionCount,
          'categories': _parseCategories(map['category']),
          'nutritionalInfo': {
            'calories': _toNonNegativeDouble(map['nutrition_calories']),
            'protein': _toNonNegativeDouble(map['nutrition_protein']),
            'fat': _toNonNegativeDouble(map['nutrition_fat']),
            'carbohydrates': _toNonNegativeDouble(
              map['nutrition_carbohydrates'],
            ),
          },
          'ingredients': map['ingredients']?.toString() ?? '',
          'characteristics': _parseCharacteristics(map['characteristics']),
          'suppliers': [
            {
              'id': supplierId.toString(),
              'name': map['supplier_name'] ?? 'Поставщик',
              'rating': avgRating,
              'reviewCount': reviewCount,
              'pricePerUnit': _toPositiveInt(map['price_per_unit']),
              'minQuantity': minQuantity,
              'maxQuantity': stockQuantity > 0 ? stockQuantity : null,
              'stockQuantity': stockQuantity,
              'deliveryDate': map['delivery_date'] ?? '',
              'deliveryInfo': 'Доставка по согласованию',
              'deliveryBadge': map['delivery_badge'] ?? '',
            },
          ],
          'similarProducts': const <Map<String, dynamic>>[],
          'ratingDistribution': const <Map<String, dynamic>>[],
        };
      }).toList();

      return Response.ok(
        jsonEncode({'products': products, 'total': total}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при загрузке товаров поставщика: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера');
    }
  });
}

// Личный кабинет поставщика: товары, заказы, вопросы и отзывы.

void _registerSupplierDashboardRoutes(Router router, Connection connection) {
  router.get('/supplier/products', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null) {
        return Response.badRequest(
          body: 'Идентификатор пользователя указан некорректно',
        );
      }

      final userResult = await connection.execute(
        Sql.named('SELECT id, role, supplier_name FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound('Ресурс не найден');
      }
      final user = userResult.first.toColumnMap();
      if ((user['role'] ?? _defaultRole) != 'supplier') {
        return Response.forbidden('Доступ запрещен');
      }

      final result = await connection.execute(
        Sql.named(
          'SELECT * FROM products WHERE supplier_user_id = @id ORDER BY id DESC;',
        ),
        parameters: {'id': userId},
      );
      final products = result
          .map((row) => _productRowToModerationDto(row.toColumnMap()))
          .toList();

      return Response.ok(
        jsonEncode(products),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/supplier/orders', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null) {
        return Response.badRequest(
          body: 'Идентификатор пользователя указан некорректно',
        );
      }

      final userResult = await connection.execute(
        Sql.named('SELECT id, role, supplier_name FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound('Ресурс не найден');
      }
      final user = userResult.first.toColumnMap();
      if ((user['role'] ?? _defaultRole) != 'supplier') {
        return Response.forbidden('Доступ запрещен');
      }

      final supplierName = (user['supplier_name'] ?? '').toString();

      final itemsResult = await connection.execute(
        Sql.named('''
          SELECT *
          FROM order_items
          WHERE supplier_user_id = @supplier_user_id
             OR (supplier_user_id IS NULL AND supplier_name = @supplier_name)
          ORDER BY id;
          '''),
        parameters: {'supplier_user_id': userId, 'supplier_name': supplierName},
      );

      final itemsByOrderId = <int, List<Map<String, dynamic>>>{};
      for (final row in itemsResult) {
        final map = row.toColumnMap();
        final orderId = map['order_id'] as int;
        itemsByOrderId.putIfAbsent(orderId, () => []);
        itemsByOrderId[orderId]!.add({
          'name': map['name'] ?? '',
          'price': map['price'] ?? 0,
          'quantity': map['quantity'] ?? 0,
          'imageUrl': map['image_url'] ?? '',
          'isReceived': map['is_received'] ?? false,
        });
      }

      if (itemsByOrderId.isEmpty) {
        return Response.ok(
          jsonEncode([]),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final orderIds = itemsByOrderId.keys.toList();
      final orderResult = await connection.execute(
        Sql.named(
          'SELECT * FROM orders WHERE id = ANY(@ids) ORDER BY created_at DESC;',
        ),
        parameters: {'ids': orderIds},
      );

      final orders = orderResult.map((row) {
        final map = row.toColumnMap();
        final orderId = map['id'] as int;
        return {
          'id': orderId.toString(),
          'date': (map['created_at'] as DateTime).toIso8601String(),
          'status': map['status'] ?? '',
          'deliveryAddress': map['delivery_address'] ?? '',
          'items': itemsByOrderId[orderId] ?? [],
        };
      }).toList();

      return Response.ok(
        jsonEncode(orders),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  // GET /supplier/questions - Получить пагинированные вопросы для продуктов поставщика
  router.get('/supplier/questions', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(
          body: jsonEncode({'error': 'userId must be a positive integer'}),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      // Проверяем, что пользователь существует и является поставщиком
      final userResult = await connection.execute(
        Sql.named('SELECT id, role FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response(
          401,
          body: jsonEncode({'error': 'Authentication required'}),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final user = userResult.first.toColumnMap();
      if ((user['role'] ?? _defaultRole) != 'supplier') {
        return Response(
          403,
          body: jsonEncode({
            'error': 'You do not have permission to view these questions',
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final page =
          int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '20') ?? 20;
      final offset = (page - 1) * limit;

      // Вопросы по товарам этого поставщика. LEFT JOIN на question_answers,
      // чтобы тянуть и неотвеченные тоже - именно по ним показывается «Ответить».
      final result = await connection.execute(
        Sql.named('''
          SELECT
            q.id, q.product_id, q.user_id, q.question_text, q.created_at, q.is_answered,
            u.name as user_name, u.avatar_url as user_avatar_url,
            p.name as product_name, p.image_url as product_image,
            qa.id as answer_id, qa.answer_text, qa.answered_at,
            us.supplier_name as supplier_name, us.id as supplier_id
          FROM questions q
          JOIN products p ON q.product_id = p.id
          JOIN users u ON q.user_id = u.id
          LEFT JOIN question_answers qa ON q.id = qa.question_id
          LEFT JOIN users us ON qa.supplier_user_id = us.id
          WHERE p.supplier_user_id = @supplier_user_id
          ORDER BY q.created_at DESC
          LIMIT @limit OFFSET @offset
        '''),
        parameters: {
          'supplier_user_id': userId,
          'limit': limit,
          'offset': offset,
        },
      );

      final countResult = await connection.execute(
        Sql.named('''
          SELECT COUNT(*) as cnt
          FROM questions q
          JOIN products p ON q.product_id = p.id
          WHERE p.supplier_user_id = @supplier_user_id
        '''),
        parameters: {'supplier_user_id': userId},
      );
      final total = _toPositiveInt(countResult.first.toColumnMap()['cnt']);

      final questions = result.map((row) {
        final map = row.toColumnMap();

        final createdAt = map['created_at'];
        final createdAtIso = (createdAt is DateTime)
            ? createdAt.toIso8601String()
            : null;
        final answeredAt = map['answered_at'];
        final answeredAtIso = (answeredAt is DateTime)
            ? answeredAt.toIso8601String()
            : null;

        // Считаем вопрос отвеченным, если реально есть запись в question_answers,
        // а не только по флагу is_answered - флаг бывает рассинхронизирован.
        final hasAnswer = map['answer_id'] != null;
        final answerDto = hasAnswer
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
          'productName': map['product_name'] ?? '',
          'productImage': map['product_image'] ?? '',
          'userId': map['user_id'].toString(),
          'userName': map['user_name'] ?? 'Пользователь',
          'userAvatarUrl': _avatarUrlOrNull(request, map['user_avatar_url']),
          'questionText': map['question_text'] ?? '',
          'createdAt': createdAtIso,
          'isAnswered': hasAnswer || map['is_answered'] == true,
          'answer': answerDto,
        };
      }).toList();

      return Response.ok(
        jsonEncode({'questions': questions, 'total': total}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error fetching supplier questions: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
  });

  // GET /supplier/reviews - Получить отзывы для товаров поставщика с пагинацией
  router.get('/supplier/reviews', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final pageRaw = request.url.queryParameters['page'];
      final limitRaw = request.url.queryParameters['limit'];

      final userId = int.tryParse(userIdRaw ?? '');
      final page = int.tryParse(pageRaw ?? '1') ?? 1;
      final limit = int.tryParse(limitRaw ?? '20') ?? 20;

      if (userId == null || userId <= 0) {
        return Response.badRequest(body: 'Invalid userId');
      }

      if (page < 1) {
        return Response.badRequest(body: 'Invalid page');
      }
      if (limit < 1 || limit > 100) {
        return Response.badRequest(body: 'Invalid limit');
      }

      final offset = (page - 1) * limit;

      // Получить общее количество отзывов для товаров поставщика
      final countResult = await connection.execute(
        Sql.named('''
          SELECT COUNT(*) as total
          FROM reviews r
          JOIN order_items oi ON r.order_item_id = oi.id
          WHERE oi.supplier_user_id = @supplier_user_id;
        '''),
        parameters: {'supplier_user_id': userId},
      );

      final total = countResult.isNotEmpty
          ? _toPositiveInt(countResult.first.toColumnMap()['total'])
          : 0;

      // Получить отзывы с пагинацией
      final result = await connection.execute(
        Sql.named('''
          SELECT
            r.id,
            r.order_id,
            r.order_item_id,
            r.product_id,
            p.name as product_name,
            p.image_url as product_image,
            oi.name as order_item_name,
            oi.image_url as order_item_image,
            r.rating,
            r.review_text,
            u.name as reviewer_name,
            u.avatar_url as user_avatar_url,
            r.created_at
          FROM reviews r
          JOIN order_items oi ON r.order_item_id = oi.id
          LEFT JOIN products p ON p.id = r.product_id
          LEFT JOIN users u ON u.id = r.user_id
          WHERE oi.supplier_user_id = @supplier_user_id
          ORDER BY r.created_at DESC
          LIMIT @limit OFFSET @offset;
        '''),
        parameters: {
          'supplier_user_id': userId,
          'limit': limit,
          'offset': offset,
        },
      );

      final reviews = result
          .map((row) => _reviewRowToDto(row.toColumnMap(), request))
          .toList();

      return Response.ok(
        jsonEncode({'reviews': reviews, 'total': total}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при загрузке отзывов поставщика: $e\n$st');
      return Response.internalServerError();
    }
  });
}

// Статистика поставщика: revenue, top-products, order/buyer/rating stats.

void _registerSupplierStatisticsRoutes(Router router, Connection connection) {
  // GET /supplier/statistics/summary - Обзор продаж поставщика
  router.get('/supplier/statistics/summary', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(
          body: jsonEncode({'error': 'userId must be a positive integer'}),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      // Проверяем, что пользователь является поставщиком
      final userResult = await connection.execute(
        Sql.named('SELECT id, role FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty ||
          (userResult.first.toColumnMap()['role'] ?? _defaultRole) !=
              'supplier') {
        return Response.forbidden('Access denied');
      }

      final result = await connection.execute(
        Sql.named('''
          SELECT
            COALESCE(SUM(oi.price * oi.quantity), 0) as total_revenue,
            COALESCE(SUM(CASE WHEN DATE_TRUNC('month', o.created_at) = DATE_TRUNC('month', NOW()) THEN oi.price * oi.quantity ELSE 0 END), 0) as monthly_revenue,
            COALESCE(SUM(CASE WHEN DATE_TRUNC('week', o.created_at) = DATE_TRUNC('week', NOW()) THEN oi.price * oi.quantity ELSE 0 END), 0) as weekly_revenue,
            COUNT(DISTINCT o.id) as total_orders,
            CASE WHEN COUNT(DISTINCT o.id) > 0 THEN COALESCE(SUM(oi.price * oi.quantity), 0) / COUNT(DISTINCT o.id) ELSE 0 END as average_order_value
          FROM order_items oi
          JOIN orders o ON oi.order_id = o.id
          WHERE oi.supplier_user_id = @supplier_user_id;
        '''),
        parameters: {'supplier_user_id': userId},
      );

      if (result.isEmpty) {
        return Response.ok(
          jsonEncode({
            'totalRevenue': 0,
            'monthlyRevenue': 0,
            'weeklyRevenue': 0,
            'totalOrders': 0,
            'averageOrderValue': 0,
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final row = result.first.toColumnMap();
      return Response.ok(
        jsonEncode({
          'totalRevenue': _toPositiveInt(row['total_revenue']),
          'monthlyRevenue': _toPositiveInt(row['monthly_revenue']),
          'weeklyRevenue': _toPositiveInt(row['weekly_revenue']),
          'totalOrders': _toPositiveInt(row['total_orders']),
          'averageOrderValue': _toPositiveInt(row['average_order_value']),
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error fetching supplier stats summary: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
  });

  // GET /supplier/statistics/revenue-history - История доходов по месяцам
  router.get('/supplier/statistics/revenue-history', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(body: 'Invalid userId');
      }

      final monthsRaw = request.url.queryParameters['months'];
      final months = int.tryParse(monthsRaw ?? '6') ?? 6;

      final result = await connection.execute(
        Sql.named('''
          SELECT
            DATE_TRUNC('month', o.created_at)::date as month,
            COALESCE(SUM(oi.price * oi.quantity), 0) as revenue
          FROM order_items oi
          JOIN orders o ON oi.order_id = o.id
          WHERE oi.supplier_user_id = @supplier_user_id
            AND o.created_at >= NOW() - INTERVAL '1 month' * @months
          GROUP BY DATE_TRUNC('month', o.created_at)
          ORDER BY month ASC;
        '''),
        parameters: {'supplier_user_id': userId, 'months': months},
      );

      final history = result.map((row) {
        final map = row.toColumnMap();
        final month = map['month'] as DateTime;
        return {
          'month': '${month.month.toString().padLeft(2, '0')}.${month.year}',
          'revenue': _toPositiveInt(map['revenue']),
        };
      }).toList();

      return Response.ok(
        jsonEncode(history),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error fetching revenue history: $e\n$st');
      return Response.internalServerError();
    }
  });

  // GET /supplier/statistics/revenue-daily - Дневная выручка
  router.get('/supplier/statistics/revenue-daily', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final startRaw = request.url.queryParameters['startDate'];
      final endRaw = request.url.queryParameters['endDate'];

      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(body: 'Invalid userId');
      }

      final startDate = DateTime.tryParse(startRaw ?? '');
      final endDate = DateTime.tryParse(endRaw ?? '');
      if (startDate == null || endDate == null) {
        return Response.badRequest(body: 'startDate and endDate are required');
      }
      if (startDate.isAfter(endDate)) {
        return Response.badRequest(body: 'startDate must be before endDate');
      }

      // Устанавливаем границы дня
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final result = await connection.execute(
        Sql.named('''
          SELECT
            DATE(o.created_at) as day,
            COALESCE(SUM(oi.price * oi.quantity), 0) as revenue
          FROM order_items oi
          JOIN orders o ON oi.order_id = o.id
          WHERE oi.supplier_user_id = @supplier_user_id
            AND o.created_at BETWEEN @start AND @end
          GROUP BY DATE(o.created_at)
          ORDER BY day ASC;
        '''),
        parameters: {'supplier_user_id': userId, 'start': start, 'end': end},
      );

      final dailyData = result.map((row) {
        final map = row.toColumnMap();
        final day = map['day'] as DateTime;
        return {
          'date': day.toIso8601String(),
          'revenue': _toPositiveInt(map['revenue']),
        };
      }).toList();

      return Response.ok(
        jsonEncode(dailyData),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error fetching daily revenue: $e\n$st');
      return Response.internalServerError();
    }
  });

  // GET /supplier/statistics/top-products - Топ товаров по продажам
  router.get('/supplier/statistics/top-products', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(body: 'Invalid userId');
      }

      final limitRaw = request.url.queryParameters['limit'];
      final limit = int.tryParse(limitRaw ?? '5') ?? 5;

      final result = await connection.execute(
        Sql.named('''
          SELECT
            p.id,
            p.name as product_name,
            SUM(oi.quantity) as units_sold,
            COALESCE(SUM(oi.price * oi.quantity), 0) as revenue
          FROM order_items oi
          JOIN products p ON oi.product_id = p.id
          WHERE oi.supplier_user_id = @supplier_user_id
          GROUP BY p.id, p.name
          ORDER BY units_sold DESC
          LIMIT @limit;
        '''),
        parameters: {'supplier_user_id': userId, 'limit': limit},
      );

      final products = result.map((row) {
        final map = row.toColumnMap();
        return {
          'productId': (map['id'] ?? '').toString(),
          'productName': map['product_name'] ?? '',
          'unitsSold': _toPositiveInt(map['units_sold']),
          'revenue': _toPositiveInt(map['revenue']),
        };
      }).toList();

      return Response.ok(
        jsonEncode(products),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error fetching top products: $e\n$st');
      return Response.internalServerError();
    }
  });

  // GET /supplier/statistics/order-stats - Статистика заказов
  router.get('/supplier/statistics/order-stats', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(body: 'Invalid userId');
      }

      final result = await connection.execute(
        Sql.named('''
          SELECT
            COUNT(DISTINCT o.id) as total_orders,
            SUM(CASE WHEN o.status ILIKE '%принят%' OR o.status = 'accepted' THEN 1 ELSE 0 END) as confirmed_count,
            SUM(CASE WHEN o.status ILIKE '%отмен%' OR o.status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_count,
            SUM(CASE WHEN DATE_TRUNC('month', o.created_at) = DATE_TRUNC('month', NOW()) THEN 1 ELSE 0 END) as this_month_count,
            SUM(CASE WHEN DATE_TRUNC('month', o.created_at) = DATE_TRUNC('month', NOW() - INTERVAL '1 month') THEN 1 ELSE 0 END) as last_month_count,
            COALESCE(AVG(EXTRACT(DAY FROM NOW() - o.created_at)), 0) as average_fulfillment_days
          FROM order_items oi
          JOIN orders o ON oi.order_id = o.id
          WHERE oi.supplier_user_id = @supplier_user_id;
        '''),
        parameters: {'supplier_user_id': userId},
      );

      if (result.isEmpty) {
        return Response.ok(
          jsonEncode({
            'totalOrders': 0,
            'pendingCount': 0,
            'confirmedCount': 0,
            'shippedCount': 0,
            'deliveredCount': 0,
            'cancelledCount': 0,
            'averageFulfillmentDays': 0,
            'thisMonthCount': 0,
            'lastMonthCount': 0,
            'recentOrders': [],
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final row = result.first.toColumnMap();

      // Получаем недавние заказы
      final recentResult = await connection.execute(
        Sql.named('''
          SELECT DISTINCT
            o.id,
            o.created_at,
            o.status,
            COALESCE(SUM(oi.price * oi.quantity), 0) as total_amount
          FROM order_items oi
          JOIN orders o ON oi.order_id = o.id
          WHERE oi.supplier_user_id = @supplier_user_id
          GROUP BY o.id, o.created_at, o.status
          ORDER BY o.created_at DESC
          LIMIT 5;
        '''),
        parameters: {'supplier_user_id': userId},
      );

      final recentOrders = recentResult.map((r) {
        final m = r.toColumnMap();
        return {
          'orderId': m['id'],
          'date': (m['created_at'] as DateTime).toIso8601String(),
          'status': m['status'] ?? '',
          'totalAmount': _toPositiveInt(m['total_amount']),
        };
      }).toList();

      return Response.ok(
        jsonEncode({
          'totalOrders': _toPositiveInt(row['total_orders']),
          'pendingCount': 0,
          'confirmedCount': _toPositiveInt(row['confirmed_count']),
          'shippedCount': 0,
          'deliveredCount': 0,
          'cancelledCount': _toPositiveInt(row['cancelled_count']),
          'averageFulfillmentDays': _toPositiveInt(
            row['average_fulfillment_days'],
          ),
          'thisMonthCount': _toPositiveInt(row['this_month_count']),
          'lastMonthCount': _toPositiveInt(row['last_month_count']),
          'recentOrders': recentOrders,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error fetching order stats: $e\n$st');
      return Response.internalServerError();
    }
  });

  // GET /supplier/statistics/buyer-stats - Статистика покупателей
  router.get('/supplier/statistics/buyer-stats', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(body: 'Invalid userId');
      }

      final result = await connection.execute(
        Sql.named('''
          SELECT
            COUNT(DISTINCT buyer_stats.user_id) as total_buyers,
            SUM(CASE WHEN buyer_stats.buyer_order_count > 1 THEN 1 ELSE 0 END) as repeat_buyers
          FROM (
            SELECT
              o.user_id,
              COUNT(*) as buyer_order_count
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            WHERE oi.supplier_user_id = @supplier_user_id
            GROUP BY o.user_id
          ) buyer_stats;
        '''),
        parameters: {'supplier_user_id': userId},
      );

      final totalBuyers = result.isNotEmpty
          ? _toPositiveInt(result.first.toColumnMap()['total_buyers'])
          : 0;
      final repeatBuyers = result.isNotEmpty
          ? _toPositiveInt(result.first.toColumnMap()['repeat_buyers'])
          : 0;
      final repeatPercentage = totalBuyers > 0
          ? ((repeatBuyers / totalBuyers) * 100).toInt()
          : 0;

      // Получаем новых покупателей за этот месяц
      final newBuyersResult = await connection.execute(
        Sql.named('''
          SELECT COUNT(DISTINCT o.user_id) as new_buyers
          FROM order_items oi
          JOIN orders o ON oi.order_id = o.id
          WHERE oi.supplier_user_id = @supplier_user_id
            AND DATE_TRUNC('month', o.created_at) = DATE_TRUNC('month', NOW());
        '''),
        parameters: {'supplier_user_id': userId},
      );

      final newBuyers = newBuyersResult.isNotEmpty
          ? _toPositiveInt(newBuyersResult.first.toColumnMap()['new_buyers'])
          : 0;

      return Response.ok(
        jsonEncode({
          'totalBuyers': totalBuyers,
          'repeatBuyers': repeatBuyers,
          'repeatBuyersPercentage': repeatPercentage,
          'newBuyersThisMonth': newBuyers,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error fetching buyer stats: $e\n$st');
      return Response.internalServerError();
    }
  });

  // GET /supplier/statistics/rating-stats - Статистика рейтингов и отзывов
  router.get('/supplier/statistics/rating-stats', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(body: 'Invalid userId');
      }

      final result = await connection.execute(
        Sql.named('''
          SELECT
            COUNT(*) as total_reviews,
            AVG(r.rating) as average_rating,
            SUM(CASE WHEN r.rating = 5 THEN 1 ELSE 0 END) as five_star_count,
            SUM(CASE WHEN r.rating = 4 THEN 1 ELSE 0 END) as four_star_count,
            SUM(CASE WHEN r.rating = 3 THEN 1 ELSE 0 END) as three_star_count,
            SUM(CASE WHEN r.rating = 2 THEN 1 ELSE 0 END) as two_star_count,
            SUM(CASE WHEN r.rating = 1 THEN 1 ELSE 0 END) as one_star_count
          FROM reviews r
          JOIN order_items oi ON r.order_item_id = oi.id
          WHERE oi.supplier_user_id = @supplier_user_id;
        '''),
        parameters: {'supplier_user_id': userId},
      );

      final totalReviews = result.isNotEmpty
          ? _toPositiveInt(result.first.toColumnMap()['total_reviews'])
          : 0;
      final avgRating = result.isNotEmpty
          ? _toNonNegativeDouble(result.first.toColumnMap()['average_rating'])
          : 0.0;

      // Получаем недавние отзывы
      final recentResult = await connection.execute(
        Sql.named('''
          SELECT
            p.name as product_name,
            r.rating,
            SUBSTRING(r.review_text, 1, 100) as comment_snippet
          FROM reviews r
          JOIN order_items oi ON r.order_item_id = oi.id
          JOIN products p ON r.product_id = p.id
          WHERE oi.supplier_user_id = @supplier_user_id
          ORDER BY r.created_at DESC
          LIMIT 3;
        '''),
        parameters: {'supplier_user_id': userId},
      );

      final recentReviews = recentResult.map((r) {
        final m = r.toColumnMap();
        return {
          'productName': m['product_name'] ?? '',
          'rating': _toPositiveInt(m['rating']),
          'commentSnippet': m['comment_snippet'] ?? '',
        };
      }).toList();

      return Response.ok(
        jsonEncode({
          'totalReviews': totalReviews,
          'averageRating': avgRating,
          'fiveStarCount': result.isNotEmpty
              ? _toPositiveInt(result.first.toColumnMap()['five_star_count'])
              : 0,
          'fourStarCount': result.isNotEmpty
              ? _toPositiveInt(result.first.toColumnMap()['four_star_count'])
              : 0,
          'threeStarCount': result.isNotEmpty
              ? _toPositiveInt(result.first.toColumnMap()['three_star_count'])
              : 0,
          'twoStarCount': result.isNotEmpty
              ? _toPositiveInt(result.first.toColumnMap()['two_star_count'])
              : 0,
          'oneStarCount': result.isNotEmpty
              ? _toPositiveInt(result.first.toColumnMap()['one_star_count'])
              : 0,
          'recentReviews': recentReviews,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error fetching rating stats: $e\n$st');
      return Response.internalServerError();
    }
  });
}
