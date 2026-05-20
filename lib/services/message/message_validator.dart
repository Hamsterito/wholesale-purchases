import '../../models/message.dart';

// Принимаем строчный и заглавный hex, чтобы не отклонять валидные id из внешних систем.
final RegExp _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Результат валидации: `errors` — критичные нарушения, `warnings` — рекомендации.
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ValidationResult.success({List<String> warnings = const []}) {
    return ValidationResult(
      isValid: true,
      errors: const [],
      warnings: List.unmodifiable(warnings),
    );
  }

  factory ValidationResult.failure(
    List<String> errors, {
    List<String> warnings = const [],
  }) {
    return ValidationResult(
      isValid: false,
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
    );
  }

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Валидатор Message. Все ошибки накапливаются, валидатор не прерывается на первой.
class MessageValidator {
  static const int maxBodyLength = 5000;
  static const int maxTitleLength = 200;

  static ValidationResult validate(Message message) {
    final errors = <String>[];
    final warnings = <String>[];

    if (message.id.isEmpty) {
      errors.add('Поле id пустое');
    } else if (!_uuidRegex.hasMatch(message.id)) {
      errors.add('Поле id не соответствует формату UUID');
    }

    if (message.body.isEmpty) {
      errors.add('Поле body пустое');
    } else if (message.body.length > maxBodyLength) {
      errors.add('Длина body превышает $maxBodyLength символов');
    }

    if (message.title.length > maxTitleLength) {
      errors.add('Длина title превышает $maxTitleLength символов');
    }
    if (message.title.isEmpty) {
      if (message.type == MessageType.error ||
          message.type == MessageType.notification) {
        errors.add('Поле title обязательно для типа "${message.type.value}"');
      }
    }

    if (message.language != 'ru') {
      errors.add(
        'Поддерживается только язык "ru", получен "${message.language}"',
      );
    }

    // Round-trip через ISO 8601 ловит подделанные DateTime, которые не сериализуются.
    if (!_isTimestampRoundTrippable(message.timestamp)) {
      errors.add('Поле timestamp некорректно или не сериализуется в ISO 8601');
    }

    if (!MessageType.values.contains(message.type)) {
      errors.add('Неизвестное значение type');
    }
    if (!MessageSeverity.values.contains(message.severity)) {
      errors.add('Неизвестное значение severity');
    }

    _applyTypeSpecificRules(message, errors, warnings);

    if (errors.isEmpty) {
      return ValidationResult.success(warnings: warnings);
    }
    return ValidationResult.failure(errors, warnings: warnings);
  }

  /// Валидация сырого JSON до конструирования Message — чтобы не доводить до исключений в fromJson.
  static ValidationResult validatePartial(Map<String, dynamic> json) {
    final errors = <String>[];
    final warnings = <String>[];

    if (json.containsKey('id')) {
      final id = json['id'];
      if (id is! String || id.isEmpty) {
        errors.add('Поле id должно быть непустой строкой');
      } else if (!_uuidRegex.hasMatch(id)) {
        errors.add('Поле id не соответствует формату UUID');
      }
    }

    if (json.containsKey('type')) {
      final type = json['type'];
      if (type is! String) {
        errors.add('Поле type должно быть строкой');
      } else if (!_isKnownEnumValue(
        type,
        MessageType.values.map((e) => e.value),
      )) {
        errors.add('Неизвестное значение type: "$type"');
      }
    }

    if (json.containsKey('severity')) {
      final severity = json['severity'];
      if (severity is! String) {
        errors.add('Поле severity должно быть строкой');
      } else if (!_isKnownEnumValue(
        severity,
        MessageSeverity.values.map((e) => e.value),
      )) {
        errors.add('Неизвестное значение severity: "$severity"');
      }
    }

    if (json.containsKey('body')) {
      final body = json['body'];
      if (body is! String) {
        errors.add('Поле body должно быть строкой');
      } else if (body.isEmpty) {
        errors.add('Поле body пустое');
      } else if (body.length > maxBodyLength) {
        errors.add('Длина body превышает $maxBodyLength символов');
      }
    }

    if (json.containsKey('title')) {
      final title = json['title'];
      if (title is! String) {
        errors.add('Поле title должно быть строкой');
      } else if (title.length > maxTitleLength) {
        errors.add('Длина title превышает $maxTitleLength символов');
      }
    }

    if (json.containsKey('timestamp')) {
      final ts = json['timestamp'];
      if (ts is DateTime) {
        if (!_isTimestampRoundTrippable(ts)) {
          errors.add('Поле timestamp не сериализуется в ISO 8601');
        }
      } else if (ts is String) {
        if (DateTime.tryParse(ts) == null) {
          errors.add('Поле timestamp не парсится как ISO 8601');
        }
      } else {
        errors.add('Поле timestamp должно быть строкой ISO 8601 или DateTime');
      }
    }

    if (json.containsKey('language')) {
      final lang = json['language'];
      if (lang is! String) {
        errors.add('Поле language должно быть строкой');
      } else if (lang != 'ru') {
        errors.add('Поддерживается только язык "ru", получен "$lang"');
      }
    }

    if (errors.isEmpty) {
      return ValidationResult.success(warnings: warnings);
    }
    return ValidationResult.failure(errors, warnings: warnings);
  }

  static void _applyTypeSpecificRules(
    Message message,
    List<String> errors,
    List<String> warnings,
  ) {
    switch (message.type) {
      case MessageType.apiResponse:
        break;
      case MessageType.error:
        if (message.code == null || message.code!.isEmpty) {
          warnings.add('Для типа "error" рекомендуется указывать поле code');
        }
        break;
      case MessageType.notification:
        break;
      case MessageType.supportChat:
        break;
      case MessageType.aiGenerated:
        final model = message.metadata['model'];
        if (model == null || (model is String && model.isEmpty)) {
          warnings.add(
            'Для типа "ai_generated" рекомендуется указывать metadata["model"]',
          );
        }
        break;
    }
  }

  static bool _isTimestampRoundTrippable(DateTime timestamp) {
    try {
      final iso = timestamp.toIso8601String();
      return DateTime.tryParse(iso) != null;
    } catch (_) {
      return false;
    }
  }

  static bool _isKnownEnumValue(String value, Iterable<String> known) {
    for (final v in known) {
      if (v == value) return true;
    }
    return false;
  }
}
