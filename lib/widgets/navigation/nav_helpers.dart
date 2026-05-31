// Чистые помощники для роль-зависимой навигации: выбор активной вкладки
// и отображение значка уведомлений. Общий источник правды для виджетов
// и property-тестов.

/// Вкладка активна, только если её индекс совпадает с currentIndex
/// и попадает в диапазон видимых вкладок. null или индекс вне диапазона
/// означает, что активной вкладки нет.
bool isTabActive(int? currentIndex, int index, int tabCount) {
  return currentIndex == index && index >= 0 && index < tabCount;
}

/// Текст значка: пусто при 0, само число для 1..maxCount,
/// иначе "maxCount+" при превышении порога.
String badgeDisplayText(int count, {int maxCount = 99}) {
  if (count <= 0) return '';
  if (count > maxCount) return '$maxCount+';
  return count.toString();
}

/// Семантическая метка значка для screen reader: называет вкладку и счётчик.
String badgeSemanticLabel(String tabLabel, int count) {
  return '$tabLabel, $count';
}
