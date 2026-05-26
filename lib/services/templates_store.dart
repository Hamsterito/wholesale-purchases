import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import 'app_logger.dart';
import 'auth_storage.dart';
import 'cart_store.dart';
import 'product_resolver.dart';
import 'shared_prefs_provider.dart';

/// Шаблон покупок: именованный набор позиций с метаданными.
class PurchaseTemplate {
  PurchaseTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TemplateItem> items;

  PurchaseTemplate copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TemplateItem>? items,
  }) {
    return PurchaseTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  // Порядок ключей зафиксирован для детерминированного encode.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
  };

  /// При невалидности кидает FormatException - выше decode ловит и пропускает запись.
  static PurchaseTemplate fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final rawItems = json['items'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('PurchaseTemplate.id невалиден');
    }
    if (name is! String) {
      throw const FormatException('PurchaseTemplate.name невалиден');
    }
    if (createdAt is! String) {
      throw const FormatException('PurchaseTemplate.createdAt невалиден');
    }
    if (updatedAt is! String) {
      throw const FormatException('PurchaseTemplate.updatedAt невалиден');
    }
    if (rawItems is! List) {
      throw const FormatException('PurchaseTemplate.items невалиден');
    }
    final parsedCreated = DateTime.tryParse(createdAt);
    final parsedUpdated = DateTime.tryParse(updatedAt);
    if (parsedCreated == null) {
      throw const FormatException('PurchaseTemplate.createdAt не ISO-8601');
    }
    if (parsedUpdated == null) {
      throw const FormatException('PurchaseTemplate.updatedAt не ISO-8601');
    }
    final items = <TemplateItem>[];
    for (final raw in rawItems) {
      if (raw is! Map) {
        throw const FormatException('TemplateItem не объект');
      }
      items.add(TemplateItem.fromJson(raw.cast<String, dynamic>()));
    }
    return PurchaseTemplate(
      id: id,
      name: name,
      createdAt: parsedCreated,
      updatedAt: parsedUpdated,
      items: items,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PurchaseTemplate) return false;
    if (other.id != id ||
        other.name != name ||
        other.createdAt != createdAt ||
        other.updatedAt != updatedAt ||
        other.items.length != items.length) {
      return false;
    }
    for (var i = 0; i < items.length; i++) {
      if (other.items[i] != items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, createdAt, updatedAt, Object.hashAll(items));
}

/// Позиция шаблона: productId/supplierId/quantity плюс снимок отображения,
/// чтобы лист шаблонов открывался без сетевых запросов.
class TemplateItem {
  TemplateItem({
    required this.productId,
    required this.supplierId,
    required this.quantity,
    required this.productName,
    required this.productImageUrl,
    required this.supplierName,
    required this.pricePerUnit,
    required this.minQuantity,
    required this.maxQuantity,
  });

  final String productId;
  final String supplierId;
  final int quantity;
  final String productName;
  final String productImageUrl;
  final String supplierName;
  final int pricePerUnit;
  final int minQuantity;
  final int? maxQuantity;

  TemplateItem copyWith({
    String? productId,
    String? supplierId,
    int? quantity,
    String? productName,
    String? productImageUrl,
    String? supplierName,
    int? pricePerUnit,
    int? minQuantity,
    int? maxQuantity,
    bool clearMaxQuantity = false,
  }) {
    return TemplateItem(
      productId: productId ?? this.productId,
      supplierId: supplierId ?? this.supplierId,
      quantity: quantity ?? this.quantity,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      supplierName: supplierName ?? this.supplierName,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: clearMaxQuantity ? null : (maxQuantity ?? this.maxQuantity),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'productId': productId,
    'supplierId': supplierId,
    'quantity': quantity,
    'productName': productName,
    'productImageUrl': productImageUrl,
    'supplierName': supplierName,
    'pricePerUnit': pricePerUnit,
    'minQuantity': minQuantity,
    'maxQuantity': maxQuantity,
  };

  static TemplateItem fromJson(Map<String, dynamic> json) {
    final productId = json['productId'];
    final supplierId = json['supplierId'];
    final quantity = json['quantity'];
    final productName = json['productName'];
    final productImageUrl = json['productImageUrl'];
    final supplierName = json['supplierName'];
    final pricePerUnit = json['pricePerUnit'];
    final minQuantity = json['minQuantity'];
    final maxQuantity = json['maxQuantity'];

    if (productId is! String || productId.isEmpty) {
      throw const FormatException('TemplateItem.productId невалиден');
    }
    if (supplierId is! String || supplierId.isEmpty) {
      throw const FormatException('TemplateItem.supplierId невалиден');
    }
    if (quantity is! int || quantity < 1) {
      throw const FormatException('TemplateItem.quantity невалиден');
    }
    if (productName is! String) {
      throw const FormatException('TemplateItem.productName невалиден');
    }
    if (productImageUrl is! String) {
      throw const FormatException('TemplateItem.productImageUrl невалиден');
    }
    if (supplierName is! String) {
      throw const FormatException('TemplateItem.supplierName невалиден');
    }
    if (pricePerUnit is! int) {
      throw const FormatException('TemplateItem.pricePerUnit невалиден');
    }
    if (minQuantity is! int) {
      throw const FormatException('TemplateItem.minQuantity невалиден');
    }
    if (maxQuantity != null && maxQuantity is! int) {
      throw const FormatException('TemplateItem.maxQuantity невалиден');
    }
    return TemplateItem(
      productId: productId,
      supplierId: supplierId,
      quantity: quantity,
      productName: productName,
      productImageUrl: productImageUrl,
      supplierName: supplierName,
      pricePerUnit: pricePerUnit,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity as int?,
    );
  }

  /// Создаёт позицию шаблона из CartItem со снимком отображаемых полей.
  /// quantity клиппится к minQuantity..(maxQuantity ?? quantity) -
  /// сама корзина гарантирует валидность, но защищаемся от пограничных кейсов.
  factory TemplateItem.fromCartItem(CartItem cartItem) {
    final product = cartItem.product;
    final supplier = cartItem.supplier;
    final image = product.imageUrls.isNotEmpty ? product.imageUrls.first : '';

    final lower = supplier.minQuantity;
    final upperRaw = supplier.maxQuantity ?? cartItem.quantity;
    // Если по какой-то причине верхняя граница меньше нижней - приоритет у min.
    final upper = upperRaw < lower ? lower : upperRaw;
    var clamped = cartItem.quantity;
    if (clamped < lower) clamped = lower;
    if (clamped > upper) clamped = upper;

    return TemplateItem(
      productId: product.id,
      supplierId: supplier.id,
      quantity: clamped,
      productName: product.name,
      productImageUrl: image,
      supplierName: supplier.name,
      pricePerUnit: supplier.pricePerUnit,
      minQuantity: supplier.minQuantity,
      maxQuantity: supplier.maxQuantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateItem &&
        other.productId == productId &&
        other.supplierId == supplierId &&
        other.quantity == quantity &&
        other.productName == productName &&
        other.productImageUrl == productImageUrl &&
        other.supplierName == supplierName &&
        other.pricePerUnit == pricePerUnit &&
        other.minQuantity == minQuantity &&
        other.maxQuantity == maxQuantity;
  }

  @override
  int get hashCode => Object.hash(
    productId,
    supplierId,
    quantity,
    productName,
    productImageUrl,
    supplierName,
    pricePerUnit,
    minQuantity,
    maxQuantity,
  );
}

/// Виды ошибок валидации шаблона. Готовое русское сообщение -
/// в TemplateValidationError.userMessage.
enum TemplateValidationErrorKind {
  nameEmpty,
  nameTooLong,
  nameDuplicate,
  itemsEmpty,
  itemsLimitExceeded,
  templatesLimitExceeded,
}

/// Ошибка валидации шаблона с готовым русским сообщением для UI.
class TemplateValidationError {
  const TemplateValidationError({
    required this.kind,
    required this.userMessage,
  });

  final TemplateValidationErrorKind kind;
  final String userMessage;

  /// Фабрики с фиксированными сообщениями.
  factory TemplateValidationError.nameEmpty() => const TemplateValidationError(
    kind: TemplateValidationErrorKind.nameEmpty,
    userMessage: 'Имя шаблона: от 1 до 50 символов',
  );

  factory TemplateValidationError.nameTooLong() =>
      const TemplateValidationError(
        kind: TemplateValidationErrorKind.nameTooLong,
        userMessage: 'Имя шаблона: от 1 до 50 символов',
      );

  factory TemplateValidationError.nameDuplicate() =>
      const TemplateValidationError(
        kind: TemplateValidationErrorKind.nameDuplicate,
        userMessage: 'Шаблон с таким именем уже существует',
      );

  // Защитный кейс: UI скрывает действие при пустой корзине, но стор
  // всё равно валидирует вход.
  factory TemplateValidationError.itemsEmpty() => const TemplateValidationError(
    kind: TemplateValidationErrorKind.itemsEmpty,
    userMessage: 'Шаблон не может быть пустым',
  );

  factory TemplateValidationError.itemsLimitExceeded() =>
      const TemplateValidationError(
        kind: TemplateValidationErrorKind.itemsLimitExceeded,
        userMessage: 'В шаблоне может быть не более 100 позиций.',
      );

  factory TemplateValidationError.templatesLimitExceeded() =>
      const TemplateValidationError(
        kind: TemplateValidationErrorKind.templatesLimitExceeded,
        userMessage: 'Достигнут лимит шаблонов: 20. Удалите ненужный шаблон.',
      );

  @override
  bool operator ==(Object other) =>
      other is TemplateValidationError &&
      other.kind == kind &&
      other.userMessage == userMessage;

  @override
  int get hashCode => Object.hash(kind, userMessage);

  @override
  String toString() => 'TemplateValidationError($kind, $userMessage)';
}

/// Исключение, кидаемое create/overwrite/rename при провале валидации.
class TemplateValidationException implements Exception {
  const TemplateValidationException(this.error);

  final TemplateValidationError error;

  TemplateValidationErrorKind get kind => error.kind;
  String get userMessage => error.userMessage;

  @override
  String toString() => 'TemplateValidationException: ${error.userMessage}';
}

/// Причина пропуска позиции при применении шаблона:
/// productMissing - товар отсутствует, supplierMissing - поставщик не предлагает товар.
enum SkipReason { productMissing, supplierMissing }

/// Причина корректировки количества: raisedToMin - qty поднят до минимума,
/// loweredToMax - опущен до максимума.
enum AdjustReason { raisedToMin, loweredToMax }

/// Пропущенная позиция шаблона с причиной.
class SkippedTemplateItem {
  const SkippedTemplateItem({required this.item, required this.reason});

  final TemplateItem item;
  final SkipReason reason;
}

/// Скорректированная позиция шаблона: исходное и итоговое количество с причиной.
class AdjustedTemplateItem {
  const AdjustedTemplateItem({
    required this.item,
    required this.oldQuantity,
    required this.newQuantity,
    required this.reason,
  });

  final TemplateItem item;
  final int oldQuantity;
  final int newQuantity;
  final AdjustReason reason;
}

/// Результат применения шаблона к корзине.
/// cartReplaced=false - корзина не тронута (ни одной применимой позиции).
class ApplyTemplateResult {
  const ApplyTemplateResult({
    required this.cartReplaced,
    required this.addedCount,
    required this.skipped,
    required this.adjusted,
  });

  /// Пустой результат без изменений: шаблон не найден или ничего не применимо.
  const ApplyTemplateResult.empty()
    : cartReplaced = false,
      addedCount = 0,
      skipped = const <SkippedTemplateItem>[],
      adjusted = const <AdjustedTemplateItem>[];

  final bool cartReplaced;
  final int addedCount;
  final List<SkippedTemplateItem> skipped;
  final List<AdjustedTemplateItem> adjusted;

  int get skippedCount => skipped.length;
  int get adjustedCount => adjusted.length;
}

/// Стор шаблонов покупок: singleton + in-memory кэш per-user.
/// Mutating методы обновляют updatedAt, пишут JSON в SharedPreferences
/// и зовут notifyListeners только при фактических изменениях.
class TemplatesStore extends ChangeNotifier {
  TemplatesStore._();

  static final TemplatesStore instance = TemplatesStore._();

  static const String _logScope = 'templates';
  static const String _keyPrefix = 'purchase_templates_';

  // Лимиты из дизайна: 20 шаблонов на пользователя, 100 позиций в шаблоне,
  // имя - 1..50 символов после trim.
  static const int maxTemplatesPerUser = 20;
  static const int maxItemsPerTemplate = 100;
  static const int maxNameLength = 50;

  // userId, под которым загружен текущий кэш. null - кэш ещё не грузили
  // или принадлежит "никому" (несогласованное состояние авторизации).
  int? _loadedUserId;
  bool _isLoaded = false;
  final List<PurchaseTemplate> _templates = <PurchaseTemplate>[];

  /// Кэш загружен из SharedPreferences хотя бы один раз.
  bool get isLoaded => _isLoaded;

  /// Число шаблонов в текущем кэше.
  int get count => _templates.length;

  /// Неизменяемая копия списка шаблонов, отсортированного по updatedAt
  /// от свежих к старым.
  List<PurchaseTemplate> get templates {
    final sorted = List<PurchaseTemplate>.from(_templates)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<PurchaseTemplate>.unmodifiable(sorted);
  }

  /// Ключ хранилища для конкретного пользователя.
  static String _storageKey(int userId) => '$_keyPrefix$userId';

  /// Загружает шаблоны текущего пользователя из SharedPreferences.
  /// На рассогласование isRemembered/userId - пустой список + warning, без исключений.
  Future<void> loadForCurrentUser() async {
    final remembered = AuthStorage.isRemembered;
    final userId = AuthStorage.userId;

    if (remembered && (userId == null || userId <= 0)) {
      AppLogger.warning(
        'loadForCurrentUser: рассогласование авторизации '
        '(isRemembered=true, userId=$userId), кэш пуст',
        scope: _logScope,
      );
      _replaceCache(<PurchaseTemplate>[], loadedUserId: null);
      return;
    }

    if (userId == null || userId <= 0) {
      // Не авторизован - пустой кэш без записи в хранилище.
      _replaceCache(<PurchaseTemplate>[], loadedUserId: null);
      return;
    }

    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final raw = prefs.getString(_storageKey(userId));
      if (raw == null || raw.isEmpty) {
        _replaceCache(<PurchaseTemplate>[], loadedUserId: userId);
        return;
      }
      final parsed = decode(raw);
      _replaceCache(parsed, loadedUserId: userId);
    } catch (e, st) {
      AppLogger.error(
        'loadForCurrentUser: не удалось прочитать SharedPreferences',
        scope: _logScope,
        error: e,
        stackTrace: st,
      );
      _replaceCache(<PurchaseTemplate>[], loadedUserId: userId);
    }
  }

  /// Очищает шаблоны текущего пользователя из памяти и SharedPreferences.
  /// Зовётся перед AuthStorage.forget() при выходе.
  Future<void> clearCache() async {
    final userId = AuthStorage.userId;
    final hadTemplates = _templates.isNotEmpty;

    _templates.clear();
    _loadedUserId = null;
    _isLoaded = false;

    if (userId != null && userId > 0) {
      try {
        final prefs = await SharedPrefsProvider.getInstance();
        await prefs.remove(_storageKey(userId));
      } catch (e, st) {
        AppLogger.error(
          'clearCache: не удалось очистить SharedPreferences',
          scope: _logScope,
          error: e,
          stackTrace: st,
        );
      }
    }

    if (hadTemplates) {
      notifyListeners();
    }
  }

  // Атомарно заменяет кэш и помечает его как загруженный.
  // notifyListeners вызывается, только если состав фактически изменился.
  void _replaceCache(
    List<PurchaseTemplate> next, {
    required int? loadedUserId,
  }) {
    final changed = !_listsEqual(_templates, next);
    _templates
      ..clear()
      ..addAll(next);
    _loadedUserId = loadedUserId;
    _isLoaded = true;
    if (changed) {
      notifyListeners();
    }
  }

  static bool _listsEqual(List<PurchaseTemplate> a, List<PurchaseTemplate> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Сериализует список в детерминированную JSON-строку: фиксированный порядок
  /// ключей в toJson, шаблоны и позиции - как в исходных списках.
  static String encode(List<PurchaseTemplate> templates) {
    final list = templates.map((t) => t.toJson()).toList(growable: false);
    return jsonEncode(list);
  }

  /// Мягкий парсинг JSON: корневая ошибка → пустой список,
  /// битые элементы массива пропускаются целиком, остальные восстанавливаются.
  static List<PurchaseTemplate> decode(String json) {
    if (json.isEmpty) return const <PurchaseTemplate>[];

    final dynamic root;
    try {
      root = jsonDecode(json);
    } catch (e) {
      AppLogger.warning(
        'TemplatesStore.decode: невалидный JSON, возвращаем пустой список ($e)',
        scope: _logScope,
      );
      return const <PurchaseTemplate>[];
    }

    if (root is! List) {
      AppLogger.warning(
        'TemplatesStore.decode: ожидался JSON-массив, получили ${root.runtimeType}',
        scope: _logScope,
      );
      return const <PurchaseTemplate>[];
    }

    final result = <PurchaseTemplate>[];
    for (var i = 0; i < root.length; i++) {
      final raw = root[i];
      if (raw is! Map) {
        AppLogger.warning(
          'TemplatesStore.decode: элемент $i не объект, пропущен',
          scope: _logScope,
        );
        continue;
      }
      try {
        result.add(PurchaseTemplate.fromJson(raw.cast<String, dynamic>()));
      } catch (e) {
        AppLogger.warning(
          'TemplatesStore.decode: элемент $i не разобран ($e), пропущен',
          scope: _logScope,
        );
      }
    }
    return result;
  }

  // Поиск и валидация

  /// Ищет шаблон по имени без учёта регистра (после trim).
  /// excludeId полезен при rename, чтобы не считать сам себя дубликатом.
  PurchaseTemplate? findByNameCi(String name, {String? excludeId}) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final t in _templates) {
      if (excludeId != null && t.id == excludeId) continue;
      if (t.name.trim().toLowerCase() == needle) return t;
    }
    return null;
  }

  /// Возвращает null, если имя валидно. Те же правила, что у create/rename.
  TemplateValidationError? validateName(String name, {String? excludeId}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return TemplateValidationError.nameEmpty();
    if (trimmed.length > maxNameLength) {
      return TemplateValidationError.nameTooLong();
    }
    if (findByNameCi(trimmed, excludeId: excludeId) != null) {
      return TemplateValidationError.nameDuplicate();
    }
    return null;
  }

  /// Проверка количества позиций (1..100). null - валидно.
  TemplateValidationError? validateItemsCount(int count) {
    if (count < 1) return TemplateValidationError.itemsEmpty();
    if (count > maxItemsPerTemplate) {
      return TemplateValidationError.itemsLimitExceeded();
    }
    return null;
  }

  // Мутации: create / overwrite / rename / remove / restore

  /// Создаёт новый шаблон. StateError без userId,
  /// TemplateValidationException при невалидных входных данных.
  Future<PurchaseTemplate> create({
    required String name,
    required List<TemplateItem> items,
  }) async {
    final userId = _requireUserId('create');

    final trimmed = name.trim();
    final nameError = validateName(trimmed);
    if (nameError != null) throw TemplateValidationException(nameError);

    final itemsError = validateItemsCount(items.length);
    if (itemsError != null) throw TemplateValidationException(itemsError);

    if (_templates.length >= maxTemplatesPerUser) {
      throw TemplateValidationException(
        TemplateValidationError.templatesLimitExceeded(),
      );
    }

    final now = DateTime.now().toUtc();
    final template = PurchaseTemplate(
      id: _generateId(),
      name: trimmed,
      createdAt: now,
      updatedAt: now,
      items: List<TemplateItem>.unmodifiable(items),
    );

    _templates.add(template);
    await _persist(userId);
    notifyListeners();
    return template;
  }

  /// Подменяет состав шаблона. Если состав не изменился - no-op.
  /// Шаблон не найден - тихий no-op.
  Future<void> overwrite({
    required String templateId,
    required List<TemplateItem> items,
  }) async {
    final userId = _requireUserId('overwrite');

    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index < 0) return;

    final itemsError = validateItemsCount(items.length);
    if (itemsError != null) throw TemplateValidationException(itemsError);

    final current = _templates[index];
    if (_itemListsEqual(current.items, items)) {
      // Состав не изменился - не трогаем хранилище и не нотифицируем.
      return;
    }

    _templates[index] = current.copyWith(
      items: List<TemplateItem>.unmodifiable(items),
      updatedAt: DateTime.now().toUtc(),
    );
    await _persist(userId);
    notifyListeners();
  }

  /// Переименовывает шаблон. Совпадение с текущим именем (после trim) - no-op.
  /// Дубликат с другим шаблоном - TemplateValidationException. Не найден - no-op.
  Future<void> rename({
    required String templateId,
    required String newName,
  }) async {
    final userId = _requireUserId('rename');

    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index < 0) return;

    final current = _templates[index];
    final trimmed = newName.trim();

    // Совпадение с текущим именем после trim - no-op.
    if (trimmed == current.name.trim()) return;

    if (trimmed.isEmpty) {
      throw TemplateValidationException(TemplateValidationError.nameEmpty());
    }
    if (trimmed.length > maxNameLength) {
      throw TemplateValidationException(TemplateValidationError.nameTooLong());
    }
    if (findByNameCi(trimmed, excludeId: templateId) != null) {
      throw TemplateValidationException(
        TemplateValidationError.nameDuplicate(),
      );
    }

    _templates[index] = current.copyWith(
      name: trimmed,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persist(userId);
    notifyListeners();
  }

  /// Удаляет шаблон по id. Если шаблона нет - no-op.
  Future<void> remove(String templateId) async {
    final userId = _requireUserId('remove');

    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index < 0) return;

    _templates.removeAt(index);
    await _persist(userId);
    notifyListeners();
  }

  /// Восстанавливает шаблон по полному снимку для undo после remove.
  /// Лимит 20 не проверяется. Существующий с тем же id - заменяется.
  Future<void> restore(PurchaseTemplate template) async {
    final userId = _requireUserId('restore');

    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index >= 0) {
      _templates[index] = template;
    } else {
      _templates.add(template);
    }
    await _persist(userId);
    notifyListeners();
  }

  // Применение шаблона к корзине

  /// Применяет шаблон к корзине: фильтрует недоступные, подгоняет qty к границам,
  /// заменяет содержимое корзины. Если применимых позиций нет - корзина не трогается,
  /// возвращается ApplyTemplateResult.empty(). Шаблоны не мутируются.
  Future<ApplyTemplateResult> apply({
    required String templateId,
    required ProductResolver resolver,
    required CartStore cart,
  }) async {
    // apply read-only по шаблонам, но требует того же авторизованного состояния,
    // что и остальные методы - иначе писать в чужую корзину было бы странно.
    _requireUserId('apply');

    final template = _templates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => _missingTemplate,
    );
    if (identical(template, _missingTemplate)) {
      return const ApplyTemplateResult.empty();
    }

    final applicable = <_ApplicableItem>[];
    final skipped = <SkippedTemplateItem>[];
    final adjusted = <AdjustedTemplateItem>[];

    for (final item in template.items) {
      final product = await resolver.resolveProduct(item.productId);
      if (product == null) {
        skipped.add(
          SkippedTemplateItem(item: item, reason: SkipReason.productMissing),
        );
        continue;
      }

      Supplier? supplier;
      for (final s in product.suppliers) {
        if (s.id == item.supplierId) {
          supplier = s;
          break;
        }
      }
      if (supplier == null) {
        skipped.add(
          SkippedTemplateItem(item: item, reason: SkipReason.supplierMissing),
        );
        continue;
      }

      // Clamp к актуальным границам. Порядок проверки: сначала min,
      // потом max - если qty слишком мал, поднимаем; если слишком велик,
      // опускаем. Внутри min..max ничего не делаем.
      var finalQty = item.quantity;
      AdjustReason? reason;
      if (finalQty < supplier.minQuantity) {
        finalQty = supplier.minQuantity;
        reason = AdjustReason.raisedToMin;
      } else if (supplier.maxQuantity != null &&
          finalQty > supplier.maxQuantity!) {
        finalQty = supplier.maxQuantity!;
        reason = AdjustReason.loweredToMax;
      }

      if (reason != null) {
        adjusted.add(
          AdjustedTemplateItem(
            item: item,
            oldQuantity: item.quantity,
            newQuantity: finalQty,
            reason: reason,
          ),
        );
      }

      applicable.add(
        _ApplicableItem(
          product: product,
          supplier: supplier,
          quantity: finalQty,
        ),
      );
    }

    if (applicable.isEmpty) {
      // Корзину не трогаем, шаблон считается неприменённым.
      return ApplyTemplateResult(
        cartReplaced: false,
        addedCount: 0,
        skipped: List<SkippedTemplateItem>.unmodifiable(skipped),
        adjusted: List<AdjustedTemplateItem>.unmodifiable(adjusted),
      );
    }

    cart.clear();
    for (final a in applicable) {
      cart.addOrUpdate(
        product: a.product,
        supplier: a.supplier,
        quantity: a.quantity,
      );
    }

    return ApplyTemplateResult(
      cartReplaced: true,
      addedCount: applicable.length,
      skipped: List<SkippedTemplateItem>.unmodifiable(skipped),
      adjusted: List<AdjustedTemplateItem>.unmodifiable(adjusted),
    );
  }

  // Маркер «шаблон не найден» для firstWhere - без аллокаций на каждый apply.
  static final PurchaseTemplate _missingTemplate = PurchaseTemplate(
    id: '',
    name: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    items: const <TemplateItem>[],
  );

  // Внутренние помощники

  /// Требует валидного userId для мутации. Иначе StateError -
  /// мутировать без userId означало бы писать «в никуда».
  int _requireUserId(String op) {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      throw StateError(
        'TemplatesStore.$op требует авторизованного пользователя',
      );
    }
    return userId;
  }

  /// Сохраняет список в SharedPreferences. Ошибки записи не пробрасываются -
  /// сбой не должен откатывать состояние в памяти (UI уже среагировал).
  Future<void> _persist(int userId) async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      await prefs.setString(_storageKey(userId), encode(_templates));
    } catch (e, st) {
      AppLogger.error(
        '_persist: не удалось записать шаблоны в SharedPreferences',
        scope: _logScope,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Поэлементное сравнение списков позиций (порядок - часть состава).
  static bool _itemListsEqual(List<TemplateItem> a, List<TemplateItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Источник случайности для генерации id. Random.secure доступен везде,
  // куда дотянется dart:math; на проблемных платформах фолбэк на Random().
  static final Random _idRandom = _initRandom();

  static Random _initRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  /// Генерирует уникальный id формата tpl_microseconds_8hex.
  /// UUID-пакета в проекте нет, криптостойкость не нужна - хватает уникальности per-user.
  static String _generateId() {
    final ts = DateTime.now().toUtc().microsecondsSinceEpoch;
    final buf = StringBuffer('tpl_')
      ..write(ts.toRadixString(16))
      ..write('_');
    for (var i = 0; i < 4; i++) {
      final byte = _idRandom.nextInt(256);
      buf.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  // Тестовые хуки: сбрасывают состояние без обращения к SharedPreferences.
  // Не предназначены для продакшена.
  @visibleForTesting
  void debugReset() {
    _templates.clear();
    _loadedUserId = null;
    _isLoaded = false;
  }

  @visibleForTesting
  int? get debugLoadedUserId => _loadedUserId;
}

/// Внутреннее представление позиции, готовой к добавлению в корзину
/// после фильтрации и clamp.
class _ApplicableItem {
  const _ApplicableItem({
    required this.product,
    required this.supplier,
    required this.quantity,
  });

  final Product product;
  final Supplier supplier;
  final int quantity;
}
