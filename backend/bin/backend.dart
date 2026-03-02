import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:postgres/postgres.dart';

part 'schema_tables.dart';
part 'crud_operations.dart';

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

double _toNonNegativeDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) {
    return fallback;
  }
  if (value is double) {
    return value < 0 ? fallback : value;
  }
  if (value is int) {
    return value < 0 ? fallback : value.toDouble();
  }
  final parsed = double.tryParse(value.toString());
  if (parsed == null || parsed < 0) {
    return fallback;
  }
  return parsed;
}

DateTime? _toNullableDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String _toIso8601OrNow(dynamic value) {
  final parsed = _toNullableDateTime(value);
  return (parsed ?? DateTime.now()).toIso8601String();
}

const String _defaultRole = 'buyer';
const String _moderatorCode = 'MOD123';
const Set<String> _allowedRoles = {'buyer', 'supplier', 'moderator'};
const Set<String> _allowedSupportChatStatuses = {'open', 'closed'};
const Set<String> _allowedModerationStatuses = {
  'pending',
  'approved',
  'rejected',
};
const String _cancelledOrderStatus = 'Отменен';
const Duration _orderCancellationWindow = Duration(hours: 1);
const Set<String> _acceptedOrderStatuses = {
  'принят',
  'принята',
  'принято',
  'приняты',
  'accepted',
  'received',
};
const String _supplierOrderStatusAssembling = 'Собирается';
const String _supplierOrderStatusInTransit = 'В пути';
const String _supplierOrderStatusDelivered = 'Доставлен';
const Set<String> _allowedAddressLabels = {'home', 'work', 'other'};
const int _addressLineMaxLength = 500;
const int _streetMaxLength = 100;
const int _zipMaxLength = 10;
const int _apartmentMaxLength = 20;
const int _postgresIntMaxValue = 2147483647;
const double _numeric10Scale2Bound = 100000000.0;
const double _numeric10Scale2MaxValue = 99999999.99;
final RegExp _zipPattern = RegExp(r'^\d{3,10}$');
final RegExp _apartmentPattern = RegExp(r'^[0-9A-Za-z\u0400-\u04FF /-]+$');
const Map<String, String> _utf8TextHeaders = {
  'content-type': 'text/plain; charset=utf-8',
};
final StreamController<Map<String, dynamic>> _supportEventsController =
    StreamController<Map<String, dynamic>>.broadcast();

String _normalizeRole(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return _defaultRole;
  if (_allowedRoles.contains(raw)) return raw;
  return _defaultRole;
}

String _supplierNameForRole(Object? role, Object? supplierName) {
  if (_normalizeRole(role) != 'supplier') {
    return '';
  }
  return supplierName?.toString() ?? '';
}

void _emitSupportEvent({
  required String kind,
  required int userId,
  int? chatId,
  int? messageId,
  String? senderRole,
  String? reason,
  int? actorUserId,
}) {
  if (_supportEventsController.isClosed) return;

  final event = <String, dynamic>{
    'kind': kind,
    'userId': userId,
    if (chatId != null && chatId > 0) 'chatId': chatId,
    if (messageId != null && messageId > 0) 'messageId': messageId,
    if (senderRole != null && senderRole.isNotEmpty) 'senderRole': senderRole,
    if (reason != null && reason.isNotEmpty) 'reason': reason,
    if (actorUserId != null && actorUserId > 0) 'actorUserId': actorUserId,
    'timestamp': DateTime.now().toIso8601String(),
  };
  _supportEventsController.add(event);
}

Response _buildSupportEventsResponse({
  required String scope,
  required bool Function(Map<String, dynamic>) filter,
}) {
  final controller = StreamController<List<int>>();
  StreamSubscription<Map<String, dynamic>>? subscription;
  Timer? keepAlive;
  var closed = false;

  void pushFrame(String payload, {String event = 'support'}) {
    if (closed) return;
    final buffer = StringBuffer();
    if (event.isNotEmpty) {
      buffer.writeln('event: $event');
    }
    for (final line in payload.split('\n')) {
      buffer.writeln('data: $line');
    }
    buffer.writeln();
    controller.add(utf8.encode(buffer.toString()));
  }

  Future<void> shutdown() async {
    if (closed) return;
    closed = true;
    keepAlive?.cancel();
    await subscription?.cancel();
    await controller.close();
  }

  controller.onListen = () {
    pushFrame(
      jsonEncode({
        'kind': 'connected',
        'scope': scope,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      event: 'connected',
    );

    subscription = _supportEventsController.stream.listen(
      (event) {
        if (!filter(event)) return;
        pushFrame(jsonEncode(event));
      },
      onError: (_) {
        if (!closed) {
          controller.add(utf8.encode(': stream-error\n\n'));
        }
      },
    );

    keepAlive = Timer.periodic(const Duration(seconds: 20), (_) {
      if (closed) return;
      controller.add(utf8.encode(': keep-alive\n\n'));
    });
  };

  controller.onCancel = shutdown;

  return Response.ok(
    controller.stream,
    headers: {
      'content-type': 'text/event-stream; charset=utf-8',
      'cache-control': 'no-cache',
      'connection': 'keep-alive',
      'x-accel-buffering': 'no',
    },
  );
}

String _normalizeSupportSenderRole(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == 'moderator') {
    return 'moderator';
  }
  return 'user';
}

String _normalizeSupportChatStatus(Object? value, {String fallback = 'open'}) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return fallback;
  if (_allowedSupportChatStatuses.contains(raw)) return raw;
  return fallback;
}

String _normalizeModerationStatus(
  Object? value, {
  String fallback = 'pending',
}) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return fallback;
  if (_allowedModerationStatuses.contains(raw)) return raw;
  return fallback;
}

bool _isAcceptedOrderStatus(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return false;
  return _acceptedOrderStatuses.contains(raw);
}

bool _isCancelledOrderStatus(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return false;
  return raw.contains('отмен') ||
      raw.contains('отмена') ||
      raw == 'canceled' ||
      raw == 'cancelled';
}

String? _normalizeSupplierOrderStatus(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  if (raw.contains('собира') ||
      raw.contains("собира") ||
      raw == "assembling" ||
      raw == "processing") {
    return _supplierOrderStatusAssembling;
  }
  if (raw.contains('в пути') ||
      raw.contains("в пути") ||
      raw == "in transit" ||
      raw == "on the way") {
    return _supplierOrderStatusInTransit;
  }
  if (raw.contains('достав') || raw.contains("достав") || raw == "delivered") {
    return _supplierOrderStatusDelivered;
  }
  return null;
}

int _supplierOrderStatusStep(Object? value) {
  final normalized = _normalizeSupplierOrderStatus(value);
  if (normalized == _supplierOrderStatusAssembling) return 0;
  if (normalized == _supplierOrderStatusInTransit) return 1;
  if (normalized == _supplierOrderStatusDelivered) return 2;
  if (_isAcceptedOrderStatus(value)) return 3;
  return -1;
}

bool _canSupplierUpdateOrderStatus(Object? currentStatus, String nextStatus) {
  final currentStep = _supplierOrderStatusStep(currentStatus);
  final nextStep = _supplierOrderStatusStep(nextStatus);
  if (nextStep < 0 || nextStep > 2) {
    return false;
  }
  if (currentStep < 0) {
    return true;
  }
  if (currentStep >= 3) {
    return false;
  }
  if (nextStep == currentStep) {
    return true;
  }
  return nextStep == currentStep + 1;
}

String _normalizeAddressLabel(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return 'other';
  final lower = raw.toLowerCase();
  if (_allowedAddressLabels.contains(lower)) return lower;
  return raw;
}

String _normalizeAddressText(Object? value, {bool collapseWhitespaces = true}) {
  if (value == null) {
    return '';
  }
  final trimmed = value.toString().trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (!collapseWhitespaces) {
    return trimmed;
  }
  return trimmed.replaceAll(RegExp(r'\s+'), ' ');
}

String? _normalizeOptionalAddressText(
  Object? value, {
  bool collapseWhitespaces = true,
}) {
  final normalized = _normalizeAddressText(
    value,
    collapseWhitespaces: collapseWhitespaces,
  );
  if (normalized.isEmpty) {
    return null;
  }
  return normalized;
}

class _AddressPayload {
  final String label;
  final String addressLine;
  final String? street;
  final String? zip;
  final String? apartment;

  const _AddressPayload({
    required this.label,
    required this.addressLine,
    required this.street,
    required this.zip,
    required this.apartment,
  });
}

_AddressPayload _normalizeAddressPayload(Map<String, dynamic> payload) {
  return _AddressPayload(
    label: _normalizeAddressLabel(payload['label']),
    addressLine: _normalizeAddressText(payload['addressLine']),
    street: _normalizeOptionalAddressText(payload['street']),
    zip: _normalizeOptionalAddressText(
      payload['zip'],
      collapseWhitespaces: false,
    ),
    apartment: _normalizeOptionalAddressText(
      payload['apartment'],
      collapseWhitespaces: false,
    ),
  );
}

String? _validateAddressPayload(_AddressPayload payload) {
  if (payload.label.length > 50) {
    return 'Название адреса не должно превышать 50 символов.';
  }

  if (payload.addressLine.isEmpty) {
    return 'Поле адреса обязательно.';
  }
  if (payload.addressLine.length < 5) {
    return 'Адрес слишком короткий (минимум 5 символов).';
  }
  if (payload.addressLine.length > _addressLineMaxLength) {
    return 'Поле адреса не должно превышать $_addressLineMaxLength символов.';
  }

  final street = payload.street;
  if (street != null && street.length > _streetMaxLength) {
    return 'Поле "Улица" не должно превышать $_streetMaxLength символов.';
  }

  final zip = payload.zip;
  if (zip != null && zip.length > _zipMaxLength) {
    return 'Индекс не должен превышать $_zipMaxLength символов.';
  }
  if (zip != null && !_zipPattern.hasMatch(zip)) {
    return 'Индекс должен содержать только цифры (от 3 до 10).';
  }

  final apartment = payload.apartment;
  if (apartment != null && apartment.length > _apartmentMaxLength) {
    return 'Поле "Квартира/офис" не должно превышать $_apartmentMaxLength символов.';
  }
  if (apartment != null && !_apartmentPattern.hasMatch(apartment)) {
    return 'Поле "Квартира/офис" содержит недопустимые символы.';
  }

  return null;
}

String? _validateSupplierProductPayload({
  required int pricePerUnit,
  required int minQuantity,
  required int? maxQuantity,
  required int stockQuantity,
  required double nutritionCalories,
  required double nutritionProtein,
  required double nutritionFat,
  required double nutritionCarbohydrates,
}) {
  if (pricePerUnit <= 0) {
    return 'Цена за единицу должна быть больше 0.';
  }
  if (pricePerUnit > _postgresIntMaxValue) {
    return 'Цена за единицу не должна превышать $_postgresIntMaxValue.';
  }

  if (minQuantity <= 0) {
    return 'Минимальное количество должно быть больше 0.';
  }
  if (minQuantity > _postgresIntMaxValue) {
    return 'Минимальное количество не должно превышать $_postgresIntMaxValue.';
  }

  if (maxQuantity != null) {
    if (maxQuantity <= 0) {
      return 'Максимальное количество должно быть больше 0.';
    }
    if (maxQuantity > _postgresIntMaxValue) {
      return 'Максимальное количество не должно превышать $_postgresIntMaxValue.';
    }
    if (maxQuantity < minQuantity) {
      return 'Максимальное количество не может быть меньше минимального.';
    }
  }

  if (stockQuantity < 0) {
    return 'Остаток на складе не может быть отрицательным.';
  }
  if (stockQuantity > _postgresIntMaxValue) {
    return 'Остаток на складе не должен превышать $_postgresIntMaxValue.';
  }
  if (stockQuantity > 0 && stockQuantity < minQuantity) {
    return 'Остаток на складе не может быть меньше минимального количества.';
  }

  final caloriesError = _validateNumeric10Scale2Field(
    value: nutritionCalories,
    fieldLabel: 'Калории',
  );
  if (caloriesError != null) {
    return caloriesError;
  }

  final proteinError = _validateNumeric10Scale2Field(
    value: nutritionProtein,
    fieldLabel: 'Белки',
  );
  if (proteinError != null) {
    return proteinError;
  }

  final fatError = _validateNumeric10Scale2Field(
    value: nutritionFat,
    fieldLabel: 'Жиры',
  );
  if (fatError != null) {
    return fatError;
  }

  final carbohydratesError = _validateNumeric10Scale2Field(
    value: nutritionCarbohydrates,
    fieldLabel: 'Углеводы',
  );
  if (carbohydratesError != null) {
    return carbohydratesError;
  }

  return null;
}

String? _validateNumeric10Scale2Field({
  required double value,
  required String fieldLabel,
}) {
  if (!value.isFinite || value < 0) {
    return 'Поле "$fieldLabel" должно быть неотрицательным числом.';
  }

  final roundedToScale = (value * 100).round() / 100;
  if (roundedToScale >= _numeric10Scale2Bound) {
    return 'Поле "$fieldLabel" превышает допустимый предел NUMERIC(10,2): максимум $_numeric10Scale2MaxValue.';
  }

  return null;
}

String? _supplierProductDbConstraintMessage(Object error) {
  final text = error.toString().toLowerCase();
  if (!text.contains('22003') || !text.contains('numeric')) {
    return null;
  }
  return 'Одно из числовых полей превышает допустимый предел NUMERIC(10,2): максимум $_numeric10Scale2MaxValue.';
}

String? _supplierProductDeleteConstraintMessage(Object error) {
  final text = error.toString().toLowerCase();
  final isForeignKeyViolation =
      text.contains('23503') || text.contains('foreign key');
  if (!isForeignKeyViolation) {
    return null;
  }

  if (
    text.contains('fk_order_items_product_id') ||
    text.contains('fk_reviews_product_id') ||
    text.contains('order_items_product_id_fkey') ||
    text.contains('reviews_product_id_fkey')
  ) {
    return 'Нельзя удалить товар: он уже участвует в заказах или отзывах.';
  }

  return 'Нельзя удалить товар из-за связанных записей.';
}

Map<String, dynamic> _productRowToModerationDto(Map<String, dynamic> map) {
  final categories = _parseCategories(map['category']);
  final imageUrls = _parseImageUrls(map['image_url']);
  final characteristics = _parseCharacteristics(map['characteristics']);
  final stockQuantity = _toPositiveInt(
    map['stock_quantity'] ?? map['max_quantity'],
  );
  return {
    'id': (map['id'] ?? '').toString(),
    'name': map['name'] ?? '',
    'description': map['description'] ?? '',
    'categories': categories,
    'imageUrls': imageUrls,
    'pricePerUnit': map['price_per_unit'] ?? 0,
    'minQuantity': map['min_quantity'] ?? 1,
    'maxQuantity': _toNullablePositiveInt(map['max_quantity']),
    'stockQuantity': stockQuantity,
    'supplierName': map['supplier_name'] ?? '',
    'deliveryDate': map['delivery_date'] ?? '',
    'deliveryBadge': map['delivery_badge'] ?? '',
    'ingredients': map['ingredients'] ?? '',
    'nutritionalInfo': {
      'calories': _toNonNegativeDouble(map['nutrition_calories']),
      'protein': _toNonNegativeDouble(map['nutrition_protein']),
      'fat': _toNonNegativeDouble(map['nutrition_fat']),
      'carbohydrates': _toNonNegativeDouble(map['nutrition_carbohydrates']),
    },
    'characteristics': characteristics,
    'moderationStatus': map['moderation_status'] ?? 'approved',
    'moderationComment': map['moderation_comment'] ?? '',
    'supplierUserId': map['supplier_user_id'],
  };
}

Map<String, dynamic> _addressRowToDto(Map<String, dynamic> map) {
  final createdAt = map['created_at'];
  String? createdAtIso;
  if (createdAt is DateTime) {
    createdAtIso = createdAt.toIso8601String();
  }
  return {
    'id': map['id'],
    'userId': map['user_id'],
    'label': map['label'] ?? '',
    'addressLine': map['address_line'] ?? '',
    'street': map['street'] ?? '',
    'zip': map['zip'] ?? '',
    'apartment': map['apartment'] ?? '',
    if (createdAtIso != null) 'createdAt': createdAtIso,
  };
}

Map<String, dynamic> _reviewRowToDto(Map<String, dynamic> map) {
  String? createdAtIso;
  final createdAt = map['created_at'];
  if (createdAt is DateTime) {
    createdAtIso = createdAt.toIso8601String();
  }

  return {
    'id': map['id']?.toString() ?? '',
    'orderId': map['order_id']?.toString() ?? '',
    'orderItemId': map['order_item_id']?.toString() ?? '',
    'productId': map['product_id']?.toString() ?? '',
    'productName': map['product_name'] ?? map['order_item_name'] ?? '',
    'productImage': map['product_image'] ?? map['order_item_image'] ?? '',
    'rating': map['rating'] ?? 0,
    'reviewText': map['review_text'] ?? '',
    'reviewerName': map['reviewer_name'] ?? '',
    if (createdAtIso != null) 'createdAt': createdAtIso,
  };
}

Map<String, dynamic> _supportChatRowToDto(Map<String, dynamic> map) {
  String? createdAtIso;
  String? updatedAtIso;
  String? closedAtIso;

  final createdAt = map['created_at'];
  if (createdAt is DateTime) {
    createdAtIso = createdAt.toIso8601String();
  }

  final updatedAt = map['updated_at'];
  if (updatedAt is DateTime) {
    updatedAtIso = updatedAt.toIso8601String();
  }

  final closedAt = map['closed_at'];
  if (closedAt is DateTime) {
    closedAtIso = closedAt.toIso8601String();
  }

  return {
    'id': _toPositiveInt(map['id']),
    'userId': _toPositiveInt(map['user_id']),
    'status': _normalizeSupportChatStatus(map['status']),
    'category': map['category'] ?? '',
    'subject': map['subject'] ?? '',
    'closeReason': map['close_reason'] ?? '',
    'closedByUserId': _toNullablePositiveInt(map['closed_by_user_id']),
    if (createdAtIso != null) 'createdAt': createdAtIso,
    if (updatedAtIso != null) 'updatedAt': updatedAtIso,
    if (closedAtIso != null) 'closedAt': closedAtIso,
  };
}

Map<String, dynamic> _supportMessageRowToDto(Map<String, dynamic> map) {
  String? createdAtIso;
  final createdAt = map['created_at'];
  if (createdAt is DateTime) {
    createdAtIso = createdAt.toIso8601String();
  }

  return {
    'id': map['id']?.toString() ?? '',
    'chatId': _toPositiveInt(map['chat_id']),
    'userId': _toPositiveInt(map['user_id']),
    'senderRole': _normalizeSupportSenderRole(map['sender_role']),
    'senderUserId': _toNullablePositiveInt(map['sender_user_id']),
    'category': map['category'] ?? '',
    'subject': map['subject'] ?? '',
    'text': map['message_text'] ?? '',
    if (createdAtIso != null) 'createdAt': createdAtIso,
  };
}

Future<List<Map<String, dynamic>>> _loadSupportMessagesByChat(
  Connection connection,
  int chatId,
) async {
  final result = await connection.execute(
    Sql.named('''
      SELECT *
      FROM support_messages
      WHERE chat_id = @chat_id
      ORDER BY id ASC;
    '''),
    parameters: {'chat_id': chatId},
  );
  return result
      .map((row) => _supportMessageRowToDto(row.toColumnMap()))
      .toList();
}

Future<Map<String, dynamic>?> _loadSupportChatById(
  Connection connection,
  int chatId, {
  int? userId,
}) async {
  final result = userId == null
      ? await connection.execute(
          Sql.named('''
            SELECT *
            FROM support_chats
            WHERE id = @chat_id
            LIMIT 1;
          '''),
          parameters: {'chat_id': chatId},
        )
      : await connection.execute(
          Sql.named('''
            SELECT *
            FROM support_chats
            WHERE id = @chat_id
              AND user_id = @user_id
            LIMIT 1;
          '''),
          parameters: {'chat_id': chatId, 'user_id': userId},
        );
  if (result.isEmpty) return null;
  return result.first.toColumnMap();
}

Future<Map<String, dynamic>?> _loadPreferredSupportChatForUser(
  Connection connection,
  int userId, {
  int? chatId,
}) async {
  if (chatId != null && chatId > 0) {
    return _loadSupportChatById(connection, chatId, userId: userId);
  }

  final result = await connection.execute(
    Sql.named('''
      SELECT *
      FROM support_chats
      WHERE user_id = @user_id
      ORDER BY
        CASE WHEN status = 'open' THEN 0 ELSE 1 END ASC,
        updated_at DESC,
        id DESC
      LIMIT 1;
    '''),
    parameters: {'user_id': userId},
  );
  if (result.isEmpty) return null;
  return result.first.toColumnMap();
}

Future<Map<String, dynamic>> _loadSupportThreadForUser(
  Connection connection,
  int userId, {
  int? chatId,
}) async {
  final chatMap = await _loadPreferredSupportChatForUser(
    connection,
    userId,
    chatId: chatId,
  );
  if (chatMap == null) {
    return {'chat': null, 'messages': <Map<String, dynamic>>[]};
  }

  final resolvedChatId = _toPositiveInt(chatMap['id']);
  final messages = resolvedChatId > 0
      ? await _loadSupportMessagesByChat(connection, resolvedChatId)
      : <Map<String, dynamic>>[];

  return {'chat': _supportChatRowToDto(chatMap), 'messages': messages};
}

List<String> _parseCategories(Object? value, {bool includeFallback = true}) {
  final raw = value?.toString() ?? '';
  final parts = raw.split(RegExp(r'[;,|]'));
  final categories = parts
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (categories.isNotEmpty) {
    return categories;
  }
  if (!includeFallback) {
    return const <String>[];
  }
  return ['Без категории'];
}

List<String> _parseCategoryKeywords(Object? value) {
  final raw = value?.toString() ?? '';
  if (raw.trim().isEmpty) {
    return const <String>[];
  }
  return raw
      .split(RegExp(r'[;,|]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

String? _normalizeOptionalText(Object? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.toString().trim();
  if (normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String? _normalizeCategoryKeywordsPayload(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is List) {
    final keywords = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (keywords.isEmpty) {
      return null;
    }
    return keywords.join(', ');
  }
  final parsed = _parseCategoryKeywords(value);
  if (parsed.isEmpty) {
    return null;
  }
  return parsed.join(', ');
}

String _normalizeCategoryName(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

Future<Map<String, String>> _loadAllowedCategoriesByKey(
  Connection connection, {
  bool includeInactive = false,
}) async {
  final query = includeInactive
      ? '''
        SELECT name
        FROM public.categories
        ORDER BY sort_order ASC, id ASC;
      '''
      : '''
        SELECT name
        FROM public.categories
        WHERE is_active = true
        ORDER BY sort_order ASC, id ASC;
      ''';
  final rows = await connection.execute(query);
  final result = <String, String>{};
  for (final row in rows) {
    final map = row.toColumnMap();
    final name = _normalizeCategoryName((map['name'] ?? '').toString());
    if (name.isEmpty) {
      continue;
    }
    result.putIfAbsent(name.toLowerCase(), () => name);
  }
  return result;
}

Map<String, String> _parseCharacteristics(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return const <String, String>{};
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final result = <String, String>{};
      decoded.forEach((key, val) {
        final normalizedKey = key.toString().trim();
        final normalizedValue = val?.toString().trim() ?? '';
        if (normalizedKey.isNotEmpty && normalizedValue.isNotEmpty) {
          result[normalizedKey] = normalizedValue;
        }
      });
      if (result.isNotEmpty) {
        return result;
      }
    }
  } catch (_) {
    // Fallback to simple key:value parsing below.
  }

  final result = <String, String>{};
  for (final part in raw.split(RegExp(r'[;\n]+'))) {
    final normalized = part.trim();
    if (normalized.isEmpty) {
      continue;
    }
    final delimiterIndex = normalized.indexOf(':');
    if (delimiterIndex <= 0 || delimiterIndex >= normalized.length - 1) {
      continue;
    }
    final key = normalized.substring(0, delimiterIndex).trim();
    final val = normalized.substring(delimiterIndex + 1).trim();
    if (key.isEmpty || val.isEmpty) {
      continue;
    }
    result[key] = val;
  }
  return result;
}

String _serializeCharacteristics(Object? value) {
  if (value is Map) {
    final normalized = <String, String>{};
    value.forEach((key, val) {
      final k = key.toString().trim();
      final v = val?.toString().trim() ?? '';
      if (k.isNotEmpty && v.isNotEmpty) {
        normalized[k] = v;
      }
    });
    if (normalized.isNotEmpty) {
      return jsonEncode(normalized);
    }
    return '';
  }
  if (value is String) {
    final parsed = _parseCharacteristics(value);
    if (parsed.isNotEmpty) {
      return jsonEncode(parsed);
    }
    return '';
  }
  return '';
}

Future<List<String>> _resolvePayloadCategories(
  Connection connection,
  Object? payloadValue,
) async {
  final selected = <String>[];
  if (payloadValue is List) {
    for (final item in payloadValue) {
      final normalized = _normalizeCategoryName(item.toString());
      if (normalized.isNotEmpty) {
        selected.add(normalized);
      }
    }
  } else if (payloadValue != null) {
    selected.addAll(_parseCategories(payloadValue, includeFallback: false));
  }

  final allowed = await _loadAllowedCategoriesByKey(connection);
  final result = <String>[];
  final seen = <String>{};

  for (final raw in selected) {
    final canonical = allowed[raw.toLowerCase()];
    if (canonical == null) {
      continue;
    }
    if (seen.add(canonical.toLowerCase())) {
      result.add(canonical);
    }
  }

  return result;
}

Map<String, dynamic> _categoryRowToDto(Map<String, dynamic> map) {
  return {
    'id': map['id'],
    'name': map['name'] ?? '',
    'parentId': _toNullablePositiveInt(map['parent_id']),
    'subtitle': map['subtitle'] ?? '',
    'imagePath': map['image_path'] ?? '',
    'keywords': _parseCategoryKeywords(map['keywords']),
    'sortOrder': _toPositiveInt(map['sort_order']),
    'isActive': map['is_active'] ?? true,
  };
}

List<String> _parseImageUrls(Object? value) {
  final raw = value?.toString() ?? '';
  final parts = raw.split(RegExp(r'[;,|]'));
  return parts
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
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

  print('Подключение к PostgreSQL выполнено.');

  try {
    await _ensureDatabaseSchema(connection);
  } catch (e, st) {
    print('Ошибка при подготовке схемы БД: $e\n$st');
    rethrow;
  }

  final router = Router();

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

    final result = await connection.execute(
      Sql.named(
        'SELECT id, name, email, role, supplier_name, phone FROM users WHERE id = @id',
      ),
      parameters: {'id': userId},
    );

    if (result.isEmpty) {
      return Response.notFound('Ресурс не найден');
    }

    final user = result.first.toColumnMap();
    final role = user['role'] ?? _defaultRole;
    return Response.ok(
      jsonEncode({
        'id': user['id'],
        'name': user['name'] ?? '',
        'email': user['email'] ?? '',
        'role': role,
        'supplierName': _supplierNameForRole(role, user['supplier_name']),
        'phone': user['phone'] ?? '',
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
               EXISTS(
                 SELECT 1
                 FROM order_items oi
                 WHERE oi.product_id = p.id
               ) AS has_orders
        FROM products p
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

  router.get('/moderation/products', (Request request) async {
    try {
      final status = request.url.queryParameters['status'];
      final normalized = status == null || status == 'all'
          ? 'all'
          : _normalizeModerationStatus(status, fallback: 'pending');

      final result = normalized == 'all'
          ? await connection.execute('SELECT * FROM products ORDER BY id DESC;')
          : await connection.execute(
              Sql.named(
                'SELECT * FROM products WHERE moderation_status = @status ORDER BY id DESC;',
              ),
              parameters: {'status': normalized},
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

  router.get('/moderation/categories', (Request request) async {
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

      final categories = result
          .map((row) => _categoryRowToDto(row.toColumnMap()))
          .toList();

      return Response.ok(
        jsonEncode(categories),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/support/thread', (Request request) async {
    try {
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(
          body: 'Идентификатор пользователя указан некорректно',
        );
      }

      final chatIdRaw = request.url.queryParameters['chatId'];
      final chatId = chatIdRaw == null ? null : int.tryParse(chatIdRaw);
      if (chatIdRaw != null && (chatId == null || chatId <= 0)) {
        return Response.badRequest(body: 'chatId обязателен');
      }

      final thread = await _loadSupportThreadForUser(
        connection,
        userId,
        chatId: chatId,
      );
      return Response.ok(
        jsonEncode(thread),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });
  router.get('/support/events', (Request request) async {
    final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
    if (userId == null || userId <= 0) {
      return Response.badRequest(
        body: 'Идентификатор пользователя указан некорректно',
      );
    }

    final chatIdRaw = request.url.queryParameters['chatId'];
    final chatId = chatIdRaw == null ? null : int.tryParse(chatIdRaw);
    if (chatIdRaw != null && (chatId == null || chatId <= 0)) {
      return Response.badRequest(body: 'chatId обязателен');
    }

    return _buildSupportEventsResponse(
      scope: 'user',
      filter: (event) {
        if (_toPositiveInt(event['userId']) != userId) return false;
        if (chatId != null && _toPositiveInt(event['chatId']) != chatId) {
          return false;
        }
        return true;
      },
    );
  });

  router.get('/support/messages', (Request request) async {
    try {
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      if (userId == null || userId <= 0) {
        return Response.badRequest(
          body: 'Идентификатор пользователя указан некорректно',
        );
      }

      final chatIdRaw = request.url.queryParameters['chatId'];
      final chatId = chatIdRaw == null ? null : int.tryParse(chatIdRaw);
      if (chatIdRaw != null && (chatId == null || chatId <= 0)) {
        return Response.badRequest(body: 'chatId обязателен');
      }

      final chat = await _loadPreferredSupportChatForUser(
        connection,
        userId,
        chatId: chatId,
      );
      final messages = chat == null
          ? <Map<String, dynamic>>[]
          : await _loadSupportMessagesByChat(
              connection,
              _toPositiveInt(chat['id']),
            );
      return Response.ok(
        jsonEncode(messages),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/moderation/support/chats', (Request request) async {
    try {
      final result = await connection.execute('''
        SELECT
          sc.id AS chat_id,
          sc.user_id,
          sc.status,
          sc.category AS chat_category,
          sc.subject AS chat_subject,
          sc.close_reason,
          sc.created_at AS chat_created_at,
          sc.updated_at AS chat_updated_at,
          sc.closed_at,
          sc.closed_by_user_id,
          lm.message_text AS last_message,
          lm.sender_role AS last_sender_role,
          lm.created_at AS last_message_at,
          u.name AS user_name,
          u.email AS user_email,
          u.role AS user_role,
          u.supplier_name
        FROM support_chats sc
        JOIN users u ON u.id = sc.user_id
        LEFT JOIN LATERAL (
          SELECT
            message_text,
            sender_role,
            created_at
          FROM support_messages sm
          WHERE sm.chat_id = sc.id
          ORDER BY sm.id DESC
          LIMIT 1
        ) lm ON TRUE
        ORDER BY
          CASE WHEN sc.status = 'open' THEN 0 ELSE 1 END ASC,
          COALESCE(lm.created_at, sc.updated_at, sc.created_at) DESC,
          sc.id DESC;
      ''');

      final chats = result.map((row) {
        final map = row.toColumnMap();
        final lastMessageAtRaw =
            map['last_message_at'] ??
            map['chat_updated_at'] ??
            map['chat_created_at'];
        String? lastMessageAtIso;
        if (lastMessageAtRaw is DateTime) {
          lastMessageAtIso = lastMessageAtRaw.toIso8601String();
        }

        final chatDto = _supportChatRowToDto({
          'id': map['chat_id'],
          'user_id': map['user_id'],
          'status': map['status'],
          'category': map['chat_category'],
          'subject': map['chat_subject'],
          'close_reason': map['close_reason'],
          'created_at': map['chat_created_at'],
          'updated_at': map['chat_updated_at'],
          'closed_at': map['closed_at'],
          'closed_by_user_id': map['closed_by_user_id'],
        });

        final createdAtIso = chatDto['createdAt']?.toString();
        final closedAtIso = chatDto['closedAt']?.toString();

        return {
          'chatId': _toPositiveInt(map['chat_id']),
          'userId': _toPositiveInt(map['user_id']),
          'status': chatDto['status'] ?? 'open',
          'category': chatDto['category'] ?? '',
          'subject': chatDto['subject'] ?? '',
          'closeReason': chatDto['closeReason'] ?? '',
          'userName': map['user_name'] ?? '',
          'userEmail': map['user_email'] ?? '',
          'userRole': map['user_role'] ?? _defaultRole,
          'supplierName': map['supplier_name'] ?? '',
          'lastMessage': map['last_message'] ?? '',
          'lastSenderRole': _normalizeSupportSenderRole(
            map['last_sender_role'],
          ),
          if (createdAtIso != null) 'createdAt': createdAtIso,
          if (lastMessageAtIso != null) 'lastMessageAt': lastMessageAtIso,
          if (closedAtIso != null) 'closedAt': closedAtIso,
        };
      }).toList();

      return Response.ok(
        jsonEncode(chats),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/moderation/support/events', (Request request) async {
    final chatIdRaw = request.url.queryParameters['chatId'];
    final chatId = chatIdRaw == null ? null : int.tryParse(chatIdRaw);
    if (chatIdRaw != null && (chatId == null || chatId <= 0)) {
      return Response.badRequest(body: 'chatId обязателен');
    }

    return _buildSupportEventsResponse(
      scope: 'moderator',
      filter: (event) {
        if (chatId != null && _toPositiveInt(event['chatId']) != chatId) {
          return false;
        }
        return true;
      },
    );
  });

  router.get('/moderation/support/messages/<id>', (
    Request request,
    String id,
  ) async {
    try {
      final parsedId = int.tryParse(id);
      if (parsedId == null || parsedId <= 0) {
        return Response.badRequest(body: 'Некорректный идентификатор');
      }

      final directChat = await _loadSupportChatById(connection, parsedId);
      final chat =
          directChat ??
          await _loadPreferredSupportChatForUser(connection, parsedId);
      if (chat == null) {
        return Response.ok(
          jsonEncode(<Map<String, dynamic>>[]),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final chatId = _toPositiveInt(chat['id']);
      final messages = chatId <= 0
          ? <Map<String, dynamic>>[]
          : await _loadSupportMessagesByChat(connection, chatId);
      return Response.ok(
        jsonEncode(messages),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/moderation/support/thread/<id>', (
    Request request,
    String id,
  ) async {
    try {
      final chatId = int.tryParse(id);
      if (chatId == null || chatId <= 0) {
        return Response.badRequest(body: 'chatId обязателен');
      }

      final chat = await _loadSupportChatById(connection, chatId);
      if (chat == null) {
        return Response.notFound('chatId обязателен');
      }

      final messages = await _loadSupportMessagesByChat(connection, chatId);
      return Response.ok(
        jsonEncode({'chat': _supportChatRowToDto(chat), 'messages': messages}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка сервера: $e\n$st');
      return Response.internalServerError(body: 'Некорректный запрос');
    }
  });

  router.get('/orders', (Request request) async {
    try {
      final userIdRaw = request.url.queryParameters['userId'];
      final userId = int.tryParse(userIdRaw ?? '');
      if (userIdRaw != null && userId == null) {
        return Response.badRequest(
          body: 'Идентификатор пользователя указан некорректно',
        );
      }

      final ordersResult = userId == null
          ? await connection.execute(
              'SELECT * FROM orders ORDER BY created_at DESC;',
            )
          : await connection.execute(
              Sql.named(
                'SELECT * FROM orders WHERE user_id = @user_id ORDER BY created_at DESC;',
              ),
              parameters: {'user_id': userId},
            );

      final ordersRows = ordersResult.map((row) => row.toColumnMap()).toList();
      if (ordersRows.isEmpty) {
        return Response.ok(
          jsonEncode([]),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final orderIds = ordersRows.map((row) => row['id'] as int).toList();
      final itemsResult = await connection.execute(
        Sql.named(
          'SELECT * FROM order_items WHERE order_id = ANY(@ids) ORDER BY id;',
        ),
        parameters: {'ids': orderIds},
      );

      final itemsByOrderId = <int, List<Map<String, dynamic>>>{};
      for (final row in itemsResult) {
        final map = row.toColumnMap();
        final orderId = map['order_id'] as int;
        itemsByOrderId.putIfAbsent(orderId, () => []);
        itemsByOrderId[orderId]!.add({
          'id': map['id']?.toString() ?? '',
          'productId': map['product_id']?.toString() ?? '',
          'name': map['name'] ?? '',
          'price': map['price'] ?? 0,
          'quantity': map['quantity'] ?? 0,
          'imageUrl': map['image_url'] ?? '',
          'supplierName': map['supplier_name'] ?? '',
          'isReceived': map['is_received'] ?? false,
        });
      }

      final orders = ordersRows.map((map) {
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

      final filters = <String>[];
      final parameters = <String, dynamic>{};
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
                 u.name AS reviewer_name
          FROM reviews r
          LEFT JOIN order_items oi ON oi.id = r.order_item_id
          LEFT JOIN products p ON p.id = r.product_id
          LEFT JOIN users u ON u.id = r.user_id
          $whereClause
          ORDER BY r.created_at DESC;
        '''),
        parameters: parameters,
      );

      final reviews = result
          .map((row) => _reviewRowToDto(row.toColumnMap()))
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

  _registerMutationRoutes(router, connection);

  router.post('/login', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);

      final email = data['email']?.trim();
      final password = data['password']?.trim();

      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        return Response.badRequest(
          body: 'Введите почту и пароль',
          headers: _utf8TextHeaders,
        );
      }

      final result = await connection.execute(
        Sql.named(
          'SELECT * FROM users WHERE email = @email AND password = @password',
        ),
        parameters: {'email': email, 'password': password},
      );

      if (result.isEmpty) {
        return Response(
          401,
          body: 'Неверная почта или пароль',
          headers: _utf8TextHeaders,
        );
      }

      final user = result.first.toColumnMap();
      final role = user['role'] ?? _defaultRole;
      return Response.ok(
        jsonEncode({
          'id': user['id'],
          'name': user['name'] ?? '',
          'email': user['email'] ?? '',
          'role': role,
          'supplierName': _supplierNameForRole(role, user['supplier_name']),
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response.badRequest(
        body: 'Доступ запрещен',
        headers: _utf8TextHeaders,
      );
    } catch (e, st) {
      print('Ошибка сервера при входе: $e\n$st');
      return Response.internalServerError(
        body: 'Не удалось выполнить вход. Попробуйте позже.',
        headers: _utf8TextHeaders,
      );
    }
  });

  // Middleware (CORS и логирование запросов)
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  // Запуск HTTP-сервера
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('Сервер запущен: http://${server.address.host}:${server.port}');
}

