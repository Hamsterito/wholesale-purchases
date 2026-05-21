import '../services/api_service.dart';

/// Регистронезависимый фильтр модераторов по подстроке имени или email.
/// Пустой запрос возвращает копию исходного списка в исходном порядке.
List<Moderator> filterModerators(List<Moderator> list, String query) {
  final q = query.toLowerCase();
  if (q.isEmpty) {
    return List.of(list);
  }
  return list.where((m) {
    return m.name.toLowerCase().contains(q) ||
        m.email.toLowerCase().contains(q);
  }).toList();
}
