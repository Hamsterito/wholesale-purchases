import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  static const Color _primaryColor = Color(0xFF6288D5);
  final TextEditingController _editController = TextEditingController();
  int? _editingIndex;

  final List<_ReviewItem> _reviews = [
    const _ReviewItem(
      productName: '\u041d\u0430\u043f\u0438\u0442\u043e\u043a Coca-Cola \u0433\u0430\u0437\u0438\u0440\u043e\u0432\u0430\u043d\u043d\u044b\u0439 1.5 \u043b',
      productImage: 'assets/cart_home/CocaCola.png',
      rating: 5,
      date: '15.10.2025',
      reviewText: '\u041e\u0442\u043b\u0438\u0447\u043d\u044b\u0439 \u043d\u0430\u043f\u0438\u0442\u043e\u043a! \u0412\u0441\u0435\u0433\u0434\u0430 \u0441\u0432\u0435\u0436\u0438\u0439 \u0438 \u0432\u043a\u0443\u0441\u043d\u044b\u0439. \u0414\u043e\u0441\u0442\u0430\u0432\u043a\u0430 \u0431\u044b\u0441\u0442\u0440\u0430\u044f, \u0443\u043f\u0430\u043a\u043e\u0432\u043a\u0430 \u043d\u0430\u0434\u0435\u0436\u043d\u0430\u044f. \u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u044e!',
    ),
    const _ReviewItem(
      productName: '\u041c\u043e\u043b\u043e\u043a\u043e \u043a\u0438\u0441\u043b\u043e\u043c\u043e\u043b\u043e\u0447\u043d\u043e\u0435 2.5%',
      productImage: 'assets/cart_home/CocaCola.png',
      rating: 4,
      date: '12.10.2025',
      reviewText: '\u0425\u043e\u0440\u043e\u0448\u0435\u0435 \u043a\u0430\u0447\u0435\u0441\u0442\u0432\u043e, \u043d\u043e \u0446\u0435\u043d\u0430 \u043d\u0435\u043c\u043d\u043e\u0433\u043e \u0437\u0430\u0432\u044b\u0448\u0435\u043d\u0430. \u0412 \u0446\u0435\u043b\u043e\u043c \u0434\u043e\u0432\u043e\u043b\u0435\u043d \u043f\u043e\u043a\u0443\u043f\u043a\u043e\u0439.',
    ),
    const _ReviewItem(
      productName: '\u0425\u043b\u0435\u0431 \u0431\u0435\u043b\u044b\u0439 \u043d\u0430\u0440\u0435\u0437\u043d\u043e\u0439',
      productImage: 'assets/cart_home/CocaCola.png',
      rating: 5,
      date: '10.10.2025',
      reviewText: '\u0421\u0432\u0435\u0436\u0438\u0439 \u0445\u043b\u0435\u0431, \u043c\u044f\u0433\u043a\u0438\u0439 \u0438 \u0432\u043a\u0443\u0441\u043d\u044b\u0439. \u0412\u0441\u0435\u0433\u0434\u0430 \u0431\u0435\u0440\u0443 \u0437\u0434\u0435\u0441\u044c!',
    ),
    const _ReviewItem(
      productName: '\u042f\u0431\u043b\u043e\u043a\u0438 \u0413\u043e\u043b\u0434\u0435\u043d',
      productImage: 'assets/cart_home/CocaCola.png',
      rating: 3,
      date: '08.10.2025',
      reviewText: '\u042f\u0431\u043b\u043e\u043a\u0438 \u043d\u0435\u043f\u043b\u043e\u0445\u0438\u0435, \u043d\u043e \u043f\u043e\u043f\u0430\u043b\u0438\u0441\u044c \u043d\u0435\u043c\u043d\u043e\u0433\u043e \u043c\u044f\u0442\u044b\u0435. \u041d\u0430\u0434\u0435\u044e\u0441\u044c \u0432 \u0441\u043b\u0435\u0434\u0443\u044e\u0449\u0438\u0439 \u0440\u0430\u0437 \u0431\u0443\u0434\u0443\u0442 \u043f\u043e\u043b\u0443\u0447\u0448\u0435.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pageBg = theme.scaffoldBackgroundColor;
    final cardBg = colorScheme.surface;
    final mutedText = colorScheme.onSurfaceVariant;
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '\u0412\u0430\u0448\u0438 \u043e\u0442\u0437\u044b\u0432\u044b',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _reviews.isEmpty
          ? Center(
              child: Text(
                '\u041f\u043e\u043a\u0430 \u043d\u0435\u0442 \u043e\u0442\u0437\u044b\u0432\u043e\u0432',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 14,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return _buildReviewCard(
                  context: context,
                  review: review,
                  isEditing: _editingIndex == index,
                  onEdit: () => _startEdit(index),
                  onCancel: _cancelEdit,
                  onSave: () => _saveEdit(index),
                  onDelete: () => _confirmDelete(index),
                );
              },
            ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildReviewCard({
    required BuildContext context,
    required _ReviewItem review,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required VoidCallback onSave,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBg = colorScheme.surface;
    final mutedText = colorScheme.onSurfaceVariant;
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Продукт с изображением
          Row(
            children: [
              // Изображение товара
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    review.productImage,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.shopping_bag_outlined,
                        size: 30,
                        color: mutedText,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Название товара
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.date,
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Рейтинг
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),

          const SizedBox(height: 12),

          // Текст отзыва
          if (isEditing)
            TextField(
              controller: _editController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '\u0422\u0435\u043a\u0441\u0442 \u043e\u0442\u0437\u044b\u0432\u0430',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            )
          else
            Text(
              review.reviewText,
              style: TextStyle(
                fontSize: 14,
                color: mutedText,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 12),

          // Кнопки действий
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isEditing) ...[
                TextButton(
                  onPressed: onCancel,
                  child: const Text('\u041e\u0442\u043c\u0435\u043d\u0430'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onSave,
                  child: const Text('\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c'),
                ),
              ] else ...[
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text('\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u0442\u044c'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text('\u0423\u0434\u0430\u043b\u0438\u0442\u044c'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _startEdit(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingIndex = index;
      _editController.text = _reviews[index].reviewText;
    });
  }

  void _cancelEdit() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingIndex = null;
      _editController.clear();
    });
  }

  void _saveEdit(int index) {
    final text = _editController.text.trim();
    if (text.isEmpty) {
      _showSnack('\u0422\u0435\u043a\u0441\u0442 \u043e\u0442\u0437\u044b\u0432\u0430 \u043d\u0435 \u043c\u043e\u0436\u0435\u0442 \u0431\u044b\u0442\u044c \u043f\u0443\u0441\u0442\u044b\u043c');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _reviews[index] = _reviews[index].copyWith(reviewText: text);
      _editingIndex = null;
      _editController.clear();
    });
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(int index) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u043e\u0442\u0437\u044b\u0432?'),
          content: Text('\u042d\u0442\u043e \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0435 \u043d\u0435\u043b\u044c\u0437\u044f \u043e\u0442\u043c\u0435\u043d\u0438\u0442\u044c.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('\u041e\u0442\u043c\u0435\u043d\u0430'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('\u0423\u0434\u0430\u043b\u0438\u0442\u044c'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (approved != true) {
      return;
    }

    setState(() {
      _reviews.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
        _editController.clear();
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });

    _showSnack('Отзыв удален');
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReviewItem {
  const _ReviewItem({
    required this.productName,
    required this.productImage,
    required this.rating,
    required this.date,
    required this.reviewText,
  });

  final String productName;
  final String productImage;
  final int rating;
  final String date;
  final String reviewText;

  _ReviewItem copyWith({
    String? reviewText,
    int? rating,
    String? date,
  }) {
    return _ReviewItem(
      productName: productName,
      productImage: productImage,
      rating: rating ?? this.rating,
      date: date ?? this.date,
      reviewText: reviewText ?? this.reviewText,
    );
  }
}

