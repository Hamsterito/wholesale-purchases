import 'package:flutter/material.dart';

import '../../theme/app_color_palette.dart';
import '../../utils/ru_plural.dart';
import 'nav_helpers.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';

/// Виджет значка уведомлений - отображает счётчик в виде круглого бейджа.
class NotificationBadge extends StatefulWidget {
  const NotificationBadge({
    required this.count,
    this.maxCount = 99,
    this.backgroundColor,
    this.textColor,
    this.size = 20,
    this.fontSize = 12,
    this.semanticLabel,
    super.key,
  });

  /// Количество уведомлений. При 0 виджет полностью скрывается.
  final int count;

  /// Максимальное значение перед отображением "99+".
  final int maxCount;

  /// Цвет фона значка. По умолчанию - error-цвет из текущей темы.
  final Color? backgroundColor;

  /// Цвет текста. По умолчанию - белый (допустимое исключение для контраста).
  final Color? textColor;

  /// Диаметр значка в пикселях (минимум 20).
  final double size;

  /// Размер шрифта счётчика.
  final double fontSize;

  /// Метка для screen readers. Если не задана - генерируется автоматически.
  final String? semanticLabel;

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Отображаемое значение - обновляется при изменении count
  late int _displayCount;

  @override
  void initState() {
    super.initState();

    _displayCount = widget.count;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Если при создании уже есть уведомления - сразу показываем значок
    // без анимации (value = 1.0), чтобы он был виден мгновенно при
    // переходе на новую страницу. Анимация нужна только при появлении
    // нового уведомления во время работы приложения.
    if (widget.count > 0) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.count == widget.count) return;

    if (oldWidget.count == 0 && widget.count > 0) {
      // Значок появляется - обновляем счётчик и запускаем анимацию вперёд
      setState(() => _displayCount = widget.count);
      _animationController.forward();
    } else if (oldWidget.count > 0 && widget.count == 0) {
      // Значок исчезает - сначала анимируем, потом обновляем счётчик
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() => _displayCount = widget.count);
        }
      });
    } else {
      // Просто изменилось число - обновляем без анимации скрытия
      setState(() => _displayCount = widget.count);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Скрываем виджет полностью когда нет уведомлений
    if (_displayCount == 0 && !_animationController.isAnimating) {
      return const SizedBox.shrink();
    }

    final palette = AppColorPalette.of(context);

    // Текст значка берём из badgeDisplayText - единый источник правды
    // с property-тестами. При 0 значок уже скрыт выше по коду.
    final label = badgeDisplayText(_displayCount, maxCount: widget.maxCount);

    // Семантическая метка для screen readers с правильным склонением
    final semanticText =
        widget.semanticLabel ??
        '$_displayCount ${pluralizeRu(_displayCount, context.l10n.getString('auto_neprochitannoeUvedomleni'), context.l10n.getString('auto_neprochitannyhUvedomleni'), context.l10n.getString('auto_neprochitannyhUvedomleni_1'))}';

    // Минимальный размер - 20px согласно требованиям
    final badgeSize = widget.size < 20 ? 20.0 : widget.size;

    // Для одной цифры - круг, для двух и более символов - капсула
    // (контейнер расширяется по ширине, но высота остаётся фиксированной)
    final isSingleChar = label.length == 1;
    final horizontalPadding = isSingleChar ? 0.0 : 5.0;

    // RepaintBoundary изолирует ScaleTransition бейджа от родителя
    // (bottom_nav_bar): анимация масштаба не вызывает перерисовку соседних
    // иконок навигации.
    return Positioned(
      right: -8,
      top: -8,
      child: RepaintBoundary(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Semantics(
            label: semanticText,
            child: Container(
              height: badgeSize,
              constraints: BoxConstraints(minWidth: badgeSize),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              // clipBehavior сглаживает края круга при anti-aliasing
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? palette.error,
                borderRadius: BorderRadius.circular(badgeSize / 2),
                // Тонкая обводка цветом карточки даёт визуальный отступ
                // от иконки и делает круг чётким на любом фоне
                border: Border.all(color: palette.card, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // Colors.white - допустимое исключение для контраста на цветном фоне
                    color: widget.textColor ?? Colors.white,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    // Убираем лишние отступы, чтобы текст точно центрировался
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
