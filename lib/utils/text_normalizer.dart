import 'dart:convert';

class TextNormalizer {
  TextNormalizer._();

  static String normalize(String input) {
    if (input.isEmpty) return input;

    final candidates = <String>[input];

    final latinFixed = _tryFixLatin1(input);
    if (latinFixed != null && latinFixed != input) {
      candidates.add(latinFixed);
    }

    final cp1251Fixed = _tryFixCp1251(input);
    if (cp1251Fixed != null && cp1251Fixed != input) {
      candidates.add(cp1251Fixed);
    }

    return _pickBest(candidates, input);
  }

  static String? _tryFixLatin1(String input) {
    try {
      return _decodeUtf8(latin1.encode(input));
    } catch (_) {
      return null;
    }
  }

  static String? _tryFixCp1251(String input) {
    final bytes = _encodeCp1251(input);
    if (bytes == null) return null;
    return _decodeUtf8(bytes);
  }

  static String _decodeUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  static String _pickBest(List<String> candidates, String original) {
    var best = original;
    var bestScore = _score(original);

    for (var i = 1; i < candidates.length; i++) {
      final candidate = candidates[i];
      final score = _score(candidate);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }

    return best;
  }

  static int _score(String value) {
    var cyrillic = 0;
    var uppercaseCyrillic = 0;
    var replacements = 0;
    var mojibakeMarkers = 0;

    for (final rune in value.runes) {
      if (rune == 0xFFFD || rune == 0x003F) {
        replacements++;
      }

      if (rune >= 0x0400 && rune <= 0x04FF) {
        cyrillic++;
        if (rune >= 0x0410 && rune <= 0x042F) {
          uppercaseCyrillic++;
        }
        if (rune == 0x0420 || rune == 0x0421) {
          mojibakeMarkers++;
        }
      }

      if (rune == 0x00D0 ||
          rune == 0x00D1 ||
          rune == 0x00C3 ||
          rune == 0x00C2) {
        mojibakeMarkers++;
      }
    }

    final lowercaseCyrillic = cyrillic - uppercaseCyrillic;
    return (lowercaseCyrillic * 3) +
        cyrillic -
        (uppercaseCyrillic ~/ 2) -
        (replacements * 10) -
        (mojibakeMarkers * 2);
  }

  static List<int>? _encodeCp1251(String input) {
    final bytes = <int>[];
    for (final rune in input.runes) {
      if (rune <= 0x7F) {
        bytes.add(rune);
        continue;
      }
      final mapped = _cp1251EncodeMap[rune];
      if (mapped == null) {
        return null;
      }
      bytes.add(mapped);
    }
    return bytes;
  }

  static Map<int, int> _buildCp1251EncodeMap() {
    final map = <int, int>{};
    for (var i = 0; i < _cp1251DecodeTable.length; i++) {
      final codePoint = _cp1251DecodeTable[i];
      if (codePoint >= 0) {
        map[codePoint] = 0x80 + i;
      }
    }
    return map;
  }

  static final Map<int, int> _cp1251EncodeMap = _buildCp1251EncodeMap();

  static const List<int> _cp1251DecodeTable = [
    0x0402,
    0x0403,
    0x201A,
    0x0453,
    0x201E,
    0x2026,
    0x2020,
    0x2021,
    0x20AC,
    0x2030,
    0x0409,
    0x2039,
    0x040A,
    0x040C,
    0x040B,
    0x040F,
    0x0452,
    0x2018,
    0x2019,
    0x201C,
    0x201D,
    0x2022,
    0x2013,
    0x2014,
    -1,
    0x2122,
    0x0459,
    0x203A,
    0x045A,
    0x045C,
    0x045B,
    0x045F,
    0x00A0,
    0x040E,
    0x045E,
    0x0408,
    0x00A4,
    0x0490,
    0x00A6,
    0x00A7,
    0x0401,
    0x00A9,
    0x0404,
    0x00AB,
    0x00AC,
    0x00AD,
    0x00AE,
    0x0407,
    0x00B0,
    0x00B1,
    0x0406,
    0x0456,
    0x0491,
    0x00B5,
    0x00B6,
    0x00B7,
    0x0451,
    0x2116,
    0x0454,
    0x00BB,
    0x0458,
    0x0405,
    0x0455,
    0x0457,
    0x0410,
    0x0411,
    0x0412,
    0x0413,
    0x0414,
    0x0415,
    0x0416,
    0x0417,
    0x0418,
    0x0419,
    0x041A,
    0x041B,
    0x041C,
    0x041D,
    0x041E,
    0x041F,
    0x0420,
    0x0421,
    0x0422,
    0x0423,
    0x0424,
    0x0425,
    0x0426,
    0x0427,
    0x0428,
    0x0429,
    0x042A,
    0x042B,
    0x042C,
    0x042D,
    0x042E,
    0x042F,
    0x0430,
    0x0431,
    0x0432,
    0x0433,
    0x0434,
    0x0435,
    0x0436,
    0x0437,
    0x0438,
    0x0439,
    0x043A,
    0x043B,
    0x043C,
    0x043D,
    0x043E,
    0x043F,
    0x0440,
    0x0441,
    0x0442,
    0x0443,
    0x0444,
    0x0445,
    0x0446,
    0x0447,
    0x0448,
    0x0449,
    0x044A,
    0x044B,
    0x044C,
    0x044D,
    0x044E,
    0x044F,
  ];
}
