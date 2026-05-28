import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:postgres/postgres.dart';
import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:dotenv/dotenv.dart';
import 'package:excel/excel.dart';

part 'utils/constants.dart';
part 'utils/converters.dart';
part 'utils/json_responses.dart';
part 'utils/auth_helpers.dart';
part 'utils/support_helpers.dart';
part 'utils/order_helpers.dart';
part 'utils/address_helpers.dart';
part 'utils/product_helpers.dart';

part 'schema_tables.dart';
part 'crud_operations.dart';
part 'routes/helpers.dart';
part 'routes/shared_user_routes.dart';
part 'routes/buyer_routes.dart';
part 'routes/supplier_routes.dart';
part 'routes/moderator_routes.dart';
part 'routes/admin_routes.dart';
part 'routes/auth_routes.dart';
part 'routes/two_factor_routes.dart';
part 'routes/support_routes.dart';

// Главная функция приложения
void main() async {
  // Подключение к базе данных PostgreSQL
  final connection = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'shop_db',
      username: 'postgres',
      password: '1234',
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

  // Создаём/чиним главного администратора при каждом старте
  await _ensureSuperAdminUser(connection);

  // Дефолтный поставщик dima@gmail.com / 123456 - удобный аккаунт для разработки.
  await _ensureDefaultSupplierUser(connection);

  final router = Router();

  // Read-роуты (GET) и POST /login
  _registerReadRoutes(router, connection);

  // Mutation-роуты (POST/PATCH/DELETE) и роуты с side effects
  _registerMutationRoutes(router, connection);

  // Админские роуты Super_Admin (X-User-Id)
  _registerAdminModeratorRoutes(router, connection);

  // Каталог поставщиков (модератор)
  _registerSupplierDirectoryRoute(router, connection);

  // Настройка middleware для обработки CORS и логирования запросов.
  // Расширяем список разрешённых заголовков, чтобы пропускать кастомный
  // X-User-Id (используется эндпоинтами /admin/moderators*).
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(
        corsHeaders(
          headers: const {
            ACCESS_CONTROL_ALLOW_HEADERS:
                'accept, accept-encoding, authorization, content-type, dnt, origin, user-agent, x-user-id',
          },
        ),
      )
      .addHandler(router.call);

  // Запуск периодической очистки истекших OTP кодов (каждые 10 минут)
  Timer.periodic(const Duration(minutes: 10), (_) async {
    await _cleanupExpiredEmailVerifications(connection);
    await _cleanupExpiredPasswordResets(connection);
    await _cleanupExpiredTwoFactorPendingSessions(connection);
    await _cleanupExpiredTrustedDevices(connection);
  });

  // Запуск HTTP сервера на порту 8080
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('Сервер запущен: http://${server.address.host}:${server.port}');
}
