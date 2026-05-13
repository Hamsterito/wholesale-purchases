class DateFormatter {
  static String formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    try {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.isNegative) {
        return 'только что';
      }

      if (difference.inSeconds < 60) {
        return 'только что';
      }

      if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes ${_pluralizeMinutes(minutes)} назад';
      }

      if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours ${_pluralizeHours(hours)} назад';
      }

      if (difference.inDays < 7) {
        final days = difference.inDays;
        return '$days ${_pluralizeDays(days)} назад';
      }

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day.$month.$year';
    } catch (e) {
      return '';
    }
  }

  /// Плюрализация для минут на русском (минута/минуты/минут)
  static String _pluralizeMinutes(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'минуту';
    } else if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'минуты';
    } else {
      return 'минут';
    }
  }

  /// Плюрализация для часов на русском (час/часа/часов)
  static String _pluralizeHours(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'час';
    } else if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'часа';
    } else {
      return 'часов';
    }
  }

  /// Плюрализация для дней на русском (день/дня/дней)
  static String _pluralizeDays(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'день';
    } else if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }
}
