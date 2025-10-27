import 'package:flutter/material.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final TextEditingController _addressController = TextEditingController(
    text: '3235 Royal Ln. Mesa, New Jersy 34567',
  );
  final TextEditingController _streetController = TextEditingController(
    text: 'Hason Nagar',
  );
  final TextEditingController _zipController = TextEditingController(
    text: '34567',
  );
  final TextEditingController _apartmentController = TextEditingController(
    text: '345',
  );

  String _selectedType = 'Home';

  @override
  void dispose() {
    _addressController.dispose();
    _streetController.dispose();
    _zipController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

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
          'Мой адрес',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // АДРЕС
            _buildTextField(
              label: 'АДРЕС',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 16),

            // УЛИЦА и ПОЧТОВЫЙ ИНДЕКС в одной строке
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'УЛИЦА',
                    controller: _streetController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'ПОЧТОВЫЙ ИНДЕКС',
                    controller: _zipController,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // КВАРТИРА
            _buildTextField(
              label: 'КВАРТИРА',
              controller: _apartmentController,
            ),

            const SizedBox(height: 24),

            // Кнопки выбора типа адреса
            Row(
              children: [
                _buildTypeButton('Home'),
                const SizedBox(width: 12),
                _buildTypeButton('Work'),
                const SizedBox(width: 12),
                _buildTypeButton('Other'),
              ],
            ),

            const SizedBox(height: 32),

            // Кнопка сохранить
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Сохранить адрес
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
                  'СОХРАНИТЬ АДРЕС',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.grey[600])
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefixIcon != null ? 0 : 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton(String type) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            type,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}