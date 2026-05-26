/// Модели для каталога поставщиков. Раньше тут жили модели отдельного
/// модератор-поставщикского чата - теперь чат идёт через support_chats.
library;

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _parseString(dynamic value) => value?.toString() ?? '';

String? _parseNullableString(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  return str.isEmpty ? null : str;
}

/// Запись в каталоге поставщиков.
class SupplierDirectoryEntry {
  final int supplierId;
  final String displayName;
  final String companyName;
  final String? email;
  final String? avatarUrl;

  const SupplierDirectoryEntry({
    required this.supplierId,
    required this.displayName,
    required this.companyName,
    this.email,
    this.avatarUrl,
  });

  factory SupplierDirectoryEntry.fromJson(Map<String, dynamic> json) {
    return SupplierDirectoryEntry(
      supplierId: _parseInt(json['supplierId']),
      displayName: _parseString(json['displayName']),
      companyName: _parseString(json['companyName']),
      email: _parseNullableString(json['email']),
      avatarUrl: _parseNullableString(json['avatarUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'displayName': displayName,
      'companyName': companyName,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

/// Ответ от GET /moderation/suppliers.
class SupplierDirectoryPage {
  final List<SupplierDirectoryEntry> items;
  final int total;
  final int offset;
  final int limit;

  const SupplierDirectoryPage({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });

  bool get hasMore => offset + items.length < total;

  factory SupplierDirectoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => SupplierDirectoryEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <SupplierDirectoryEntry>[];

    return SupplierDirectoryPage(
      items: items,
      total: _parseInt(json['total']),
      offset: _parseInt(json['offset']),
      limit: _parseInt(json['limit']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'total': total,
      'offset': offset,
      'limit': limit,
    };
  }
}
