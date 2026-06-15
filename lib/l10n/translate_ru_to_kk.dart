import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Dotenv dotenv = Dotenv();

class Dotenv {
  final Map<String, String> _values = {};
  
  Future<void> load() async {
    final file = File('.env');
    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final idx = trimmed.indexOf('=');
        if (idx > 0) {
          final key = trimmed.substring(0, idx).trim();
          final value = trimmed.substring(idx + 1).trim();
          _values[key] = value;
        }
      }
    }
  }
  
  Map<String, String> get env => _values;
}

const int _kChunkSize = 50;
const int _kMaxRetries = 3;
const Duration _kRetryDelay = Duration(seconds: 2);
const Duration _kChunkDelay = Duration(milliseconds: 300);

void main() async {
  await dotenv.load();

  final String folderId = dotenv.env['KEY_ID_YANDEX'] ?? '';
  final String apiKey   = dotenv.env['SECRET_KEY_YANDEX'] ?? '';

  if (folderId.isEmpty || apiKey.isEmpty) {
    stderr.writeln('Ошибка: переменные KEY_ID_YANDEX или SECRET_KEY_YANDEX не найдены в .env');
    exit(1);
  }
  stdout.writeln('✓ Ключи Yandex Cloud загружены.');

  final sourceFile = File('lib/l10n/app_ru.arb');
  if (!sourceFile.existsSync()) {
    stderr.writeln('Ошибка: файл lib/l10n/app_ru.arb не найден.');
    exit(1);
  }

  final Map<String, dynamic> ruData = jsonDecode(sourceFile.readAsStringSync()) as Map<String, dynamic>;

  final keysToTranslate   = <String>[];
  final textsToTranslate  = <String>[];
  final Map<String, String> descriptionsToTranslate = {};

  for (final entry in ruData.entries) {
    final key   = entry.key;
    final value = entry.value;

    if (key.startsWith('@@')) {
      // Сохраняем метаданные @@ как есть, потом пропишем @@locale = 'kk'
    } else if (key.startsWith('@')) {
      if (value is Map && value['description'] != null) {
        descriptionsToTranslate[key] = value['description'] as String;
      }
    } else {
      keysToTranslate.add(key);
      textsToTranslate.add(value as String);
    }
  }

  stdout.writeln('Строк для перевода: ${textsToTranslate.length}');

  final translatedTexts = await _translateAllInChunks(
    texts: textsToTranslate,
    apiKey: apiKey,
    folderId: folderId,
  );

  if (translatedTexts.length != keysToTranslate.length) {
    stderr.writeln('Предупреждение: отправлено ${keysToTranslate.length} строк, получено ${translatedTexts.length}.');
  }

  final List<String> descTexts = descriptionsToTranslate.values.toList();
  final Map<String, String> translatedDescMap = {};
  
  if (descTexts.isNotEmpty) {
    stdout.writeln('Описаний для перевода: ${descTexts.length}');
    final List<String> translatedDescs = await _translateAllInChunks(
      texts: descTexts,
      apiKey: apiKey,
      folderId: folderId,
    );

    var descIdx = 0;
    for (final metaKey in descriptionsToTranslate.keys) {
      if (descIdx < translatedDescs.length && translatedDescs[descIdx].isNotEmpty) {
        translatedDescMap[metaKey] = translatedDescs[descIdx];
      }
      descIdx++;
    }
  }

  // Сборка результирующего файла сохраняем порядок оригинала
  final kkData = <String, dynamic>{};
  
  for (final entry in ruData.entries) {
    final key = entry.key;
    final value = entry.value;

    if (key.startsWith('@@')) {
      kkData[key] = (key == '@@locale') ? 'kk' : value;
    } else if (key.startsWith('@')) {
      if (value is Map) {
        final copiedMeta = Map<String, dynamic>.from(value);
        if (translatedDescMap.containsKey(key)) {
          copiedMeta['description'] = translatedDescMap[key];
        }
        kkData[key] = copiedMeta;
      } else {
        kkData[key] = value;
      }
    } else {
      final idx = keysToTranslate.indexOf(key);
      kkData[key] = (idx < translatedTexts.length && translatedTexts[idx].isNotEmpty)
          ? translatedTexts[idx]
          : value;
    }
  }

  final destinationFile = File('lib/l10n/app_kk.arb');
  destinationFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(kkData),
  );

  stdout.writeln('\n✓ Готово! Файл lib/l10n/app_kk.arb сохранён. Переведено ключей: ${keysToTranslate.length}.');
}

Future<List<String>> _translateAllInChunks({
  required List<String> texts,
  required String apiKey,
  required String folderId,
}) async {
  final allTranslations = <String>[];

  for (var i = 0; i < texts.length; i += _kChunkSize) {
    final end   = (i + _kChunkSize).clamp(0, texts.length);
    final chunk = texts.sublist(i, end);

    stdout.writeln('  Перевод ${i + 1}–$end из ${texts.length}...');

    final protectedChunk = chunk.map(_protectFlutterVariables).toList();

    final translatedChunk = await _sendWithRetry(
      texts: protectedChunk,
      apiKey: apiKey,
      folderId: folderId,
    );

    if (translatedChunk == null) {
      stderr.writeln('  ✗ Не удалось перевести строки ${i + 1}–$end.');
      allTranslations.addAll(chunk);
    } else {
      allTranslations.addAll(translatedChunk.map(_restoreFlutterVariables));
    }

    if (end < texts.length) {
      await Future.delayed(_kChunkDelay);
    }
  }

  return allTranslations;
}

Future<List<String>?> _sendWithRetry({
  required List<String> texts,
  required String apiKey,
  required String folderId,
}) async {
  for (var attempt = 1; attempt <= _kMaxRetries; attempt++) {
    try {
      final response = await http
          .post(
            Uri.parse('https://translate.api.cloud.yandex.net/translate/v2/translate'),
            headers: {
              'Authorization': 'Api-Key $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'folderId': folderId,
              'texts': texts,
              'targetLanguageCode': 'kk',
              'sourceLanguageCode': 'ru',
              'format': 'HTML',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decodedBody) as Map<String, dynamic>;
        return (json['translations'] as List<dynamic>).map((t) => t['text'] as String).toList();
      }

      final isRetryable = response.statusCode == 429 || response.statusCode >= 500;
      stderr.writeln('  Попытка $attempt/$_kMaxRetries: HTTP ${response.statusCode}');

      if (!isRetryable || attempt == _kMaxRetries) return null;
      await Future.delayed(_kRetryDelay * attempt);
    } catch (e) {
      stderr.writeln('  Попытка $attempt/$_kMaxRetries: исключение — $e');
      if (attempt == _kMaxRetries) return null;
      await Future.delayed(_kRetryDelay * attempt);
    }
  }
  return null;
}

String _protectFlutterVariables(String text) {
  return text.replaceAllMapped(
    RegExp(r'\{([a-zA-Z0-9_]+)\}'),
    (m) => '<notranslate>{${m.group(1)}}</notranslate>',
  );
}

String _restoreFlutterVariables(String text) {
  var result = text.replaceAll(RegExp(r'<\s*/?\s*notranslate\s*>', caseSensitive: false), '');
  return result.replaceAllMapped(RegExp(r'\{\s*([a-zA-Z0-9_]+)\s*\}'), (m) => '{${m.group(1)}}');
}
