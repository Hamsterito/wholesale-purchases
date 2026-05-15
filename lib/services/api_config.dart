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
      return 'http://localhost:8080';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://localhost:8080';
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
    return 'https://openrouter.ai/api/v1';
  }

  static String get aiModel {
    final envModel = dotenv.get('AI_MODEL', fallback: '');
    if (envModel.isNotEmpty) {
      return envModel;
    }
    return 'google/gemma-4-31b-it:free';
  }
}
