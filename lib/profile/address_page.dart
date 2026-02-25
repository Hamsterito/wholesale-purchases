import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_address.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key, this.initial});

  final AddressDraft? initial;

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  static const int _addressLineMaxLength = 500;
  static const int _streetMaxLength = 100;
  static const int _zipMaxLength = 10;
  static const int _apartmentMaxLength = 20;
  static final RegExp _zipPattern = RegExp(r'^\d{3,10}$');
  static final RegExp _apartmentPattern = RegExp(
    r'^[0-9A-Za-zА-Яа-яЁё\\-\\/ ]+$',
  );

  late final TextEditingController _addressController;
  late final TextEditingController _streetController;
  late final TextEditingController _zipController;
  late final TextEditingController _apartmentController;

  String _selectedType = 'home';
  String? _addressError;
  String? _streetError;
  String? _zipError;
  String? _apartmentError;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _colorScheme.surfaceVariant;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _addressController = TextEditingController(text: initial?.addressLine ?? '');
    _streetController = TextEditingController(text: initial?.street ?? '');
    _zipController = TextEditingController(text: initial?.zip ?? '');
    _apartmentController = TextEditingController(text: initial?.apartment ?? '');
    final label = initial?.label.trim().toLowerCase();
    if (label == 'home' || label == 'work' || label == 'other') {
      _selectedType = label!;
    }
  }

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
    final isEditing = widget.initial != null;
    final titleText = isEditing ? 'Редактировать адрес' : 'Добавить адрес';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleText,
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
            _buildTextField(
              label: 'АДРЕС',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
              errorText: _addressError,
              onChanged: _onAddressChanged,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_addressLineMaxLength),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'УЛИЦА',
                    controller: _streetController,
                    errorText: _streetError,
                    onChanged: _onStreetChanged,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_streetMaxLength),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'ПОЧТОВЫЙ ИНДЕКС',
                    controller: _zipController,
                    keyboardType: TextInputType.number,
                    errorText: _zipError,
                    onChanged: _onZipChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_zipMaxLength),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'КВАРТИРА',
              controller: _apartmentController,
              errorText: _apartmentError,
              onChanged: _onApartmentChanged,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_apartmentMaxLength),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildTypeButton(value: 'home', label: 'Дом'),
                const SizedBox(width: 12),
                _buildTypeButton(value: 'work', label: 'Работа'),
                const SizedBox(width: 12),
                _buildTypeButton(value: 'other', label: 'Другое'),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
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
                  isEditing ? 'СОХРАНИТЬ' : 'СОХРАНИТЬ АДРЕС',
                  style: const TextStyle(
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
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
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
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
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
        onTap: () => setState(() => _selectedType = value),
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

  void _submit() {
    _validateForm();
    if (_addressError != null ||
        _streetError != null ||
        _zipError != null ||
        _apartmentError != null) {
      return;
    }

    final addressLine = _normalizeText(_addressController.text);
    final street = _normalizeOptionalText(_streetController.text);
    final zip = _zipController.text.trim();
    final apartment = _apartmentController.text.trim();

    final draft = AddressDraft(
      label: _selectedType,
      addressLine: addressLine,
      street: street ?? '',
      zip: zip,
      apartment: apartment,
    );

    Navigator.pop(context, draft);
  }

  void _validateForm() {
    setState(() {
      _addressError = _validateAddress(_addressController.text);
      _streetError = _validateStreet(_streetController.text);
      _zipError = _validateZip(_zipController.text);
      _apartmentError = _validateApartment(_apartmentController.text);
    });
  }

  void _onAddressChanged(String value) {
    setState(() {
      _addressError = _validateAddress(value);
    });
  }

  void _onStreetChanged(String value) {
    setState(() {
      _streetError = _validateStreet(value);
    });
  }

  void _onZipChanged(String value) {
    setState(() {
      _zipError = _validateZip(value);
    });
  }

  void _onApartmentChanged(String value) {
    setState(() {
      _apartmentError = _validateApartment(value);
    });
  }

  String? _validateAddress(String value) {
    final addressLine = _normalizeText(value);
    if (addressLine.isEmpty) {
      return 'Введите адрес';
    }
    if (addressLine.length < 5) {
      return 'Адрес слишком короткий';
    }
    return null;
  }

  String? _validateStreet(String value) {
    final street = _normalizeOptionalText(value);
    if (street != null && street.length > _streetMaxLength) {
      return 'Поле "Улица" не должно превышать $_streetMaxLength символов';
    }
    return null;
  }

  String? _validateZip(String value) {
    final zip = value.trim();
    if (zip.length > _zipMaxLength) {
      return 'Индекс не должен превышать $_zipMaxLength символов';
    }
    if (zip.isNotEmpty && !_zipPattern.hasMatch(zip)) {
      return 'Индекс должен содержать только цифры (3-10)';
    }
    return null;
  }

  String? _validateApartment(String value) {
    final apartment = value.trim();
    if (apartment.length > _apartmentMaxLength) {
      return 'Поле "Квартира" не должно превышать $_apartmentMaxLength символов';
    }
    if (apartment.isNotEmpty && !_apartmentPattern.hasMatch(apartment)) {
      return 'Некорректный формат квартиры';
    }
    return null;
  }

  String _normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _normalizeOptionalText(String value) {
    final normalized = _normalizeText(value);
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

}

