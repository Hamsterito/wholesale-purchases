import 'dart:convert';
import 'dart:io';

void main() {
  final kkFile = File('lib/l10n/app_kk.arb');
  final ruFile = File('lib/l10n/app_ru.arb');

  final kkJson = json.decode(kkFile.readAsStringSync()) as Map<String, dynamic>;
  final ruJson = json.decode(ruFile.readAsStringSync()) as Map<String, dynamic>;

  final kazakhSpecific = RegExp(r'[әіңғүұқөһӘІҢҒҮҰҚӨҺ]');
  final cyrillic = RegExp(r'[А-Яа-яЁё]');

  // Whitelist of keys we already checked and know are OK or acceptable loanwords
  final whitelistKeys = [
    'catalog_title', 'profile_title', 'settings_currency', 'nav_statistics',
    'cart_payment_method_card', 'filter_sort_rating', 'filter_rating_title',
    'unit_kcal_short', 'unit_g_short', 'auto_kod', 'role_moderator',
    'supplier_stats', 'auto_moderator', 'util_kcal', 'util_grams_per_100g',
    'util_minute_many', 'auto_partiya', 'zakazi_minutes',
    'nutrition_calories_unit', 'nutrition_grams_unit', 'auto_telefon',
    'auto_pozitsiya', 'auto_katalog', 'auto_reyting', 'auto_ivanIvanov',
    'auto_foto', 'auto_kompaniya', 'auto_statistika', 'auto_nm'
  ];

  for (final entry in kkJson.entries) {
    if (entry.key.startsWith('@')) continue;
    if (whitelistKeys.contains(entry.key)) continue;
    if (entry.key.startsWith('search_normalizer')) continue;
    if (entry.key.startsWith('month_year_parser')) continue;

    final value = entry.value;
    if (value is String) {
      if (cyrillic.hasMatch(value) && !kazakhSpecific.hasMatch(value)) {
        final lettersOnly = value.replaceAll(RegExp(r'[^А-Яа-яЁё]'), '');
        if (lettersOnly.length >= 5) {
           final ruValue = ruJson[entry.key];
           print('Key: ${entry.key}');
           print('  RU: $ruValue');
           print('  KK: $value');
        }
      }
    }
  }
}
