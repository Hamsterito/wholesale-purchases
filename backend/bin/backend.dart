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
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';

part 'utils/constants.dart';
part 'utils/converters.dart';
part 'utils/json_responses.dart';
part 'utils/auth_helpers.dart';
part 'utils/support_helpers.dart';
part 'utils/order_helpers.dart';
part 'utils/address_helpers.dart';
part 'utils/product_helpers.dart';
part 'utils/avatar_helpers.dart';
part 'utils/exchange_rate_helper.dart';

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
part 'routes/avatar_routes.dart';
part 'routes/static_routes.dart';

void main() async {
  // Подключение к базе данных PostgreSQL с поддержкой переменных окружения и повторными попытками
  final dbHost = env['DB_HOST'] ?? Platform.environment['DB_HOST'] ?? 'localhost';
  final dbPort = int.tryParse(env['DB_PORT'] ?? Platform.environment['DB_PORT'] ?? '') ?? 5432;
  final dbName = env['DB_NAME'] ?? Platform.environment['DB_NAME'] ?? 'shop_db';
  final dbUser = env['DB_USER'] ?? Platform.environment['DB_USER'] ?? 'postgres';
  final dbPass = env['DB_PASS'] ?? Platform.environment['DB_PASS'] ?? '1234';

  late final Connection connection;
  var retries = 5;
  while (retries > 0) {
    try {
      connection = await Connection.open(
        Endpoint(
          host: dbHost,
          port: dbPort,
          database: dbName,
          username: dbUser,
          password: dbPass,
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
      break;
    } catch (e) {
      retries--;
      print('Не удалось подключиться к базе данных. Оставшиеся попытки: $retries. Ошибка: $e');
      if (retries == 0) {
        rethrow;
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

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

  // Проверка и обновление курсов валют при запуске
  await checkAndUpdateExchangeRates(connection);

  final router = Router();

  // Read-роуты (GET) и POST /login
  _registerReadRoutes(router, connection);

  // Mutation-роуты (POST/PATCH/DELETE) и роуты с side effects
  _registerMutationRoutes(router, connection);

  // Админские роуты Super_Admin (X-User-Id)
  _registerAdminModeratorRoutes(router, connection);

  // Каталог поставщиков (модератор)
  _registerSupplierDirectoryRoute(router, connection);

  // Статическая раздача файлов аватарок
  _registerStaticRoutes(router);

  // Настройка middleware для обработки CORS и логирования запросов.
  // Расширяем список разрешённых заголовков, чтобы пропускать кастомный
  // X-User-Id (используется эндпоинтами /admin/moderators*).
  // shelf_cors_headers сам отвечает 200 на OPTIONS-preflight, когда в
  // запросе есть Origin - это покрывает все cross-origin случаи из браузера.
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(
        corsHeaders(
          headers: const {
            ACCESS_CONTROL_ALLOW_HEADERS:
                'accept, accept-encoding, authorization, content-type, dnt, origin, user-agent, x-user-id, x-device-token',
            ACCESS_CONTROL_ALLOW_METHODS:
                'GET, POST, PATCH, PUT, DELETE, OPTIONS',
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

  // Запуск периодической проверки курсов валют (каждый час)
  Timer.periodic(const Duration(hours: 1), (_) async {
    await checkAndUpdateExchangeRates(connection);
  });

  // Запуск HTTP сервера на порту 8081
  final server = await serve(handler, InternetAddress.anyIPv4, 8081);
  print('Сервер запущен: http://${server.address.host}:${server.port}');
}
