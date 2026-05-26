part of '../backend.dart';

// Хелперы для работы с адресами: нормализация лейбла/текста, валидация
// payload и DTO-маппер строки addresses.

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
