import 'package:flutter/material.dart';

/// Единая стандартизированная цветовая палитра для приложения "Оптовые закупки"
class AppColorPalette {
  const AppColorPalette({
    // Основные цвета
    required this.primary,
    required this.secondary,
    required this.tertiary,

    // Акцентные цвета
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.accentMist,

    // Семантические цвета
    required this.success,
    required this.error,
    required this.warning,
    required this.info,

    // Нейтральные цвета
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.line,
    required this.ink,
    required this.muted,

    // Дополнительные цвета
    required this.star,
    required this.shadow,

    // Цвета статусов
    required this.statusDelivered,
    required this.statusShipped,
    required this.statusPending,
    required this.statusCancelled,
  });

  // Основные цвета
  final Color primary;
  final Color secondary;
  final Color tertiary;

  // Акцентные цвета
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color accentMist;

  // Семантические цвета
  final Color success;
  final Color error;
  final Color warning;
  final Color info;

  // Нейтральные цвета
  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color line;
  final Color ink;
  final Color muted;

  // Дополнительные цвета
  final Color star;
  final Color shadow;

  // Цвета статусов
  final Color statusDelivered;
  final Color statusShipped;
  final Color statusPending;
  final Color statusCancelled;

  /// Светлая тема
  static const light = AppColorPalette(
    // Основные цвета
    primary: Color(0xFF6288D5),
    secondary: Color(0xFF8B5CF6),
    tertiary: Color(0xFF059669),

    // Акцентные цвета
    accent: Color(0xFF6288D5),
    accentDark: Color(0xFF4F70C6),
    accentSoft: Color(0xFFDCE6FA),
    accentMist: Color(0xFFF0F4FF),

    // Семантические цвета
    success: Color(0xFF4CAF50),
    error: Color(0xFFE4572E),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF2563EB),

    // Нейтральные цвета
    bgTop: Color(0xFFF6F8FF),
    bgBottom: Color(0xFFEFF3FF),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE3E8F3),
    ink: Color(0xFF1B1E2B),
    muted: Color(0xFF6D748A),

    // Дополнительные цвета
    star: Color(0xFFF4B740),
    shadow: Color(0x14000000),

    // Цвета статусов
    statusDelivered: Color(0xFF10B981),
    statusShipped: Color(0xFF6288D5),
    statusPending: Color(0xFFF59E0B),
    statusCancelled: Color(0xFFD32F2F),
  );

  /// Тёмная тема
  static const dark = AppColorPalette(
    // Основные цвета
    primary: Color(0xFF6288D5),
    secondary: Color(0xFF8B5CF6),
    tertiary: Color(0xFF059669),

    // Акцентные цвета
    accent: Color(0xFF6288D5),
    accentDark: Color(0xFF9BB6FF),
    accentSoft: Color(0xFF243251),
    accentMist: Color(0xFF1A243A),

    // Семантические цвета
    success: Color(0xFF66BB6A),
    error: Color(0xFFFF6B4A),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF60A5FA),

    // Нейтральные цвета
    bgTop: Color(0xFF0F141F),
    bgBottom: Color(0xFF141B2B),
    card: Color(0xFF1A2336),
    line: Color(0xFF2B364D),
    ink: Color(0xFFE9EDFF),
    muted: Color(0xFF9AA3B6),

    // Дополнительные цвета
    star: Color(0xFFF4B740),
    shadow: Color(0x66000000),

    // Цвета статусов
    statusDelivered: Color(0xFF10B981),
    statusShipped: Color(0xFF6288D5),
    statusPending: Color(0xFFF59E0B),
    statusCancelled: Color(0xFFFF6B4A),
  );

  /// Получить палитру для текущей темы
  static AppColorPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

/// Расширение для удобного доступа к палитре через BuildContext
extension AppColorPaletteX on BuildContext {
  AppColorPalette get colorPalette => AppColorPalette.of(this);
}
