part of '../backend.dart';

// Раздача файлов аватарок: GET /uploads/avatars/<filename>.
// Имя проверяется до любых обращений к ФС - защита от path traversal.

const Map<String, String> _avatarMimeByExtension = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

void _registerStaticRoutes(Router router) {
  router.get('/uploads/avatars/<filename>', (
    Request request,
    String filename,
  ) async {
    if (!_isSafeAvatarFilename(filename)) {
      return Response.badRequest(
        body: 'Недопустимое имя файла',
        headers: _utf8TextHeaders,
      );
    }

    final file = File(p.join(_avatarStorageDir, filename));
    if (!await file.exists()) {
      return Response.notFound(
        'Файл не найден',
        headers: _utf8TextHeaders,
      );
    }

    // MIME по расширению - на загрузке мы пишем только jpg/png/webp,
    // но защищаемся и от ручных файлов в каталоге.
    final ext = p.extension(filename).toLowerCase();
    final mime = _avatarMimeByExtension[ext];
    if (mime == null) {
      return Response.notFound(
        'Файл не найден',
        headers: _utf8TextHeaders,
      );
    }

    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': mime,
        'cache-control': 'public, max-age=86400',
      },
    );
  });
}
