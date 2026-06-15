import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/ui/theme/app_dimensions.dart';
import '../models/supplier_product.dart';
import '../services/api/api_service.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../theme/app_color_palette.dart';
import '../utils/custom_characteristic_validation.dart';
import '../utils/delivery_schedule.dart';
import '../utils/wizard_init.dart';
import '../widgets/smart_image.dart';
import '../widgets/messages/top_message.dart';

// Режим задания расписания доставки в визарде поставщика.
enum _DeliveryMode { weekly, leadTime }

// Общий фильтр ввода для числовых полей с десятичной частью - вынесен в top-level
// final, чтобы не пересоздавать RegExp на каждый ребилд экрана.
final RegExp _kNumericInputAllowed = RegExp(r'[0-9.,]');

class SupplierProductWizardPage extends StatefulWidget {
  const SupplierProductWizardPage({super.key, this.product});

  final SupplierProduct? product;

  @override
  State<SupplierProductWizardPage> createState() =>
      _SupplierProductWizardPageState();
}

class _SupplierProductWizardPageState extends State<SupplierProductWizardPage> {
  final _picker = ImagePicker();
  final _categorySearchController = TextEditingController();
  Timer? _categorySearchDebounce;
  static const Duration _categorySearchDebounceDuration = Duration(
    milliseconds: 300,
  );

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
  late final TextEditingController _shelfLifeController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _deliveryBadgeController;
  late final TextEditingController _deliveryTimeController;
  late final TextEditingController _leadMinController;
  late final TextEditingController _leadMaxController;
  late final TextEditingController _cutoffController;

  int _step = 0;
  String? _error;
  bool _isSubmitting = false;
  bool _deliveryTimeInputInvalid = false;
  bool _cutoffInputInvalid = false;
  _DeliveryMode _deliveryMode = _DeliveryMode.weekly;
  bool _isInit = false;
  // Якорь для прокрутки к блоку расписания после смены режима.
  final GlobalKey _deliveryBlockKey = GlobalKey();
  final List<String> _images = [];
  final List<_CustomCharacteristicDraft> _customCharacteristics = [];
  final LinkedHashSet<String> _selectedCategories = LinkedHashSet<String>();
  final LinkedHashSet<int> _deliveryWeekdays = LinkedHashSet<int>();
  TimeOfDay _deliveryTime = TimeOfDay(hour: 14, minute: 0);

  Map<int, String> get _weekdaysFull => <int, String>{
    DateTime.monday: context.l10n.getString('auto_ponedelnik_1'),
    DateTime.tuesday: context.l10n.getString('auto_vtornik_1'),
    DateTime.wednesday: context.l10n.getString('auto_sreda_1'),
    DateTime.thursday: context.l10n.getString('auto_chetverg_1'),
    DateTime.friday: context.l10n.getString('auto_pyatnitsa_1'),
    DateTime.saturday: context.l10n.getString('auto_subbota_1'),
    DateTime.sunday: context.l10n.getString('auto_voskresene_1'),
  };
  
  Map<int, String> get _weekdaysShort => <int, String>{
    DateTime.monday: context.l10n.getString('auto_pn'),
    DateTime.tuesday: context.l10n.getString('auto_vt_1'),
    DateTime.wednesday: context.l10n.getString('auto_sr_1'),
    DateTime.thursday: context.l10n.getString('auto_cht_1'),
    DateTime.friday: context.l10n.getString('auto_pt_1'),
    DateTime.saturday: context.l10n.getString('auto_sb_1'),
    DateTime.sunday: context.l10n.getString('auto_vs_1'),
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

  List<String> get _fallbackPresetCategories => [
    context.l10n.getString('auto_napitki'),
    context.l10n.getString('auto_molochnayaProduktsiya'),
    context.l10n.getString('auto_ovoshchiIFrukty'),
    context.l10n.getString('auto_myasoIPtitsa'),
    context.l10n.getString('auto_bakaleya'),
    context.l10n.getString('auto_hlebIVypechka'),
    context.l10n.getString('auto_zamorozka'),
    context.l10n.getString('auto_sneki'),
    context.l10n.getString('auto_bytovayaHimiya'),
    context.l10n.getString('auto_tovaryDlyaDoma'),
  ];
  late final List<String> _presetCategories = List<String>.from(
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final product = widget.product;
      if (product != null) {
        _countryController.text = product.characteristics[context.l10n.getString('auto_stranaProizvoditelya')] ?? '';
        _shelfLifeController.text = product.characteristics[context.l10n.getString('auto_srokGodnosti')] ?? '';
      }
      _isInit = true;
    }
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
    _countryController = TextEditingController();
    _shelfLifeController = TextEditingController();
    final now = DateTime.now();
    final eta = now.add(const Duration(days: 1));
    _deliveryWeekdays
      ..clear()
      ..add(eta.weekday);
    final deliveryDate = product?.deliveryDate.trim() ?? '';
    final deliveryBadge = product?.deliveryBadge.trim() ?? '';
    _deliveryDateController = TextEditingController();
    _deliveryBadgeController = TextEditingController();
    _leadMinController = TextEditingController(text: '1');
    _leadMaxController = TextEditingController(text: '3');
    _cutoffController = TextEditingController();
    _applyDeliveryScheduleFromRaw(
      deliveryDate: deliveryDate,
      deliveryBadge: deliveryBadge,
    );
    _deliveryTimeController = TextEditingController(
      text: _formatTime(_deliveryTime),
    );
    if (product != null) {
      final drafts = initCustomCharacteristicDrafts(product.characteristics);
      for (final d in drafts) {
        _customCharacteristics.add(
          _CustomCharacteristicDraft(name: d.name, value: d.value),
        );
      }
      _images.addAll(
        initWizardImages(product.imageUrls, _isDisplayableImagePath),
      );
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
    _shelfLifeController.dispose();
    _deliveryDateController.dispose();
    _deliveryBadgeController.dispose();
    _deliveryTimeController.dispose();
    _leadMinController.dispose();
    _leadMaxController.dispose();
    _cutoffController.dispose();
    _categorySearchController.dispose();
    _categorySearchDebounce?.cancel();
    for (final draft in _customCharacteristics) {
      draft.dispose();
    }
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

  void _removeImage(int index) {
    if (index < 0 || index >= _images.length) return;
    _images.removeAt(index);
    setState(() {});
  }

  bool _validateStep() {
    setState(() => _error = null);
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        _error = context.l10n.getString('auto_vvediteNazvanieTovara');
        return false;
      }
      if (_shelfLifeController.text.trim().isEmpty) {
        _error = context.l10n.getString('auto_ukazhiteSrokGodnosti');
        return false;
      }
      if (_selectedCategories.isEmpty) {
        _error = context.l10n.getString('auto_vyberiteKategoriyuIzSp');
        return false;
      }
      return true;
    }
    if (_step == 1) {
      final price = int.tryParse(_priceController.text.trim());
      final minQuantity = int.tryParse(_minController.text.trim()) ?? 1;
      final stockQuantity = int.tryParse(_stockController.text.trim()) ?? -1;
      if (price == null || price <= 0) {
        _error = context.l10n.getString('auto_vvediteKorrektnuyuTsenu');
        return false;
      }
      if (price > _maxIntegerFieldValue) {
        _error = context.l10n.wizardErrorPriceMax(_maxIntegerFieldValue.toString());
        return false;
      }
      if (minQuantity <= 0) {
        _error = context.l10n.getString('auto_minimalnoeKolichestvoDo');
        return false;
      }
      if (minQuantity > _maxIntegerFieldValue) {
        _error = context.l10n.wizardErrorMinQuantityMax(_maxIntegerFieldValue.toString());
        return false;
      }
      if (stockQuantity < 0) {
        _error = context.l10n.getString('auto_ukazhiteOstatokNaSklad');
        return false;
      }
      if (stockQuantity > _maxIntegerFieldValue) {
        _error = context.l10n.wizardErrorStockMax(_maxIntegerFieldValue.toString());
        return false;
      }
      if (stockQuantity > 0 && stockQuantity < minQuantity) {
        _error = context.l10n.getString('auto_ostatokNeMozhetBytMen');
        return false;
      }
      if (_deliveryMode == _DeliveryMode.weekly) {
        if (!_applyDeliveryTimeFromInput(markInvalid: true)) {
          _error = context.l10n.getString('auto_vvediteVremyaDostavkiV');
          return false;
        }
        if (_deliveryDateController.text.trim().isEmpty ||
            _deliveryBadgeController.text.trim().isEmpty) {
          _error = context.l10n.getString('auto_ukazhiteGrafikDostavki');
          return false;
        }
      } else {
        final minLeadText = _leadMinController.text.trim();
        final maxLeadText = _leadMaxController.text.trim();
        final minLead = int.tryParse(minLeadText);
        final maxLead = int.tryParse(maxLeadText);
        if (minLead == null || minLead < 0) {
          _error = context.l10n.getString('auto_vvediteMinimalnyySrokD');
          return false;
        }
        if (maxLead == null || maxLead < minLead) {
          _error = context.l10n.getString('auto_maksimalnyySrokNeMozhe');
          return false;
        }
        if (maxLead > 365) {
          _error = context.l10n.getString('auto_srokDostavkiSlishkomBo');
          return false;
        }
        final cutoffRaw = _cutoffController.text.trim();
        if (cutoffRaw.isNotEmpty && _parseCutoff() == null) {
          setState(() {
            _cutoffInputInvalid = true;
          });
          _error = context.l10n.getString('auto_vvediteVremyaOtsechkiV');
          return false;
        }
        _cutoffInputInvalid = false;
        _syncDeliveryControllers();
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
          _error = context.l10n.getString('auto_kaloriiDolzhnyBytNeotr');
          return false;
        }
        if (_exceedsNumeric10Scale2(calories)) {
          _error = context.l10n.wizardErrorCaloriesMax(_numeric10Scale2MaxValue.toString());
          return false;
        }
      }
      if (proteinText.isNotEmpty) {
        protein = double.tryParse(proteinText.replaceAll(',', '.'));
        if (protein == null || protein < 0) {
          _error = context.l10n.getString('auto_belkiDolzhnyBytNeotrit');
          return false;
        }
        if (_exceedsNumeric10Scale2(protein)) {
          _error = context.l10n.wizardErrorProteinMax(_numeric10Scale2MaxValue.toString());
          return false;
        }
      }
      if (fatText.isNotEmpty) {
        fat = double.tryParse(fatText.replaceAll(',', '.'));
        if (fat == null || fat < 0) {
          _error = context.l10n.getString('auto_zhiryDolzhnyBytNeotrit');
          return false;
        }
        if (_exceedsNumeric10Scale2(fat)) {
          _error = context.l10n.wizardErrorFatMax(_numeric10Scale2MaxValue.toString());
          return false;
        }
      }
      if (carbsText.isNotEmpty) {
        carbs = double.tryParse(carbsText.replaceAll(',', '.'));
        if (carbs == null || carbs < 0) {
          _error = context.l10n.getString('auto_uglevodyDolzhnyBytNeot');
          return false;
        }
        if (_exceedsNumeric10Scale2(carbs)) {
          _error = context.l10n.wizardErrorCarbsMax(_numeric10Scale2MaxValue.toString());
          return false;
        }
      }
      // Произвольные характеристики проверяем вместе с обязательными полями
      // («Страна производителя», «Срок годности»), чтобы дубликаты с этими
      // ключами тоже отлавливались.
      final country = _countryController.text.trim();
      final shelfLife = _shelfLifeController.text.trim();
      final starter = <String, String>{
        if (country.isNotEmpty) context.l10n.getString('auto_stranaProizvoditelya'): country,
        if (shelfLife.isNotEmpty) context.l10n.getString('auto_srokGodnosti'): shelfLife,
      };
      final drafts = _customCharacteristics
          .map((d) => (name: d.name, value: d.value))
          .toList(growable: false);
      final result = validateCustomCharacteristics(drafts, starter: starter);
      if (result.error != null) {
        _error = result.error!.message;
        return false;
      }
      return true;
    }
    if (_step == 3) {
      final hasValidImage = _images.any(_isDisplayableImagePath);
      if (!hasValidImage) {
        _error = context.l10n.getString('auto_dobavteHotyaByOdnuFot');
        return false;
      }
      return true;
    }
    return true;
  }

  void _nextStep() {
    if (!_validateStep()) {
      _showErrorMessage();
      return;
    }
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

  // Переход на произвольный шаг по тапу на цифру в шапке.
  // Назад идём свободно. Вперёд - валидируя каждый промежуточный шаг.
  void _jumpToStep(int target) {
    if (target == _step) return;
    if (target < 0 || target >= _totalSteps) return;
    if (target < _step) {
      setState(() => _step = target);
      return;
    }
    while (_step < target) {
      if (!_validateStep()) {
        _showErrorMessage();
        setState(() {});
        return;
      }
      setState(() => _step += 1);
    }
  }

  // Топ-сообщение с текстом текущей ошибки. Используем единый стиль приложения,
  // чтобы валидация визарда выглядела как и в других экранах.
  void _showErrorMessage() {
    final message = _error;
    if (message == null || message.isEmpty) return;
    showTopMessage(
      context,
      message,
      backgroundColor: context.colorPalette.error,
    );
  }

  Future<void> _submit() async {
    if (!_validateStep()) {
      _showErrorMessage();
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Отдельная проверка характеристик: «Сохранить» можно нажать с шага 3
    // (фото), а ошибка на шаге 2 должна вернуть пользователя к ней.
    final country = _countryController.text.trim();
    final shelfLife = _shelfLifeController.text.trim();
    final starter = <String, String>{
      if (country.isNotEmpty) context.l10n.getString('auto_stranaProizvoditelya'): country,
      if (shelfLife.isNotEmpty) context.l10n.getString('auto_srokGodnosti'): shelfLife,
    };
    final drafts = _customCharacteristics
        .map((d) => (name: d.name, value: d.value))
        .toList(growable: false);
    final charResult = validateCustomCharacteristics(drafts, starter: starter);
    if (charResult.error != null) {
      setState(() {
        _step = 2;
        _error = charResult.error!.message;
        _isSubmitting = false;
      });
      _showErrorMessage();
      return;
    }

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
    final characteristics = charResult.normalized;
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

    final confirmed = await _confirmSave();
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _isSubmitting = false);
      return;
    }

    Navigator.pop(context, result);
  }

  // Текст подтверждения зависит от режима - пользователь должен видеть, что правки уйдут на модерацию.
  Future<bool?> _confirmSave() {
    final isEdit = widget.product != null;
    final title = isEdit ? context.l10n.getString('auto_sohranitIzmeneniya') : context.l10n.getString('auto_sozdatTovar');
    final message = isEdit
        ? context.l10n.getString('auto_izmeneniyaBudutOtpravle')
        : context.l10n.getString('auto_tovarBudetOtpravlenNa');
    final confirmLabel = isEdit ? context.l10n.save : context.l10n.getString('auto_sozdat');
     return showDialog<bool>(
       context: context,
       builder: (dialogContext) {
         final palette = context.colorPalette;
         return AlertDialog(
           backgroundColor: palette.card,
           title: Text(title),
           content: Text(message),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(dialogContext).pop(false),
               child: Text(context.l10n.cancel),
             ),
             FilledButton(
               onPressed: () => Navigator.of(dialogContext).pop(true),
               child: Text(confirmLabel),
             ),
           ],
         );
       },
     );
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          widget.product == null ? context.l10n.getString('auto_sozdanieTovara') : context.l10n.getString('auto_redaktirovanieTovara'),
        ),
      ),
      body: Column(
        children: [
          _StepHeader(
            step: _step,
            totalSteps: _totalSteps,
            onStepTap: _jumpToStep,
          ),
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
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(16, 8, 16, AppDimensions.minBottomSafePadding),
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
                  child: Text(context.l10n.backTooltip),
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
                      ? Text(context.l10n.save)
                      : Text(context.l10n.next),
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
      title: context.l10n.getString('auto_osnovnyeDannye'),
      subtitle: context.l10n.getString('auto_zapolniteNazvanieOpisan'),
      child: Column(
        children: [
          _buildField(context.l10n.getString('auto_nazvanieTovara'), _nameController),
          _buildField(context.l10n.getString('auto_opisanie_1'), _descriptionController, maxLines: 3),
          _buildField(
            context.l10n.getString('auto_stranaProizvoditelya'),
            _countryController,
            hintText: context.l10n.getString('auto_naprimerKazahstan'),
          ),
          _buildField(
            context.l10n.getString('auto_srokGodnosti'),
            _shelfLifeController,
            hintText: context.l10n.getString('auto_naprimer12Mesyatsev'),
          ),
          _buildCategoryPicker(),
        ],
      ),
    );
  }

  Widget _buildPriceStep() {
    return _StepCard(
      title: context.l10n.getString('auto_tsenaIUsloviya'),
      subtitle: context.l10n.getString('auto_minimalnyeKolichestvaI'),
      child: Column(
        children: [
          _buildField(
            context.l10n.getString('auto_tsenaZaEdinitsu'),
            _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hintText: context.l10n.getString('auto_naprimer1450'),
          ),
          _buildField(
            context.l10n.getString('auto_minimalnoeKolichestvo'),
            _minController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _buildField(
            context.l10n.getString('auto_vsegoKolichestvo'),
            _stockController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hintText: context.l10n.getString('auto_naprimer120'),
          ),
          _buildDeliverySchedulePicker(),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return _StepCard(
      title: context.l10n.getString('auto_sostavIHarakteristiki'),
      subtitle: context.l10n.getString('auto_neobyazatelnyeDannyeZap'),
      child: Column(
        children: [
          _buildField(context.l10n.getString('auto_sostav'), _ingredientsController, maxLines: 3),
          _buildField(
            context.l10n.getString('auto_kaloriiKkal100g'),
            _caloriesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(_kNumericInputAllowed),
            ],
          ),
          _buildField(
            context.l10n.getString('auto_belkiG100g'),
            _proteinController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(_kNumericInputAllowed),
            ],
          ),
          _buildField(
            context.l10n.getString('auto_zhiryG100g'),
            _fatController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(_kNumericInputAllowed),
            ],
          ),
          _buildField(
            context.l10n.getString('auto_uglevodyG100g'),
            _carbsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(_kNumericInputAllowed),
            ],
          ),
          _buildCustomCharacteristicsSection(),
        ],
      ),
    );
  }

  Widget _buildCustomCharacteristicsSection() {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.getString('auto_harakteristikiTovara'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _customCharacteristics.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.line),
              ),
              child: Stack(
                children: [
                  Padding(
                    // Резервируем место под крестик в правом верхнем углу.
                    padding: const EdgeInsets.only(right: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.getString('auto_nazvanie'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _customCharacteristics[i].nameCtrl,
                          maxLength: 100,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: cs.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.getString('auto_znachenie'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _customCharacteristics[i].valueCtrl,
                          maxLength: 200,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(200),
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: cs.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -10,
                    right: -4,
                    child: IconButton(
                      tooltip: context.l10n.getString('auto_udalitHarakteristiku'),
                      icon: Icon(Icons.close, color: palette.muted, size: 20),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          final removed = _customCharacteristics.removeAt(i);
                          removed.dispose();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _customCharacteristics.add(_CustomCharacteristicDraft());
              });
            },
            icon: Icon(Icons.add, color: palette.accent),
            label: Text(
              context.l10n.getString('auto_dobavitHarakteristiku'),
              style: TextStyle(color: palette.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return _StepCard(
      title: context.l10n.getString('auto_fotografiiTovara'),
      subtitle: context.l10n.getString('auto_dobavteNeskolkoFoto'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          const minPreviewWidth = 156.0;
          const maxPreviewWidth = 188.0;
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width - 64;
          final previewWidth = ((availableWidth - spacing) / 2)
              .clamp(minPreviewWidth, maxPreviewWidth)
              .toDouble();
          final previewHeight = (previewWidth * 1.18).roundToDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (int i = 0; i < _images.length; i++)
                    _buildPhotoPreview(
                      path: _images[i],
                      width: previewWidth,
                      height: previewHeight,
                      onRemove: () => _removeImage(i),
                    ),
                  _buildAddPhotoTile(
                    width: previewWidth,
                    height: previewHeight,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhotoPreview({
    required String path,
    required double width,
    required double height,
    required VoidCallback onRemove,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            padding: const EdgeInsets.all(8),
            child: SizedBox.expand(
              child: SmartImage(
                path: path,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(12),
                placeholder: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 42,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoTile({required double width, required double height}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined),
            const SizedBox(height: 6),
            Text(context.l10n.getString('auto_dobavit'), style: const TextStyle(fontSize: 12)),
          ],
        ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.getString('auto_ozhidaemayaDataDostavki'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_DeliveryMode>(
            // Растягиваем оба сегмента на всю ширину поровну.
            expandedInsets: EdgeInsets.zero,
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
            segments: [
              ButtonSegment(
                value: _DeliveryMode.weekly,
                label: Text(
                  context.l10n.getString('auto_poGrafiku'),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
              ButtonSegment(
                value: _DeliveryMode.leadTime,
                label: Text(
                  context.l10n.getString('auto_poSroku'),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
            selected: {_deliveryMode},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              setState(() {
                _deliveryMode = selection.first;
                _error = null;
                _syncDeliveryControllers();
              });
              _scrollDeliveryBlockIntoView();
            },
          ),
          const SizedBox(height: 12),
          // Плавная смена режима - высота анимируется, контент фейдится.
          AnimatedSize(
            key: _deliveryBlockKey,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_deliveryMode),
                child: _deliveryMode == _DeliveryMode.weekly
                    ? _buildWeeklyDeliveryBlock(colorScheme)
                    : _buildLeadTimeDeliveryBlock(colorScheme),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.getString('auto_pokupatelUviditOzhidaem'),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // Weekly-блок выше leadTime - после смены режима докручиваем экран, чтобы он влез.
  void _scrollDeliveryBlockIntoView() {
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      final ctx = _deliveryBlockKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    });
  }

  Widget _buildWeeklyDeliveryBlock(ColorScheme colorScheme) {
    return Container(
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
            context.l10n.getString('auto_vyberiteDniNedeli'),
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
            context.l10n.getString('auto_bystryyVybor'),
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
                label: Text(context.l10n.productWeekdays),
                selected: _isPresetSelected(_workdayPreset),
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }
                  _applyWeekdayPreset(_workdayPreset);
                },
              ),
              ChoiceChip(
                label: Text(context.l10n.productWeekend),
                selected: _isPresetSelected(_weekendPreset),
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }
                  _applyWeekdayPreset(_weekendPreset);
                },
              ),
              ChoiceChip(
                label: Text(context.l10n.productEveryday),
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
            context.l10n.getString('auto_vremyaDostavki'),
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
              helperText: context.l10n.getString('auto_formatChchmm'),
              errorText: _deliveryTimeInputInvalid
                  ? context.l10n.getString('auto_nekorrektnoeVremya')
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
    );
  }

  Widget _buildLeadTimeDeliveryBlock(ColorScheme colorScheme) {
    return Container(
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.getString('auto_minimumDney'),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _leadMinController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: (_) => _syncDeliveryControllers(),
                      decoration: InputDecoration(
                        hintText: '1',
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.getString('auto_maksimumDney'),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _leadMaxController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: (_) => _syncDeliveryControllers(),
                      decoration: InputDecoration(
                        hintText: '3',
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
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.getString('auto_srokPriyomaZakazaNaSe'),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cutoffController,
            keyboardType: TextInputType.number,
            inputFormatters: [const _DeliveryTimeInputFormatter()],
            onChanged: (_) {
              if (_cutoffInputInvalid) {
                setState(() => _cutoffInputInvalid = false);
              }
              _syncDeliveryControllers();
            },
            decoration: InputDecoration(
              hintText: '14:00 (${context.l10n.optional})',
              helperText: context.l10n.ordersCutoffTime,
              helperMaxLines: 1,
              errorText: _cutoffInputInvalid ? context.l10n.invalidTime : null,
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
    );
  }

  Widget _buildDeliveryWeekdayChip(int weekday) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _deliveryWeekdays.contains(weekday);
    final label = _weekdaysShort[weekday] ?? _weekdaysFull[weekday] ?? context.l10n.getString('auto_pn');

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
          Text(
            context.l10n.getString('auto_kategorii'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.selectCategoryFromCatalog,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _categorySearchController,
            onChanged: (_) {
              _categorySearchDebounce?.cancel();
              _categorySearchDebounce = Timer(
                _categorySearchDebounceDuration,
                () {
                  if (!mounted) return;
                  setState(() {});
                },
              );
            },
            decoration: InputDecoration(
              hintText: context.l10n.getString('auto_poiskKategorii'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _categorySearchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.l10n.getString('auto_ochistit'),
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
              context.l10n.getString('auto_kategoriiNeNaydeny'),
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
                    ? context.l10n.getString('auto_pokazatMenshe')
                    : context.l10n.wizardShowAllCategories(filteredCategories.length),
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
    if (source.isEmpty) {
      _syncDeliveryControllers();
      return;
    }
    final parsed = DeliverySchedule.decode(source);
    if (parsed is LeadTimeDeliverySchedule) {
      _deliveryMode = _DeliveryMode.leadTime;
      _leadMinController.text = parsed.minDays.toString();
      _leadMaxController.text = parsed.maxDays.toString();
      _cutoffController.text = parsed.cutoff == null
          ? ''
          : _formatHm(parsed.cutoff!.hour, parsed.cutoff!.minute);
      _syncDeliveryControllers();
      return;
    }
    if (parsed is WeeklyDeliverySchedule) {
      _deliveryMode = _DeliveryMode.weekly;
      _deliveryTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      _deliveryWeekdays
        ..clear()
        ..addAll(parsed.weekdays);
      _syncDeliveryControllers();
      return;
    }
    _syncDeliveryControllers();
  }

  String _formatHm(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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
    if (_deliveryMode == _DeliveryMode.leadTime) {
      final schedule = _buildLeadTimeSchedule();
      if (schedule != null) {
        return schedule.encode();
      }
      // Если ввод сейчас невалиден - возвращаем пустую строку, шаг проверит сам
      return '';
    }
    final weekdays = _resolvedDeliveryWeekdays();
    final schedule = WeeklyDeliverySchedule(
      weekdays: weekdays.toSet(),
      hour: _deliveryTime.hour,
      minute: _deliveryTime.minute,
    );
    return schedule.encode();
  }

  // Парсит cutoff-поле; null без ошибки если поле пустое.
  ({int hour, int minute})? _parseCutoff() {
    final raw = _cutoffController.text.trim();
    if (raw.isEmpty) return null;
    final m = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(raw);
    if (m == null) return null;
    return (hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
  }

  LeadTimeDeliverySchedule? _buildLeadTimeSchedule() {
    final min = int.tryParse(_leadMinController.text.trim());
    final max = int.tryParse(_leadMaxController.text.trim());
    if (min == null || max == null || min < 0 || max < min || max > 365) {
      return null;
    }
    final cutoffRaw = _cutoffController.text.trim();
    ({int hour, int minute})? cutoff;
    if (cutoffRaw.isNotEmpty) {
      cutoff = _parseCutoff();
      if (cutoff == null) return null;
    }
    return LeadTimeDeliverySchedule(minDays: min, maxDays: max, cutoff: cutoff);
  }

  void _syncDeliveryControllers() {
    if (_deliveryMode == _DeliveryMode.leadTime) {
      final formatted = _buildDeliveryScheduleLabel();
      _deliveryDateController.text = formatted;
      _deliveryBadgeController.text = formatted;
      return;
    }
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
  const _StepHeader({
    required this.step,
    required this.totalSteps,
    this.onStepTap,
  });

  final int step;
  final int totalSteps;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labels = [context.l10n.getString('auto_dannye'), context.l10n.getString('auto_tsena'), context.l10n.getString('auto_sostav'), context.l10n.getString('auto_foto')];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: context.colorPalette.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.wizardStepIndicator(step + 1, totalSteps),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    const Expanded(flex: 1, child: SizedBox()),
                    for (var index = 0; index < totalSteps - 1; index++)
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 2,
                          color: index < step
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    const Expanded(flex: 1, child: SizedBox()),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < totalSteps; index++)
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StepCircle(
                            index: index,
                            isActive: index <= step,
                            onTap: onStepTap == null ? null : () => onStepTap!(index),
                          ),
                          const SizedBox(height: 8),
                          () {
                            final isActive = index <= step;
                            final label = Text(
                              labels[index],
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                              ),
                            );
                            if (onStepTap == null) return label;
                            return InkWell(
                              onTap: () => onStepTap!(index),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                child: label,
                              ),
                            );
                          }(),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Кружок-индикатор шага. Внешне совпадает со старым Container, но слушает тап.
class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.index, required this.isActive, this.onTap});

  final int index;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final circle = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (onTap == null) return circle;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: circle,
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
        color: context.colorPalette.card,
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

class _CustomCharacteristicDraft {
  _CustomCharacteristicDraft({String name = '', String value = ''})
    : nameCtrl = TextEditingController(text: name),
      valueCtrl = TextEditingController(text: value);

  final TextEditingController nameCtrl;
  final TextEditingController valueCtrl;

  void dispose() {
    nameCtrl.dispose();
    valueCtrl.dispose();
  }

  String get name => nameCtrl.text.trim();
  String get value => valueCtrl.text.trim();
}
