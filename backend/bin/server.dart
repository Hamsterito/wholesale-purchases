import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import '../bin/database.dart';

void main() async {
  await initDatabase(); // подключаемся к БД при запуске

  final app = Router();

  app.get('/hello', (Request request) {
    return Response.ok(
      'Привет! Сервер работает ✅',
      headers: {'Content-Type': 'text/plain; charset=utf-8'},
    );
  });

















































































































  final server = await serve(app, InternetAddress.anyIPv4, 8080);
  print('🚀 Сервер запущен: http://localhost:${server.port}');
}
