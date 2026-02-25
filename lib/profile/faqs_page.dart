import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  State<FAQsPage> createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  int? _expandedIndex;
  static const _expansionDuration = Duration(milliseconds: 280);
  static const _expansionCurve = Curves.easeInOutCubic;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _shadowColor =>
      _isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.05);

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Как сделать заказ?',
      'answer': 'Чтобы сделать заказ, выберите товары из каталога, добавьте их в корзину и оформите заказ, указав адрес доставки и способ оплаты.'
    },
    {
      'question': 'Какие способы оплаты доступны?',
      'answer': 'Мы принимаем оплату наличными, банковскими картами (Visa, Mastercard), а также через PayPal.'
    },
    {
      'question': 'Сколько времени занимает доставка?',
      'answer': 'Стандартная доставка занимает 1-3 рабочих дня. Экспресс-доставка доступна в течение 24 часов.'
    },
    {
      'question': 'Могу ли я отменить заказ?',
      'answer': 'Вы можете отменить заказ в течение 30 минут после оформления. После этого заказ уже будет передан на склад для сборки.'
    },
    {
      'question': 'Как изменить адрес доставки?',
      'answer': 'Вы можете изменить адрес доставки в разделе "Профиль" -> "Адреса". Также можно указать новый адрес при оформлении заказа.'
    },
    {
      'question': 'Что делать если товар не подошел?',
      'answer': 'Вы можете вернуть товар в течение 14 дней с момента получения. Свяжитесь с нашей службой поддержки для оформления возврата.'
    },
    {
      'question': 'Как связаться с поддержкой?',
      'answer': 'Вы можете связаться с нами через раздел "Техподдержка" в приложении, по электронной почте или по телефону горячей линии.'
    },
    {
      'question': 'Есть ли минимальная сумма заказа?',
      'answer': 'Минимальная сумма заказа составляет 500 ₸. При заказе от 5000 ₸ доставка бесплатная.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Вопросы и ответы',
          style: _theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          final isExpanded = _expandedIndex == index;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              faq['question']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: _expansionDuration,
                            curve: _expansionCurve,
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: _expansionDuration,
                    reverseDuration: _expansionDuration,
                    switchInCurve: _expansionCurve,
                    switchOutCurve: _expansionCurve,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: _expansionCurve,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: SizeTransition(
                          sizeFactor: curved,
                          axisAlignment: -1,
                          child: child,
                        ),
                      );
                    },
                    child: isExpanded
                        ? Padding(
                            key: const ValueKey('expanded'),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              faq['answer']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: _mutedText,
                                height: 1.5,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('collapsed'),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }
}

