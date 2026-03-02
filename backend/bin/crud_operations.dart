part of 'backend.dart';

Future<void> _recalculateProductRating(
  Connection connection,
  int productId,
) async {
  final result = await connection.execute(
    Sql.named('''
      SELECT COUNT(*) AS count, COALESCE(AVG(rating), 0) AS avg_rating
      FROM reviews
      WHERE product_id = @product_id;
      '''),
    parameters: {'product_id': productId},
  );

  if (result.isEmpty) {
    return;
  }

  final row = result.first.toColumnMap();
  final count = _toPositiveInt(row['count']);
  final avgRating = double.tryParse(row['avg_rating']?.toString() ?? '') ?? 0.0;

  await connection.execute(
    Sql.named('''
      UPDATE products
      SET rating = @rating,
          review_count = @review_count
      WHERE id = @product_id;
      '''),
    parameters: {
      'rating': avgRating,
      'review_count': count,
      'product_id': productId,
    },
  );
}

void _registerMutationRoutes(Router router, Connection connection) {
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

  router.patch('/users/<id>', (Request request, String id) async {
    try {
      final userId = int.tryParse(id);
      if (userId == null) {
        return Response.badRequest(body: 'Invalid user id');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Expected JSON object');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final hasName = payload.containsKey('name');
      final hasEmail = payload.containsKey('email');
      final hasPhone = payload.containsKey('phone');
      final hasSupplierName =
          payload.containsKey('supplierName') ||
          payload.containsKey('supplier_name');

      if (!hasName && !hasEmail && !hasPhone && !hasSupplierName) {
        return Response.badRequest(body: 'Nothing to update');
      }

      final userResult = await connection.execute(
        Sql.named(
          'SELECT id, name, email, role, supplier_name, phone FROM users WHERE id = @id',
        ),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound('User not found');
      }
      final user = userResult.first.toColumnMap();

      var nextName = (user['name'] ?? '').toString().trim();
      var nextEmail = (user['email'] ?? '').toString().trim();
      var nextRole = (user['role'] ?? _defaultRole).toString();
      var nextSupplierName = (user['supplier_name'] ?? '').toString().trim();
      String? nextPhone = user['phone']?.toString().trim();
      if (nextPhone != null && nextPhone.isEmpty) {
        nextPhone = null;
      }

      if (hasName) {
        nextName = (payload['name'] ?? '').toString().trim();
        if (nextName.isEmpty) {
          return Response.badRequest(body: 'Name is required');
        }
      }

      if (hasEmail) {
        nextEmail = (payload['email'] ?? '').toString().trim();
        if (nextEmail.isEmpty) {
          return Response.badRequest(body: 'Email is required');
        }
        final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        if (!emailPattern.hasMatch(nextEmail)) {
          return Response.badRequest(body: 'Invalid email format');
        }

        final duplicate = await connection.execute(
          Sql.named('''
            SELECT id
            FROM users
            WHERE email = @email
              AND id <> @id
            LIMIT 1;
            '''),
          parameters: {'email': nextEmail, 'id': userId},
        );
        if (duplicate.isNotEmpty) {
          return Response(409, body: 'Email already in use');
        }
      }

      if (hasPhone) {
        final rawPhone = (payload['phone'] ?? '').toString();
        final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) {
          nextPhone = null;
        } else {
          if (digits.length != 11 || !digits.startsWith('7')) {
            return Response.badRequest(body: 'Invalid phone format');
          }
          nextPhone = digits;
        }
      }

      if (hasSupplierName) {
        final supplierNameRaw = payload.containsKey('supplierName')
            ? payload['supplierName']
            : payload['supplier_name'];
        nextSupplierName = (supplierNameRaw ?? '').toString().trim();
      }

      final normalizedRole = _normalizeRole(nextRole);
      if (normalizedRole != 'supplier') {
        nextSupplierName = '';
      } else if (hasSupplierName && nextSupplierName.isEmpty) {
        return Response.badRequest(body: 'Supplier name is required');
      }

      final updated = await connection.execute(
        Sql.named('''
          UPDATE users
          SET name = @name,
              email = @email,
              phone = @phone,
              supplier_name = @supplier_name
          WHERE id = @id
          RETURNING id, name, email, role, supplier_name, phone;
          '''),
        parameters: {
          'id': userId,
          'name': nextName,
          'email': nextEmail,
          'phone': nextPhone,
          'supplier_name': nextSupplierName,
        },
      );

      if (updated.isEmpty) {
        return Response.notFound('User not found');
      }

      final updatedUser = updated.first.toColumnMap();
      nextRole = (updatedUser['role'] ?? nextRole).toString();

      return Response.ok(
        jsonEncode({
          'id': updatedUser['id'],
          'name': updatedUser['name'] ?? '',
          'email': updatedUser['email'] ?? '',
          'role': nextRole,
          'supplierName': _supplierNameForRole(
            nextRole,
            updatedUser['supplier_name'],
          ),
          'phone': updatedUser['phone'] ?? '',
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Invalid JSON');
    } catch (e, st) {
      print('Error updating user profile: $e\n$st');
      return Response.internalServerError(body: 'Server error: $e');
    }
  });

  router.patch('/users/<id>/password', (Request request, String id) async {
    try {
      final userId = int.tryParse(id);
      if (userId == null || userId <= 0) {
        return Response.badRequest(
          body: 'Некорректный id пользователя',
          headers: _utf8TextHeaders,
        );
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(
          body: 'Ожидается JSON объект',
          headers: _utf8TextHeaders,
        );
      }
      final payload = Map<String, dynamic>.from(decoded);

      final currentPasswordRaw = payload.containsKey('currentPassword')
          ? payload['currentPassword']
          : payload['current_password'];
      final newPasswordRaw = payload.containsKey('newPassword')
          ? payload['newPassword']
          : payload['new_password'];
      final confirmPasswordRaw = payload.containsKey('confirmPassword')
          ? payload['confirmPassword']
          : payload['confirm_password'];

      final currentPassword = currentPasswordRaw?.toString().trim() ?? '';
      final newPassword = newPasswordRaw?.toString().trim() ?? '';
      final confirmPassword = confirmPasswordRaw?.toString().trim();

      if (currentPassword.isEmpty || newPassword.isEmpty) {
        return Response.badRequest(
          body: 'Текущий и новый пароль обязательны',
          headers: _utf8TextHeaders,
        );
      }

      if (currentPassword.length < 6 || newPassword.length < 6) {
        return Response.badRequest(
          body: 'Пароль должен содержать минимум 6 символов',
          headers: _utf8TextHeaders,
        );
      }

      if (newPassword == currentPassword) {
        return Response.badRequest(
          body: 'Новый пароль должен отличаться от текущего',
          headers: _utf8TextHeaders,
        );
      }

      if (confirmPassword != null && confirmPassword != newPassword) {
        return Response.badRequest(
          body: 'Подтверждение пароля не совпадает',
          headers: _utf8TextHeaders,
        );
      }

      final userResult = await connection.execute(
        Sql.named(
          'SELECT id, password FROM users WHERE id = @id LIMIT 1;',
        ),
        parameters: {'id': userId},
      );
      if (userResult.isEmpty) {
        return Response.notFound(
          'Пользователь не найден',
          headers: _utf8TextHeaders,
        );
      }

      final user = userResult.first.toColumnMap();
      final persistedPassword = (user['password'] ?? '').toString().trim();
      if (persistedPassword != currentPassword) {
        return Response(
          401,
          body: 'Текущий пароль указан неверно',
          headers: _utf8TextHeaders,
        );
      }

      await connection.execute(
        Sql.named('''
          UPDATE users
          SET password = @password
          WHERE id = @id;
          '''),
        parameters: {'id': userId, 'password': newPassword},
      );

      return Response.ok(
        jsonEncode({'updated': true}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(
        body: 'Неверный JSON',
        headers: _utf8TextHeaders,
      );
    } catch (e, st) {
      print('Ошибка при смене пароля: $e\n$st');
      return Response.internalServerError(
        body: 'Ошибка сервера: $e',
        headers: _utf8TextHeaders,
      );
    }
  });

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
        jsonEncode({'deleted': true, 'id': productId.toString()}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      final constraintError = _supplierProductDeleteConstraintMessage(e);
      if (constraintError != null) {
        return Response(
          409,
          body: constraintError,
          headers: _utf8TextHeaders,
        );
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

  router.patch('/moderation/products/<id>', (Request request, String id) async {
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

      final status = _normalizeModerationStatus(payload['status']);
      final comment = payload['comment']?.toString();

      final updated = await connection.execute(
        Sql.named('''
          UPDATE products
          SET moderation_status = @status,
              moderation_comment = @comment
          WHERE id = @id
          RETURNING *;
        '''),
        parameters: {'id': productId, 'status': status, 'comment': comment},
      );

      if (updated.isEmpty) {
        return Response.notFound('Товар не найден');
      }

      final updatedMap = updated.first.toColumnMap();
      return Response.ok(
        jsonEncode(_productRowToModerationDto(updatedMap)),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при модерации товара: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.delete('/moderation/products/<id>', (
    Request request,
    String id,
  ) async {
    try {
      final productId = int.tryParse(id);
      if (productId == null || productId <= 0) {
        return Response.badRequest(body: 'Неверный id товара');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return Response.badRequest(
          body: 'Требуются moderatorId и reason',
          headers: _utf8TextHeaders,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final moderatorId = _toPositiveInt(payload['moderatorId']);
      if (moderatorId <= 0) {
        return Response.badRequest(
          body: 'Требуется корректный moderatorId',
          headers: _utf8TextHeaders,
        );
      }

      final reason = payload['reason']?.toString().trim() ?? '';
      if (reason.isEmpty) {
        return Response.badRequest(
          body: 'Укажите причину удаления товара',
          headers: _utf8TextHeaders,
        );
      }

      final moderatorCheck = await connection.execute(
        Sql.named('SELECT role FROM users WHERE id = @id'),
        parameters: {'id': moderatorId},
      );
      if (moderatorCheck.isEmpty) {
        return Response.notFound('Модератор не найден');
      }
      final moderatorRole = _normalizeRole(
        moderatorCheck.first.toColumnMap()['role'],
      );
      if (moderatorRole != 'moderator') {
        return Response.badRequest(
          body: 'Пользователь не является модератором',
          headers: _utf8TextHeaders,
        );
      }

      final productResult = await connection.execute(
        Sql.named('SELECT * FROM products WHERE id = @id LIMIT 1'),
        parameters: {'id': productId},
      );
      if (productResult.isEmpty) {
        return Response.notFound('Товар не найден');
      }
      final productMap = productResult.first.toColumnMap();
      final productName = (productMap['name'] ?? 'Товар').toString().trim();
      final normalizedReason = reason.replaceAll(RegExp(r'\s+'), ' ').trim();
      final moderationComment = 'Удалено модератором: $normalizedReason';

      Future<bool> hideFromCatalog() async {
        final updated = await connection.execute(
          Sql.named('''
            UPDATE products
            SET moderation_status = 'rejected',
                moderation_comment = @comment,
                stock_quantity = 0
            WHERE id = @id
            RETURNING id;
          '''),
          parameters: {'id': productId, 'comment': moderationComment},
        );
        return updated.isNotEmpty;
      }

      final linkedOrders = await connection.execute(
        Sql.named('''
          SELECT o.status
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          WHERE oi.product_id = @id;
        '''),
        parameters: {'id': productId},
      );
      final hasUnacceptedOrders = linkedOrders.any((row) {
        final status = row.toColumnMap()['status'];
        return !_isAcceptedOrderStatus(status) && !_isCancelledOrderStatus(status);
      });

      var action = 'hard_deleted';
      if (hasUnacceptedOrders) {
        final hidden = await hideFromCatalog();
        if (!hidden) {
          return Response.notFound('Товар не найден');
        }
        action = 'hidden_from_catalog';
      } else {
        try {
          final deleted = await connection.execute(
            Sql.named('''
              DELETE FROM products
              WHERE id = @id
              RETURNING id;
            '''),
            parameters: {'id': productId},
          );
          if (deleted.isEmpty) {
            return Response.notFound('Товар не найден');
          }
        } catch (e) {
          final constraintError = _supplierProductDeleteConstraintMessage(e);
          if (constraintError == null) {
            rethrow;
          }
          final hidden = await hideFromCatalog();
          if (!hidden) {
            return Response.notFound('Товар не найден');
          }
          action = 'hidden_from_catalog';
        }
      }

      final supplierUserId = _toPositiveInt(productMap['supplier_user_id']);
      var supplierNotified = false;
      if (supplierUserId > 0) {
        var chatMap = await _loadPreferredSupportChatForUser(
          connection,
          supplierUserId,
        );
        final hasOpenChat =
            chatMap != null &&
            _normalizeSupportChatStatus(chatMap['status']) == 'open';
        if (!hasOpenChat) {
          final createdChat = await connection.execute(
            Sql.named('''
              INSERT INTO support_chats (
                user_id,
                status,
                category,
                subject
              )
              VALUES (
                @user_id,
                'open',
                @category,
                @subject
              )
              RETURNING *;
            '''),
            parameters: {
              'user_id': supplierUserId,
              'category': 'Модерация товаров',
              'subject': 'Действие по товару за нарушение',
            },
          );
          if (createdChat.isNotEmpty) {
            chatMap = createdChat.first.toColumnMap();
          }
        }

        final chatId = chatMap == null ? 0 : _toPositiveInt(chatMap['id']);
        if (chatId > 0) {
          final resolvedChatMap = chatMap!;
          final category =
              _normalizeOptionalText(resolvedChatMap['category']) ??
              'Модерация товаров';
          final subject =
              _normalizeOptionalText(resolvedChatMap['subject']) ??
              'Действие по товару за нарушение';
          final notificationText = action == 'hidden_from_catalog'
              ? 'Товар "$productName" снят с публикации модератором за нарушение. '
                    'Причина: $normalizedReason'
              : 'Товар "$productName" удален модератором за нарушение. '
                    'Причина: $normalizedReason';

          final insertedMessage = await connection.execute(
            Sql.named('''
              INSERT INTO support_messages (
                chat_id,
                user_id,
                sender_role,
                sender_user_id,
                category,
                subject,
                message_text
              )
              VALUES (
                @chat_id,
                @user_id,
                'moderator',
                @sender_user_id,
                @category,
                @subject,
                @message_text
              )
              RETURNING *;
            '''),
            parameters: {
              'chat_id': chatId,
              'user_id': supplierUserId,
              'sender_user_id': moderatorId,
              'category': category,
              'subject': subject,
              'message_text': notificationText,
            },
          );
          if (insertedMessage.isNotEmpty) {
            await connection.execute(
              Sql.named('''
                UPDATE support_chats
                SET
                  updated_at = NOW(),
                  category = COALESCE(category, @category),
                  subject = COALESCE(subject, @subject)
                WHERE id = @chat_id;
              '''),
              parameters: {
                'chat_id': chatId,
                'category': category,
                'subject': subject,
              },
            );

            final messageDto = _supportMessageRowToDto(
              insertedMessage.first.toColumnMap(),
            );
            _emitSupportEvent(
              kind: 'message',
              userId: supplierUserId,
              chatId: chatId,
              messageId: _toPositiveInt(messageDto['id']),
              senderRole: messageDto['senderRole']?.toString(),
            );
            supplierNotified = true;
          }
        }
      }

      return Response.ok(
        jsonEncode({
          'deleted': true,
          'id': productId.toString(),
          'action': action,
          'supplierUserId': supplierUserId > 0 ? supplierUserId : null,
          'supplierNotified': supplierNotified,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      final constraintError = _supplierProductDeleteConstraintMessage(e);
      if (constraintError != null) {
        return Response(409, body: constraintError, headers: _utf8TextHeaders);
      }
      print('Ошибка удаления товара модератором: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.post('/moderation/categories', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);
      final name = _normalizeCategoryName(payload['name']?.toString() ?? '');
      if (name.isEmpty) {
        return Response.badRequest(body: 'Название категории обязательно');
      }

      final parentId = _toNullablePositiveInt(payload['parentId']);
      if (parentId != null) {
        final parentResult = await connection.execute(
          Sql.named('SELECT id FROM public.categories WHERE id = @id'),
          parameters: {'id': parentId},
        );
        if (parentResult.isEmpty) {
          return Response.badRequest(body: 'Родительская категория не найдена');
        }
      }

      final subtitle = _normalizeOptionalText(payload['subtitle']);
      final imagePath = _normalizeOptionalText(payload['imagePath']);
      final keywords = _normalizeCategoryKeywordsPayload(payload['keywords']);
      final sortOrder = _toPositiveInt(payload['sortOrder'], fallback: 0);
      final isActive = payload['isActive'] == null
          ? true
          : payload['isActive'] == true;

      final inserted = await connection.execute(
        Sql.named('''
          INSERT INTO public.categories (
            name,
            parent_id,
            subtitle,
            image_path,
            keywords,
            sort_order,
            is_active
          )
          VALUES (
            @name::varchar(120),
            @parent_id::integer,
            @subtitle::varchar(255),
            @image_path::varchar(255),
            @keywords::text,
            @sort_order::integer,
            @is_active::boolean
          )
          ON CONFLICT ((COALESCE(parent_id, 0)), (LOWER(name))) DO UPDATE
          SET parent_id = EXCLUDED.parent_id,
              subtitle = EXCLUDED.subtitle,
              image_path = EXCLUDED.image_path,
              keywords = EXCLUDED.keywords,
              sort_order = EXCLUDED.sort_order,
              is_active = EXCLUDED.is_active,
              updated_at = NOW()
          RETURNING
            id,
            name,
            parent_id,
            subtitle,
            image_path,
            keywords,
            sort_order,
            is_active;
        '''),
        parameters: {
          'name': name,
          'parent_id': parentId,
          'subtitle': subtitle,
          'image_path': imagePath,
          'keywords': keywords,
          'sort_order': sortOrder,
          'is_active': isActive,
        },
      );

      return Response(
        201,
        body: jsonEncode(_categoryRowToDto(inserted.first.toColumnMap())),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при создании категории: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.put('/moderation/categories/<id>', (Request request, String id) async {
    try {
      final categoryId = int.tryParse(id);
      if (categoryId == null) {
        return Response.badRequest(body: 'Неверный id категории');
      }

      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final hasName = payload.containsKey('name');
      final hasSortOrder = payload.containsKey('sortOrder');
      final hasIsActive = payload.containsKey('isActive');
      final hasParentId = payload.containsKey('parentId');
      final hasSubtitle = payload.containsKey('subtitle');
      final hasImagePath = payload.containsKey('imagePath');
      final hasKeywords = payload.containsKey('keywords');
      if (!hasName &&
          !hasSortOrder &&
          !hasIsActive &&
          !hasParentId &&
          !hasSubtitle &&
          !hasImagePath &&
          !hasKeywords) {
        return Response.badRequest(body: 'Нет данных для обновления');
      }

      final existingResult = await connection.execute(
        Sql.named('''
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
          WHERE id = @id
        '''),
        parameters: {'id': categoryId},
      );
      if (existingResult.isEmpty) {
        return Response.notFound('Категория не найдена');
      }
      final existing = existingResult.first.toColumnMap();

      final nextName = hasName
          ? _normalizeCategoryName(payload['name']?.toString() ?? '')
          : (existing['name'] ?? '').toString();
      if (nextName.isEmpty) {
        return Response.badRequest(body: 'Название категории обязательно');
      }

      final nextParentId = hasParentId
          ? _toNullablePositiveInt(payload['parentId'])
          : _toNullablePositiveInt(existing['parent_id']);
      if (nextParentId != null) {
        if (nextParentId == categoryId) {
          return Response.badRequest(
            body: 'Категория не может быть родителем самой себе',
          );
        }
        final parentResult = await connection.execute(
          Sql.named('SELECT id FROM public.categories WHERE id = @id'),
          parameters: {'id': nextParentId},
        );
        if (parentResult.isEmpty) {
          return Response.badRequest(body: 'Родительская категория не найдена');
        }
      }

      final nextSubtitle = hasSubtitle
          ? _normalizeOptionalText(payload['subtitle'])
          : _normalizeOptionalText(existing['subtitle']);
      final nextImagePath = hasImagePath
          ? _normalizeOptionalText(payload['imagePath'])
          : _normalizeOptionalText(existing['image_path']);
      final nextKeywords = hasKeywords
          ? _normalizeCategoryKeywordsPayload(payload['keywords'])
          : _normalizeCategoryKeywordsPayload(existing['keywords']);
      final nextSortOrder = hasSortOrder
          ? _toPositiveInt(payload['sortOrder'], fallback: 0)
          : _toPositiveInt(existing['sort_order'], fallback: 0);
      final nextIsActive = hasIsActive
          ? payload['isActive'] == true
          : (existing['is_active'] == true);

      final updated = await connection.execute(
        Sql.named('''
          UPDATE public.categories
          SET name = @name::varchar(120),
              parent_id = @parent_id::integer,
              subtitle = @subtitle::varchar(255),
              image_path = @image_path::varchar(255),
              keywords = @keywords::text,
              sort_order = @sort_order::integer,
              is_active = @is_active::boolean,
              updated_at = NOW()
          WHERE id = @id
          RETURNING
            id,
            name,
            parent_id,
            subtitle,
            image_path,
            keywords,
            sort_order,
            is_active;
        '''),
        parameters: {
          'id': categoryId,
          'name': nextName,
          'parent_id': nextParentId,
          'subtitle': nextSubtitle,
          'image_path': nextImagePath,
          'keywords': nextKeywords,
          'sort_order': nextSortOrder,
          'is_active': nextIsActive,
        },
      );

      return Response.ok(
        jsonEncode(_categoryRowToDto(updated.first.toColumnMap())),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка при обновлении категории: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.delete('/moderation/categories/<id>', (
    Request request,
    String id,
  ) async {
    try {
      final categoryId = int.tryParse(id);
      if (categoryId == null) {
        return Response.badRequest(body: 'Неверный id категории');
      }

      final deleted = await connection.execute(
        Sql.named('DELETE FROM public.categories WHERE id = @id RETURNING id;'),
        parameters: {'id': categoryId},
      );
      if (deleted.isEmpty) {
        return Response.notFound('Категория не найдена');
      }

      return Response.ok(
        jsonEncode({'deleted': true}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при удалении категории: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.post('/support/messages', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(body: 'Ожидается JSON объект');
      }
      final payload = Map<String, dynamic>.from(decoded);

      final userId = _toPositiveInt(payload['userId']);
      if (userId <= 0) {
        return Response.badRequest(body: 'Требуется корректный userId');
      }

      final text = payload['text']?.toString().trim() ?? '';
      if (text.isEmpty) {
        return Response.badRequest(body: 'Текст сообщения обязателен');
      }

      final senderRole = _normalizeSupportSenderRole(payload['senderRole']);
      var senderUserId = _toNullablePositiveInt(payload['senderUserId']);
      if (senderRole == 'user') {
        senderUserId = userId;
      }

      final userCheck = await connection.execute(
        Sql.named('SELECT id FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      if (userCheck.isEmpty) {
        return Response.notFound('Пользователь не найден');
      }

      if (senderRole == 'moderator') {
        if (senderUserId == null || senderUserId <= 0) {
          return Response.badRequest(
            body: 'Для сообщения модератора требуется senderUserId',
          );
        }
        final moderatorCheck = await connection.execute(
          Sql.named('SELECT role FROM users WHERE id = @id'),
          parameters: {'id': senderUserId},
        );
        if (moderatorCheck.isEmpty) {
          return Response.notFound('Модератор не найден');
        }
        final moderatorRole = _normalizeRole(
          moderatorCheck.first.toColumnMap()['role'],
        );
        if (moderatorRole != 'moderator') {
          return Response.badRequest(
            body: 'Пользователь senderUserId не является модератором',
          );
        }
      }

      final providedChatId = _toNullablePositiveInt(payload['chatId']);
      final categoryRaw = payload['category']?.toString().trim();
      final subjectRaw = payload['subject']?.toString().trim();
      final category = (categoryRaw == null || categoryRaw.isEmpty)
          ? null
          : categoryRaw;
      final subject = (subjectRaw == null || subjectRaw.isEmpty)
          ? null
          : subjectRaw;

      Map<String, dynamic>? chatMap;
      if (providedChatId != null && providedChatId > 0) {
        final chatResult = await connection.execute(
          Sql.named('''
            SELECT *
            FROM support_chats
            WHERE id = @chat_id
              AND user_id = @user_id
            LIMIT 1;
          '''),
          parameters: {'chat_id': providedChatId, 'user_id': userId},
        );
        if (chatResult.isEmpty) {
          return Response.badRequest(
            body: 'Чат не найден или не принадлежит пользователю',
          );
        }
        chatMap = chatResult.first.toColumnMap();
      } else {
        final openChatResult = await connection.execute(
          Sql.named('''
            SELECT *
            FROM support_chats
            WHERE user_id = @user_id
              AND status = 'open'
            ORDER BY id DESC
            LIMIT 1;
          '''),
          parameters: {'user_id': userId},
        );
        if (openChatResult.isNotEmpty) {
          chatMap = openChatResult.first.toColumnMap();
        }
      }

      if (chatMap != null &&
          _normalizeSupportChatStatus(chatMap['status']) == 'closed') {
        if (senderRole == 'moderator') {
          return Response.badRequest(body: 'Чат закрыт. Отправка невозможна');
        }
        chatMap = null;
      }

      if (chatMap == null) {
        if (senderRole == 'moderator') {
          return Response.badRequest(
            body: 'Для ответа модератора требуется открытый чат',
          );
        }
        if (category == null || subject == null) {
          return Response.badRequest(
            body: 'Для нового обращения укажите category и subject',
          );
        }

        final createdChat = await connection.execute(
          Sql.named('''
            INSERT INTO support_chats (
              user_id,
              status,
              category,
              subject
            )
            VALUES (
              @user_id,
              'open',
              @category,
              @subject
            )
            RETURNING *;
          '''),
          parameters: {
            'user_id': userId,
            'category': category,
            'subject': subject,
          },
        );
        if (createdChat.isEmpty) {
          return Response.internalServerError(
            body: 'Не удалось создать чат поддержки',
          );
        }
        chatMap = createdChat.first.toColumnMap();
      }

      final chatId = _toPositiveInt(chatMap['id']);
      if (chatId <= 0) {
        return Response.internalServerError(body: 'Некорректный chatId');
      }

      final effectiveCategory =
          category ?? _normalizeOptionalText(chatMap['category']);
      final effectiveSubject =
          subject ?? _normalizeOptionalText(chatMap['subject']);
      if (senderRole == 'user' &&
          (effectiveCategory == null || effectiveSubject == null)) {
        return Response.badRequest(
          body: 'Для обращения пользователя нужны category и subject',
        );
      }

      final inserted = await connection.execute(
        Sql.named('''
          INSERT INTO support_messages (
            chat_id,
            user_id,
            sender_role,
            sender_user_id,
            category,
            subject,
            message_text
          )
          VALUES (
            @chat_id,
            @user_id,
            @sender_role,
            @sender_user_id,
            @category,
            @subject,
            @message_text
          )
          RETURNING *;
        '''),
        parameters: {
          'chat_id': chatId,
          'user_id': userId,
          'sender_role': senderRole,
          'sender_user_id': senderUserId,
          'category': effectiveCategory,
          'subject': effectiveSubject,
          'message_text': text,
        },
      );

      if (inserted.isEmpty) {
        return Response.internalServerError(
          body: 'Не удалось создать сообщение',
        );
      }

      await connection.execute(
        Sql.named('''
          UPDATE support_chats
          SET
            category = COALESCE(category, @category),
            subject = COALESCE(subject, @subject),
            updated_at = NOW()
          WHERE id = @chat_id;
        '''),
        parameters: {
          'chat_id': chatId,
          'category': effectiveCategory,
          'subject': effectiveSubject,
        },
      );

      final insertedDto = _supportMessageRowToDto(inserted.first.toColumnMap());
      _emitSupportEvent(
        kind: 'message',
        userId: _toPositiveInt(insertedDto['userId']),
        chatId: _toPositiveInt(insertedDto['chatId']),
        messageId: _toPositiveInt(insertedDto['id']),
        senderRole: insertedDto['senderRole']?.toString(),
      );

      return Response(
        201,
        body: jsonEncode(insertedDto),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка создания сообщения поддержки: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

  router.patch('/moderation/support/chats/<id>/close', (
    Request request,
    String id,
  ) async {
    try {
      final chatId = int.tryParse(id);
      if (chatId == null || chatId <= 0) {
        return Response.badRequest(body: 'Неверный id чата');
      }

      final body = await request.readAsString();
      Map<String, dynamic> payload = <String, dynamic>{};
      if (body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is! Map) {
          return Response.badRequest(body: 'Ожидается JSON объект');
        }
        payload = Map<String, dynamic>.from(decoded);
      }

      final moderatorId = _toPositiveInt(payload['moderatorId']);
      if (moderatorId <= 0) {
        return Response.badRequest(body: 'Требуется корректный moderatorId');
      }

      final moderatorCheck = await connection.execute(
        Sql.named('SELECT role FROM users WHERE id = @id'),
        parameters: {'id': moderatorId},
      );
      if (moderatorCheck.isEmpty) {
        return Response.notFound('Модератор не найден');
      }
      final moderatorRole = _normalizeRole(
        moderatorCheck.first.toColumnMap()['role'],
      );
      if (moderatorRole != 'moderator') {
        return Response.badRequest(
          body: 'Пользователь не является модератором',
        );
      }

      final existing = await connection.execute(
        Sql.named('SELECT * FROM support_chats WHERE id = @id LIMIT 1'),
        parameters: {'id': chatId},
      );
      if (existing.isEmpty) {
        return Response.notFound('Чат не найден');
      }

      final current = existing.first.toColumnMap();
      if (_normalizeSupportChatStatus(current['status']) == 'closed') {
        return Response.ok(
          jsonEncode(_supportChatRowToDto(current)),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final reasonRaw = payload['reason']?.toString().trim();
      final reason = (reasonRaw == null || reasonRaw.isEmpty)
          ? null
          : reasonRaw;

      final updated = await connection.execute(
        Sql.named('''
          UPDATE support_chats
          SET
            status = 'closed',
            close_reason = COALESCE(@reason, close_reason),
            closed_at = NOW(),
            closed_by_user_id = @closed_by_user_id,
            updated_at = NOW()
          WHERE id = @id
          RETURNING *;
        '''),
        parameters: {
          'id': chatId,
          'reason': reason,
          'closed_by_user_id': moderatorId,
        },
      );
      if (updated.isEmpty) {
        return Response.internalServerError(body: 'Не удалось закрыть чат');
      }

      final updatedMap = updated.first.toColumnMap();
      _emitSupportEvent(
        kind: 'chat_closed',
        userId: _toPositiveInt(updatedMap['user_id']),
        chatId: _toPositiveInt(updatedMap['id']),
        reason: updatedMap['close_reason']?.toString(),
        actorUserId: moderatorId,
      );

      return Response.ok(
        jsonEncode(_supportChatRowToDto(updatedMap)),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(body: 'Неверный JSON');
    } catch (e, st) {
      print('Ошибка закрытия чата поддержки: $e\n$st');
      return Response.internalServerError(body: 'Ошибка сервера: $e');
    }
  });

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
        final imageUrl = item['imageUrl']?.toString() ?? '';
        final isReceived = item['isReceived'] == true;
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
        return Response.badRequest(body: 'У позиции заказа отсутствует productId');
      }
      if (
        payloadProductId != null &&
        payloadProductId != orderItemProductId
      ) {
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
                 oi.image_url AS order_item_image
          FROM reviews r
          LEFT JOIN order_items oi ON oi.id = r.order_item_id
          LEFT JOIN products p ON p.id = r.product_id
          WHERE r.id = @id;
          '''),
        parameters: {'id': reviewId},
      );

      final dto = _reviewRowToDto(reviewResult.first.toColumnMap());
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
                 oi.image_url AS order_item_image
          FROM reviews r
          LEFT JOIN order_items oi ON oi.id = r.order_item_id
          LEFT JOIN products p ON p.id = r.product_id
          WHERE r.id = @id;
          '''),
        parameters: {'id': reviewId},
      );

      final dto = _reviewRowToDto(reviewResult.first.toColumnMap());
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

  router.get('/register/check-email', (Request request) async {
    try {
      final email = request.url.queryParameters['email']?.trim() ?? '';
      if (email.isEmpty) {
        return Response.badRequest(
          body: 'Email is required',
          headers: _utf8TextHeaders,
        );
      }

      final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailPattern.hasMatch(email)) {
        return Response.badRequest(
          body: 'Invalid email format',
          headers: _utf8TextHeaders,
        );
      }

      final existing = await connection.execute(
        Sql.named('''
          SELECT id
          FROM users
          WHERE email = @email
          LIMIT 1;
        '''),
        parameters: {'email': email},
      );

      return Response.ok(
        jsonEncode({'available': existing.isEmpty}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Error while checking email availability: $e\n$st');
      return Response.internalServerError(
        body: 'Server error: $e',
        headers: _utf8TextHeaders,
      );
    }
  });

  router.post('/register', (Request request) async {
    try {
      final body = await request.readAsString();

      final data = Uri.splitQueryString(body);

      final name = data['name'];
      final email = data['email'];
      final password = data['password'];
      final role = _normalizeRole(data['role']);
      final supplierName = data['supplier_name']?.trim();
      final persistedSupplierName = role == 'supplier' ? supplierName : null;
      final moderatorCode = data['moderator_code']?.trim();
      final rawPhone = data['phone'];
      final phoneDigits = rawPhone == null
          ? ''
          : rawPhone.replaceAll(RegExp(r'\D'), '');
      final phone = phoneDigits.isEmpty ? null : phoneDigits;

      if (name == null || email == null || password == null) {
        return Response(
          400,
          body: 'Не заполнены обязательные поля',
          headers: _utf8TextHeaders,
        );
      }

      if (role == 'moderator' && moderatorCode != _moderatorCode) {
        return Response.forbidden(
          'Неверный код модератора',
          headers: _utf8TextHeaders,
        );
      }

      if (role == 'supplier' &&
          (supplierName == null || supplierName.isEmpty)) {
        return Response(
          400,
          body: 'Для поставщика требуется название',
          headers: _utf8TextHeaders,
        );
      }

      final existing = await connection.execute(
        Sql.named('SELECT * FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      if (existing.isNotEmpty) {
        return Response.forbidden(
          'Email уже зарегистрирован',
          headers: _utf8TextHeaders,
        );
      }

      await connection.execute(
        Sql.named('''
          INSERT INTO users (name, email, password, role, supplier_name, phone)
          VALUES (@name, @email, @password, @role, @supplier_name, @phone)
        '''),
        parameters: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'supplier_name': persistedSupplierName,
          'phone': phone,
        },
      );

      return Response.ok('Регистрация успешна', headers: _utf8TextHeaders);
    } catch (e, st) {
      print('Ошибка при регистрации: $e\n$st');
      return Response.internalServerError(
        body: 'Ошибка сервера: $e',
        headers: _utf8TextHeaders,
      );
    }
  });
}

