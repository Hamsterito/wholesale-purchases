import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static const Color _primaryColor = Color(0xFF6288D5);
  static const Color _primaryDark = Color(0xFF4F6FBF);

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = [
    'Проблема с заказом',
    'Проблема с оплатой',
    'Технические неполадки',
    'Вопрос о товаре',
    'Другое',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = isDark ? const Color(0xFF0F1115) : const Color(0xFFF2F5FB);
    final cardBackground = colorScheme.surface;
    final textPrimary = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;
    final fieldFill = isDark ? const Color(0xFF171D28) : const Color(0xFFF4F6FB);
    final fieldBorder = isDark ? colorScheme.outlineVariant : const Color(0xFFE1E7F3);
    final cardShadow =
        isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0x14000000);
    final baseFieldDecoration = _baseFieldDecoration(
      fillColor: fieldFill,
      borderColor: fieldBorder,
      focusColor: _primaryColor,
      hintColor: textMuted,
    );

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Техподдержка',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor,
                    _primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cardShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.message, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Свяжитесь с нами',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Мы готовы помочь вам решить любой вопрос',
                    style: TextStyle(
                      color: Color(0xFFE3ECFF),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContactItem(Icons.phone, '+7 (777) 123-45-67'),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.email, 'support@mansamart.kz'),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.access_time, 'Пн-Вс: 09:00 - 21:00'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: fieldBorder),
                boxShadow: [
                  BoxShadow(
                    color: cardShadow,
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Отправить обращение',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Категория обращения',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: Text(
                      'Выберите категорию',
                      style: TextStyle(color: textMuted),
                    ),
                    isExpanded: true,
                    icon: const SizedBox.shrink(),
                    iconSize: 0,
                    iconEnabledColor: Colors.transparent,
                    iconDisabledColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    menuMaxHeight: 260,
                    dropdownColor: cardBackground,
                    elevation: 10,
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                    selectedItemBuilder: (context) {
                      return _categories.map((category) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              color: textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    decoration: baseFieldDecoration,
                    items: _categories.map((String category) {
                      final isSelected = category == _selectedCategory;
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? fieldFill : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    isSelected ? fieldBorder : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Тема обращения',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    decoration: baseFieldDecoration.copyWith(
                      hintText: 'Введите тему',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Сообщение',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: baseFieldDecoration.copyWith(
                      hintText: 'Опишите вашу проблему подробно',
                      contentPadding: const EdgeInsets.all(16),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedCategory != null &&
                            _subjectController.text.isNotEmpty &&
                            _messageController.text.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Обращение отправлено'),
                              backgroundColor: _primaryColor,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        shadowColor: _primaryColor.withOpacity(0.3),
                      ),
                      child: Text(
                        'Отправить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  InputDecoration _baseFieldDecoration({
    required Color fillColor,
    required Color borderColor,
    required Color focusColor,
    required Color hintColor,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintStyle: TextStyle(color: hintColor),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focusColor, width: 1.4),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
