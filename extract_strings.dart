// ignore_for_file: avoid_print, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings
import 'dart:io';
import 'dart:convert';

void main() async {
  final targetDirs = ['lib/widgets', 'lib/login_screen', 'lib/reg_screan', 'lib/forgot_screan', 'lib/moderator', 'lib/supplier', 'lib/components', 'lib/utils', 'lib/theme'];
  final arbFile = File('lib/l10n/app_ru.arb');
  
  if (!arbFile.existsSync()) {
    print('arb not found');
    return;
  }
  
  final arbContent = await arbFile.readAsString();
  final Map<String, dynamic> arbJson = jsonDecode(arbContent);
  
  // Safe regex: single line, no variables ($), no quotes inside
  final regex = RegExp(r"(?<!context\.l10n\.)(['" + '"]' + r")([^'" + "'" + r'"\n\r\$]*[А-Яа-яЁё]+[^' + "'" + r'"\n\r\$]*)\1');

  int newKeys = 0;
  
  for (final dir in targetDirs) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    
    await for (final entity in d.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = await entity.readAsString();
        bool changed = false;
        
        String newContent = content.replaceAllMapped(regex, (match) {
          final text = match.group(2)!;
          
          final baseKey = _toCamelCase(_transliterate(text));
          if (baseKey.isEmpty) return match.group(0)!;
          
          String key = 'auto_$baseKey';
          int suffix = 1;
          while (arbJson.containsKey(key) && arbJson[key] != text) {
            key = 'auto_${baseKey}_$suffix';
            suffix++;
          }
          
          if (!arbJson.containsKey(key)) {
            arbJson[key] = text;
            arbJson['@$key'] = {"description": "Auto-extracted"};
            newKeys++;
          }
          
          changed = true;
          return 'context.l10n.$key';
        });
        
        if (changed) {
          if (!newContent.contains('import \'package:wholesale_purchases/services/localization/localization_extension.dart\';') &&
              !newContent.contains('import \'../../services/localization/localization_extension.dart\';') &&
              !newContent.contains('import \'../services/localization/localization_extension.dart\';') &&
              !newContent.contains('import \'../../../services/localization/localization_extension.dart\';')) {
            // Find last import
            final importIndex = newContent.lastIndexOf(RegExp(r"^import '.*';$", multiLine: true));
            if (importIndex != -1) {
              final endOfImport = newContent.indexOf('\n', importIndex) + 1;
              final pathParts = entity.path.split(Platform.pathSeparator);
              final nesting = pathParts.length - 2; // -1 for file, -1 for lib
              final prefix = List.filled(nesting, '../').join('');
              newContent = newContent.substring(0, endOfImport) + "import '${prefix}services/localization/localization_extension.dart';\n" + newContent.substring(endOfImport);
            }
          }
          await entity.writeAsString(newContent);
          print('Updated ${entity.path}');
        }
      }
    }
  }
  
  if (newKeys > 0) {
    const encoder = JsonEncoder.withIndent('  ');
    await arbFile.writeAsString(encoder.convert(arbJson));
    print('Added $newKeys keys to app_ru.arb');
  } else {
    print('No new keys added');
  }
}

String _transliterate(String text) {
  const Map<String, String> map = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo', 'ж': 'zh',
    'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o',
    'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'ts',
    'ч': 'ch', 'ш': 'sh', 'щ': 'shch', 'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya'
  };
  String res = text.toLowerCase();
  for (var entry in map.entries) {
    res = res.replaceAll(entry.key, entry.value);
  }
  res = res.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
  res = res.replaceAll(RegExp(r'\s+'), '_');
  if (res.length > 25) res = res.substring(0, 25);
  if (res.endsWith('_')) res = res.substring(0, res.length - 1);
  return res;
}

String _toCamelCase(String text) {
  if (text.isEmpty) return '';
  final parts = text.split('_').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  String result = parts[0];
  for (int i = 1; i < parts.length; i++) {
    result += parts[i][0].toUpperCase() + parts[i].substring(1);
  }
  return result;
}
