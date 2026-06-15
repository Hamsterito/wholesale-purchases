import 'dart:convert';
import 'dart:io';

void main() {
  final kkFile = File('lib/l10n/app_kk.arb');
  final ruFile = File('lib/l10n/app_ru.arb');

  final kkJson = json.decode(kkFile.readAsStringSync()) as Map<String, dynamic>;
  final ruJson = json.decode(ruFile.readAsStringSync()) as Map<String, dynamic>;

  final reverseKk = <String, List<String>>{};
  for (final entry in kkJson.entries) {
    if (entry.key.startsWith('@')) continue;
    final value = entry.value;
    if (value is String) {
      final normValue = value.toLowerCase().trim().replaceAll(RegExp(r'[^\wа-яА-ЯёЁәіңғүұқөһ]'), '');
      if (normValue.isEmpty) continue;
      reverseKk.putIfAbsent(normValue, () => []).add(entry.key);
    }
  }

  print('Potentially broken translations (same KK value, very different RU values):');
  for (final entry in reverseKk.entries) {
    final keys = entry.value;
    if (keys.length > 1) {
      final ruValues = keys.map((k) => ruJson[k].toString()).toSet();
      if (ruValues.length > 1) {
        bool suspicious = false;
        final firstRu = ruValues.first;
        for (final rv in ruValues) {
           if ((rv.length - firstRu.length).abs() > 3 || rv.toLowerCase() != firstRu.toLowerCase()) {
              suspicious = true;
           }
        }
        
        if (suspicious) {
          print('\nKK Value: "${kkJson[keys.first]}"');
          for (final key in keys) {
            print('  $key: RU="${ruJson[key]}"');
          }
        }
      }
    }
  }
}
