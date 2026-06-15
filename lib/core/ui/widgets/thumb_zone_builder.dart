import 'package:flutter/widgets.dart';
import '../../utils/responsive_utils.dart';

/// Виджет-обертка для улучшения эргономики на высоких экранах.
/// Если устройство имеет вытянутый экран (например, Tecno Pova 5),
/// контент выравнивается по указанному [alignment] (по умолчанию снизу),
/// чтобы пользователю было удобнее тянуться большим пальцем (Thumb Zone).
class ThumbZoneBuilder extends StatelessWidget {
  final Widget child;
  final Alignment alignment;

  const ThumbZoneBuilder({
    super.key,
    required this.child,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isTallScreen) {
      return Align(
        alignment: alignment,
        // Использование Flexible внутри Column/Row обрабатывается родительским виджетом,
        // поэтому тут мы просто возвращаем Align для смещения контента.
        child: child,
      );
    }
    return child;
  }
}
