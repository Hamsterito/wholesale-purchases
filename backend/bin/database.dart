import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

late Connection db;

Future<void> initDatabase() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();

  db = await Connection.open(
    Endpoint(
      host: env['DB_HOST'] ?? 'localhost',
      database: env['DB_NAME'] ?? 'postgres',
      username: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASS'] ?? 'password',
      port: int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  print('✅ База данных подключена');
}
