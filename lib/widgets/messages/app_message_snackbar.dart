import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../services/store/app_settings.dart';
import '../../theme/app_color_palette.dart';
import '../../core/ui/theme/app_dimensions.dart';

/// Унифицированный SnackBar поверх Message_System.
/// Solid-filled стиль с метриками top_message: сплошной фон по severity,
/// белый текст и кнопка закрытия, padding 14h x 10v, радиус 12, тень palette.shadow.
class AppMessageSnackBar {
  AppMessageSnackBar._();

  static const Duration _kDurationInfoWarning = Duration(seconds: 4);
  static const Duration _kDurationError = Duration(seconds: 6);
  static const Duration _kDurationCritical = Duration(seconds: 8);

  /// Показывает SnackBar для message; null или пустые title и body - no-op,
  /// возвращает null. Опциональный action встраивается между текстом и кнопкой закрытия.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show(
    BuildContext context,
    Message? message, {
    SnackBarAction? action,
  }) {
    if (message == null) return null;

    if (message.title.trim().isEmpty && message.body.trim().isEmpty) {
      return null;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return null;

    final snackBar = SnackBar(
      duration: _durationForSeverity(message.severity),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: AppMessageMetrics.outerMargin,
      content: _AppMessageSnackBarContent(message: message, action: action),
    );

    return messenger.showSnackBar(snackBar);
  }

  static Duration _durationForSeverity(MessageSeverity severity) {
    switch (severity) {
      case MessageSeverity.info:
      case MessageSeverity.warning:
        return _kDurationInfoWarning;
      case MessageSeverity.error:
        return _kDurationError;
      case MessageSeverity.critical:
        return _kDurationCritical;
    }
  }
}

/// Возвращает сплошной фон SnackBar/Toast по severity и текущей теме.
Color severityFillColor(MessageSeverity severity, BuildContext context) {
  final palette = AppColorPalette.of(context);
  switch (severity) {
    case MessageSeverity.info:
      return palette.accent;
    case MessageSeverity.warning:
      return palette.warning;
    case MessageSeverity.error:
    case MessageSeverity.critical:
      return palette.error;
  }
}

/// Единые метрики для SnackBar, Toast и шапки Dialog - взяты из существующего
/// top_message.dart («Добавлено в избранное») как ground truth.
class AppMessageMetrics {
  const AppMessageMetrics._();

  static const double borderRadius = 12;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );
  static const EdgeInsets outerMargin = EdgeInsets.fromLTRB(
    16,
    8,
    16,
    8 + AppDimensions.minBottomSafePadding,
  );

  /// Расчёт max-width: 90% ширины экрана, не больше 600 px.
  static double maxWidth(BuildContext context) {
    return math.min(0.9 * MediaQuery.sizeOf(context).width, 600.0);
  }

  /// Тень в стиле top_message: общая для всех плашек, не зависит от заливки.
  static List<BoxShadow> shadow(BuildContext context) {
    return [
      BoxShadow(
        color: AppColorPalette.of(context).shadow,
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

class _AppMessageSnackBarContent extends StatelessWidget {
  const _AppMessageSnackBarContent({required this.message, this.action});

  final Message message;
  final SnackBarAction? action;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (innerContext, _, __) => _buildBody(innerContext),
    );
  }

  Widget _buildBody(BuildContext context) {
    final fill = severityFillColor(message.severity, context);

    final title = message.title;
    final body = message.body;
    final hasTitle = title.trim().isNotEmpty;
    final hasBody = body.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: AppMessageMetrics.padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppMessageMetrics.borderRadius),
          boxShadow: AppMessageMetrics.shadow(context),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                label: _semanticsLabel(title, body),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitle)
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (hasTitle && hasBody) const SizedBox(height: 2),
                    if (hasBody)
                      Text(
                        body,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 12), action!],
            const SizedBox(width: 8),
            InkWell(
              onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _semanticsLabel(String title, String body) {
    final t = title.trim();
    final b = body.trim();
    if (t.isEmpty) return b;
    if (b.isEmpty) return t;
    return '$t. $b';
  }
}
