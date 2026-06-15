import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../models/product.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import 'dart:math' as math;
import '../../theme/app_color_palette.dart';
import '../../core/ui/theme/app_dimensions.dart';
import '../smart_image.dart';

class SupplierQAAnswerModal extends StatefulWidget {
  final Question question;
  final Product product;
  final String? existingAnswer;
  final Future<void> Function(String answerText) onSubmit;

  const SupplierQAAnswerModal({
    super.key,
    required this.question,
    required this.product,
    this.existingAnswer,
    required this.onSubmit,
  });

  @override
  State<SupplierQAAnswerModal> createState() => _SupplierQAAnswerModalState();
}

class _SupplierQAAnswerModalState extends State<SupplierQAAnswerModal> {
  late TextEditingController _answerController;
  bool _isSubmitting = false;
  String? _validationError;
  String? _submissionError;

  static const int _minLength = 10;
  static const int _maxLength = 300;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController(
      text: widget.existingAnswer ?? '',
    );
    _validateInput();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _answerController.text.trim();
    setState(() {
      if (text.isEmpty) {
        _validationError = null;
      } else if (text.length < _minLength) {
        _validationError =
            context.l10n.qaMinimumCharacters(_minLength, text.length);
      } else {
        _validationError = null;
      }
      _submissionError = null;
    });
  }

  bool get _isValid {
    final text = _answerController.text.trim();
    return text.length >= _minLength && text.length <= _maxLength;
  }

  Future<void> _submitAnswer() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(_answerController.text.trim());
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submissionError = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final answerLength = _answerController.text.length;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: math.max(MediaQuery.viewInsetsOf(context).bottom, AppDimensions.minBottomSafePadding),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Полоска-ручка
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  context.l10n.getString('auto_otvetitNaVopros'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),

              // Превью товара
              if (widget.product.imageUrls.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SmartImage(
                          path: widget.product.imageUrls[0],
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.getString('auto_tovar'),
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.product.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: palette.ink,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: palette.line, height: 1),
              ],

              // Секция вопроса
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.getString('auto_vopros'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.accentMist,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: palette.line.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        widget.question.questionText,
                        style: TextStyle(
                          fontSize: 14,
                          color: palette.ink,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.getString('auto_vashOtvet'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _answerController,
                      onChanged: (_) => _validateInput(),
                      maxLines: 5,
                      maxLength: _maxLength,
                      enabled: !_isSubmitting,
                      style: TextStyle(color: palette.ink),
                      decoration: InputDecoration(
                        hintText:
                            context.l10n.qaEnterAnswerMinimum(_minLength),
                        hintStyle: TextStyle(color: palette.muted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: palette.accent,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: palette.error,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: palette.bgTop,
                        contentPadding: const EdgeInsets.all(12),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$answerLength/$_maxLength',
                          style: TextStyle(fontSize: 12, color: palette.muted),
                        ),
                        if (_validationError != null)
                          Text(
                            _validationError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Сообщение об ошибке
              if (_submissionError != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: palette.error.withValues(alpha: 0.38),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: palette.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _submissionError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Кнопки
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(color: palette.line),
                        ),
                        child: Text(
                          context.l10n.getString('auto_otmena'),
                          style: TextStyle(color: palette.ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isSubmitting
                          ? FilledButton(
                              onPressed: null,
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.accent,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : FilledButton(
                              onPressed: _isValid ? _submitAnswer : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.accent,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: Text(context.l10n.send),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
