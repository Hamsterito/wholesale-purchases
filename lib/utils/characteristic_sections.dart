import 'package:flutter/widgets.dart';
import '../models/language.dart';
import '../models/product.dart';
import '../models/supplier_product.dart';
import '../services/localization/app_localizations.dart';
import '../services/localization/localization_extension.dart';

class CharacteristicItem {
  final String primaryKey;
  final String primaryValue;
  final String? secondaryKey;
  final String? secondaryValue;

  const CharacteristicItem({
    required this.primaryKey,
    required this.primaryValue,
    this.secondaryKey,
    this.secondaryValue,
  });
}

/// Раздел характеристик товара, отображаемый одним блоком в табе «Характеристики».
/// Состав хранится одной записью с пустым ключом - UI рендерит её одной строкой.
class CharacteristicSection {
  final String title;
  final List<CharacteristicItem> items;

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
    // Pass original supplier product data for secondary text
    supplierProduct: product,
    isKk: context.currentLanguage == LanguageCode.kazakh,
  );
}

List<CharacteristicSection> _buildSections({
  required Map<String, String> characteristics,
  required double calories,
  required double protein,
  required double fat,
  required double carbohydrates,
  required String ingredients,
  SupplierProduct? supplierProduct,
  bool isKk = false,
}) {
  final sections = <CharacteristicSection>[];

  final general = <CharacteristicItem>[];
  
  if (supplierProduct != null) {
    // We have supplier product, so we can correlate with original keys
    // characteristics parameter is ALREADY localized (keys and values are in current language)
    // We need to iterate over the ORIGINAL Russian characteristics to maintain the link
    for (final entry in supplierProduct.characteristics.entries) {
      final ruKey = entry.key.trim();
      final ruValue = entry.value.trim();
      if (ruKey.isEmpty || ruValue.isEmpty) continue;
    }
  }

  // Actually, localizedCharacteristics preserves order, so we can just iterate it.
  // And we can iterate supplierProduct.characteristics to get the corresponding original entries.
  List<MapEntry<String, String>> originalEntries = [];
  List<MapEntry<String, String>> originalKkEntries = [];
  if (supplierProduct != null) {
    final allOriginal = supplierProduct.characteristics.entries.toList();
    final allKk = supplierProduct.characteristicsKk.entries.toList();
    
    for (int i = 0; i < allOriginal.length; i++) {
      final e = allOriginal[i];
      if (e.key.trim().isNotEmpty && e.value.trim().isNotEmpty) {
        originalEntries.add(e);
        if (i < allKk.length) {
          originalKkEntries.add(allKk[i]);
        } else {
          originalKkEntries.add(const MapEntry('', ''));
        }
      }
    }
  }

  int index = 0;
  for (final entry in characteristics.entries) {
    final key = entry.key.trim();
    final value = entry.value.trim();
    if (key.isEmpty || value.isEmpty) continue;
    
    String? secKey;
    String? secValue;
    
    if (supplierProduct != null && index < originalEntries.length) {
       final ruVal = originalEntries[index].value;
       final kkVal = originalKkEntries[index].value;
       
       if (isKk) {
         secKey = null; // Don't show secondary key, or maybe 'RU'
         secValue = 'RU: $ruVal';
       } else if (kkVal.isNotEmpty) {
         secKey = null;
         secValue = 'КК: $kkVal';
       }
    }

    general.add(CharacteristicItem(
      primaryKey: key, 
      primaryValue: value,
      secondaryKey: secKey,
      secondaryValue: secValue,
    ));
    index++;
  }
  
  if (general.isNotEmpty) {
    sections.add(
      CharacteristicSection(title: AppLocalizations.current.getString('util_general_characteristics'), items: general),
    );
  }

  final nutrition = <CharacteristicItem>[];
  if (calories > 0) {
    nutrition.add(CharacteristicItem(primaryKey: AppLocalizations.current.getString('util_calories'), primaryValue: '${_formatNumber(calories)} ${AppLocalizations.current.getString('util_kcal')}'));
  }
  if (protein > 0) {
    nutrition.add(CharacteristicItem(primaryKey: AppLocalizations.current.getString('util_protein'), primaryValue: '${_formatNumber(protein)} ${AppLocalizations.current.getString('util_grams_per_100g')}'));
  }
  if (fat > 0) {
    nutrition.add(CharacteristicItem(primaryKey: AppLocalizations.current.getString('util_fat'), primaryValue: '${_formatNumber(fat)} ${AppLocalizations.current.getString('util_grams_per_100g')}'));
  }
  if (carbohydrates > 0) {
    nutrition.add(
      CharacteristicItem(primaryKey: AppLocalizations.current.getString('util_carbohydrates'), primaryValue: '${_formatNumber(carbohydrates)} ${AppLocalizations.current.getString('util_grams_per_100g')}'),
    );
  }
  if (nutrition.isNotEmpty) {
    sections.add(CharacteristicSection(title: AppLocalizations.current.getString('util_nutrition'), items: nutrition));
  }

  final trimmedIngredients = ingredients.trim();
  if (trimmedIngredients.isNotEmpty) {
    String? secVal;
    if (supplierProduct != null) {
      if (isKk && supplierProduct.ingredientsKk.isNotEmpty) {
        secVal = 'RU: ${supplierProduct.ingredients.trim()}';
      } else if (!isKk && supplierProduct.ingredientsKk.trim().isNotEmpty) {
        secVal = 'КК: ${supplierProduct.ingredientsKk.trim()}';
      }
    }
    sections.add(
      CharacteristicSection(
        title: AppLocalizations.current.getString('util_composition'),
        items: [CharacteristicItem(
          primaryKey: AppLocalizations.current.getString('util_composition'), 
          primaryValue: trimmedIngredients,
          secondaryValue: secVal,
        )],
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
