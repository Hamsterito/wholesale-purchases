import 'package:flutter/widgets.dart';

/// Утилиты для работы с размерами экрана и адаптацией под вытянутые дисплеи.
class ResponsiveUtils {
  // Защита от создания экземпляра утилитного класса
  ResponsiveUtils._();

  /// Определяет, является ли экран вытянутым (например, соотношение сторон больше 2:1).
  /// Это важно для смартфонов типа Tecno Pova 5 с соотношением 20.5:9.
  static bool isTallScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width == 0) return false;
    final ratio = size.height / size.width;
    return ratio > 2.0;
  }
}

/// Расширение для быстрого доступа к метрикам экрана прямо из контекста.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  
  double get screenHeight => MediaQuery.of(this).size.height;
  
  bool get isTallScreen => ResponsiveUtils.isTallScreen(this);
  
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  
  double get topPadding => MediaQuery.of(this).padding.top;
}
