import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';
import 'add_payment_card.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String _selectedMethod = 'Mastercard';

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6288D5);

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
          'Метод оплаты',
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Варианты оплаты
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPaymentOption(
                  iconPath: 'assets/icons/cash.png',
                  label: 'Наличные',
                  value: 'Cash',
                ),
                _buildPaymentOption(
                  iconPath: 'assets/icons/visa.png',
                  label: 'Visa',
                  value: 'Visa',
                ),
                _buildPaymentOption(
                  iconPath: 'assets/icons/mastercard.png',
                  label: 'Mastercard',
                  value: 'Mastercard',
                ),
                _buildPaymentOption(
                  iconPath: 'assets/icons/paypal.png',
                  label: 'PayPal',
                  value: 'Paypal',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Сообщение
            Text(
              'Нет способа оплаты',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Пожалуйста, выберите способ\nоплаты',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _mutedText,
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка "Добавить новый"
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPaymentCardPage(),
                  ),
                );
              },
              icon: Icon(Icons.add, size: 18),
              label: Text(
                'Добавить новый',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildPaymentOption({
    required String iconPath,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedMethod == value;
    const primaryColor = Color(0xFF6288D5);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? primaryColor : _colorScheme.surfaceVariant,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    iconPath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
