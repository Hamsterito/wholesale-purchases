import 'dart:convert';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/supplier_product.dart';
import '../services/api_service.dart';
import '../widgets/smart_image.dart';

class SupplierProductWizardPage extends StatefulWidget {
  const SupplierProductWizardPage({super.key, this.product});

  final SupplierProduct? product;

  @override
  State<SupplierProductWizardPage> createState() =>
      _SupplierProductWizardPageState();
}

class _SupplierProductWizardPageState extends State<SupplierProductWizardPage> {
  final _picker = ImagePicker();
  final _imageUrlController = TextEditingController();
  final _categorySearchController = TextEditingController();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _minController;
  late final TextEditingController _stockController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;
  late final TextEditingController _countryController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _deliveryBadgeController;
  late final TextEditingController _deliveryTimeController;

  int _step = 0;
  String? _error;
  bool _isSubmitting = false;
  bool _deliveryTimeInputInvalid = false;
  final List<String> _images = [];
  final LinkedHashSet<String> _selectedCategories = LinkedHashSet<String>();
  final LinkedHashSet<int> _deliveryWeekdays = LinkedHashSet<int>();
  TimeOfDay _deliveryTime = const TimeOfDay(hour: 14, minute: 0);

  static const Map<int, String> _weekdaysFull = <int, String>{
    DateTime.monday: 'Понедельник',
    DateTime.tuesday: 'Вторник',
    DateTime.wednesday: 'Среда',
    DateTime.thursday: 'Четверг',
    DateTime.friday: 'Пятница',
    DateTime.saturday: 'Суббота',
    DateTime.sunday: 'Воскресенье',
  };
  static const Map<int, String> _weekdaysShort = <int, String>{
    DateTime.monday: 'Пн',
    DateTime.tuesday: 'Вт',
    DateTime.wednesday: 'Ср',
    DateTime.thursday: 'Чт',
    DateTime.friday: 'Пт',
    DateTime.saturday: 'Сб',
    DateTime.sunday: 'Вс',
  };
  static const List<int> _weekdayOrder = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];
  static const List<int> _workdayPreset = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];
  static const List<int> _weekendPreset = <int>[
    DateTime.saturday,
    DateTime.sunday,
  ];
  static const int _maxIntegerFieldValue = 2147483647;
  static const double _numeric10Scale2Bound = 100000000.0;
  static const double _numeric10Scale2MaxValue = 99999999.99;
  static const int _initialCategoryVisibleLimit = 14;

  static const List<String> _fallbackPresetCategories = [
    'Напитки',
    'Молочная продукция',
    'Овощи и фрукты',
    'Мясо и птица',
    'Бакалея',
    'Хлеб и выпечка',
    'Заморозка',
    'Снеки',
    'Бытовая химия',
    'Товары для дома',
  ];
  final List<String> _presetCategories = List<String>.from(
    _fallbackPresetCategories,
  );
  bool _showAllPresetCategories = false;

  int get _totalSteps => 4;

  bool _exceedsNumeric10Scale2(double value) {
    if (!value.isFinite) {
      return true;
    }
    final roundedToScale = (value * 100).round() / 100;
    return roundedToScale >= _numeric10Scale2Bound;
  }

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    for (final category in product?.categories ?? const <String>[]) {
      final normalized = _normalizeCategory(category);
      if (normalized.isNotEmpty) {
        _selectedCategories.add(normalized);
      }
    }
    _priceController = TextEditingController(
      text: product?.pricePerUnit.toString() ?? '',
    );
    _minController = TextEditingController(
      text: product?.minQuantity.toString() ?? '1',
    );
    _stockController = TextEditingController(
      text: (product?.stockQuantity ?? 0) > 0
          ? product!.stockQuantity.toString()
          : (product?.maxQuantity?.toString() ?? ''),
    );
    _ingredientsController = TextEditingController(
      text: product?.ingredients ?? '',
    );
    _caloriesController = TextEditingController(
      text: product?.nutritionalInfo.calories.toStringAsFixed(0) ?? '',
    );
    _proteinController = TextEditingController(
      text: product?.nutritionalInfo.protein.toStringAsFixed(1) ?? '',
    );
    _fatController = TextEditingController(
      text: product?.nutritionalInfo.fat.toStringAsFixed(1) ?? '',
    );
    _carbsController = TextEditingController(
      text: product?.nutritionalInfo.carbohydrates.toStringAsFixed(1) ?? '',
    );
    _countryController = TextEditingController(
      text: product?.characteristics['Страна производителя'] ?? '',
    );
    final now = DateTime.now();
    final eta = now.add(const Duration(days: 1));
    _deliveryWeekdays
      ..clear()
      ..add(eta.weekday);
    final deliveryDate = product?.deliveryDate.trim() ?? '';
    final deliveryBadge = product?.deliveryBadge.trim() ?? '';
    _deliveryDateController = TextEditingController();
    _deliveryBadgeController = TextEditingController();
    _applyDeliveryScheduleFromRaw(
      deliveryDate: deliveryDate,
      deliveryBadge: deliveryBadge,
    );
    _deliveryTimeController = TextEditingController(
      text: _formatTime(_deliveryTime),
    );
    if (product != null) {
      for (final image in product.imageUrls) {
        final normalized = image.trim();
        if (normalized.isEmpty) {
          continue;
        }
        if (_isDisplayableImagePath(normalized) &&
            !_images.contains(normalized)) {
          _images.add(normalized);
        }
      }
    }
    _loadPresetCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _minController.dispose();
    _stockController.dispose();
    _ingredientsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _countryController.dispose();
    _deliveryDateController.dispose();
    _deliveryBadgeController.dispose();
    _deliveryTimeController.dispose();
    _imageUrlController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPresetCategories() async {
    try {
      final tree = await ApiService.getCatalogCategoryTree();
      final categories = _extractSelectableCategories(tree);
      if (!mounted || categories.isEmpty) {
        return;
      }
      setState(() {
        _presetCategories
          ..clear()
          ..addAll(categories);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _presetCategories
          ..clear()
          ..addAll(_fallbackPresetCategories);
      });
    }
  }

  List<String> _extractSelectableCategories(List<Map<String, dynamic>> tree) {
    final categories = <String>[];
    final seen = <String>{};

    void addCategory(Object? value) {
      final normalized = _normalizeCategory(value?.toString() ?? '');
      if (normalized.isEmpty) {
        return;
      }
      final key = normalized.toLowerCase();
      if (seen.add(key)) {
        categories.add(normalized);
      }
    }

    for (final root in tree) {
      final subRows = root['subcategories'];
      if (subRows is List && subRows.isNotEmpty) {
        for (final child in subRows) {
          if (child is! Map) {
            continue;
          }
          addCategory(child['name']);
        }
        continue;
      }
      addCategory(root['name']);
    }

    return categories;
  }

  Future<void> _pickImages() async {
    try {
      final picks = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picks.isEmpty) return;
      await _addPickedFiles(picks);
    } catch (_) {
      final pick = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (pick == null) return;
      await _addPickedFiles([pick]);
    }
  }

  Future<void> _addPickedFiles(List<XFile> files) async {
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final mime = _guessMime(file.name);
      final encoded = base64Encode(bytes);
      final payload = 'base64:$mime:$encoded';
      if (!_images.contains(payload)) {
        _images.add(payload);
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  String _guessMime(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _addImageUrl() {
    final raw = _imageUrlController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Вставьте ссылку на фото');
      return;
    }

    final parts = raw
        .split(RegExp(r'[\r\n\t ]+'))
        .map((item) => item.trim().replaceAll(RegExp(r'[;,]+$'), ''))
        .where((item) => item.isNotEmpty)
        .toList();

    final validUrls = <String>[];
    for (final candidate in parts) {
      if (_isValidImageUrl(candidate)) {
        validUrls.add(candidate);
      }
    }

    if (validUrls.isEmpty) {
      setState(() => _error = 'Введите корректную ссылку (http/https)');
      return;
    }

    var addedCount = 0;
    for (final url in validUrls) {
      if (!_images.contains(url)) {
        _images.add(url);
        addedCount += 1;
      }
    }

    _imageUrlController.clear();
    setState(() {
      _error = addedCount == 0 ? 'Эта ссылка уже добавлена' : null;
    });
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _images.length) return;
    _images.removeAt(index);
    setState(() {});
  }

  bool _validateStep() {
    setState(() => _error = null);
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        _error = 'Введите название товара';
        return false;
      }
      if (_selectedCategories.isEmpty) {
        _error = 'Выберите категорию из списка';
        return false;
      }
      return true;
    }
    if (_step == 1) {
      final price = int.tryParse(_priceController.text.trim());
      final minQuantity = int.tryParse(_minController.text.trim()) ?? 1;
      final stockQuantity = int.tryParse(_stockController.text.trim()) ?? -1;
      if (price == null || price <= 0) {
        _error = 'Введите корректную цену';
        return false;
      }
      if (price > _maxIntegerFieldValue) {
        _error = 'Цена не должна превышать $_maxIntegerFieldValue';
        return false;
      }
      if (minQuantity <= 0) {
        _error = 'Минимальное количество должно быть больше 0';
        return false;
      }
      if (minQuantity > _maxIntegerFieldValue) {
        _error =
            'Минимальное количество не должно превышать $_maxIntegerFieldValue';
        return false;
      }
      if (stockQuantity < 0) {
        _error = 'Укажите остаток на складе';
        return false;
      }
      if (stockQuantity > _maxIntegerFieldValue) {
        _error = 'Остаток на складе не должен превышать $_maxIntegerFieldValue';
        return false;
      }
      if (stockQuantity > 0 && stockQuantity < minQuantity) {
        _error = 'Остаток не может быть меньше минимальной партии';
        return false;
      }
      if (!_applyDeliveryTimeFromInput(markInvalid: true)) {
        _error = 'Введите время доставки в формате ЧЧ:ММ';
        return false;
      }
      if (_deliveryDateController.text.trim().isEmpty ||
          _deliveryBadgeController.text.trim().isEmpty) {
        _error = 'Укажите график доставки';
        return false;
      }
      return true;
    }
    if (_step == 2) {
      final caloriesText = _caloriesController.text.trim();
      final proteinText = _proteinController.text.trim();
      final fatText = _fatController.text.trim();
      final carbsText = _carbsController.text.trim();

      double? calories;
      double? protein;
      double? fat;
      double? carbs;

      if (caloriesText.isNotEmpty) {
        calories = double.tryParse(caloriesText.replaceAll(',', '.'));
        if (calories == null || calories < 0) {
          _error = 'Калории должны быть неотрицательным числом';
          return false;
        }
        if (_exceedsNumeric10Scale2(calories)) {
          _error =
              'Калории не должны превышать $_numeric10Scale2MaxValue (ограничение NUMERIC(10,2))';
          return false;
        }
      }
      if (proteinText.isNotEmpty) {
        protein = double.tryParse(proteinText.replaceAll(',', '.'));
        if (protein == null || protein < 0) {
          _error = 'Белки должны быть неотрицательным числом';
          return false;
        }
        if (_exceedsNumeric10Scale2(protein)) {
          _error =
              'Белки не должны превышать $_numeric10Scale2MaxValue (ограничение NUMERIC(10,2))';
          return false;
        }
      }
      if (fatText.isNotEmpty) {
        fat = double.tryParse(fatText.replaceAll(',', '.'));
        if (fat == null || fat < 0) {
          _error = 'Жиры должны быть неотрицательным числом';
          return false;
        }
        if (_exceedsNumeric10Scale2(fat)) {
          _error =
              'Жиры не должны превышать $_numeric10Scale2MaxValue (ограничение NUMERIC(10,2))';
          return false;
        }
      }
      if (carbsText.isNotEmpty) {
        carbs = double.tryParse(carbsText.replaceAll(',', '.'));
        if (carbs == null || carbs < 0) {
          _error = 'Углеводы должны быть неотрицательным числом';
          return false;
        }
        if (_exceedsNumeric10Scale2(carbs)) {
          _error =
              'Углеводы не должны превышать $_numeric10Scale2MaxValue (ограничение NUMERIC(10,2))';
          return false;
        }
      }
      return true;
    }
    if (_step == 3) {
      final hasValidImage = _images.any(_isDisplayableImagePath);
      if (!hasValidImage) {
        _error = 'Добавьте хотя бы одну фотографию';
        return false;
      }
      return true;
    }
    return true;
  }

  void _nextStep() {
    if (!_validateStep()) return;
    if (_step >= _totalSteps - 1) {
      _submit();
      return;
    }
    setState(() => _step += 1);
  }

  void _previousStep() {
    if (_step == 0) return;
    setState(() => _step -= 1);
  }

  void _submit() {
    if (!_validateStep()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final categories = _selectedCategories.toList(growable: false);
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final minQuantity = int.tryParse(_minController.text.trim()) ?? 1;
    final stockQuantity = int.tryParse(_stockController.text.trim()) ?? 0;
    final deliverySchedule = _buildDeliveryScheduleLabel();
    final calories =
        double.tryParse(_caloriesController.text.trim().replaceAll(',', '.')) ??
        0.0;
    final protein =
        double.tryParse(_proteinController.text.trim().replaceAll(',', '.')) ??
        0.0;
    final fat =
        double.tryParse(_fatController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final carbs =
        double.tryParse(_carbsController.text.trim().replaceAll(',', '.')) ??
        0.0;
    final characteristics = <String, String>{};
    final country = _countryController.text.trim();
    if (country.isNotEmpty) {
      characteristics['Страна производителя'] = country;
    }
    final images = LinkedHashSet<String>.from(
      _images
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty && _isDisplayableImagePath(item)),
    ).toList(growable: false);

    final result = SupplierProduct(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      categories: categories,
      imageUrls: images,
      pricePerUnit: price,
      minQuantity: minQuantity,
      maxQuantity: stockQuantity > 0 ? stockQuantity : null,
      stockQuantity: stockQuantity,
      ingredients: _ingredientsController.text.trim(),
      nutritionalInfo: SupplierNutritionalInfo(
        calories: calories,
        protein: protein,
        fat: fat,
        carbohydrates: carbs,
      ),
      characteristics: characteristics,
      supplierName: widget.product?.supplierName ?? '',
      deliveryDate: deliverySchedule,
      deliveryBadge: deliverySchedule,
      moderationStatus: widget.product?.moderationStatus ?? 'pending',
      moderationComment: widget.product?.moderationComment ?? '',
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Создание товара' : 'Редактирование товара',
        ),
      ),
      body: Column(
        children: [
          _StepHeader(step: _step, totalSteps: _totalSteps),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _step == 0
                    ? _buildInfoStep()
                    : (_step == 1
                          ? _buildPriceStep()
                          : (_step == 2
                                ? _buildDetailsStep()
                                : _buildPhotosStep())),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _step == 0 ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    minimumSize: const Size.fromHeight(54),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Назад'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _step == _totalSteps - 1
                      ? const Text('Сохранить')
                      : const Text('Далее'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoStep() {
    return _StepCard(
      title: 'Основные данные',
      subtitle: 'Заполните название, описание, страну и категорию товара.',
      child: Column(
        children: [
          _buildField('Название товара', _nameController),
          _buildField('Описание', _descriptionController, maxLines: 3),
          _buildField(
            'Страна производителя',
            _countryController,
            hintText: 'Например, Казахстан',
          ),
          _buildCategoryPicker(),
        ],
      ),
    );
  }

  Widget _buildPriceStep() {
    return _StepCard(
      title: 'Цена и условия',
      subtitle: 'Минимальные количества и доставка.',
      child: Column(
        children: [
          _buildField(
            'Цена за единицу (₸)',
            _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hintText: 'Например, 1450',
          ),
          _buildField(
            'Минимальное количество',
            _minController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _buildField(
            'Всего количество',
            _stockController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hintText: 'Например, 120',
          ),
          _buildDeliverySchedulePicker(),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return _StepCard(
      title: 'Состав и характеристики',
      subtitle: 'Необязательные данные: заполняйте только то, что нужно.',
      child: Column(
        children: [
          _buildField('Состав', _ingredientsController, maxLines: 3),
          _buildField(
            'Калории (ккал/100г)',
            _caloriesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          _buildField(
            'Белки (г/100г)',
            _proteinController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          _buildField(
            'Жиры (г/100г)',
            _fatController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          _buildField(
            'Углеводы (г/100г)',
            _carbsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    const previewWidth = 152.0;
    const previewHeight = 182.0;
    return _StepCard(
      title: 'Фотографии товара',
      subtitle: 'Добавьте несколько фото, как в маркетплейсах.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (int i = 0; i < _images.length; i++)
                Stack(
                  children: [
                    SmartImage(
                      path: _images[i],
                      width: previewWidth,
                      height: previewHeight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: () => _removeImage(i),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              InkWell(
                onTap: _pickImages,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: previewWidth,
                  height: previewHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined),
                      SizedBox(height: 6),
                      Text('Добавить', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Или вставьте ссылку на фото (https://...)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(hintText: 'https://...'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addImageUrl,
                child: const Text('Добавить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 6),
            Text(
              helperText,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliverySchedulePicker() {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedValue = _buildDeliveryScheduleLabel();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ожидаемая дата доставки',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: colorScheme.surfaceContainerHighest,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выберите дни недели',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _weekdayOrder
                      .map((weekday) => _buildDeliveryWeekdayChip(weekday))
                      .toList(growable: false),
                ),
                const SizedBox(height: 10),
                Text(
                  'Быстрый выбор',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Будни'),
                      selected: _isPresetSelected(_workdayPreset),
                      onSelected: (selected) {
                        if (!selected) {
                          return;
                        }
                        _applyWeekdayPreset(_workdayPreset);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Выходные'),
                      selected: _isPresetSelected(_weekendPreset),
                      onSelected: (selected) {
                        if (!selected) {
                          return;
                        }
                        _applyWeekdayPreset(_weekendPreset);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Ежедневно'),
                      selected: _isPresetSelected(_weekdayOrder),
                      onSelected: (selected) {
                        if (!selected) {
                          return;
                        }
                        _applyWeekdayPreset(_weekdayOrder);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Время доставки',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _deliveryTimeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [const _DeliveryTimeInputFormatter()],
                  onChanged: _onDeliveryTimeInputChanged,
                  onEditingComplete: _onDeliveryTimeInputComplete,
                  onSubmitted: (_) => _onDeliveryTimeInputComplete(),
                  decoration: InputDecoration(
                    hintText: '14:00',
                    helperText: 'Формат: ЧЧ:ММ',
                    errorText: _deliveryTimeInputInvalid
                        ? 'Некорректное время'
                        : null,
                    prefixIcon: const Icon(Icons.schedule_outlined),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainerHighest,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Формат сохранения: $formattedValue',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Можно выбрать один или несколько дней недели, например Пн и Пт.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryWeekdayChip(int weekday) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _deliveryWeekdays.contains(weekday);
    final label = _weekdaysShort[weekday] ?? _weekdaysFull[weekday] ?? 'Пн';

    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surface,
      side: BorderSide(
        color: selected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (_) => _toggleDeliveryWeekday(weekday),
    );
  }

  void _toggleDeliveryWeekday(int weekday) {
    setState(() {
      if (_deliveryWeekdays.contains(weekday)) {
        if (_deliveryWeekdays.length == 1) {
          return;
        }
        _deliveryWeekdays.remove(weekday);
      } else {
        _deliveryWeekdays.add(weekday);
      }
      _syncDeliveryControllers();
    });
  }

  bool _isPresetSelected(Iterable<int> preset) {
    final left = _sortWeekdays(_deliveryWeekdays);
    final right = _sortWeekdays(preset);
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  void _applyWeekdayPreset(Iterable<int> preset) {
    setState(() {
      _deliveryWeekdays
        ..clear()
        ..addAll(_sortWeekdays(preset));
      _syncDeliveryControllers();
    });
  }

  bool _isSameTime(TimeOfDay first, TimeOfDay second) {
    return first.hour == second.hour && first.minute == second.minute;
  }

  TimeOfDay? _parseDeliveryTimeInput(String raw) {
    final normalized = raw.trim();
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(normalized);
    if (match == null) {
      return null;
    }
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _applyDeliveryTimeFromInput({bool markInvalid = false}) {
    final parsed = _parseDeliveryTimeInput(_deliveryTimeController.text);
    if (parsed == null) {
      if (markInvalid) {
        _deliveryTimeInputInvalid = true;
      }
      return false;
    }
    _deliveryTimeInputInvalid = false;
    if (_isSameTime(_deliveryTime, parsed)) {
      return true;
    }
    _deliveryTime = parsed;
    _syncDeliveryControllers();
    return true;
  }

  void _onDeliveryTimeInputChanged(String value) {
    final parsed = _parseDeliveryTimeInput(value);
    if (parsed == null) {
      if (_deliveryTimeInputInvalid) {
        setState(() {
          _deliveryTimeInputInvalid = false;
        });
      }
      return;
    }
    if (_isSameTime(_deliveryTime, parsed) && !_deliveryTimeInputInvalid) {
      return;
    }
    setState(() {
      _deliveryTimeInputInvalid = false;
      _deliveryTime = parsed;
      _syncDeliveryControllers();
    });
  }

  void _onDeliveryTimeInputComplete() {
    setState(() {
      _applyDeliveryTimeFromInput(markInvalid: true);
    });
  }

  Widget _buildCategoryPicker() {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _normalizeCategory(
      _categorySearchController.text,
    ).toLowerCase();
    final filteredCategories = _presetCategories
        .where(
          (category) => query.isEmpty || category.toLowerCase().contains(query),
        )
        .toList(growable: false);
    final hasOverflow =
        query.isEmpty &&
        filteredCategories.length > _initialCategoryVisibleLimit;
    final visibleCategories = hasOverflow && !_showAllPresetCategories
        ? filteredCategories
              .take(_initialCategoryVisibleLimit)
              .toList(growable: false)
        : filteredCategories;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Категории',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите категорию из каталога. Новые категории добавляются через модерацию.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _categorySearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Поиск категории',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _categorySearchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистить',
                      onPressed: () {
                        setState(() {
                          _categorySearchController.clear();
                          _showAllPresetCategories = false;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          if (visibleCategories.isEmpty)
            Text(
              'Категории не найдены',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleCategories
                  .map((category) {
                    final selected = _containsCategory(category);
                    return FilterChip(
                      label: Text(category),
                      selected: selected,
                      selectedColor: colorScheme.primary.withValues(
                        alpha: 0.14,
                      ),
                      checkmarkColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected
                            ? colorScheme.primary.withValues(alpha: 0.55)
                            : colorScheme.outlineVariant,
                      ),
                      onSelected: (_) => _toggleCategory(category),
                    );
                  })
                  .toList(growable: false),
            ),
          if (hasOverflow) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllPresetCategories = !_showAllPresetCategories;
                });
              },
              child: Text(
                _showAllPresetCategories
                    ? 'Показать меньше'
                    : 'Показать все (${filteredCategories.length})',
              ),
            ),
          ],
          if (_selectedCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedCategories
                  .map((category) {
                    return InputChip(
                      label: Text(category),
                      onDeleted: () =>
                          _toggleCategory(category, forceRemove: true),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleCategory(String raw, {bool forceRemove = false}) {
    final normalized = _normalizeCategory(raw);
    if (normalized.isEmpty) {
      return;
    }
    final existing = _findExistingCategory(normalized);
    setState(() {
      if (existing != null && (forceRemove || _containsCategory(normalized))) {
        _selectedCategories.remove(existing);
      } else {
        _selectedCategories.add(normalized);
      }
      _error = null;
    });
  }

  bool _containsCategory(String value) => _findExistingCategory(value) != null;

  String? _findExistingCategory(String value) {
    final lowered = value.toLowerCase();
    for (final category in _selectedCategories) {
      if (category.toLowerCase() == lowered) {
        return category;
      }
    }
    return null;
  }

  String _normalizeCategory(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isValidImageUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || !uri.isAbsolute) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  bool _isDisplayableImagePath(String raw) {
    if (raw.startsWith('base64:') || raw.startsWith('data:image')) {
      return true;
    }
    if (raw.startsWith('assets/')) {
      return true;
    }
    return _isValidImageUrl(raw);
  }

  void _applyDeliveryScheduleFromRaw({
    required String deliveryDate,
    required String deliveryBadge,
  }) {
    final source = deliveryBadge.trim().isNotEmpty
        ? deliveryBadge.trim()
        : deliveryDate.trim();
    final normalized = source.toLowerCase();
    final timeMatch = RegExp(
      r'([01]?\d|2[0-3]):([0-5]\d)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1) ?? '');
      final minute = int.tryParse(timeMatch.group(2) ?? '');
      if (hour != null && minute != null) {
        _deliveryTime = TimeOfDay(hour: hour, minute: minute);
        final weekdaysPart = normalized.substring(0, timeMatch.start).trim();
        final parsedWeekdays = _parseDeliveryWeekdays(weekdaysPart);
        if (parsedWeekdays.isNotEmpty) {
          _deliveryWeekdays
            ..clear()
            ..addAll(parsedWeekdays);
        }
      }
    }
    _syncDeliveryControllers();
  }

  List<int> _parseDeliveryWeekdays(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const <int>[];
    }

    if (normalized == 'будни') {
      return _sortWeekdays(_workdayPreset);
    }
    if (normalized == 'выходные') {
      return _sortWeekdays(_weekendPreset);
    }
    if (normalized == 'ежедневно' || normalized == 'каждый день') {
      return _sortWeekdays(_weekdayOrder);
    }

    final rangeParts = normalized.split(RegExp(r'\s*-\s*'));
    if (rangeParts.length == 2) {
      final start = _parseWeekdayAny(rangeParts.first);
      final end = _parseWeekdayAny(rangeParts.last);
      if (start != null && end != null) {
        return _expandWeekdayRange(start, end);
      }
    }

    final sourceTokens = normalized.contains(',')
        ? normalized.split(RegExp(r'\s*,\s*'))
        : normalized.split(RegExp(r'\s+'));
    final parsedWeekdays = <int>{};
    for (final token in sourceTokens) {
      final weekday = _parseWeekdayAny(token);
      if (weekday != null) {
        parsedWeekdays.add(weekday);
      }
    }
    if (parsedWeekdays.isNotEmpty) {
      return _sortWeekdays(parsedWeekdays);
    }

    final single = _parseWeekdayAny(normalized);
    if (single != null) {
      return <int>[single];
    }
    return const <int>[];
  }

  int? _parseWeekdayAny(String? value) {
    final shortWeekday = _parseWeekdayShort(value);
    if (shortWeekday != null) {
      return shortWeekday;
    }
    return _parseWeekdayFull(value);
  }

  int? _parseWeekdayShort(String? value) {
    final normalized = value?.replaceAll('.', '').trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final entry in _weekdaysShort.entries) {
      if (entry.value.toLowerCase() == normalized) {
        return entry.key;
      }
    }
    return null;
  }

  int? _parseWeekdayFull(String? value) {
    final normalized = value?.replaceAll('.', '').trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final entry in _weekdaysFull.entries) {
      if (entry.value.toLowerCase() == normalized) {
        return entry.key;
      }
    }
    return null;
  }

  List<int> _expandWeekdayRange(int start, int end) {
    final expanded = <int>[start];
    var current = start;
    while (current != end && expanded.length < _weekdayOrder.length) {
      current = current == DateTime.sunday ? DateTime.monday : current + 1;
      expanded.add(current);
    }
    return _sortWeekdays(expanded);
  }

  List<int> _sortWeekdays(Iterable<int> weekdays) {
    final sorted = weekdays.toSet().toList(growable: false)
      ..sort((a, b) {
        final firstOrder = _weekdayOrder.indexOf(a);
        final secondOrder = _weekdayOrder.indexOf(b);
        if (firstOrder == -1 && secondOrder == -1) {
          return a.compareTo(b);
        }
        if (firstOrder == -1) {
          return 1;
        }
        if (secondOrder == -1) {
          return -1;
        }
        return firstOrder.compareTo(secondOrder);
      });
    return sorted;
  }

  List<int> _resolvedDeliveryWeekdays() {
    if (_deliveryWeekdays.isEmpty) {
      return const <int>[DateTime.monday];
    }
    return _sortWeekdays(_deliveryWeekdays);
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _buildDeliveryScheduleLabel() {
    final formattedTime = _formatTime(_deliveryTime);
    final weekdays = _resolvedDeliveryWeekdays();
    if (_isPresetSelected(_weekdayOrder)) {
      return 'Ежедневно $formattedTime';
    }
    if (_isPresetSelected(_workdayPreset)) {
      return 'Будни $formattedTime';
    }
    if (_isPresetSelected(_weekendPreset)) {
      return 'Выходные $formattedTime';
    }
    if (weekdays.length == 1) {
      final dayName = _weekdaysFull[weekdays.first] ?? 'Понедельник';
      return '$dayName $formattedTime';
    }

    final daysLabel = weekdays
        .map((weekday) => _weekdaysShort[weekday] ?? 'Пн')
        .join(', ');
    return '$daysLabel $formattedTime';
  }

  void _syncDeliveryControllers() {
    if (_deliveryWeekdays.isEmpty) {
      _deliveryWeekdays.add(DateTime.monday);
    }
    final formatted = _buildDeliveryScheduleLabel();
    _deliveryDateController.text = formatted;
    _deliveryBadgeController.text = formatted;
  }
}

class _DeliveryTimeInputFormatter extends TextInputFormatter {
  const _DeliveryTimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clamped = digits.length > 4 ? digits.substring(0, 4) : digits;

    String text;
    if (clamped.length <= 2) {
      text = clamped;
    } else {
      text = '${clamped.substring(0, 2)}:${clamped.substring(2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.totalSteps});

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labels = const ['Данные', 'Цена', 'Состав', 'Фото'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Шаг ${step + 1} из $totalSteps',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var index = 0; index < totalSteps; index++) ...[
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index <= step
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index <= step
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (index != totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: index < step
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index <= step;
              final isFirst = index == 0;
              final isLast = index == totalSteps - 1;
              final alignment = isFirst
                  ? Alignment.centerLeft
                  : (isLast ? Alignment.centerRight : Alignment.center);
              final textAlign = isFirst
                  ? TextAlign.left
                  : (isLast ? TextAlign.right : TextAlign.center);
              return Expanded(
                child: Align(
                  alignment: alignment,
                  child: Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: textAlign,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

