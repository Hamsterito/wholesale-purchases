import 'package:flutter/material.dart';

import '../../theme/app_color_palette.dart';

/// Виджет для поля перевода (KK), реализующий паттерн прогрессивного раскрытия.
/// По умолчанию свернут (показывает только кнопку "Добавить перевод"),
/// разворачивается для ручного ввода по клику,
/// и превращается в компактное превью, если текст введен (вручную или автопереводчиком).
class TranslationField extends StatefulWidget {
  const TranslationField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.isAutoTranslated = false,
    this.maxLines = 1,
    this.targetLanguage = 'KK',
    this.onRetranslate,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isAutoTranslated;
  final int maxLines;
  final String targetLanguage;
  final VoidCallback? onRetranslate;
  final ValueChanged<String>? onChanged;

  @override
  State<TranslationField> createState() => _TranslationFieldState();
}

class _TranslationFieldState extends State<TranslationField> {
  late final FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    // Слушаем контроллер, чтобы перерисовывать превью при изменениях извне (например, автоперевод)
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(TranslationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _onControllerChange() {
    // Вызываем setState, чтобы если пришел автоперевод извне, 
    // виджет переключился из collapsed в preview.
    setState(() {});
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    // Ждем фрейм, чтобы инпут отрендерился, затем ставим фокус
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final colorScheme = Theme.of(context).colorScheme;
    final hasText = widget.controller.text.trim().isNotEmpty;

    if (_isEditing) {
      return _buildEditingState(palette, colorScheme);
    }

    if (hasText) {
      return _buildPreviewState(palette, colorScheme);
    }

    return _buildCollapsedState(palette);
  }

  Widget _buildCollapsedState(AppColorPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: _startEditing,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: palette.accent),
                const SizedBox(width: 6),
                Text(
                  'Добавить перевод (${widget.targetLanguage})',
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewState(AppColorPalette palette, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isAutoTranslated 
                        ? colorScheme.primaryContainer 
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: widget.isAutoTranslated 
                        ? null 
                        : Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Text(
                    widget.isAutoTranslated ? 'Автоперевод ${widget.targetLanguage}' : 'Перевод ${widget.targetLanguage}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.isAutoTranslated 
                          ? colorScheme.onPrimaryContainer 
                          : palette.muted,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.onRetranslate != null) ...[
                  InkWell(
                    onTap: widget.onRetranslate,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.refresh, size: 18, color: palette.muted),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                InkWell(
                  onTap: _startEditing,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 18, color: palette.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.text,
              style: TextStyle(fontSize: 14, color: palette.ink),
            ),
            if (widget.isAutoTranslated)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Сгенерировано Яндекс.Переводчиком. Нажмите на карандаш, чтобы исправить.',
                  style: TextStyle(fontSize: 11, color: palette.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingState(AppColorPalette palette, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
