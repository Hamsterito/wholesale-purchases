/// Формат рейтинга для русского интерфейса: одна цифра после запятой,
/// разделитель - запятая (4,9 вместо 4.9).
String formatRating(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
