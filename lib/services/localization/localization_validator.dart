import 'dart:convert';
import '../app_logger.dart';

/// Валидатор ARB-файлов для проверки полноты переводов
class LocalizationValidator {
  /// Путь к директории с ARB-файлами
  static const String arbDirectory = 'lib/l10n';

  /// Список поддерживаемых локалей
  static const List<String> supportedLocales = ['ru', 'kk'];

  /// Проверяет ARB-файлы на соответствие требованиям
  ///
  /// Возвращает отчёт о проблемах и покрытии переводов.
  static Future<LocalizationValidationReport> validateArbFiles() async {
    final report = LocalizationValidationReport();

    try {
      // Загружаем все ARB-файлы
      final arbFiles = <String, Map<String, dynamic>>{};

      for (final locale in supportedLocales) {
        final path = '$arbDirectory/app_$locale.arb';
        try {
          final content = await _loadAsset(path);
          final jsonData = json.decode(content) as Map<String, dynamic>;
          arbFiles[locale] = jsonData;
        } catch (e) {
          report.missingFiles.add(locale);
          AppLogger.warning('Could not load ARB file for locale: $locale');
        }
      }

      if (arbFiles.isEmpty) {
        return report;
      }

      // Получаем базовые ключи из русского файла
      final russianKeys = <String, dynamic>{};
      final russianData = arbFiles['ru']!;

      for (final entry in russianData.entries) {
        final key = entry.key;
        // Пропускаем метаданные и описания
        if (key.startsWith('@')) continue;
        russianKeys[key] = entry.value;
      }

      report.totalRussianKeys = russianKeys.length;

      // Проверяем каждую локаль на соответствие
      for (final locale in supportedLocales) {
        if (locale == 'ru') continue;

        final localeData = arbFiles[locale]!;
        for (final key in russianKeys.keys) {
          final hasKey = localeData.containsKey(key);

          if (!hasKey) {
            report.missingTranslations[locale] = report.missingTranslations[locale] ?? [];
            report.missingTranslations[locale]!.add(key);
          } else {
            final value = localeData[key];
            if (value == null || (value is String && value.isEmpty)) {
              report.emptyTranslations[locale] = report.emptyTranslations[locale] ?? [];
              report.emptyTranslations[locale]!.add(key);
            }
          }
        }

        // Проверяем naming convention
        for (final key in localeData.keys) {
          if (key.startsWith('@')) continue;
          if (!_isValidKeyName(key)) {
            report.invalidNaming[locale] = report.invalidNaming[locale] ?? [];
            report.invalidNaming[locale]!.add(key);
          }
        }
      }

      // Вычисляем покрытие
      for (final locale in supportedLocales) {
        if (locale == 'ru') continue;

        final missing = report.missingTranslations[locale]?.length ?? 0;
        final covered = russianKeys.length - missing;
        report.coverage[locale] = russianKeys.isEmpty ? 0 : (covered / russianKeys.length * 100).round();
      }

      AppLogger.info('Localization validation complete: ${report.toString()}');
      return report;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Validation failed',
        error: e,
        stackTrace: stackTrace,
      );
      return report;
    }
  }

  /// Проверяет, что ключ следует snake_case конвенции
  static bool _isValidKeyName(String key) {
    final snakeCasePattern = RegExp(r'^[a-z][a-z0-9_]*$');
    return snakeCasePattern.hasMatch(key);
  }

  /// Загружает содержимое ассета (заглушка для Flutter)
  static Future<String> _loadAsset(String path) async {
    // В реальном Flutter приложении используем rootBundle.loadString(path)
    // Для тестирования без Flutter - имитируем
    throw UnsupportedError('Use with Flutter rootBundle');
  }

  /// Проверяет конкретный ARB-контент на валидность
  /// Используется для тестов без Flutter
  static LocalizationValidationReport validateArbContent({
    required Map<String, dynamic> russianArb,
    required Map<String, dynamic> kazakhArb,
  }) {
    final report = LocalizationValidationReport();

    final russianKeys = <String>{};

    for (final entry in russianArb.entries) {
      if (entry.key.startsWith('@')) continue;
      russianKeys.add(entry.key);
    }

    report.totalRussianKeys = russianKeys.length;

    // Проверяем казахский на соответствие
    for (final key in russianKeys) {
      if (!kazakhArb.containsKey(key)) {
        report.missingTranslations['kk'] = report.missingTranslations['kk'] ?? [];
        report.missingTranslations['kk']!.add(key);
      } else {
        final value = kazakhArb[key];
        if (value == null || (value is String && value.isEmpty)) {
          report.emptyTranslations['kk'] = report.emptyTranslations['kk'] ?? [];
          report.emptyTranslations['kk']!.add(key);
        }
      }
    }

    // Проверяем naming convention для казахского
    for (final key in kazakhArb.keys) {
      if (key.startsWith('@')) continue;
      if (!_isValidKeyName(key)) {
        report.invalidNaming['kk'] = report.invalidNaming['kk'] ?? [];
        report.invalidNaming['kk']!.add(key);
      }
    }

    // Вычисляем покрытие
    final missing = report.missingTranslations['kk']?.length ?? 0;
    final covered = russianKeys.length - missing;
    report.coverage['kk'] = russianKeys.isEmpty ? 0 : (covered / russianKeys.length * 100).round();

    return report;
  }
}

/// Отчёт о валидации локализации
class LocalizationValidationReport {
  final List<String> missingFiles = [];
  final Map<String, List<String>> missingTranslations = {};
  final Map<String, List<String>> emptyTranslations = {};
  final Map<String, List<String>> invalidNaming = {};
  final Map<String, int> coverage = {};
  int totalRussianKeys = 0;

  /// Проверяет, что все переводы присутствуют
  bool get isComplete {
    return missingFiles.isEmpty &&
        missingTranslations.values.every((list) => list.isEmpty) &&
        emptyTranslations.values.every((list) => list.isEmpty);
  }

  /// Проверяет, что покрытие 100%
  bool get hasFullCoverage {
    return coverage.values.every((percent) => percent == 100);
  }

  /// Генерирует человекочитаемый отчёт
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Localization Validation Report ===\n');
    buffer.writeln('Russian keys total: $totalRussianKeys\n');

    buffer.writeln('Missing files:');
    if (missingFiles.isEmpty) {
      buffer.writeln('  None');
    } else {
      for (final file in missingFiles) {
        buffer.writeln('  - $file');
      }
    }

    buffer.writeln('\nMissing translations:');
    if (missingTranslations.values.every((list) => list.isEmpty)) {
      buffer.writeln('  None');
    } else {
      for (final entry in missingTranslations.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value.length} missing');
        for (final key in entry.value) {
          buffer.writeln('    - $key');
        }
      }
    }

    buffer.writeln('\nEmpty translations:');
    if (emptyTranslations.values.every((list) => list.isEmpty)) {
      buffer.writeln('  None');
    } else {
      for (final entry in emptyTranslations.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value.length} empty');
        for (final key in entry.value) {
          buffer.writeln('    - $key');
        }
      }
    }

    buffer.writeln('\nInvalid naming:');
    if (invalidNaming.values.every((list) => list.isEmpty)) {
      buffer.writeln('  None');
    } else {
      for (final entry in invalidNaming.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value.length} invalid');
        for (final key in entry.value) {
          buffer.writeln('    - $key');
        }
      }
    }

    buffer.writeln('\nTranslation coverage:');
    for (final entry in coverage.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}%');
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return 'LocalizationValidationReport(isComplete: $isComplete, coverage: $coverage)';
  }
}
