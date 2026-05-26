import 'package:flutter/material.dart';

import '../services/templates_store.dart';
import '../theme/app_color_palette.dart';

/// Результат диалога сохранения. overwriteId != null - подтверждена перезапись.
class SaveTemplateResult {
  const SaveTemplateResult({required this.name, this.overwriteId});

  /// Имя после trim.
  final String name;

  /// id перезаписываемого шаблона; null - создание нового.
  final String? overwriteId;
}

/// Диалог «Сохранить как шаблон». На дубликате имени без учёта регистра
/// предлагает перезаписать или сохранить под другим именем.
class SaveTemplateDialog extends StatefulWidget {
  const SaveTemplateDialog({super.key, required this.defaultName});

  /// Предзаполняемое имя - обычно «Шаблон от dd.MM.yyyy».
  final String defaultName;

  @override
  State<SaveTemplateDialog> createState() => _SaveTemplateDialogState();
}

/// Стадия выбора при дубликате: unset - ждём выбор, overwrite - согласие на перезапись.
enum _DuplicateChoice { unset, overwrite }

class _SaveTemplateDialogState extends State<SaveTemplateDialog> {
  late final TextEditingController _nameController;
  String? _error;
  _DuplicateChoice? _choice;

  // Шаблон-дубликат, найденный по введённому имени (без учёта регистра).
  // Сохраняем ссылку, чтобы вернуть её id при выборе «Перезаписать».
  PurchaseTemplate? _duplicate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    // Любая правка после выбора «Сохранить под другим именем» сбрасывает
    // прежнюю ошибку, чтобы пользователь сразу видел чистое поле.
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  void _onConfirm() {
    final trimmed = _nameController.text.trim();

    if (trimmed.isEmpty || trimmed.length > 50) {
      setState(() {
        _error = 'Имя шаблона: от 1 до 50 символов';
        _choice = null;
        _duplicate = null;
      });
      return;
    }

    // Если уже подтвердили перезапись - закрываем с прежним id дубликата.
    if (_choice == _DuplicateChoice.overwrite && _duplicate != null) {
      Navigator.of(
        context,
      ).pop(SaveTemplateResult(name: trimmed, overwriteId: _duplicate!.id));
      return;
    }

    // Ищем дубликат среди шаблонов текущего пользователя.
    final existing = TemplatesStore.instance.findByNameCi(trimmed);
    if (existing != null) {
      // Дубликат - переходим в режим выбора, диалог не закрываем.
      setState(() {
        _choice = _DuplicateChoice.unset;
        _duplicate = existing;
        _error = null;
      });
      return;
    }

    Navigator.of(
      context,
    ).pop(SaveTemplateResult(name: trimmed, overwriteId: null));
  }

  void _onOverwrite() {
    if (_duplicate == null) return;
    final trimmed = _nameController.text.trim();
    Navigator.of(
      context,
    ).pop(SaveTemplateResult(name: trimmed, overwriteId: _duplicate!.id));
  }

  void _onSaveAsAnother() {
    // Очищаем поле и сбрасываем состояние дубликата - пользователь введёт новое имя.
    setState(() {
      _nameController.clear();
      _choice = null;
      _duplicate = null;
      _error = null;
    });
  }

  void _onCancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.colorPalette;

    final showDuplicate = _choice == _DuplicateChoice.unset;

    // Ограничиваем масштабирование текста сверху до 2.0.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 2.0,
      child: AlertDialog(
        backgroundColor: palette.card,
        title: const Text('Сохранить как шаблон'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                maxLength: 50,
                textInputAction: TextInputAction.done,
                onChanged: _onChanged,
                onSubmitted: (_) => _onConfirm(),
                decoration: InputDecoration(
                  labelText: 'Имя шаблона',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                  counterText: '',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(color: palette.ink),
              ),
              if (showDuplicate) ...[
                const SizedBox(height: 12),
                Text(
                  'Шаблон с таким именем уже существует',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.error,
                  ),
                ),
                const SizedBox(height: 8),
                // Две кнопки выбора. Обе - вторичные действия по отношению
                // к основному «Сохранить» в actions, поэтому показываем их
                // как Outlined/Filled и располагаем стопкой для длинных подписей.
                FilledButton(
                  onPressed: _onOverwrite,
                  child: const Text('Перезаписать'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _onSaveAsAnother,
                  child: const Text('Сохранить под другим именем'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _onCancel, child: const Text('Отмена')),
          if (!showDuplicate)
            FilledButton(onPressed: _onConfirm, child: const Text('Сохранить')),
        ],
      ),
    );
  }
}

/// Открывает диалог сохранения шаблона.
Future<SaveTemplateResult?> showSaveTemplateDialog(
  BuildContext context, {
  required String defaultName,
}) {
  return showDialog<SaveTemplateResult>(
    context: context,
    builder: (_) => SaveTemplateDialog(defaultName: defaultName),
  );
}
