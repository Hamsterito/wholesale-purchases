import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'shop_db',
      username: 'postgres',
      password: '123',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  print('✅ Подключено к PostgreSQL!');

  final router = Router();

  router.get('/', (Request request) {
    return Response.ok(
      '✅ Бекенд работает и подключен к PostgreSQL!',
      headers: {'content-type': 'text/plain; charset=utf-8'},
    );
  });

  router.get('/users', (Request request) async {
    final result = await connection.execute('SELECT * FROM users;');
    final users = result.map((row) => row.toColumnMap()).toList();

    return Response.ok(
      users.toString(),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  // 🔐 Авторизация
  router.post('/login', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body); // email, password из Flutter

      final email = data['email'];
      final password = data['password'];

      if (email == null || password == null) {
        return Response.badRequest(body: '❌ Отсутствует email или пароль');
      }

      final result = await connection.execute(
        Sql.named('SELECT * FROM users WHERE email = @email AND password = @password'),
        parameters: {'email': email, 'password': password},
      );

      if (result.isEmpty) {
        return Response.forbidden('❌ Неправильный логин или пароль');
      }

      final user = result.first.toColumnMap();
      return Response.ok(
        '✅ Добро пожаловать, ${user['name']}!',
        headers: {'content-type': 'text/plain; charset=utf-8'},
      );
    } catch (e) {
      print('Ошибка при авторизации: $e');
      return Response.internalServerError(body: '⚠️ Ошибка сервера');
    }
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router);

  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('🚀 Сервер запущен: http://${server.address.host}:${server.port}');
}
