import 'package:flutter/widgets.dart';
import '../models/product.dart';
import '../models/supplier_product.dart';
import '../services/localization/app_localizations.dart';

/// Раздел характеристик товара, отображаемый одним блоком в табе «Характеристики».
/// Состав хранится одной записью с пустым ключом - UI рендерит её одной строкой.
class CharacteristicSection {
  final String title;
  final List<MapEntry<String, String>> items;

  const CharacteristicSection({required this.title, required this.items});
}

/// Собирает разделы характеристик в порядке отображения:
/// «Общие характеристики» → «Питание» → «Состав». Пустые источники пропускаются.
List<CharacteristicSection> buildCharacteristicSections(Product product, BuildContext context) {
  final info = product.nutritionalInfo;
  return _buildSections(
    characteristics: product.localizedCharacteristics(context),
    calories: info.calories,
    protein: info.protein,
    fat: info.fat,
    carbohydrates: info.carbohydrates,
    ingredients: product.localizedIngredients(context),
  );
}

/// Те же разделы, но из SupplierProduct - для модератора, который видит
/// сырую заявку поставщика без агрегации по продавцам.
List<CharacteristicSection> buildSupplierProductSections(
  SupplierProduct product,
  BuildContext context,
) {
  final info = product.nutritionalInfo;
  return _buildSections(
    characteristics: product.localizedCharacteristics(context),
    calories: info.calories,
    protein: info.protein,
    fat: info.fat,
    carbohydrates: info.carbohydrates,
    ingredients: product.localizedIngredients(context),
  );
}

List<CharacteristicSection> _buildSections({
  required Map<String, String> characteristics,
  required double calories,
  required double protein,
  required double fat,
  required double carbohydrates,
  required String ingredients,
}) {
  final sections = <CharacteristicSection>[];

  final general = <MapEntry<String, String>>[];
  for (final entry in characteristics.entries) {
    final key = entry.key.trim();
    final value = entry.value.trim();
    if (key.isEmpty || value.isEmpty) continue;
    general.add(MapEntry(key, value));
  }
  if (general.isNotEmpty) {
    sections.add(
      CharacteristicSection(title: AppLocalizations.current.getString('util_general_characteristics'), items: general),
    );
  }

  final nutrition = <MapEntry<String, String>>[];
  if (calories > 0) {
    nutrition.add(MapEntry(AppLocalizations.current.getString('util_calories'), '${_formatNumber(calories)} ${AppLocalizations.current.getString('util_kcal')}'));
  }
  if (protein > 0) {
    nutrition.add(MapEntry(AppLocalizations.current.getString('util_protein'), '${_formatNumber(protein)} ${AppLocalizations.current.getString('util_grams_per_100g')}'));
  }
  if (fat > 0) {
    nutrition.add(MapEntry(AppLocalizations.current.getString('util_fat'), '${_formatNumber(fat)} ${AppLocalizations.current.getString('util_grams_per_100g')}'));
  }
  if (carbohydrates > 0) {
    nutrition.add(
      MapEntry(AppLocalizations.current.getString('util_carbohydrates'), '${_formatNumber(carbohydrates)} ${AppLocalizations.current.getString('util_grams_per_100g')}'),
    );
  }
  if (nutrition.isNotEmpty) {
    sections.add(CharacteristicSection(title: AppLocalizations.current.getString('util_nutrition'), items: nutrition));
  }

  final trimmedIngredients = ingredients.trim();
  if (trimmedIngredients.isNotEmpty) {
    sections.add(
      CharacteristicSection(
        title: AppLocalizations.current.getString('util_composition'),
        items: [MapEntry(AppLocalizations.current.getString('util_composition'), trimmedIngredients)],
      ),
    );
  }

  return sections;
}

/// Возвращает true, если описание товара отсутствует или состоит только
/// из пробельных символов - тогда Description_Tab показывает плейсхолдер.
bool shouldShowDescriptionPlaceholder(String? description) {
  return description == null || description.trim().isEmpty;
}

/// Целые значения показываем без дробной части, остальное - с одним знаком после точки.
String _formatNumber(double value) {
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
