import 'package:flutter/material.dart';

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  State<FAQsPage> createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  int? _expandedIndex;

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
      'answer': 'Вы можете связаться с нами через раздел "Техподдержка" в приложении, по email или по телефону горячей линии.'
    },
    {
      'question': 'Есть ли минимальная сумма заказа?',
      'answer': 'Минимальная сумма заказа составляет 500 ₸. При заказе от 5000 ₸ доставка бесплатная.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'FAQs',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  faq['question']!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                trailing: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
                onExpansionChanged: (expanded) {
                  setState(() {
                    _expandedIndex = expanded ? index : null;
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq['answer']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}