/// Поддерживаемые языки в приложении
enum LanguageCode {
  russian, // ru
  kazakh,  // kk
}

extension LanguageCodeExtension on LanguageCode {
  String get code {
    switch (this) {
      case LanguageCode.russian:
        return 'ru';
      case LanguageCode.kazakh:
        return 'kk';
    }
  }

  String get displayName {
    switch (this) {
      case LanguageCode.russian:
        return 'Русский';
      case LanguageCode.kazakh:
        return 'Қазақша';
    }
  }

  String get displayNameInLanguage {
    switch (this) {
      case LanguageCode.russian:
        return 'Русский';
      case LanguageCode.kazakh:
        return 'Қазақша';
    }
  }
}

class Language {
  final LanguageCode code;
  final String nativeName;
  final String englishName;

  Language({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  String get displayNameInLanguage => code.displayNameInLanguage;

  static final List<Language> supported = [
    Language(
      code: LanguageCode.russian,
      nativeName: 'Русский',
      englishName: 'Russian',
    ),
    Language(
      code: LanguageCode.kazakh,
      nativeName: 'Қазақша',
      englishName: 'Kazakh',
    ),
  ];

  static Language? fromCode(String code) {
    try {
      return supported.firstWhere((lang) => lang.code.code == code);
    } catch (e) {
      return null;
    }
  }

  static Language get defaultLanguage => supported.first;
}
