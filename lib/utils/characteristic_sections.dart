import '../models/product.dart';
import '../models/supplier_product.dart';

/// Раздел характеристик товара, отображаемый одним блоком в табе «Характеристики».
/// Состав хранится одной записью с пустым ключом — UI рендерит её одной строкой.
class CharacteristicSection {
  final String title;
  final List<MapEntry<String, String>> items;

  const CharacteristicSection({required this.title, required this.items});
}

/// Собирает разделы характеристик в порядке отображения:
/// «Общие характеристики» → «Питание» → «Состав». Пустые источники пропускаются.
List<CharacteristicSection> buildCharacteristicSections(Product product) {
  final info = product.nutritionalInfo;
  return _buildSections(
    characteristics: product.characteristics,
    calories: info.calories,
    protein: info.protein,
    fat: info.fat,
    carbohydrates: info.carbohydrates,
    ingredients: product.ingredients,
  );
}

/// Те же разделы, но из SupplierProduct — для модератора, который видит
/// сырую заявку поставщика без агрегации по продавцам.
List<CharacteristicSection> buildSupplierProductSections(
  SupplierProduct product,
) {
  final info = product.nutritionalInfo;
  return _buildSections(
    characteristics: product.characteristics,
    calories: info.calories,
    protein: info.protein,
    fat: info.fat,
    carbohydrates: info.carbohydrates,
    ingredients: product.ingredients,
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
      CharacteristicSection(title: 'Общие характеристики', items: general),
    );
  }

  final nutrition = <MapEntry<String, String>>[];
  if (calories > 0) {
    nutrition.add(MapEntry('Калории', '${_formatNumber(calories)} ккал'));
  }
  if (protein > 0) {
    nutrition.add(MapEntry('Белки', '${_formatNumber(protein)} г/100 г'));
  }
  if (fat > 0) {
    nutrition.add(MapEntry('Жиры', '${_formatNumber(fat)} г/100 г'));
  }
  if (carbohydrates > 0) {
    nutrition.add(
      MapEntry('Углеводы', '${_formatNumber(carbohydrates)} г/100 г'),
    );
  }
  if (nutrition.isNotEmpty) {
    sections.add(CharacteristicSection(title: 'Питание', items: nutrition));
  }

  final trimmedIngredients = ingredients.trim();
  if (trimmedIngredients.isNotEmpty) {
    sections.add(
      CharacteristicSection(
        title: 'Состав',
        items: [MapEntry('Состав', trimmedIngredients)],
      ),
    );
  }

  return sections;
}

/// Возвращает true, если описание товара отсутствует или состоит только
/// из пробельных символов — тогда Description_Tab показывает плейсхолдер.
bool shouldShowDescriptionPlaceholder(String? description) {
  return description == null || description.trim().isEmpty;
}

/// Целые значения показываем без дробной части, остальное — с одним знаком после точки.
String _formatNumber(double value) {
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
