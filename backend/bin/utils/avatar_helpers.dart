part of '../backend.dart';

// Хелперы для аватарок: whitelist MIME, генерация имени файла,
// проверка имени до обращения к ФС и сборка абсолютного URL.

const Set<String> _avatarAllowedMimeTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
};

const int _avatarMaxSizeBytes = 5 * 1024 * 1024;

const String _avatarStorageDir = 'uploads/avatars';

const String _avatarPublicPrefix = '/uploads/avatars';

// Whitelist - единственный источник правды по допустимым типам:
// сначала отсекаем всё лишнее, потом маппим в расширение.
String? _avatarExtensionForMime(String mime) {
  final normalized = mime.trim().toLowerCase();
  if (!_avatarAllowedMimeTypes.contains(normalized)) {
    return null;
  }
  switch (normalized) {
    case 'image/jpeg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    default:
      return null;
  }
}

// Размер 0..5 МБ включительно. Отрицательные отклоняем -
// случайный сбой подсчёта длины не должен пролезать как валидный.
bool isValidAvatarSize(int bytes) {
  return bytes >= 0 && bytes <= _avatarMaxSizeBytes;
}

// Имя вида {userId}_{hex32}.{ext}. UUID без дефисов, чтобы имя не
// содержало разделителей и проходило _isSafeAvatarFilename как есть.
String generateAvatarFilename({required int userId, required String mime}) {
  if (userId <= 0) {
    throw ArgumentError('userId должен быть положительным');
  }
  final ext = _avatarExtensionForMime(mime);
  if (ext == null) {
    throw ArgumentError('Недопустимый MIME-тип: $mime');
  }
  final uuid = const Uuid().v4().replaceAll('-', '');
  return '${userId}_$uuid.$ext';
}

// Защита от path traversal, абсолютных путей, нулевых байт и dot-файлов.
bool _isSafeAvatarFilename(String name) {
  if (name.isEmpty) return false;
  if (name.length > 255) return false;
  if (name.startsWith('.')) return false;
  if (name.contains('..')) return false;
  if (name.contains('/')) return false;
  if (name.contains('\\')) return false;
  if (name.contains('\x00')) return false;
  if (p.isAbsolute(name)) return false;
  return true;
}

// Абсолютный URL для клиента: schema из requestedUri, host из Host-заголовка
// (он обязателен в HTTP/1.1), фолбэк - authority requestedUri.
String _absoluteAvatarUrl(Request request, String relativePath) {
  final scheme = request.requestedUri.scheme;
  final hostHeader = request.headers['host']?.trim();
  final authority = (hostHeader != null && hostHeader.isNotEmpty)
      ? hostHeader
      : request.requestedUri.authority;
  final path = relativePath.startsWith('/') ? relativePath : '/$relativePath';
  return '$scheme://$authority$path';
}

// Нормализует значение avatar_url из БД в абсолютный URL или null.
// Пустые строки тоже считаем за «аватарки нет».
String? _avatarUrlOrNull(Request request, Object? raw) {
  final value = (raw ?? '').toString().trim();
  if (value.isEmpty) return null;
  return _absoluteAvatarUrl(request, value);
}
