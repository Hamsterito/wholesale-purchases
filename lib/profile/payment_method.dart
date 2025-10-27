import 'package:flutter/material.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String _selectedMethod = 'Mastercard';

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
          'Метод оплаты',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Варианты оплаты PNG
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPaymentOption(
                  iconPath: 'assets/icons/cash.png',
                  label: 'Cash',
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
                  label: 'Paypal',
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
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Пожалуйста, выберите способ\nоплаты',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка ADD NEW
            TextButton.icon(
              onPressed: () {
                // действие
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'ADD NEW',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),

            const Spacer(),

            // Кнопка назад
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ДОБАВИТЬ НОВЫЙ АДРЕС',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Метод построения кнопки оплаты
  Widget _buildPaymentOption({
    required String iconPath,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedMethod == value;

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
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
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
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
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
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
