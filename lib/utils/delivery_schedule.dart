import 'ru_plural.dart';
import '../services/localization/app_localizations.dart';

/// Расписание доставки, которое поставщик задаёт в визарде.
/// Покупатель видит не сырую строку, а вычисленный текст: «Доставка завтра, 14:00»
/// или «Доставка через 2-3 дня».
sealed class DeliverySchedule {
  const DeliverySchedule();

  /// Строка для хранения в Supplier.deliveryDate / SupplierProduct.deliveryDate.
  String encode();

  /// Разбор строки. Поддерживает префиксы schedule: / lead:,
  /// а также старый weekly-формат без префикса для обратной совместимости.
  static DeliverySchedule? decode(String raw) {
    final source = raw.trim();
    if (source.isEmpty) return null;

    if (source.startsWith('schedule:')) {
      return _decodeWeekly(source.substring('schedule:'.length).trim());
    }
    if (source.startsWith('lead:')) {
      return _decodeLeadTime(source.substring('lead:'.length).trim());
    }
    // Без префикса - попытка распарсить старый weekly-формат
    return _decodeWeekly(source);
  }
}

class WeeklyDeliverySchedule extends DeliverySchedule {
  WeeklyDeliverySchedule({
    required Set<int> weekdays,
    required this.hour,
    required this.minute,
  }) : weekdays = _sortWeekdays(weekdays).toSet();

  final Set<int> weekdays;
  final int hour;
  final int minute;

  @override
  String encode() {
    // ALWAYS use ru short weekdays for backend storage backward compatibility!
    const ruShortWeekday = {
      DateTime.monday: 'Пн',
      DateTime.tuesday: 'Вт',
      DateTime.wednesday: 'Ср',
      DateTime.thursday: 'Чт',
      DateTime.friday: 'Пт',
      DateTime.saturday: 'Сб',
      DateTime.sunday: 'Вс',
    };
    final days = _sortWeekdays(
      weekdays,
    ).map((w) => ruShortWeekday[w]!).join(',');
    return 'schedule:$days ${_formatHm(hour, minute)}';
  }
}

class LeadTimeDeliverySchedule extends DeliverySchedule {
  LeadTimeDeliverySchedule({
    required this.minDays,
    required this.maxDays,
    this.cutoff,
  });

  final int minDays;
  final int maxDays;
  final ({int hour, int minute})? cutoff;

  @override
  String encode() {
    final range = 'lead:$minDays-$maxDays';
    if (cutoff == null) return range;
    return '$range cutoff:${_formatHm(cutoff!.hour, cutoff!.minute)}';
  }
}

/// Короткая сводка для бейджа на карточке товара (без времени).
String formatScheduleSummary(DeliverySchedule s) {
  if (s is WeeklyDeliverySchedule) {
    final preset = _matchWeeklyPreset(s.weekdays);
    if (preset != null) return preset;
    final sorted = _sortWeekdays(s.weekdays);
    // Один день показываем полным названием
    if (sorted.length == 1) {
      return _fullWeekdayNominative[sorted.first] ?? AppLocalizations.current.getString('util_weekday_mon');
    }
    return sorted.map((w) => _shortWeekday[w] ?? AppLocalizations.current.getString('util_weekday_mon')).join(', ');
  }
  if (s is LeadTimeDeliverySchedule) {
    if (s.minDays == 0 && s.maxDays == 0) return AppLocalizations.current.getString('util_today');
    if (s.minDays == 1 && s.maxDays == 1) return AppLocalizations.current.getString('util_tomorrow');
    if (s.minDays == s.maxDays) {
      return '${s.minDays} ${_daysLabel(s.minDays)}';
    }
    return '${s.minDays}–${s.maxDays} ${_daysLabel(s.maxDays)}';
  }
  return '';
}

/// Текст с временем развоза для детальной карточки.
String? formatDeliveryTimeNote(DeliverySchedule s) {
  if (s is WeeklyDeliverySchedule) {
    return AppLocalizations.current.getString('util_delivery_at').replaceAll('{time}', _formatHm(s.hour, s.minute));
  }
  if (s is LeadTimeDeliverySchedule) {
    final c = s.cutoff;
    if (c == null) return null;
    return AppLocalizations.current.getString('util_orders_before').replaceAll('{time}', _formatHm(c.hour, c.minute));
  }
  return null;
}

/// Только время «14:00» без префикса - для компактной строки с иконкой.
String? formatDeliveryTimeShort(DeliverySchedule s) {
  if (s is WeeklyDeliverySchedule) {
    return _formatHm(s.hour, s.minute);
  }
  if (s is LeadTimeDeliverySchedule) {
    final c = s.cutoff;
    if (c == null) return null;
    return _formatHm(c.hour, c.minute);
  }
  return null;
}

/// Только дата «26 мая» без префикса «Доставка» - для компактной строки.
String? formatDeliveryDateShort(DeliverySchedule s, DateTime now) {
  if (s is WeeklyDeliverySchedule) {
    if (s.weekdays.isEmpty) return null;
    for (var offset = 0; offset <= 14; offset++) {
      final date = now.add(Duration(days: offset));
      if (!s.weekdays.contains(date.weekday)) continue;
      final candidate = DateTime(
        date.year,
        date.month,
        date.day,
        s.hour,
        s.minute,
      );
      if (candidate.isBefore(now)) continue;
      if (offset == 0) return AppLocalizations.current.getString('util_today_lower');
      if (offset == 1) return AppLocalizations.current.getString('util_tomorrow_lower');
      return _formatDayMonth(date);
    }
    return null;
  }
  if (s is LeadTimeDeliverySchedule) {
    var min = s.minDays;
    var max = s.maxDays;
    final c = s.cutoff;
    if (c != null) {
      final nowMin = now.hour * 60 + now.minute;
      final cutMin = c.hour * 60 + c.minute;
      if (nowMin > cutMin) {
        min += 1;
        max += 1;
      }
    }
    if (min == 0 && max == 0) return AppLocalizations.current.getString('util_today_lower');
    if (min == 1 && max == 1) return AppLocalizations.current.getString('util_tomorrow_lower');
    final from = now.add(Duration(days: min));
    if (min == max) return _formatDayMonth(from);
    final to = now.add(Duration(days: max));
    if (from.month == to.month && from.year == to.year) {
      return '${from.day}–${to.day} ${_genitiveMonth[to.month] ?? ''}';
    }
    return '${_formatDayMonth(from)} – ${_formatDayMonth(to)}';
  }
  return null;
}

/// Текст «Доставка завтра, 14:00» / «Доставка через 2 дня» для покупателя.
String formatExpectedDelivery(DeliverySchedule s, DateTime now) {
  if (s is WeeklyDeliverySchedule) {
    return _formatWeeklyExpected(s, now);
  }
  if (s is LeadTimeDeliverySchedule) {
    return _formatLeadTimeExpected(s, now);
  }
  return AppLocalizations.current.getString('util_delivery');
}

String _formatWeeklyExpected(WeeklyDeliverySchedule s, DateTime now) {
  if (s.weekdays.isEmpty) return AppLocalizations.current.getString('util_delivery');
  for (var offset = 0; offset <= 14; offset++) {
    final date = now.add(Duration(days: offset));
    if (!s.weekdays.contains(date.weekday)) continue;
    final candidate = DateTime(
      date.year,
      date.month,
      date.day,
      s.hour,
      s.minute,
    );
    if (candidate.isBefore(now)) continue;
    if (offset == 0) return AppLocalizations.current.getString('util_delivery_today');
    if (offset == 1) return AppLocalizations.current.getString('util_delivery_tomorrow');
    return AppLocalizations.current.getString('util_delivery_date').replaceAll('{date}', _formatDayMonth(date));
  }
  return AppLocalizations.current.getString('util_delivery');
}

String _formatLeadTimeExpected(LeadTimeDeliverySchedule s, DateTime now) {
  var min = s.minDays;
  var max = s.maxDays;
  // Если задано время отсечки и сейчас уже позже - сдвигаем оба края на день
  final cutoff = s.cutoff;
  if (cutoff != null) {
    final nowMinutes = now.hour * 60 + now.minute;
    final cutoffMinutes = cutoff.hour * 60 + cutoff.minute;
    if (nowMinutes > cutoffMinutes) {
      min += 1;
      max += 1;
    }
  }
  if (min == 0 && max == 0) return AppLocalizations.current.getString('util_delivery_today');
  if (min == 1 && max == 1) return AppLocalizations.current.getString('util_delivery_tomorrow');
  // Календарные даты вместо «через N дней» - покупатель сразу видит число.
  final fromDate = now.add(Duration(days: min));
  if (min == max) {
    return AppLocalizations.current.getString('util_delivery_date').replaceAll('{date}', _formatDayMonth(fromDate));
  }
  final toDate = now.add(Duration(days: max));
  return AppLocalizations.current.getString('util_delivery_range').replaceAll('{range}', _formatDateRange(fromDate, toDate));
}

String _formatDayMonth(DateTime date) {
  return '${date.day} ${_genitiveMonth[date.month] ?? ''}';
}

String _formatDateRange(DateTime from, DateTime to) {
  // Если даты в одном месяце - пишем месяц один раз: «13-15 ноября»,
  // иначе «30 октября - 2 ноября».
  if (from.month == to.month && from.year == to.year) {
    return '${from.day}–${to.day} ${_genitiveMonth[to.month] ?? ''}';
  }
  return '${_formatDayMonth(from)} – ${_formatDayMonth(to)}';
}

// RegExp вынесены в top-level final, чтобы не пересоздавать на каждый decode.
// Время в конце строки (для weekly): «Пн,Ср 14:00»
final RegExp _kWeeklyTimeSuffix = RegExp(r'([01]?\d|2[0-3]):([0-5]\d)\s*$');
// Формат диапазона дней lead-time: «1-3»
final RegExp _kLeadRange = RegExp(r'^(\d{1,3})-(\d{1,3})$');
// Время cutoff: «14:00»
final RegExp _kCutoffTime = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');
// Сплит по пробелам и запятым с пробелами
final RegExp _kWhitespace = RegExp(r'\s+');
final RegExp _kCommaSeparator = RegExp(r'\s*,\s*');
final RegExp _kDashSeparator = RegExp(r'\s*-\s*');

WeeklyDeliverySchedule? _decodeWeekly(String raw) {
  final source = raw.trim();
  if (source.isEmpty) return null;
  final timeMatch = _kWeeklyTimeSuffix.firstMatch(source);
  if (timeMatch == null) return null;
  final hour = int.tryParse(timeMatch.group(1) ?? '');
  final minute = int.tryParse(timeMatch.group(2) ?? '');
  if (hour == null || minute == null) return null;
  final daysPart = source.substring(0, timeMatch.start).trim();
  final weekdays = _parseWeekdaysPart(daysPart);
  if (weekdays.isEmpty) return null;
  return WeeklyDeliverySchedule(weekdays: weekdays, hour: hour, minute: minute);
}

LeadTimeDeliverySchedule? _decodeLeadTime(String raw) {
  // Формат: 1-3 или 1-3 cutoff:14:00
  final parts = raw.split(_kWhitespace);
  if (parts.isEmpty) return null;
  final rangeMatch = _kLeadRange.firstMatch(parts.first);
  if (rangeMatch == null) return null;
  final min = int.tryParse(rangeMatch.group(1) ?? '');
  final max = int.tryParse(rangeMatch.group(2) ?? '');
  if (min == null || max == null) return null;
  if (min < 0 || max < min || max > 365) return null;

  ({int hour, int minute})? cutoff;
  for (var i = 1; i < parts.length; i++) {
    final token = parts[i];
    if (token.startsWith('cutoff:')) {
      final value = token.substring('cutoff:'.length);
      final m = _kCutoffTime.firstMatch(value);
      if (m == null) return null;
      cutoff = (hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
    }
  }
  return LeadTimeDeliverySchedule(minDays: min, maxDays: max, cutoff: cutoff);
}

Set<int> _parseWeekdaysPart(String raw) {
  final lowered = raw.toLowerCase().trim();
  if (lowered.isEmpty) return const <int>{};
  if (lowered == AppLocalizations.current.getString('util_weekday_keyword_weekdays') || lowered == 'будни' || lowered == 'weekdays') return _workdayPreset.toSet();
  if (lowered == AppLocalizations.current.getString('util_weekday_keyword_weekends') || lowered == 'выходные' || lowered == 'weekends') return _weekendPreset.toSet();
  if (lowered == AppLocalizations.current.getString('util_weekday_keyword_daily') ||
      lowered == AppLocalizations.current.getString('util_weekday_keyword_every_day') ||
      lowered == 'ежедневно' || lowered == 'каждый день' || lowered == 'daily') {
    return _weekdayOrder.toSet();
  }

  // Диапазон вида «Пн-Пт»
  final rangeParts = lowered.split(_kDashSeparator);
  if (rangeParts.length == 2) {
    final start = _parseWeekday(rangeParts.first);
    final end = _parseWeekday(rangeParts.last);
    if (start != null && end != null) {
      final result = <int>{};
      var current = start;
      while (true) {
        result.add(current);
        if (current == end) break;
        current = current == DateTime.sunday ? DateTime.monday : current + 1;
      }
      return result;
    }
  }

  final tokens = lowered.contains(',')
      ? lowered.split(_kCommaSeparator)
      : lowered.split(_kWhitespace);
  final result = <int>{};
  for (final token in tokens) {
    final w = _parseWeekday(token);
    if (w != null) result.add(w);
  }
  return result;
}

int? _parseWeekday(String value) {
  final v = value.replaceAll('.', '').trim().toLowerCase();
  if (v.isEmpty) return null;
  for (final entry in _shortWeekday.entries) {
    if (entry.value.toLowerCase() == v) return entry.key;
  }
  for (final entry in _fullWeekdayNominative.entries) {
    if (entry.value.toLowerCase() == v) return entry.key;
  }

  // Fallbacks to Russian/English to parse data saved in other locales
  const ruShort = {'пн': 1, 'вт': 2, 'ср': 3, 'чт': 4, 'пт': 5, 'сб': 6, 'вс': 7};
  if (ruShort.containsKey(v)) return ruShort[v];

  const ruFull = {'понедельник': 1, 'вторник': 2, 'среда': 3, 'четверг': 4, 'пятница': 5, 'суббота': 6, 'воскресенье': 7};
  if (ruFull.containsKey(v)) return ruFull[v];

  const enShort = {'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7};
  if (enShort.containsKey(v)) return enShort[v];

  return null;
}

String? _matchWeeklyPreset(Set<int> weekdays) {
  if (_sameWeekdays(weekdays, _weekdayOrder)) return AppLocalizations.current.getString('util_daily');
  if (_sameWeekdays(weekdays, _workdayPreset)) return AppLocalizations.current.getString('util_weekdays');
  if (_sameWeekdays(weekdays, _weekendPreset)) return AppLocalizations.current.getString('util_weekends');
  return null;
}

bool _sameWeekdays(Iterable<int> a, Iterable<int> b) {
  final left = _sortWeekdays(a);
  final right = _sortWeekdays(b);
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

List<int> _sortWeekdays(Iterable<int> weekdays) {
  final list = weekdays.toSet().toList(growable: false)
    ..sort(
      (a, b) => _weekdayOrder.indexOf(a).compareTo(_weekdayOrder.indexOf(b)),
    );
  return list;
}

String _formatHm(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String _daysLabel(int n) => pluralizeRu(n, AppLocalizations.current.getString('util_day_one'), AppLocalizations.current.getString('util_day_few'), AppLocalizations.current.getString('util_day_many'));

Map<int, String> get _shortWeekday => <int, String>{
  DateTime.monday: AppLocalizations.current.getString('util_weekday_mon'),
  DateTime.tuesday: AppLocalizations.current.getString('util_weekday_tue'),
  DateTime.wednesday: AppLocalizations.current.getString('util_weekday_wed'),
  DateTime.thursday: AppLocalizations.current.getString('util_weekday_thu'),
  DateTime.friday: AppLocalizations.current.getString('util_weekday_fri'),
  DateTime.saturday: AppLocalizations.current.getString('util_weekday_sat'),
  DateTime.sunday: AppLocalizations.current.getString('util_weekday_sun'),
};

Map<int, String> get _fullWeekdayNominative => <int, String>{
  DateTime.monday: AppLocalizations.current.getString('util_weekday_monday'),
  DateTime.tuesday: AppLocalizations.current.getString('util_weekday_tuesday'),
  DateTime.wednesday: AppLocalizations.current.getString('util_weekday_wednesday'),
  DateTime.thursday: AppLocalizations.current.getString('util_weekday_thursday'),
  DateTime.friday: AppLocalizations.current.getString('util_weekday_friday'),
  DateTime.saturday: AppLocalizations.current.getString('util_weekday_saturday'),
  DateTime.sunday: AppLocalizations.current.getString('util_weekday_sunday'),
};

// Месяцы в родительном падеже для дат вида «13 ноября».
Map<int, String> get _genitiveMonth => <int, String>{
  1: AppLocalizations.current.getString('util_month_gen_1'),
  2: AppLocalizations.current.getString('util_month_gen_2'),
  3: AppLocalizations.current.getString('util_month_gen_3'),
  4: AppLocalizations.current.getString('util_month_gen_4'),
  5: AppLocalizations.current.getString('util_month_gen_5'),
  6: AppLocalizations.current.getString('util_month_gen_6'),
  7: AppLocalizations.current.getString('util_month_gen_7'),
  8: AppLocalizations.current.getString('util_month_gen_8'),
  9: AppLocalizations.current.getString('util_month_gen_9'),
  10: AppLocalizations.current.getString('util_month_gen_10'),
  11: AppLocalizations.current.getString('util_month_gen_11'),
  12: AppLocalizations.current.getString('util_month_gen_12'),
};

const List<int> _weekdayOrder = <int>[
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
];

const List<int> _workdayPreset = <int>[
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
];

const List<int> _weekendPreset = <int>[DateTime.saturday, DateTime.sunday];
