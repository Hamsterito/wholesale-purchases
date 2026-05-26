part of '../backend.dart';

// Хелперы для JSON-ответов и нормализации email/role.

// Нормализация email: убираем пробелы и приводим к нижнему регистру
String _normalizeEmail(String email) => email.trim().toLowerCase();

// Проверка валидности email по регулярному выражению
bool _isValidEmail(String email) => _emailPattern.hasMatch(email);

// Создание успешного JSON ответа
Response _jsonSuccess(String message, [Map<String, dynamic>? data]) {
  final body = <String, dynamic>{'success': true, 'message': message};
  if (data != null) body.addAll(data);
  return Response.ok(
    jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

// Создание JSON ответа с ошибкой
Response _jsonError(String message, int statusCode) {
  return Response(
    statusCode,
    body: jsonEncode({'success': false, 'message': message}),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

// Нормализация роли пользователя
// Если роль недопустимая или пустая, возвращает роль по умолчанию
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
