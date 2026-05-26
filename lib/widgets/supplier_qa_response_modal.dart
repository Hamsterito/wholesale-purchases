import 'package:flutter/material.dart';
import '../models/review_entry.dart';
import '../models/product.dart';
import '../theme/app_color_palette.dart';
import './smart_image.dart';

class SupplierQAResponseModal extends StatefulWidget {
  final ReviewEntry review;
  final Product product;
  final String? existingResponse;
  final Future<void> Function(String responseText) onSubmit;

  const SupplierQAResponseModal({
    super.key,
    required this.review,
    required this.product,
    this.existingResponse,
    required this.onSubmit,
  });

  @override
  State<SupplierQAResponseModal> createState() =>
      _SupplierQAResponseModalState();
}

class _SupplierQAResponseModalState extends State<SupplierQAResponseModal> {
  late TextEditingController _responseController;
  bool _isSubmitting = false;
  String? _validationError;
  String? _submissionError;

  static const int _minLength = 10;
  static const int _maxLength = 1000;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController(
      text:
          widget.existingResponse ?? widget.review.response?.responseText ?? '',
    );
    _validateInput();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _responseController.text.trim();
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
    final text = _responseController.text.trim();
    return text.length >= _minLength && text.length <= _maxLength;
  }

  Future<void> _submitResponse() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(_responseController.text.trim());
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

  Widget _buildStarRating(int rating, AppColorPalette palette) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_outline,
          size: 16,
          color: palette.star,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final responseLength = _responseController.text.length;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
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

              // Заголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Ответить на отзыв',
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

              // Секция отзыва
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Отзыв:',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.review.reviewerName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: palette.ink,
                                ),
                              ),
                              _buildStarRating(widget.review.rating, palette),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.review.reviewText,
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.ink,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Секция ввода ответа
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
                      controller: _responseController,
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
                          '$responseLength/$_maxLength',
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
                              onPressed: _isValid ? _submitResponse : null,
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
