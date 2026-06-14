import '../services/localization/app_localizations.dart';

class DateFormatter {
  static String formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    try {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.isNegative) {
        return AppLocalizations.current.getString('util_just_now');
      }

      if (difference.inSeconds < 60) {
        return AppLocalizations.current.getString('util_just_now');
      }

      if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes ${_pluralizeMinutes(minutes)} ${AppLocalizations.current.getString('util_ago')}';
      }

      if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours ${_pluralizeHours(hours)} ${AppLocalizations.current.getString('util_ago')}';
      }

      if (difference.inDays < 7) {
        final days = difference.inDays;
        return '$days ${_pluralizeDays(days)} ${AppLocalizations.current.getString('util_ago')}';
      }

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day.$month.$year';
    } catch (e) {
      return '';
    }
  }

  /// Плюрализация для минут
  static String _pluralizeMinutes(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return AppLocalizations.current.getString('util_minute_one');
    } else if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return AppLocalizations.current.getString('util_minute_few');
    } else {
      return AppLocalizations.current.getString('util_minute_many');
    }
  }

  /// Плюрализация для часов
  static String _pluralizeHours(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return AppLocalizations.current.getString('util_hour_one');
    } else if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return AppLocalizations.current.getString('util_hour_few');
    } else {
      return AppLocalizations.current.getString('util_hour_many');
    }
  }

  /// Плюрализация для дней
  static String _pluralizeDays(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return AppLocalizations.current.getString('util_day_one');
    } else if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return AppLocalizations.current.getString('util_day_few');
    } else {
      return AppLocalizations.current.getString('util_day_many');
    }
  }
}
