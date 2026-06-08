import 'package:flutter/material.dart';

import '../../models/language.dart';
import '../../services/localization/app_localizations.dart';
import '../../services/store/app_settings.dart';

/// Текст, который сам перерисовывается при смене языка.
/// Берёт перевод по ключу из AppLocalizations и слушает AppSettings.language.
class LocalizedText extends StatelessWidget {
  const LocalizedText(
    this.translationKey, {
    super.key,
    this.params,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaler,
  })  : count = null,
        _isPlural = false;

  /// Плюрализованный вариант - форма строки выбирается по count.
  const LocalizedText.plural(
    this.translationKey,
    this.count, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaler,
  })  : params = null,
        _isPlural = true;

  final String translationKey;
  final Map<String, dynamic>? params;
  final int? count;
  final bool _isPlural;

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    // Слушаем смену языка - при изменении ValueNotifier перевод подтянется заново
    return ValueListenableBuilder<Language>(
      valueListenable: AppSettings.language,
      builder: (context, _, __) {
        final l10n = AppLocalizations.of(context);
        final text = _isPlural
            ? l10n.pluralize(translationKey, count ?? 0)
            : l10n.getString(translationKey, params: params);

        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          softWrap: softWrap,
          textScaler: textScaler,
        );
      },
    );
  }
}
