import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8081';
    }

    if (Platform.isAndroid) {
      // 10.0.2.2 - для эмулятора Android
      // 192.168.1.101 - для реального устройства в локальной сети
      // Если не работает, замени на IP своего компьютера
      return 'http://192.168.1.101:8081';
    }

    return 'http://localhost:8081';
  }

  static String get aiApiKey {
    // Сначала пробуем получить из compile-time переменной
    const compileTimeKey = String.fromEnvironment('AI_API_KEY');
    if (compileTimeKey.isNotEmpty) {
      return compileTimeKey;
    }

    // Затем пробуем получить из .env файла
    return dotenv.get('AI_API_KEY', fallback: '');
  }

  static String get aiEndpoint {
    final envEndpoint = dotenv.get('AI_ENDPOINT', fallback: '');
    if (envEndpoint.isNotEmpty) {
      return envEndpoint;
    }
    return 'https://generativelanguage.googleapis.com/v1beta/openai';
  }

  static String get aiModel {
    final envModel = dotenv.get('AI_MODEL', fallback: '');
    if (envModel.isNotEmpty) {
      return envModel;
    }
    // Gemini OpenAI Compatibility endpoint требует полный ID: models/<name>
    return 'models/gemini-2.0-flash';
  }
}
