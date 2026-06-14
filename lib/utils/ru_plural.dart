import '../services/localization/app_localizations.dart';
import '../services/localization/pluralization_rules.dart';

String pluralizeRu(int count, String one, String few, String many) {
  // Выбираем язык из текущей локали
  return PluralizationRules.pluralize(
    count, 
    one, 
    few, 
    many, 
    language: AppLocalizations.current.locale,
  );
}

String reviewsLabel(int count) {
  final l10n = AppLocalizations.current;
  return '$count ${pluralizeRu(
    count,
    l10n.getString('util_review_one'),
    l10n.getString('util_review_few'),
    l10n.getString('util_review_many'),
  )}';
}
