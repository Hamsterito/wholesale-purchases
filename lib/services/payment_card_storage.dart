import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PaymentCard {
  final String id;
  final String holderName;
  final String last4;
  final int expMonth;
  final int expYear;
  final String brand;

  const PaymentCard({
    required this.id,
    required this.holderName,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.brand,
  });

  String get maskedNumber => '**** **** **** $last4';

  String get expiryLabel {
    final month = expMonth.toString().padLeft(2, '0');
    final year = (expYear % 100).toString().padLeft(2, '0');
    return '$month/$year';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'holderName': holderName,
    'last4': last4,
    'expMonth': expMonth,
    'expYear': expYear,
    'brand': brand,
  };

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? '',
      last4: json['last4']?.toString() ?? '',
      expMonth: json['expMonth'] is int
          ? json['expMonth'] as int
          : int.tryParse(json['expMonth']?.toString() ?? '') ?? 0,
      expYear: json['expYear'] is int
          ? json['expYear'] as int
          : int.tryParse(json['expYear']?.toString() ?? '') ?? 0,
      brand: json['brand']?.toString() ?? 'Card',
    );
  }
}

class PaymentCardStorage {
  PaymentCardStorage._();

  static const _legacyCardsKey = 'payment_cards';
  static const _cardsKeyPrefix = 'payment_cards_';
  static const _legacyMigratedKey = 'payment_cards_legacy_migrated';
  static const _selectionKeyPrefix = 'payment_selection_';

  static String _cardsKey({int? userId}) {
    if (userId != null && userId > 0) {
      return '$_cardsKeyPrefix$userId';
    }
    return _legacyCardsKey;
  }

  static List<PaymentCard> _decodeCards(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => PaymentCard.fromJson(Map<String, dynamic>.from(item)))
          .where((card) => card.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<PaymentCard>> loadCards({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final cardsKey = _cardsKey(userId: userId);
    final cards = _decodeCards(prefs.getString(cardsKey));
    if (cards.isNotEmpty || userId == null || userId <= 0) {
      return cards;
    }

    // One-time migration from legacy shared key to the first authorized user.
    final migrated = prefs.getBool(_legacyMigratedKey) ?? false;
    if (migrated) {
      return [];
    }
    final legacyCards = _decodeCards(prefs.getString(_legacyCardsKey));
    if (legacyCards.isEmpty) {
      return [];
    }
    await saveCards(legacyCards, userId: userId);
    await prefs.remove(_legacyCardsKey);
    await prefs.setBool(_legacyMigratedKey, true);
    return legacyCards;
  }

  static Future<void> saveCards(List<PaymentCard> cards, {int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(cards.map((card) => card.toJson()).toList());
    await prefs.setString(_cardsKey(userId: userId), payload);
  }

  static Future<void> addCard(PaymentCard card, {int? userId}) async {
    final cards = await loadCards(userId: userId);
    cards.removeWhere((item) => item.id == card.id);
    cards.insert(0, card);
    await saveCards(cards, userId: userId);
  }

  static Future<void> removeCard(String id, {int? userId}) async {
    final cards = await loadCards(userId: userId);
    cards.removeWhere((item) => item.id == id);
    await saveCards(cards, userId: userId);
  }

  static String _selectionKey({int? userId}) {
    if (userId != null && userId > 0) {
      return '$_selectionKeyPrefix$userId';
    }
    return _selectionKeyPrefix;
  }

  static Future<PaymentSelection?> loadSelection({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_selectionKey(userId: userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return PaymentSelection.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSelection(
    PaymentSelection selection, {
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _selectionKey(userId: userId),
      jsonEncode(selection.toJson()),
    );
  }

  static Future<void> clearSelection({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectionKey(userId: userId));
  }
}

class PaymentSelection {
  final String method;
  final String? cardId;

  const PaymentSelection({required this.method, this.cardId});

  Map<String, dynamic> toJson() => {'method': method, 'cardId': cardId};

  factory PaymentSelection.fromJson(Map<String, dynamic> json) {
    return PaymentSelection(
      method: json['method']?.toString() ?? 'Card',
      cardId: json['cardId']?.toString(),
    );
  }
}

String detectCardBrand(String digits) {
  if (digits.startsWith('4')) {
    return 'Visa';
  }
  if (_isMastercard(digits)) {
    return 'Mastercard';
  }
  if (digits.startsWith('34') || digits.startsWith('37')) {
    return 'Amex';
  }
  return 'Card';
}

bool _isMastercard(String digits) {
  if (digits.length < 2) {
    return false;
  }
  final prefix2 = int.tryParse(digits.substring(0, 2)) ?? 0;
  if (prefix2 >= 51 && prefix2 <= 55) {
    return true;
  }
  if (digits.length < 4) {
    return false;
  }
  final prefix4 = int.tryParse(digits.substring(0, 4)) ?? 0;
  return prefix4 >= 2221 && prefix4 <= 2720;
}
