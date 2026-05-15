import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/product.dart';
import './smart_image.dart';

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
            'Минимум $_minLength символов (${text.length}/$_minLength)';
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
    final palette = _SupplierQAPalette.of(context);
    final answerLength = _answerController.text.length;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
                  'Ответить на вопрос',
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
                              'Товар',
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
                      'Вопрос:',
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
                      'Ваш ответ',
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
                            'Введите ответ (минимум $_minLength символов)',
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
                          borderSide: BorderSide(color: palette.danger),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: palette.danger,
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
                              color: palette.danger,
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
                      color: palette.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: palette.danger.withValues(alpha: 0.38),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: palette.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _submissionError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.danger,
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
                          'Отмена',
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
                              child: const Text('Отправить'),
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

class _SupplierQAPalette {
  const _SupplierQAPalette({
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.line,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.accentMist,
    required this.danger,
    required this.shadow,
  });

  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color line;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color accentMist;
  final Color danger;
  final Color shadow;

  static const light = _SupplierQAPalette(
    bgTop: Color(0xFFF6F8FF),
    bgBottom: Color(0xFFEFF3FF),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE3E8F3),
    ink: Color(0xFF1B1E2B),
    muted: Color(0xFF6D748A),
    accent: Color(0xFF6288D5),
    accentDark: Color(0xFF4F70C6),
    accentSoft: Color(0xFFDCE6FA),
    accentMist: Color(0xFFF0F4FF),
    danger: Color(0xFFE4572E),
    shadow: Color(0x14000000),
  );

  static const dark = _SupplierQAPalette(
    bgTop: Color(0xFF0F141F),
    bgBottom: Color(0xFF141B2B),
    card: Color(0xFF1A2336),
    line: Color(0xFF2B364D),
    ink: Color(0xFFE9EDFF),
    muted: Color(0xFF9AA3B6),
    accent: Color(0xFF6288D5),
    accentDark: Color(0xFF9BB6FF),
    accentSoft: Color(0xFF243251),
    accentMist: Color(0xFF1A243A),
    danger: Color(0xFFFF6B4A),
    shadow: Color(0x66000000),
  );

  static _SupplierQAPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
