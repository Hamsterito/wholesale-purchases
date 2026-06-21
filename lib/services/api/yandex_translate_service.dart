import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../app_logger.dart';

class YandexTranslateService {
  static const String _baseUrl = 'https://translate.api.cloud.yandex.net/translate/v2/translate';

  /// Переводит текст с русского на казахский
  static Future<String> translateToKazakh(String text) async {
    if (text.trim().isEmpty) return '';

    final apiKey = dotenv.get('SECRET_KEY_YANDEX', fallback: '');
    if (apiKey.isEmpty) {
      AppLogger.warning('Ошибка: Yandex API ключ не найден', scope: 'yandex_translate');
      return text;
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Api-Key $apiKey',
        },
        body: jsonEncode({
          'targetLanguageCode': 'kk',
          'texts': [text],
          'folderId': '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['translations'] != null && data['translations'].isNotEmpty) {
          return data['translations'][0]['text'] ?? text;
        }
      } else {
        AppLogger.error('Ошибка перевода: ${response.statusCode} - ${response.body}', scope: 'yandex_translate');
      }
    } catch (e, st) {
      AppLogger.error('Исключение при переводе', scope: 'yandex_translate', error: e, stackTrace: st);
    }

    return text;
  }

  /// Переводит Map значений
  static Future<Map<String, String>> translateMapToKazakh(Map<String, String> map) async {
    final result = <String, String>{};
    for (final entry in map.entries) {
      result[entry.key] = await translateToKazakh(entry.value);
    }
    return result;
  }
}
