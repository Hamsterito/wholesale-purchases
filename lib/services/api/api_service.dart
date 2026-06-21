import 'package:flutter_project/services/localization/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http_package;
import '../../models/product.dart';
import '../../models/order.dart';
import 'api_config.dart';
import 'app_http_client.dart';
import '../storage/auth_storage.dart';
import 'sse_stream_native.dart' if (dart.library.html) 'sse_stream_web.dart';
import '../../models/supplier_order.dart';
import '../../models/supplier_product.dart';
import '../../models/user_profile.dart';
import '../../models/user_address.dart';
import '../../models/review_entry.dart';
import '../../models/support_message.dart';
import '../../models/notification.dart';
import '../../models/message.dart';
import '../../models/chat.dart';
import '../message/message_validator.dart';
import '../message/message_store.dart';
import '../message/message_pretty_printer.dart';
import '../message/message_service_adapters.dart';

http_package.Client get http => AppHttpClient.instance;

// Разделители для строкового представления списка ключевых слов
// (когда сервер отдаёт keywords строкой, а не массивом).
final RegExp _keywordsSplitRegExp = RegExp(r'[;,|]');



class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;



  // Последнее сообщение об ошибке API (для диагностики и отображения)
  static Message? _lastErrorMessage;

  /// Возвращает последнюю ошибку API как Message, либо null.
  static Message? getLastErrorMessage() => _lastErrorMessage;

  /// Очистить последнюю ошибку - например, при успешном повторе.
  static void clearLastErrorMessage() {
    _lastErrorMessage = null;
  }

  /// Внутренняя обёртка: логирует HTTP-ответ через систему стандартизованных
  /// сообщений и складывает в MessageStore.
  /// silentForStatus подавляет запись в _lastErrorMessage и debug-вывод
  /// для указанных HTTP-кодов - для случаев, когда код ожидаемо обрабатывается
  /// вызывающим как валидное состояние.
  static Future<void> _logApiResponse(
    http_package.Response response, {
    String? endpoint,
    String? method,
    Set<int>? silentForStatus,
  }) async {
    try {
      final message = ApiServiceAdapter.wrapApiResponse(
        response,
        'ru',
        endpoint: endpoint,
        method: method,
      );
      final validation = MessageValidator.validate(message);
      if (!validation.isValid) {
        debugPrint(
          'ApiService: ответ не прошёл валидацию: ${validation.errors.join('; ')}',
        );
      }
      final isSilent =
          silentForStatus != null &&
          silentForStatus.contains(response.statusCode);
      if (!isSilent &&
          (message.severity == MessageSeverity.error ||
              message.severity == MessageSeverity.critical)) {
        _lastErrorMessage = message;
        debugPrint(
          'ApiService error: ${MessagePrettyPrinter.prettyPrint(message, detailed: false)}',
        );
      }
      await MessageStore.save(message);
    } catch (e) {
      debugPrint('ApiService._logApiResponse: $e');
    }
  }

  /// Внутренняя обёртка для исключений API. Сохраняет ошибку как
  /// последнюю и пишет в MessageStore.
  static Future<void> _logApiError(
    Object e,
    StackTrace? stack, {
    String? endpoint,
    String? method,
  }) async {
    try {
      final message = ApiServiceAdapter.wrapApiError(
        e,
        stack,
        'ru',
        endpoint: endpoint,
        method: method,
      );
      _lastErrorMessage = message;
      debugPrint(
        'ApiService error: ${MessagePrettyPrinter.prettyPrint(message, detailed: false)}',
      );
      await MessageStore.save(message);
    } catch (err) {
      debugPrint('ApiService._logApiError: $err');
    }
  }

  /// Загружает актуальные курсы валют с бэкенда.
  static Future<Map<String, double>> getExchangeRates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/exchange-rates'));

      await _logApiResponse(response, endpoint: '/exchange-rates', method: 'GET');

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
        }
      }
      throw Exception('Не удалось загрузить курсы валют: ${response.statusCode}');
    } catch (e, stack) {
      await _logApiError(e, stack, endpoint: '/exchange-rates', method: 'GET');
      debugPrint('Ошибка при загрузке курсов валют: $e');
      rethrow;
    }
  }

  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));

      await _logApiResponse(response, endpoint: '/products', method: 'GET');

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Не удалось загрузить данные: ${response.statusCode}');
      }
    } catch (e, stack) {
      await _logApiError(e, stack, endpoint: '/products', method: 'GET');
      debugPrint('Ошибка при загрузке данных: $e');
      rethrow;
    }
  }

  static const List<Map<String, dynamic>> _hardcodedCatalogTree = [
    {
      'id': 1,
      'nameRu': 'Напитки',
      'nameKk': 'Сусындар',
      'subtitleRu': 'Вода, соки, газировка',
      'subtitleKk': 'Су, шырындар, газдалған сусындар',
      'imagePath': 'assets/catalog/water.jpg',
      'sortOrder': 1,
      'isActive': true,
      'subcategories': [
        {
          'id': 2,
          'nameRu': 'Вода',
          'nameKk': 'Су',
          'imagePath': 'assets/catalog/water.jpg',
          'keywords': ['вода', 'минеральная', 'су'],
          'sortOrder': 1,
          'isActive': true,
        },
        {
          'id': 3,
          'nameRu': 'Соки',
          'nameKk': 'Шырындар',
          'imagePath': 'assets/catalog/juice.jpg',
          'keywords': ['сок', 'соки', 'juice', 'шырын'],
          'sortOrder': 2,
          'isActive': true,
        },
        {
          'id': 4,
          'nameRu': 'Газировка',
          'nameKk': 'Газдалған сусындар',
          'imagePath': 'assets/catalog/soda.jpg',
          'keywords': ['газировка', 'газированный', 'лимонад', 'soda'],
          'sortOrder': 3,
          'isActive': true,
        },
      ],
    },
    {
      'id': 5,
      'nameRu': 'Овощи и фрукты',
      'nameKk': 'Көкөністер мен жемістер',
      'subtitleRu': 'Фрукты, ягоды, овощи и зелень',
      'subtitleKk': 'Жемістер, жидектер, көкөністер және көктер',
      'imagePath': 'assets/catalog/fruits_berries.jpg',
      'sortOrder': 2,
      'isActive': true,
      'subcategories': [
        {
          'id': 6,
          'nameRu': 'Фрукты, ягоды',
          'nameKk': 'Жемістер, жидектер',
          'imagePath': 'assets/catalog/fruits_berries.jpg',
          'keywords': ['фрукты', 'ягоды', 'фрукт', 'ягода', 'жеміс'],
          'sortOrder': 1,
          'isActive': true,
        },
        {
          'id': 7,
          'nameRu': 'Овощи, грибы и зелень',
          'nameKk': 'Көкөністер, саңырауқұлақтар және көктер',
          'imagePath': 'assets/catalog/vegetables_greens.jpg',
          'keywords': ['овощи', 'грибы', 'зелень', 'овощ', 'гриб', 'көкөніс'],
          'sortOrder': 2,
          'isActive': true,
        },
      ],
    },
    {
      'id': 8,
      'nameRu': 'Хлеб и пекарня',
      'nameKk': 'Нан және наубайхана',
      'subtitleRu': 'Хлеб, булочки, пироги',
      'subtitleKk': 'Нан, тоқаштар, бәліштер',
      'imagePath': 'assets/catalog/bakery_pastry.jpg',
      'sortOrder': 3,
      'isActive': true,
      'subcategories': [
        {
          'id': 9,
          'nameRu': 'Выпечка от Манса',
          'nameKk': 'Манс пісірмелері',
          'imagePath': 'assets/catalog/bakery_pastry.jpg',
          'keywords': ['выпечка', 'пекарня', 'булочки', 'круассан', 'нан'],
          'sortOrder': 1,
          'isActive': true,
        },
        {
          'id': 10,
          'nameRu': 'Хлеб',
          'nameKk': 'Нан',
          'imagePath': 'assets/catalog/bread.jpg',
          'keywords': ['хлеб', 'батон', 'багет', 'нан'],
          'sortOrder': 2,
          'isActive': true,
        },
        {
          'id': 11,
          'nameRu': 'Выпечка и пироги',
          'nameKk': 'Пісірмелер мен бәліштер',
          'imagePath': 'assets/catalog/pie.jpg',
          'keywords': ['выпечка', 'пирог', 'пироги', 'бәліш'],
          'sortOrder': 3,
          'isActive': true,
        },
      ],
    },
    {
      'id': 12,
      'nameRu': 'Молочная продукция',
      'nameKk': 'Сүт өнімдері',
      'subtitleRu': 'Молоко, сыр, йогурты и яйца',
      'subtitleKk': 'Сүт, ірімшік, йогурт және жұмыртқа',
      'imagePath': 'assets/catalog/milk.jpg',
      'sortOrder': 4,
      'isActive': true,
      'subcategories': [
        {
          'id': 13,
          'nameRu': 'Сыр',
          'nameKk': 'Ірімшік',
          'imagePath': 'assets/catalog/cheese.jpg',
          'keywords': ['сыр', 'ірімшік'],
          'sortOrder': 1,
          'isActive': true,
        },
        {
          'id': 14,
          'nameRu': 'Творог, сметана',
          'nameKk': 'Сүзбе, қаймақ',
          'imagePath': 'assets/catalog/cottage_cheese.jpg',
          'keywords': ['творог', 'сметана', 'кисломолочные', 'сүзбе', 'қаймақ'],
          'sortOrder': 2,
          'isActive': true,
        },
        {
          'id': 15,
          'nameRu': 'Йогурт и десерты',
          'nameKk': 'Йогурт және десерттер',
          'imagePath': 'assets/catalog/yogurt_dessert.jpg',
          'keywords': ['йогурт', 'десерт', 'десерты'],
          'sortOrder': 3,
          'isActive': true,
        },
        {
          'id': 16,
          'nameRu': 'Молоко и кисломолочные продукты',
          'nameKk': 'Сүт және қышқыл сүт өнімдері',
          'imagePath': 'assets/catalog/milk.jpg',
          'keywords': ['молоко', 'кефир', 'ряженка', 'айран', 'сүт'],
          'sortOrder': 4,
          'isActive': true,
        },
        {
          'id': 17,
          'nameRu': 'Масло и яйца',
          'nameKk': 'Май және жұмыртқа',
          'imagePath': 'assets/catalog/butter_eggs.jpg',
          'keywords': ['масло', 'яйца', 'яйцо', 'май', 'жұмыртқа'],
          'sortOrder': 5,
          'isActive': true,
        },
      ],
    },
    {
      'id': 18,
      'nameRu': 'Мясо и птица',
      'nameKk': 'Ет және құс еті',
      'subtitleRu': 'Мясо, колбасы и деликатесы',
      'subtitleKk': 'Ет, шұжықтар және деликатестер',
      'imagePath': 'assets/catalog/meat.jpg',
      'sortOrder': 5,
      'isActive': true,
      'subcategories': [
        {
          'id': 19,
          'nameRu': 'Мясо и птица',
          'nameKk': 'Ет және құс еті',
          'imagePath': 'assets/catalog/meat.jpg',
          'keywords': ['мясо', 'птица', 'курица', 'говядина', 'свинина', 'ет'],
          'sortOrder': 1,
          'isActive': true,
        },
        {
          'id': 20,
          'nameRu': 'Колбасы и сосиски',
          'nameKk': 'Шұжықтар мен сосискалар',
          'imagePath': 'assets/catalog/sausages.jpg',
          'keywords': ['колбаса', 'колбасы', 'сосиски', 'сардельки', 'шұжық'],
          'sortOrder': 2,
          'isActive': true,
        },
        {
          'id': 21,
          'nameRu': 'Мясные деликатесы',
          'nameKk': 'Ет деликатестері',
          'imagePath': 'assets/catalog/deli_meats.jpg',
          'keywords': ['деликатесы', 'ветчина', 'бекон', 'хамон', 'деликатес'],
          'sortOrder': 3,
          'isActive': true,
        },
      ],
    },
  ];

  static Future<List<String>> getCatalogCategories({
    bool includeInactive = false,
  }) async {
    final categories = <String>[];
    for (final parent in _hardcodedCatalogTree) {
      if (!includeInactive && !(parent['isActive'] as bool)) continue;
      categories.add(parent['nameRu'].toString());
      
      final subcategories = parent['subcategories'] as List?;
      if (subcategories != null) {
        for (final sub in subcategories) {
          if (!includeInactive && !(sub['isActive'] as bool)) continue;
          categories.add(sub['nameRu'].toString());
        }
      }
    }
    return categories;
  }

  static Future<List<Map<String, dynamic>>> getCatalogCategoryTree({
    bool includeInactive = false,
    String locale = 'ru',
  }) async {
    final isKk = locale == 'kk';
    return _hardcodedCatalogTree
        .where((parent) => includeInactive || parent['isActive'] == true)
        .map((parent) {
      final subcategories = parent['subcategories'] as List?;
      List<Map<String, dynamic>>? mappedSubcategories;
      
      if (subcategories != null) {
        final activeSubs = subcategories
            .cast<Map<String, dynamic>>()
            .where((sub) => includeInactive || sub['isActive'] == true);
        mappedSubcategories = activeSubs.map((sub) => {
          ...sub,
          'name': isKk ? sub['nameKk'] : sub['nameRu'],
        }).toList();
      }

      return {
        ...parent,
        'name': isKk ? parent['nameKk'] : parent['nameRu'],
        'subtitle': isKk ? parent['subtitleKk'] : parent['subtitleRu'],
        'subcategories': mappedSubcategories,
      };
    }).toList();
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
    String? status,
    String? deliveryAddress,
    required int userId,
  }) async {
    final effectiveStatus = status ?? AppLocalizations.current.getString('auto_sobiraetsya');
    if (items.isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_spisok_tovarov_ne_dolzhen_byt_pusty'));
    }
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'status': effectiveStatus,
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
        AppLocalizations.current.getString('auto_neobhodimo_peredat_hotya_by_odno_po'),
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }

    final normalizedCurrentPassword = currentPassword.trim();
    final normalizedNewPassword = newPassword.trim();
    final normalizedConfirmPassword = confirmPassword?.trim();

    if (normalizedCurrentPassword.isEmpty || normalizedNewPassword.isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_tekuschiy_i_novyy_parol_obyazatelny'));
    }
    if (normalizedCurrentPassword.length < 6 ||
        normalizedNewPassword.length < 6) {
      throw ArgumentError(AppLocalizations.current.getString('auto_parol_dolzhen_soderzhat_minimum_6_s'));
    }
    if (normalizedCurrentPassword == normalizedNewPassword) {
      throw ArgumentError(AppLocalizations.current.getString('auto_novyy_parol_dolzhen_otlichatsya_ot'));
    }
    if (normalizedConfirmPassword != null &&
        normalizedConfirmPassword != normalizedNewPassword) {
      throw ArgumentError(AppLocalizations.current.getString('auto_podtverzhdenie_parolya_ne_sovpadaet'));
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

  // Загрузка аватарки пользователя через multipart/form-data.
  // Принимает байты, чтобы работало и на mobile/desktop (через File.readAsBytes),
  // и на Web (через XFile.readAsBytes - dart:io File там недоступен).
  // Возвращает абсолютный URL новой аватарки (или null, если сервер вернул
  // пустую строку). На любой статус вне 200..299 - Exception с телом ответа.
  static Future<String?> uploadAvatar({
    required int userId,
    required List<int> bytes,
    required String filename,
    String? mimeType,
  }) async {
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }

    try {
      // На Web BrowserClient.send не поддерживает streaming body, поэтому
      // MultipartRequest иногда падает с "Failed to fetch". Собираем
      // multipart-тело руками и отправляем как обычный http.post с
      // фиксированным Content-Length - это работает одинаково на всех
      // платформах.
      final boundary =
          '----dart-multipart-${DateTime.now().microsecondsSinceEpoch}';
      final mime = (mimeType == null || mimeType.trim().isEmpty)
          ? 'application/octet-stream'
          : mimeType.trim();
      final safeFilename = filename.replaceAll('"', '');

      final preamble = utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="$safeFilename"\r\n'
        'Content-Type: $mime\r\n'
        '\r\n',
      );
      final epilogue = utf8.encode('\r\n--$boundary--\r\n');

      final body = Uint8List(preamble.length + bytes.length + epilogue.length);
      body.setRange(0, preamble.length, preamble);
      body.setRange(preamble.length, preamble.length + bytes.length, bytes);
      body.setRange(preamble.length + bytes.length, body.length, epilogue);

      final actorId = AuthStorage.userId;
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/avatar'),
        headers: {
          'Content-Type': 'multipart/form-data; boundary=$boundary',
          if (actorId != null) 'X-User-Id': actorId.toString(),
        },
        body: body,
      );
      final responseBody = _decodeBody(response.bodyBytes);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(responseBody);
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final raw = decoded['avatarUrl'];
      if (raw == null) return null;
      final url = raw.toString().trim();
      return url.isEmpty ? null : url;
    } catch (e) {
      debugPrint('Ошибка при загрузке аватарки: $e');
      rethrow;
    }
  }

  // Удаление аватарки пользователя.
  // На любой статус вне 200..299 - Exception с телом ответа.
  static Future<void> deleteAvatar({required int userId}) async {
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }

    try {
      final actorId = AuthStorage.userId;
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/avatar'),
        headers: {if (actorId != null) 'X-User-Id': actorId.toString()},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_decodeBody(response.bodyBytes));
      }
    } catch (e) {
      debugPrint('Ошибка при удалении аватарки: $e');
      rethrow;
    }
  }

  static Future<List<UserAddress>> getUserAddresses({
    required int userId,
  }) async {
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_i_addressid_dolzhny_byt_polo'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_i_addressid_dolzhny_byt_polo'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_orderid_ne_dolzhen_byt_pustym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_orderid_ne_dolzhen_byt_pustym'));
    }
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_productid_ne_dolzhen_byt_pustym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_reviewid_ne_dolzhen_byt_pustym'));
    }
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_reviewid_ne_dolzhen_byt_pustym'));
    }
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_productid_ne_dolzhen_byt_pustym'));
    }
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
          'Не удалось загрузить заказы поставщика: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке заказов поставщика: $e');
      rethrow;
    }
  }

  static Future<SupplierOrder> updateSupplierOrderStatus({
    required String orderId,
    required int userId,
    required String status,
  }) async {
    if (orderId.trim().isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_orderid_ne_dolzhen_byt_pustym'));
    }
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }
    if (status.trim().isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_status_ne_dolzhen_byt_pustym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_productid_ne_dolzhen_byt_pustym'));
    }
    if (moderatorId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_moderatorid_dolzhen_byt_polozhiteln'));
    }
    if (normalizedReason.isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_reason_ne_dolzhen_byt_pustym'));
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
              _keywordsSplitRegExp,
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
      throw ArgumentError(AppLocalizations.current.getString('auto_name_ne_dolzhen_byt_pustym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_id_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_id_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }
    if (chatId != null && chatId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_chatid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }
    if (chatId != null && chatId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_chatid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }
    if (text.trim().isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_text_ne_dolzhen_byt_pustym'));
    }
    if (chatId != null && chatId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_chatid_dolzhen_byt_polozhitelnym'));
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
      // Сервер обычно отдаёт plain-text причину (например, «Чат закрыт. Отправка
      // невозможна» / «Для нового обращения укажите category и subject»),
      // её и показываем - это сильно облегчает диагностику.
      final body = _decodeBody(response.bodyBytes).trim();
      if (body.isNotEmpty) {
        throw Exception(body);
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
      throw ArgumentError(AppLocalizations.current.getString('auto_chatid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_chatid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_chatid_dolzhen_byt_polozhitelnym'));
    }
    if (moderatorId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_moderatorid_dolzhen_byt_polozhiteln'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }
    if (chatId != null && chatId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_chatid_dolzhen_byt_polozhitelnym'));
    }

    final query = <String, String>{'userId': '$userId'};
    if (chatId != null) {
      query['chatId'] = '$chatId';
    }
    final uri = Uri.parse(
      '$baseUrl/support/events',
    ).replace(queryParameters: query);
    return _sharedEventStream(uri, streamLabel: AppLocalizations.current.getString('auto_polzovatel'));
  }

  static Stream<Map<String, dynamic>> moderatorSupportEvents({int? chatId}) {
    if (chatId != null && chatId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_chatid_dolzhen_byt_polozhitelnym'));
    }

    final query = <String, String>{};
    if (chatId != null) {
      query['chatId'] = '$chatId';
    }
    final uri = Uri.parse(
      '$baseUrl/moderation/support/events',
    ).replace(queryParameters: query.isEmpty ? null : query);
    return _sharedEventStream(uri, streamLabel: AppLocalizations.current.getString('auto_moderator'));
  }

  // Мультиплексер SSE-стримов: одна реальная подписка на уникальный URI,
  // все потребители работают через broadcast-стрим. Это критично для web-
  // клиента: Chrome держит максимум 6 одновременных HTTP/1.1 соединений
  // на origin, и без шеринга 3-4 параллельных SSE намертво блокируют все
  // прочие fetch-запросы.

  /// Активные shared-подписки. Ключ - строковое представление URL.
  static final Map<String, _SharedEventStream> _sharedEventStreams = {};

  /// Broadcast-стрим для уникального SSE-URI. Один потребитель открывает
  /// реальное соединение, остальные шарят его через broadcast. Reconnect
  /// и backoff живут внутри _SharedEventStream.
  static Stream<Map<String, dynamic>> _sharedEventStream(
    Uri uri, {
    required String streamLabel,
  }) {
    final key = uri.toString();
    final existing = _sharedEventStreams[key];
    if (existing != null) {
      return existing.controller.stream;
    }

    final shared = _SharedEventStream(uri: uri, streamLabel: streamLabel);
    _sharedEventStreams[key] = shared;
    shared.start(
      onClosed: () {
        // Последний слушатель отписался - удаляем запись из реестра,
        // следующий потребитель откроет свежее соединение.
        _sharedEventStreams.remove(key);
      },
    );
    return shared.controller.stream;
  }

  static Stream<Map<String, dynamic>> _eventStreamFromUri(
    Uri uri, {
    required String streamLabel,
  }) {
    // Делегируем в платформо-зависимую реализацию: на native - стриминг
    // через package:http, на web - нативный EventSource. Conditional
    // import выбирает нужную при компиляции.
    return openSseStream(uri, streamLabel: streamLabel);
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

  /// Экспорт принятых заказов поставщика в Excel за период.
  /// В выгрузку попадают только позиции этого поставщика и только заказы
  /// со статусом «Принят» - симметрично покупательскому экспорту.
  static Future<Uint8List> exportSupplierOrdersExcel({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/export/supplier/orders/excel'),
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
          'Не удалось экспортировать заказы поставщика: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Ошибка при экспорте заказов поставщика: $e');
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
      throw ArgumentError(AppLocalizations.current.getString('auto_productid_ne_dolzhen_byt_pustym'));
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
            AppLocalizations.current.getString('auto_nevernyy_format_otveta_servera_otsu'),
          );
        }

        final questions = decoded['questions'];
        if (questions is! List) {
          throw Exception(
            AppLocalizations.current.getString('auto_nevernyy_format_otveta_servera_ques'),
          );
        }

        final total = decoded['total'];
        if (total is! int) {
          throw Exception(
            AppLocalizations.current.getString('auto_nevernyy_format_otveta_servera_tota'),
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
      throw ArgumentError(AppLocalizations.current.getString('auto_productid_ne_dolzhen_byt_pustym'));
    }
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }
    if (normalizedQuestionText.isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_vopros_ne_dolzhen_byt_pustym'));
    }
    if (normalizedQuestionText.length < 10) {
      throw ArgumentError(AppLocalizations.current.getString('auto_vopros_dolzhen_soderzhat_minimum_10'));
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
      throw Exception(AppLocalizations.current.getString('auto_ne_udalos_otvetit'));
    }
  }

  static Future<Map<String, dynamic>> getSupplierQuestions({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_questionid_ne_dolzhen_byt_pustym'));
    }
    if (supplierUserId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_supplieruserid_dolzhen_byt_polozhit'));
    }
    final normalizedAnswerText = answerText.trim();
    if (normalizedAnswerText.isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_answertext_ne_dolzhen_byt_pustym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_reviewid_ne_dolzhen_byt_pustym'));
    }
    if (supplierUserId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_supplieruserid_dolzhen_byt_polozhit'));
    }
    final normalizedResponseText = responseText.trim();
    if (normalizedResponseText.isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_responsetext_ne_dolzhen_byt_pustym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_reviewid_ne_dolzhen_byt_pustym'));
    }
    if (supplierUserId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_supplieruserid_dolzhen_byt_polozhit'));
    }
    final normalizedResponseText = responseText.trim();
    if (normalizedResponseText.isEmpty) {
      throw ArgumentError(AppLocalizations.current.getString('auto_responsetext_ne_dolzhen_byt_pustym'));
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
  // Выключен - бэкенд реализует /suppliers/{id} эндпоинты.
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
        name: AppLocalizations.current.getString('auto_ooo_optovaya_kompaniya'),
        rating: 4.5,
        reviewCount: 128,
        pricePerUnit: 1500,
        minQuantity: 10,
        maxQuantity: 1000,
        stockQuantity: 500,
        deliveryDate: '2024-01-15',
        deliveryInfo: AppLocalizations.current.getString('auto_dostavka_po_rossii'),
        deliveryBadge: AppLocalizations.current.getString('auto_bystraya_dostavka'),
        logoUrl: 'https://via.placeholder.com/200?text=Supplier123',
        description: AppLocalizations.current.getString('auto_postavschik_kachestvennyh_tovarov_o'),
        address: AppLocalizations.current.getString('auto_g_moskva_ul_primernaya_d_1'),
        phone: '+7 (495) 123-45-67',
        email: 'info@supplier123.ru',
      ),
      'supplier_456': Supplier(
        id: 'supplier_456',
        name: AppLocalizations.current.getString('auto_ooo_torgovyy_dom'),
        rating: 4.2,
        reviewCount: 95,
        pricePerUnit: 2000,
        minQuantity: 5,
        maxQuantity: 500,
        stockQuantity: 300,
        deliveryDate: '2024-01-16',
        deliveryInfo: AppLocalizations.current.getString('auto_dostavka_po_rossii_i_sng'),
        deliveryBadge: AppLocalizations.current.getString('auto_nadzhnyy_partnr'),
        logoUrl: 'https://via.placeholder.com/200?text=Supplier456',
        description: AppLocalizations.current.getString('auto_krupnyy_optovyy_postavschik_s_shiro'),
        address: AppLocalizations.current.getString('auto_g_sanktpeterburg_pr_nevskiy_d_50'),
        phone: '+7 (812) 456-78-90',
        email: 'sales@torgovydom.ru',
      ),
      'supplier_789': Supplier(
        id: 'supplier_789',
        name: AppLocalizations.current.getString('auto_ooo_ekspress_postavki'),
        rating: 4.8,
        reviewCount: 256,
        pricePerUnit: 1200,
        minQuantity: 20,
        maxQuantity: 2000,
        stockQuantity: 1500,
        deliveryDate: '2024-01-14',
        deliveryInfo: AppLocalizations.current.getString('auto_ekspressdostavka_24_chasa'),
        deliveryBadge: AppLocalizations.current.getString('auto_bystraya_dostavka'),
        logoUrl: 'https://via.placeholder.com/200?text=Supplier789',
        description: AppLocalizations.current.getString('auto_spetsializiruemsya_na_bystroy_dosta'),
        address: AppLocalizations.current.getString('auto_g_ekaterinburg_ul_glavnaya_d_100'),
        phone: '+7 (343) 789-01-23',
        email: 'express@dostavka.ru',
      ),
    };

    // Если есть точное совпадение - возвращаем его
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
      deliveryInfo: AppLocalizations.current.getString('auto_dostavka_po_rossii'),
      deliveryBadge: AppLocalizations.current.getString('auto_standartnaya_dostavka'),
      logoUrl: 'https://via.placeholder.com/200?text=$supplierId',
      description: AppLocalizations.current.getString('auto_nadzhnyy_postavschik_optovyh_tovaro'),
      address: AppLocalizations.current.getString('auto_rossiya'),
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
          'name': AppLocalizations.current.getString('auto_tovar_1_ot_postavschika_123'),
          'price': 1500,
          'rating': 4.5,
          'reviewCount': 50,
          'imageUrl': 'https://via.placeholder.com/200?text=Product1',
          'category': AppLocalizations.current.getString('auto_kategoriya_1'),
          'suppliers': [
            {
              'id': 'supplier_123',
              'name': AppLocalizations.current.getString('auto_ooo_optovaya_kompaniya'),
              'rating': 4.5,
              'reviewCount': 128,
              'pricePerUnit': 1500,
              'minQuantity': 10,
              'maxQuantity': 1000,
              'stockQuantity': 500,
              'deliveryDate': '2024-01-15',
              'deliveryInfo': AppLocalizations.current.getString('auto_dostavka_po_rossii'),
              'deliveryBadge': AppLocalizations.current.getString('auto_bystraya_dostavka'),
            },
          ],
        },
        {
          'id': 'product_2',
          'name': AppLocalizations.current.getString('auto_tovar_2_ot_postavschika_123'),
          'price': 2000,
          'rating': 4.2,
          'reviewCount': 30,
          'imageUrl': 'https://via.placeholder.com/200?text=Product2',
          'category': AppLocalizations.current.getString('auto_kategoriya_2'),
          'suppliers': [
            {
              'id': 'supplier_123',
              'name': AppLocalizations.current.getString('auto_ooo_optovaya_kompaniya'),
              'rating': 4.5,
              'reviewCount': 128,
              'pricePerUnit': 2000,
              'minQuantity': 10,
              'maxQuantity': 1000,
              'stockQuantity': 500,
              'deliveryDate': '2024-01-15',
              'deliveryInfo': AppLocalizations.current.getString('auto_dostavka_po_rossii'),
              'deliveryBadge': AppLocalizations.current.getString('auto_bystraya_dostavka'),
            },
          ],
        },
      ],
      'supplier_456': [
        {
          'id': 'product_3',
          'name': AppLocalizations.current.getString('auto_tovar_1_ot_postavschika_456'),
          'price': 2000,
          'rating': 4.2,
          'reviewCount': 40,
          'imageUrl': 'https://via.placeholder.com/200?text=Product3',
          'category': AppLocalizations.current.getString('auto_kategoriya_1'),
          'suppliers': [
            {
              'id': 'supplier_456',
              'name': AppLocalizations.current.getString('auto_ooo_torgovyy_dom'),
              'rating': 4.2,
              'reviewCount': 95,
              'pricePerUnit': 2000,
              'minQuantity': 5,
              'maxQuantity': 500,
              'stockQuantity': 300,
              'deliveryDate': '2024-01-16',
              'deliveryInfo': AppLocalizations.current.getString('auto_dostavka_po_rossii_i_sng'),
              'deliveryBadge': AppLocalizations.current.getString('auto_nadzhnyy_partnr'),
            },
          ],
        },
      ],
      'supplier_789': [
        {
          'id': 'product_4',
          'name': AppLocalizations.current.getString('auto_tovar_1_ot_postavschika_789'),
          'price': 1200,
          'rating': 4.8,
          'reviewCount': 100,
          'imageUrl': 'https://via.placeholder.com/200?text=Product4',
          'category': AppLocalizations.current.getString('auto_kategoriya_1'),
          'suppliers': [
            {
              'id': 'supplier_789',
              'name': AppLocalizations.current.getString('auto_ooo_ekspress_postavki'),
              'rating': 4.8,
              'reviewCount': 256,
              'pricePerUnit': 1200,
              'minQuantity': 20,
              'maxQuantity': 2000,
              'stockQuantity': 1500,
              'deliveryDate': '2024-01-14',
              'deliveryInfo': AppLocalizations.current.getString('auto_ekspressdostavka_24_chasa'),
              'deliveryBadge': AppLocalizations.current.getString('auto_bystraya_dostavka'),
            },
          ],
        },
        {
          'id': 'product_5',
          'name': AppLocalizations.current.getString('auto_tovar_2_ot_postavschika_789'),
          'price': 1800,
          'rating': 4.6,
          'reviewCount': 80,
          'imageUrl': 'https://via.placeholder.com/200?text=Product5',
          'category': AppLocalizations.current.getString('auto_kategoriya_2'),
          'suppliers': [
            {
              'id': 'supplier_789',
              'name': AppLocalizations.current.getString('auto_ooo_ekspress_postavki'),
              'rating': 4.8,
              'reviewCount': 256,
              'pricePerUnit': 1800,
              'minQuantity': 20,
              'maxQuantity': 2000,
              'stockQuantity': 1500,
              'deliveryDate': '2024-01-14',
              'deliveryInfo': AppLocalizations.current.getString('auto_ekspressdostavka_24_chasa'),
              'deliveryBadge': AppLocalizations.current.getString('auto_bystraya_dostavka'),
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
      throw ArgumentError(AppLocalizations.current.getString('auto_supplierid_ne_dolzhen_byt_pustym'));
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/suppliers/$normalizedId'))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(AppLocalizations.current.getString('auto_vremya_ozhidaniya_isteklo')),
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
        throw Exception(AppLocalizations.current.getString('auto_postavschik_ne_nayden'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_supplierid_ne_dolzhen_byt_pustym'));
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
            onTimeout: () => throw Exception(AppLocalizations.current.getString('auto_vremya_ozhidaniya_isteklo')),
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
        throw Exception(AppLocalizations.current.getString('auto_postavschik_ne_nayden'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
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

  /// Загружает счётчики уведомлений, собирая данные из существующих
  /// эндпоинтов параллельно. role - роль пользователя для фильтрации запросов.
  static Future<NotificationCounts> getNotificationCounts({
    required int userId,
    String role = '',
  }) async {
    if (userId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_userid_dolzhen_byt_polozhitelnym'));
    }

    // Любая роль может быть покупателем - фильтруем по роли только модерационный запрос.
    final futures = await Future.wait([
      _fetchUnreadMessagesCount(userId),
      _fetchPendingOrdersCount(userId),
      role == 'supplier'
          ? _fetchPendingSupplierOrdersCount(userId)
          : Future.value(0),
      _fetchPendingReviewsCount(userId),
      role == 'supplier' || role == 'moderator' || role == 'super_admin'
          ? _fetchPendingModerationsCount()
          : Future.value(0),
      _fetchDeliveredOrdersCount(userId),
    ]);

    return NotificationCounts(
      unreadMessages: futures[0],
      pendingBuyerOrders: futures[1],
      pendingSupplierOrders: futures[2],
      pendingReviews: futures[3],
      pendingModerations: futures[4],
      deliveredOrders: futures[5],
    );
  }

  /// Считает открытые чаты поддержки, где последнее сообщение от модератора
  /// (т.е. пользователь ещё не ответил - есть что прочитать).
  static Future<int> _fetchUnreadMessagesCount(int userId) async {
    try {
      final thread = await getSupportThread(userId: userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception(AppLocalizations.current.getString('auto_taymaut')),
      );
      if (thread.chat == null || !thread.chat!.isOpen) return 0;
      // Если последнее сообщение от модератора - значит пользователь не ответил
      if (thread.messages.isEmpty) return 0;
      final lastMsg = thread.messages.last;
      return lastMsg.isFromModerator ? 1 : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Считает покупательские заказы со статусом «В пути» - те, что ждут действия покупателя.
  static Future<int> _fetchPendingOrdersCount(int userId) async {
    try {
      final orders = await getOrders(userId: userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception(AppLocalizations.current.getString('auto_taymaut')),
      );
      return orders.where((o) => isInTransitStatus(o.status)).length;
    } catch (_) {
      return 0;
    }
  }

  /// Заказ в пути к покупателю.
  @visibleForTesting
  static bool isInTransitStatus(String status) {
    final s = status.trim().toLowerCase();
    return s == AppLocalizations.current.getString('auto_v_puti') ||
        s == 'in transit' ||
        s == 'in_transit' ||
        s == 'shipped' ||
        s == 'on the way' ||
        s == AppLocalizations.current.getString('auto_otpravlen') ||
        s == AppLocalizations.current.getString('auto_otpravleno');
  }

  /// Считает заказы поставщика, ожидающие действия:
  /// заказы со статусом AppLocalizations.current.getString('auto_sobiraetsya') / AppLocalizations.current.getString('auto_v_puti_1') / etc.
  /// (не завершённые покупателем и не отменённые).
  /// Использует /supplier/orders, а не /orders - это разные эндпоинты.
  static Future<int> _fetchPendingSupplierOrdersCount(int userId) async {
    try {
      final orders = await getSupplierOrders(userId: userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception(AppLocalizations.current.getString('auto_taymaut')),
      );
      return orders.where((o) {
        final s = o.status.trim().toLowerCase();
        // AppLocalizations.current.getString('auto_prinyat') покупателем = заказ закрыт для поставщика
        final isDone =
            s == AppLocalizations.current.getString('auto_dostavlen') ||
            s == AppLocalizations.current.getString('auto_polucheno') ||
            s == 'delivered' ||
            s == AppLocalizations.current.getString('auto_prinyat_1') ||
            s == AppLocalizations.current.getString('auto_prinyata') ||
            s == AppLocalizations.current.getString('auto_prinyato') ||
            s == AppLocalizations.current.getString('auto_prinyaty') ||
            s == 'accepted' ||
            s == 'received' ||
            s == AppLocalizations.current.getString('auto_zaversheno') ||
            s == 'completed';
        final isCancelled =
            s.contains(AppLocalizations.current.getString('auto_otmena')) ||
            s == 'cancelled' ||
            s == AppLocalizations.current.getString('auto_otmenn') ||
            s == AppLocalizations.current.getString('auto_otmenen');
        return !isDone && !isCancelled;
      }).length;
    } catch (_) {
      return 0;
    }
  }

  /// Считает доставленные заказы покупателя, которые ещё не подтверждены как полученные.
  /// Статус AppLocalizations.current.getString('auto_dostavlen_1') означает, что товар привезли, но покупатель ещё не нажал AppLocalizations.current.getString('auto_poluchil').
  static Future<int> _fetchDeliveredOrdersCount(int userId) async {
    try {
      final orders = await getOrders(userId: userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception(AppLocalizations.current.getString('auto_taymaut')),
      );
      return orders.where((o) {
        final s = o.status.trim().toLowerCase();
        return s == AppLocalizations.current.getString('auto_dostavlen') || s == 'delivered';
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
        onTimeout: () => throw Exception(AppLocalizations.current.getString('auto_taymaut')),
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
        onTimeout: () => throw Exception(AppLocalizations.current.getString('auto_taymaut')),
      );
      return products.length;
    } catch (_) {
      return 0;
    }
  }

  /// Отмечает сообщение поддержки как прочитанное.
  /// Бэкенд не поддерживает этот эндпоинт - счётчик обновляется локально в NotificationService.
  static Future<void> markMessageAsRead({
    required int userId,
    required int messageId,
  }) async {
    // no-op: отдельного эндпоинта нет, локальное уменьшение счётчика делает NotificationService
  }

  /// Отмечает заказ как просмотренный.
  /// Бэкенд не поддерживает этот эндпоинт - счётчик обновляется локально в NotificationService.
  static Future<void> markOrderAsReviewed({
    required int userId,
    required String orderId,
  }) async {
    // no-op: отдельного эндпоинта нет, локальное уменьшение счётчика делает NotificationService
  }

  /// Скрывает уведомление определённого типа.
  /// Бэкенд не поддерживает этот эндпоинт - счётчик обновляется локально в NotificationService.
  static Future<void> dismissNotification({
    required int userId,
    required String notificationType,
  }) async {
    // no-op: отдельного эндпоинта нет, локальное уменьшение счётчика делает NotificationService
  }

  // Управление модераторами (доступно только Super_Admin)

  /// Заголовки для эндпоинтов /admin/moderators*. Вшивает X-User-Id
  /// текущего пользователя из AuthStorage. Бросает StateError, если
  /// пользователь не авторизован - это позволяет UI отличать «нет сессии»
  /// от ответа сервера 401.
  static Map<String, String> _superAdminHeaders() {
    final id = AuthStorage.userId;
    if (id == null || id <= 0) {
      throw StateError(AppLocalizations.current.getString('auto_ne_avtorizovan'));
    }
    return {
      'content-type': 'application/json; charset=utf-8',
      'X-User-Id': id.toString(),
    };
  }

  /// Возвращает список модераторов. Только для Super_Admin.
  static Future<List<Moderator>> getModerators() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/moderators'),
        headers: _superAdminHeaders(),
      );

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is! List) {
          return const <Moderator>[];
        }
        return decoded
            .whereType<Map>()
            .map((e) => Moderator.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      final errorMessage = _extractResponseErrorMessage(response);
      throw Exception(
        errorMessage ??
            'Не удалось загрузить модераторов: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Ошибка при загрузке модераторов: $e');
      rethrow;
    }
  }

  /// Создаёт нового модератора. Только для Super_Admin.
  static Future<Moderator> createModerator({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/moderators'),
        headers: _superAdminHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          return Moderator.fromJson(Map<String, dynamic>.from(decoded));
        }
        throw Exception(AppLocalizations.current.getString('auto_server_vernul_nekorrektnyy_otvet'));
      }

      final errorMessage = _extractResponseErrorMessage(response);
      throw Exception(
        errorMessage ?? 'Не удалось создать модератора: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Ошибка при создании модератора: $e');
      rethrow;
    }
  }

  /// Удаляет модератора по идентификатору. Только для Super_Admin.
  static Future<void> deleteModerator({required int id}) async {
    if (id <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_id_dolzhen_byt_polozhitelnym'));
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/moderators/$id'),
        headers: _superAdminHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      final errorMessage = _extractResponseErrorMessage(response);
      throw Exception(
        errorMessage ?? 'Не удалось удалить модератора: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Ошибка при удалении модератора: $e');
      rethrow;
    }
  }

  // Каталог поставщиков и find-or-create support-чата с пользователем.
  // Используется со страницы «Чаты техподдержки» модератора.

  /// Каталог поставщиков для модератора. Сервер ищет по query (case-insensitive
  /// substring) и сортирует по companyName ASC.
  static Future<SupplierDirectoryPage> getSuppliersDirectory({
    required int offset,
    required int limit,
    String? query,
  }) async {
    if (offset < 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_offset_ne_dolzhen_byt_otritsatelnym'));
    }
    if (limit <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_limit_dolzhen_byt_polozhitelnym'));
    }

    const endpoint = '/moderation/suppliers';
    try {
      final params = <String, String>{
        'offset': offset.toString(),
        'limit': limit.toString(),
      };
      final actorId = AuthStorage.userId;
      if (actorId != null && actorId > 0) {
        params['userId'] = actorId.toString();
      }
      final trimmedQuery = query?.trim();
      if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
        params['query'] = trimmedQuery;
      }

      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: params);
      final response = await http.get(uri);

      await _logApiResponse(response, endpoint: endpoint, method: 'GET');

      if (response.statusCode == 200) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          return SupplierDirectoryPage.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
        throw Exception(AppLocalizations.current.getString('auto_server_vernul_nekorrektnyy_otvet'));
      }

      throw Exception(
        'Не удалось загрузить каталог поставщиков: ${response.statusCode}',
      );
    } catch (e, stack) {
      await _logApiError(e, stack, endpoint: endpoint, method: 'GET');
      debugPrint('Ошибка при загрузке каталога поставщиков: $e');
      rethrow;
    }
  }

  /// Открывает support-чат с пользователем. Возвращает существующий
  /// открытый чат, либо создаёт новый. peek=true не создаёт чат - вернёт
  /// null, если открытого нет; нужно UI'у для диалога «Создать чат?».
  static Future<SupportChat?> findOrCreateModeratorSupportChatWithUser({
    required int moderatorId,
    required int targetUserId,
    bool peek = false,
  }) async {
    if (moderatorId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_moderatorid_dolzhen_byt_polozhiteln'));
    }
    if (targetUserId <= 0) {
      throw ArgumentError(AppLocalizations.current.getString('auto_targetuserid_dolzhen_byt_polozhitel'));
    }

    const endpoint = '/moderation/support/chats/find-or-create';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'moderatorId': moderatorId,
          'userId': targetUserId,
          if (peek) 'peek': true,
        }),
      );

      await _logApiResponse(
        response,
        endpoint: endpoint,
        method: 'POST',
        // peek-режим: 404 - валидное состояние «открытого чата нет».
        silentForStatus: peek ? const {404} : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _decodeBody(response.bodyBytes);
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        return SupportChat.fromJson(decoded);
      }

      // peek=true и 404 - нормальный путь.
      if (peek && response.statusCode == 404) {
        return null;
      }

      throw Exception(
        'Не удалось открыть чат с пользователем: ${response.statusCode}',
      );
    } catch (e, stack) {
      await _logApiError(e, stack, endpoint: endpoint, method: 'POST');
      debugPrint('Ошибка при find-or-create support-чата: $e');
      rethrow;
    }
  }
}

/// Один реальный SSE-запрос на уникальный URI, обёрнутый в broadcast-стрим.
/// Reconnect - экспоненциальный backoff min(2 × n, 12) секунд. Освобождает
/// ресурсы, когда последний слушатель отписался.
class _SharedEventStream {
  _SharedEventStream({required this.uri, required this.streamLabel});

  final Uri uri;
  final String streamLabel;

  late final StreamController<Map<String, dynamic>> controller;
  StreamSubscription<Map<String, dynamic>>? _innerSub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  VoidCallback? _onClosed;

  void start({required VoidCallback onClosed}) {
    _onClosed = onClosed;
    controller = StreamController<Map<String, dynamic>>.broadcast(
      onListen: _maybeConnect,
      onCancel: _maybeDispose,
    );
  }

  void _maybeConnect() {
    if (_disposed) return;
    if (_innerSub != null) return;
    _innerSub = ApiService._eventStreamFromUri(uri, streamLabel: streamLabel)
        .listen(
          (event) {
            // Любой кадр сбрасывает счётчик попыток.
            _reconnectAttempt = 0;
            if (!controller.isClosed) controller.add(event);
          },
          onError: (Object e, StackTrace st) {
            _scheduleReconnect();
          },
          onDone: _scheduleReconnect,
          cancelOnError: true,
        );
  }

  void _scheduleReconnect() {
    _innerSub?.cancel();
    _innerSub = null;
    if (_disposed) return;
    if (!controller.hasListener) return;

    _reconnectAttempt += 1;
    if (_reconnectAttempt > 6) _reconnectAttempt = 6;
    final delay = Duration(seconds: _reconnectAttempt * 2);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_disposed) return;
      if (!controller.hasListener) return;
      _maybeConnect();
    });
  }

  void _maybeDispose() {
    // Все подписчики отписались - закрываем реальный стрим и таймер.
    if (controller.hasListener) return;
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _innerSub?.cancel();
    _innerSub = null;
    _onClosed?.call();
    controller.close();
  }
}

/// Модель модератора для UI и клиентского API.
class Moderator {
  final int id;
  final String name;
  final String email;
  final String phone;

  const Moderator({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory Moderator.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    return Moderator(
      id: id,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}
