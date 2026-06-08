import 'package:flutter/material.dart';

import '../../services/localization/localization_extension.dart';
import '../../services/store/templates_store.dart';
import '../../theme/app_color_palette.dart';

/// Диалог переименования. Совпадение с текущим именем (trim, без учёта
/// регистра) валидно - caller вызывает rename, который трактует это как no-op.
class RenameTemplateDialog extends StatefulWidget {
  const RenameTemplateDialog({super.key, required this.template});

  final PurchaseTemplate template;

  @override
  State<RenameTemplateDialog> createState() => _RenameTemplateDialogState();
}

class _RenameTemplateDialogState extends State<RenameTemplateDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.template.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final trimmed = _controller.text.trim();

    if (trimmed.isEmpty || trimmed.length > 50) {
      setState(() => _error = context.l10n.templateNameError);
      return;
    }

    // Совпадение с собственным именем - валидно (no-op в сторе).
    final currentNameCi = widget.template.name.trim().toLowerCase();
    final newNameCi = trimmed.toLowerCase();
    if (newNameCi != currentNameCi) {
      // Проверяем дубликаты только среди других шаблонов.
      final duplicate = TemplatesStore.instance.findByNameCi(
        trimmed,
        excludeId: widget.template.id,
      );
      if (duplicate != null) {
        setState(() => _error = context.l10n.templateDuplicateExists);
        return;
      }
    }

    Navigator.of(context).pop(trimmed);
  }

  void _onChanged(String _) {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.colorPalette;
    final l10n = context.l10n;

    // Ограничиваем масштабирование текста сверху до 2.0.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 2.0,
      child: AlertDialog(
        backgroundColor: palette.card,
        title: Text(l10n.templateRenameTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 50,
                textInputAction: TextInputAction.done,
                onChanged: _onChanged,
                onSubmitted: (_) => _onConfirm(),
                decoration: InputDecoration(
                  labelText: l10n.templateNameLabel,
                  border: const OutlineInputBorder(),
                  errorText: _error,
                  counterText: '',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(color: palette.ink),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(onPressed: _onConfirm, child: Text(l10n.save)),
        ],
      ),
    );
  }
}

/// Открывает диалог переименования.
Future<String?> showRenameTemplateDialog(
  BuildContext context, {
  required PurchaseTemplate template,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => RenameTemplateDialog(template: template),
  );
}
