import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';

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

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _colorScheme.surfaceVariant;

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
          'Мой адрес',
          style: TextStyle(
            color: _colorScheme.onSurface,
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
                _buildTypeButton(value: 'Home', label: 'Дом'),
                const SizedBox(width: 12),
                _buildTypeButton(value: 'Work', label: 'Работа'),
                const SizedBox(width: 12),
                _buildTypeButton(value: 'Other', label: 'Другое'),
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
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
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
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: _mutedText)
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

  Widget _buildTypeButton({
    required String value,
    required String label,
  }) {
    final isSelected = _selectedType == value;
    const primaryColor = Color(0xFF6288D5);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = value;
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : _inputFill,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : _colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
