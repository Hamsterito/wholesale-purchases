import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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
}
