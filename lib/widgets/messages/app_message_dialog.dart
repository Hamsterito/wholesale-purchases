import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../theme/app_color_palette.dart';
import 'app_message_snackbar.dart' show AppMessageMetrics, severityFillColor;

/// Унифицированный модальный диалог поверх Message_System.
class AppMessageDialog {
  AppMessageDialog._();

  /// Открывает модальный диалог; для null message возвращает Future со значением null.
  /// Пустой/null actions заменяется кнопкой «OK»; больше 3 действий - assert в debug,
  /// в release лишние отбрасываются.
  static Future<T?> show<T>(
    BuildContext context,
    Message? message, {
    List<Widget>? actions,
  }) {
    if (message == null) {
      return Future<T?>.value(null);
    }

    assert(
      actions == null || actions.length <= 3,
      'AppMessageDialog поддерживает максимум 3 действия',
    );

    final List<Widget> resolvedActions;
    if (actions == null || actions.isEmpty) {
      resolvedActions = const <Widget>[_DefaultOkAction()];
    } else if (actions.length > 3) {
      resolvedActions = actions.take(3).toList(growable: false);
    } else {
      resolvedActions = actions;
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) =>
          _AppMessageDialogBody(message: message, actions: resolvedActions),
    );
  }
}

class _DefaultOkAction extends StatelessWidget {
  const _DefaultOkAction();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('OK'),
    );
  }
}

/// Тело диалога. Цветная шапка severity повторяет визуал плашки top_message,
/// тело и кнопки - на нейтральном palette.card для читаемости длинного текста.
class _AppMessageDialogBody extends StatelessWidget {
  const _AppMessageDialogBody({required this.message, required this.actions});

  final Message message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = AppColorPalette.of(context);
    final fill = severityFillColor(message.severity, context);

    return Dialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMessageMetrics.borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        label: message.title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Цветная шапка severity - те же 14h x 10v padding и белый 14/w600,
            // что и в top_message.
            Container(
              color: fill,
              padding: AppMessageMetrics.padding,
              child: Text(
                message.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Тело сообщения; прокручивается, если выходит за высоту диалога.
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Text(
                  message.body,
                  style: TextStyle(color: palette.ink, height: 1.4),
                ),
              ),
            ),

            // Действия по правому краю; TextButton/FilledButton дают
            // дефолтный MaterialTapTargetSize.padded для hit-area >= 48x48.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _withGaps(actions),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> items) {
    if (items.isEmpty) return items;
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) result.add(const SizedBox(width: 8));
      result.add(items[i]);
    }
    return result;
  }
}
