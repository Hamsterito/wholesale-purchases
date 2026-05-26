// Чистый валидатор пользовательских пар «название → значение» для визарда
// товара поставщика. Не зависит от Flutter - только pure Dart.

class CustomCharacteristicValidationError {
  final String message;
  final int? offendingIndex;

  const CustomCharacteristicValidationError(
    this.message, {
    this.offendingIndex,
  });
}

class CustomCharacteristicValidationResult {
  final Map<String, String> normalized;
  final CustomCharacteristicValidationError? error;

  const CustomCharacteristicValidationResult.ok(this.normalized) : error = null;

  const CustomCharacteristicValidationResult.fail(this.error)
    : normalized = const {};

  bool get isOk => error == null;
}

const String _emptyOrTooLongMessage =
    'Заполните название и значение характеристики';
const String _duplicateMessage = 'Такая характеристика уже добавлена';

/// Возвращает .ok(normalized) если все пары валидны и уникальны,
/// иначе .fail(error) с готовым текстом сообщения и индексом проблемного
/// черновика. Уникальность проверяется без учёта регистра и крайних пробелов
/// как между черновиками, так и со starter.keys. В normalized сначала
/// идут пары из starter в исходном порядке, затем - нормализованные пары
/// из drafts.

CustomCharacteristicValidationResult validateCustomCharacteristics(
  List<({String name, String value})> drafts, {
  Map<String, String> starter = const {},
}) {
  final seen = <String>{};
  final result = <String, String>{};

  for (final entry in starter.entries) {
    seen.add(entry.key.trim().toLowerCase());
    result[entry.key] = entry.value;
  }

  for (var i = 0; i < drafts.length; i++) {
    final draft = drafts[i];
    final name = draft.name.trim();
    final value = draft.value.trim();

    if (name.isEmpty ||
        value.isEmpty ||
        name.length > 100 ||
        value.length > 200) {
      return CustomCharacteristicValidationResult.fail(
        CustomCharacteristicValidationError(
          _emptyOrTooLongMessage,
          offendingIndex: i,
        ),
      );
    }

    final normalizedKey = name.toLowerCase();
    if (seen.contains(normalizedKey)) {
      return CustomCharacteristicValidationResult.fail(
        CustomCharacteristicValidationError(
          _duplicateMessage,
          offendingIndex: i,
        ),
      );
    }

    seen.add(normalizedKey);
    result[name] = value;
  }

  return CustomCharacteristicValidationResult.ok(result);
}
