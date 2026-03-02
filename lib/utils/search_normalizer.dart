import 'text_normalizer.dart';

class SearchNormalizer {
  SearchNormalizer._();

  static String buildSearchText(String input) {
    final base = _normalizeBase(input);
    if (base.isEmpty) return '';
    final variants = <String>{
      base,
      _normalizeBase(_transliterateCyrToLat(base)),
      _normalizeBase(_transliterateLatToCyr(base)),
      _normalizeBase(_swapLayoutCyrToLat(base)),
      _normalizeBase(_swapLayoutLatToCyr(base)),
    }..removeWhere((value) => value.isEmpty);
    return variants.join(' ');
  }

  static List<String> tokenizeQuery(String query) {
    final base = _normalizeBase(query);
    if (base.isEmpty) return const [];
    return base.split(' ');
  }

  static bool matchesTokens(String haystack, List<String> tokens) {
    if (tokens.isEmpty) return true;
    if (haystack.isEmpty) return false;

    for (final token in tokens) {
      if (token.isEmpty) continue;
      final variants = _expandToken(token);
      var matched = false;
      for (final variant in variants) {
        if (haystack.contains(variant)) {
          matched = true;
          break;
        }
      }
      if (!matched) return false;
    }
    return true;
  }

  static List<String> _expandToken(String token) {
    final variants = <String>{
      token,
      _normalizeBase(_transliterateCyrToLat(token)),
      _normalizeBase(_transliterateLatToCyr(token)),
      _normalizeBase(_swapLayoutCyrToLat(token)),
      _normalizeBase(_swapLayoutLatToCyr(token)),
    }..removeWhere((value) => value.isEmpty);
    return variants.toList();
  }

  static String _normalizeBase(String input) {
    var value = TextNormalizer.normalize(input);
    value = value.toLowerCase();
    value = value.replaceAll('ё', 'е');
    value = value.replaceAll(RegExp(r'[ъь]'), '');
    value = value.replaceAll(
      RegExp(r'[^0-9a-z\u0400-\u04FF]+', caseSensitive: false),
      ' ',
    );
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return value;
  }

  static String _transliterateCyrToLat(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final mapped = _cyrToLat[char];
      if (mapped != null) {
        buffer.write(mapped);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String _transliterateLatToCyr(String input) {
    final value = input.toLowerCase();
    final buffer = StringBuffer();
    var index = 0;

    while (index < value.length) {
      final matched = _matchLatinSequence(value, index);
      if (matched != null) {
        buffer.write(matched.mapped);
        index += matched.length;
        continue;
      }

      final char = value[index];
      final mapped = _latToCyrSingle[char];
      if (mapped != null) {
        buffer.write(mapped);
      } else {
        buffer.write(char);
      }
      index += 1;
    }

    return buffer.toString();
  }

  static String _swapLayoutCyrToLat(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final mapped = _cyrKeyboardToLat[char];
      buffer.write(mapped ?? char);
    }
    return buffer.toString();
  }

  static String _swapLayoutLatToCyr(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final mapped = _latKeyboardToCyr[char];
      buffer.write(mapped ?? char);
    }
    return buffer.toString();
  }

  static _LatinMatch? _matchLatinSequence(String value, int start) {
    for (final length in _latToCyrMultiLengths) {
      final end = start + length;
      if (end > value.length) continue;
      final slice = value.substring(start, end);
      final mapped = _latToCyrMulti[slice];
      if (mapped != null) {
        return _LatinMatch(length, mapped);
      }
    }
    return null;
  }

  static const Map<String, String> _cyrToLat = {
    'а': 'a',
    'б': 'b',
    'в': 'v',
    'г': 'g',
    'д': 'd',
    'е': 'e',
    'ё': 'e',
    'ж': 'zh',
    'з': 'z',
    'и': 'i',
    'й': 'y',
    'к': 'k',
    'л': 'l',
    'м': 'm',
    'н': 'n',
    'о': 'o',
    'п': 'p',
    'р': 'r',
    'с': 's',
    'т': 't',
    'у': 'u',
    'ф': 'f',
    'х': 'kh',
    'ц': 'ts',
    'ч': 'ch',
    'ш': 'sh',
    'щ': 'shch',
    'ъ': '',
    'ы': 'y',
    'ь': '',
    'э': 'e',
    'ю': 'yu',
    'я': 'ya',
  };

  static const Map<String, String> _latToCyrMulti = {
    'shch': 'щ',
    'sch': 'щ',
    'zh': 'ж',
    'kh': 'х',
    'ts': 'ц',
    'ch': 'ч',
    'sh': 'ш',
    'yu': 'ю',
    'ya': 'я',
    'ye': 'е',
    'yo': 'ё',
    'ju': 'ю',
    'ja': 'я',
  };

  static const List<int> _latToCyrMultiLengths = [4, 3, 2];

  static const Map<String, String> _latToCyrSingle = {
    'a': 'а',
    'b': 'б',
    'v': 'в',
    'g': 'г',
    'd': 'д',
    'e': 'е',
    'z': 'з',
    'i': 'и',
    'y': 'й',
    'k': 'к',
    'l': 'л',
    'm': 'м',
    'n': 'н',
    'o': 'о',
    'p': 'п',
    'r': 'р',
    's': 'с',
    't': 'т',
    'u': 'у',
    'f': 'ф',
    'h': 'х',
    'c': 'к',
    'q': 'к',
    'w': 'в',
    'x': 'кс',
    'j': 'дж',
  };

  static const Map<String, String> _cyrKeyboardToLat = {
    'ё': '`',
    'й': 'q',
    'ц': 'w',
    'у': 'e',
    'к': 'r',
    'е': 't',
    'н': 'y',
    'г': 'u',
    'ш': 'i',
    'щ': 'o',
    'з': 'p',
    'х': '[',
    'ъ': ']',
    'ф': 'a',
    'ы': 's',
    'в': 'd',
    'а': 'f',
    'п': 'g',
    'р': 'h',
    'о': 'j',
    'л': 'k',
    'д': 'l',
    'ж': ';',
    'э': '\'',
    'я': 'z',
    'ч': 'x',
    'с': 'c',
    'м': 'v',
    'и': 'b',
    'т': 'n',
    'ь': 'm',
    'б': ',',
    'ю': '.',
  };

  static const Map<String, String> _latKeyboardToCyr = {
    'q': 'й',
    'w': 'ц',
    'e': 'у',
    'r': 'к',
    't': 'е',
    'y': 'н',
    'u': 'г',
    'i': 'ш',
    'o': 'щ',
    'p': 'з',
    '[': 'х',
    ']': 'ъ',
    'a': 'ф',
    's': 'ы',
    'd': 'в',
    'f': 'а',
    'g': 'п',
    'h': 'р',
    'j': 'о',
    'k': 'л',
    'l': 'д',
    ';': 'ж',
    '\'': 'э',
    'z': 'я',
    'x': 'ч',
    'c': 'с',
    'v': 'м',
    'b': 'и',
    'n': 'т',
    'm': 'ь',
    ',': 'б',
    '.': 'ю',
    '`': 'ё',
  };
}

class _LatinMatch {
  const _LatinMatch(this.length, this.mapped);

  final int length;
  final String mapped;
}
