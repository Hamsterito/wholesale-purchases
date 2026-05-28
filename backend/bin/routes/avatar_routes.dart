part of '../backend.dart';

// POST  /users/<id>/avatar - multipart/form-data с полем file
// DELETE /users/<id>/avatar - сбрасывает avatar_url и удаляет файл

void _registerAvatarRoutes(Router router, Connection connection) {
  router.post('/users/<id>/avatar', (Request request, String id) async {
    final userId = int.tryParse(id);
    if (userId == null || userId <= 0) {
      return Response.badRequest(
        body: 'Идентификатор пользователя указан некорректно',
        headers: _utf8TextHeaders,
      );
    }

    final authError = await _authorizeAvatarMutation(
      request,
      connection,
      userId,
    );
    if (authError != null) return authError;

    final contentType = request.headers['content-type'] ?? '';
    if (!contentType.toLowerCase().startsWith('multipart/form-data')) {
      return Response(
        415,
        body: 'Ожидается multipart/form-data',
        headers: _utf8TextHeaders,
      );
    }
    final boundary = _extractMultipartBoundary(contentType);
    if (boundary == null || boundary.isEmpty) {
      return Response(
        415,
        body: 'Ожидается multipart/form-data',
        headers: _utf8TextHeaders,
      );
    }

    File? createdFile;
    StreamIterator<MimeMultipart>? partsIterator;
    try {
      final transformer = MimeMultipartTransformer(boundary);
      // shelf отдаёт Stream<Uint8List>, MimeMultipartTransformer работает
      // с Stream<List<int>> - явный cast убирает несовместимость типов.
      final parts = request.read().cast<List<int>>().transform(transformer);
      partsIterator = StreamIterator<MimeMultipart>(parts);

      MimeMultipart? filePart;
      String partMime = '';

      // Берём первую часть с name="file", остальные drain'им -
      // иначе сокет останется с недочитанными данными.
      while (await partsIterator.moveNext()) {
        final part = partsIterator.current;
        final disposition = part.headers['content-disposition'] ?? '';
        final name = _extractContentDispositionField(disposition, 'name');
        if (name == 'file') {
          partMime = (part.headers['content-type'] ?? '').trim().toLowerCase();
          filePart = part;
          break;
        } else {
          await part.drain<void>(null);
        }
      }

      if (filePart == null) {
        return Response.badRequest(
          body: 'Файл аватарки не передан',
          headers: _utf8TextHeaders,
        );
      }

      final ext = _avatarExtensionForMime(partMime);
      if (ext == null) {
        await filePart.drain<void>(null);
        return Response(
          415,
          body: 'Поддерживаются только JPEG, PNG и WebP',
          headers: _utf8TextHeaders,
        );
      }

      final newFilename = generateAvatarFilename(
        userId: userId,
        mime: partMime,
      );
      final newRelativePath = '$_avatarPublicPrefix/$newFilename';

      final dir = Directory(_avatarStorageDir);
      await dir.create(recursive: true);

      final filePath = p.join(_avatarStorageDir, newFilename);
      final file = File(filePath);
      createdFile = file;

      // Пишем потоково и считаем размер. При превышении лимита
      // обрываем сразу - лишние байты в память не грузим.
      var totalBytes = 0;
      var oversize = false;
      final sink = file.openWrite();
      try {
        await for (final chunk in filePart) {
          totalBytes += chunk.length;
          if (totalBytes > _avatarMaxSizeBytes) {
            oversize = true;
            break;
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (oversize) {
        try {
          await file.delete();
        } catch (_) {}
        createdFile = null;
        return Response(
          413,
          body: 'Размер файла не должен превышать 5 МБ',
          headers: _utf8TextHeaders,
        );
      }

      // Транзакция: запоминаем старый avatar_url и атомарно меняем на новый.
      // Если пользователя нет - бросаем _AvatarUserMissing, чтобы откатиться
      // и удалить только что записанный файл.
      String? oldRelativePath;
      try {
        await connection.runTx((session) async {
          final existing = await session.execute(
            Sql.named(
              'SELECT avatar_url FROM public.users WHERE id = @id LIMIT 1;',
            ),
            parameters: {'id': userId},
          );
          if (existing.isEmpty) {
            throw _AvatarUserMissing();
          }
          final raw = existing.first.toColumnMap()['avatar_url'];
          oldRelativePath = raw?.toString();

          await session.execute(
            Sql.named('''
              UPDATE public.users
              SET avatar_url = @new
              WHERE id = @id;
            '''),
            parameters: {'id': userId, 'new': newRelativePath},
          );
        });
      } on _AvatarUserMissing {
        try {
          await file.delete();
        } catch (_) {}
        return Response.notFound(
          'Пользователь не найден',
          headers: _utf8TextHeaders,
        );
      }

      // БД зафиксировала новый путь - удаляем старый файл, если он был.
      // Падение этого удаления не должно ломать ответ: клиент уже получил
      // новый avatarUrl, БД консистентна.
      if (oldRelativePath != null && oldRelativePath!.isNotEmpty) {
        final oldName = p.basename(oldRelativePath!);
        if (_isSafeAvatarFilename(oldName)) {
          final oldFile = File(p.join(_avatarStorageDir, oldName));
          try {
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (_) {}
        }
      }

      return Response.ok(
        jsonEncode({
          'avatarUrl': _absoluteAvatarUrl(request, newRelativePath),
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при загрузке аватарки: $e\n$st');
      // Любая ошибка после создания файла - удаляем недописанный файл.
      // БД либо не трогалась, либо уже откатилась.
      if (createdFile != null) {
        try {
          await createdFile.delete();
        } catch (_) {}
      }
      return Response.internalServerError(
        body: 'Не удалось сохранить файл',
        headers: _utf8TextHeaders,
      );
    } finally {
      // Дочитываем оставшиеся multipart-части и закрываем итератор.
      // Иначе на keep-alive соединении следующий запрос в браузере
      // умирает с "Failed to fetch", потому что сокет ещё не свободен.
      if (partsIterator != null) {
        try {
          while (await partsIterator.moveNext()) {
            await partsIterator.current.drain<void>(null);
          }
        } catch (_) {}
        try {
          await partsIterator.cancel();
        } catch (_) {}
      }
    }
  });

  router.delete('/users/<id>/avatar', (Request request, String id) async {
    final userId = int.tryParse(id);
    if (userId == null || userId <= 0) {
      return Response.badRequest(
        body: 'Идентификатор пользователя указан некорректно',
        headers: _utf8TextHeaders,
      );
    }

    final authError = await _authorizeAvatarMutation(
      request,
      connection,
      userId,
    );
    if (authError != null) return authError;

    try {
      String? oldRelativePath;
      await connection.runTx((session) async {
        final existing = await session.execute(
          Sql.named(
            'SELECT avatar_url FROM public.users WHERE id = @id LIMIT 1;',
          ),
          parameters: {'id': userId},
        );
        if (existing.isEmpty) {
          // Пользователя нет - тот же 200 {avatarUrl: null}, ФС/БД не трогаем.
          return;
        }
        final raw = existing.first.toColumnMap()['avatar_url'];
        final value = raw?.toString();
        if (value == null || value.isEmpty) {
          // В БД уже NULL - UPDATE и ФС не нужны.
          return;
        }
        oldRelativePath = value;

        await session.execute(
          Sql.named(
            'UPDATE public.users SET avatar_url = NULL WHERE id = @id;',
          ),
          parameters: {'id': userId},
        );
      });

      if (oldRelativePath != null && oldRelativePath!.isNotEmpty) {
        final oldName = p.basename(oldRelativePath!);
        if (_isSafeAvatarFilename(oldName)) {
          final oldFile = File(p.join(_avatarStorageDir, oldName));
          try {
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (_) {}
        }
      }

      return Response.ok(
        jsonEncode({'avatarUrl': null}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e, st) {
      print('Ошибка при удалении аватарки: $e\n$st');
      return Response.internalServerError(
        body: 'Не удалось удалить файл',
        headers: _utf8TextHeaders,
      );
    }
  });
}

// Авторизация мутаций аватарки: владелец профиля или super_admin.
Future<Response?> _authorizeAvatarMutation(
  Request request,
  Connection connection,
  int targetUserId,
) async {
  final raw = request.headers['x-user-id']?.trim() ?? '';
  final actorId = int.tryParse(raw);
  if (actorId == null || actorId <= 0) {
    return _jsonError('Доступ запрещён', 403);
  }
  if (actorId == targetUserId) {
    return null;
  }
  final role = await _resolveUserRoleById(connection, actorId);
  if (role == 'super_admin') {
    return null;
  }
  return _jsonError('Доступ запрещён', 403);
}

// Достаёт boundary из Content-Type. Поддерживает кавычки вокруг значения.
String? _extractMultipartBoundary(String contentType) {
  for (final segment in contentType.split(';')) {
    final trimmed = segment.trim();
    if (trimmed.toLowerCase().startsWith('boundary=')) {
      var value = trimmed.substring('boundary='.length).trim();
      if (value.length >= 2 &&
          value.startsWith('"') &&
          value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      return value;
    }
  }
  return null;
}

// Достаёт значение поля из Content-Disposition: для
// 'form-data; name="file"; filename="a.jpg"' и fieldName='name' вернёт 'file'.
String? _extractContentDispositionField(String header, String fieldName) {
  final pattern = RegExp(
    '${RegExp.escape(fieldName)}=' r'(?:"([^"]*)"|([^;\s]+))',
    caseSensitive: false,
  );
  final match = pattern.firstMatch(header);
  if (match == null) return null;
  return match.group(1) ?? match.group(2);
}

// Маркер для отката транзакции при отсутствии целевого пользователя.
class _AvatarUserMissing implements Exception {}
