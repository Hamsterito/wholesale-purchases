part of '../backend.dart';

// Общие helpers для CRUD-операций: пересчёт рейтинга товара,
// определение модерационных ролей, авторизация Super_Admin.
Future<void> _recalculateProductRating(
  Connection connection,
  int productId,
) async {
  final result = await connection.execute(
    Sql.named('''
      SELECT COUNT(*) AS count, COALESCE(AVG(rating), 0) AS avg_rating
      FROM reviews
      WHERE product_id = @product_id AND product_id IS NOT NULL;
      '''),
    parameters: {'product_id': productId},
  );

  if (result.isEmpty) {
    return;
  }

  final row = result.first.toColumnMap();
  final count = _toPositiveInt(row['count']);
  final avgRating = double.tryParse(row['avg_rating']?.toString() ?? '') ?? 0.0;

  await connection.execute(
    Sql.named('''
      UPDATE products
      SET rating = @rating,
          review_count = @review_count
      WHERE id = @product_id;
      '''),
    parameters: {
      'rating': avgRating,
      'review_count': count,
      'product_id': productId,
    },
  );
}

/// Допустимые роли для модерационных действий: обычный модератор и
/// главный администратор. Super_Admin наследует все возможности модератора.
const Set<String> _moderationActorRoles = {'moderator', 'super_admin'};

bool _isModerationActor(String? role) {
  if (role == null) return false;
  return _moderationActorRoles.contains(role.trim().toLowerCase());
}

/// Авторизация Super_Admin по заголовку X-User-Id.
/// Возвращает Response 401/403 или Map строки пользователя.
Future<Object> _requireSuperAdmin(
  Request request,
  Connection connection,
) async {
  final raw = request.headers['x-user-id']?.trim();
  if (raw == null || raw.isEmpty) {
    return _jsonError('Требуется авторизация', 401);
  }
  final userId = int.tryParse(raw);
  if (userId == null || userId <= 0) {
    return _jsonError('Требуется авторизация', 401);
  }
  final result = await connection.execute(
    Sql.named('SELECT id, role FROM public.users WHERE id = @id LIMIT 1;'),
    parameters: {'id': userId},
  );
  if (result.isEmpty) {
    return _jsonError('Требуется авторизация', 401);
  }
  final row = result.first.toColumnMap();
  final role = row['role']?.toString().trim().toLowerCase() ?? '';
  if (role != 'super_admin') {
    return _jsonError('Доступ только для главного администратора', 403);
  }
  return row;
}

Future<String?> _resolveUserRoleById(Connection connection, int userId) async {
  if (userId <= 0) return null;
  final result = await connection.execute(
    Sql.named('SELECT role FROM public.users WHERE id = @id LIMIT 1;'),
    parameters: {'id': userId},
  );
  if (result.isEmpty) return null;
  return result.first.toColumnMap()['role']?.toString().trim().toLowerCase();
}

// Authorization для модерационных операций: модератор или super_admin.
// userId берём из query или из заголовка X-User-Id.
Future<Object> _resolveModerationActor(
  Request request,
  Connection connection,
) async {
  final raw =
      request.url.queryParameters['userId'] ??
      request.headers['x-user-id']?.trim();
  if (raw == null || raw.toString().trim().isEmpty) {
    return _jsonError('Требуется авторизация', 401);
  }
  final userId = int.tryParse(raw.toString().trim());
  if (userId == null || userId <= 0) {
    return _jsonError('Требуется авторизация', 401);
  }
  final role = await _resolveUserRoleById(connection, userId);
  if (role == null) {
    return _jsonError('Требуется авторизация', 401);
  }
  if (role != 'moderator' && role != 'super_admin') {
    return _jsonError('Недостаточно прав', 403);
  }
  return userId;
}
