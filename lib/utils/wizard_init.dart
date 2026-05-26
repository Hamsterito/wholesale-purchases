/// Чистые init-функции для edit-режима SupplierProductWizardPage.
///
/// Вынесены в отдельный модуль, чтобы покрыть property-тестами без
/// поднятия Flutter-стека: ни один import из package:flutter здесь
/// не нужен.
library;

/// Ключи характеристик, которые редактируются отдельными полями визарда
/// (страна и срок годности) и не попадают в список произвольных характеристик.
const String _countryCharacteristicKey = 'Страна производителя';
const String _shelfLifeCharacteristicKey = 'Срок годности';

/// Превращает product.characteristics в список черновиков для блока
/// произвольных характеристик. Записи с ключами «Страна производителя» и
/// «Срок годности» (точное совпадение после trim) выкидываются - их
/// редактируют отдельные поля.
///
/// Порядок и оригинальные name/value сохраняются как в Map.entries;
/// trim делает уже валидатор при сохранении.
List<({String name, String value})> initCustomCharacteristicDrafts(
  Map<String, String> characteristics,
) {
  final drafts = <({String name, String value})>[];
  for (final entry in characteristics.entries) {
    final key = entry.key.trim();
    if (key == _countryCharacteristicKey) continue;
    if (key == _shelfLifeCharacteristicKey) continue;
    drafts.add((name: entry.key, value: entry.value));
  }
  return drafts;
}

/// Подготавливает список изображений для edit-режима визарда.
///
/// Каждый путь триммится; пустые строки и пути, которые isDisplayable
/// не распознал (битые URL, неизвестные схемы), отбрасываются. Дубликаты
/// удаляются по первому вхождению - порядок остаётся стабильным.
///
/// isDisplayable инжектится извне, чтобы оставить файл чистым Dart-ом.
List<String> initWizardImages(
  List<String> imageUrls,
  bool Function(String) isDisplayable,
) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in imageUrls) {
    final normalized = raw.trim();
    if (normalized.isEmpty) continue;
    if (!isDisplayable(normalized)) continue;
    if (seen.add(normalized)) {
      result.add(normalized);
    }
  }
  return result;
}
