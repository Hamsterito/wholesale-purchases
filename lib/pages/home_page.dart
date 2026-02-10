import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../services/api_service.dart';
import 'product_detail_page.dart';

enum SortField { price, rating }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Все', 'Напитки', 'Овощи фрукты', 'Мясо'];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _searchIndex = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _filtersInitialized = false;
  double _priceMinBound = 0;
  double _priceMaxBound = 0;
  RangeValues _priceRange = const RangeValues(0, 0);
  bool _priceMaxUnlimited = true;
  double _minRating = 0;
  bool _onlyDiscounted = false;
  SortField _sortField = SortField.price;
  bool _sortAscending = true;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;
  Color get _surfaceVariant => _colorScheme.surfaceVariant;
  Color get _shadowColor =>
      _isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.05);

  bool get _hasActiveFilters {
    if (!_filtersInitialized) return false;
    final priceChanged =
        _priceRange.start > 0 ||
        (!_priceMaxUnlimited && _priceRange.end < _priceMaxBound);
    final ratingChanged = _minRating > 0;
    final discountChanged = _onlyDiscounted;
    return priceChanged || ratingChanged || discountChanged;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final products = await ApiService.getProducts();
      final searchIndex = _buildSearchIndex(products);

      setState(() {
        _products = products;
        _searchIndex = searchIndex;
        _syncFilterBounds(products);
        _filteredProducts = _filterProducts(products);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки товаров: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterTabs(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6288D5),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: _mutedText),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: _mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6288D5),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Text(
          'Товары не найдены',
          style: TextStyle(color: _mutedText, fontSize: 16),
        ),
      );
    }

    return _buildProductGrid();
  }

  Widget _buildHeader() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Главная',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Поиск...',
          hintStyle: TextStyle(color: _mutedText),
          prefixIcon: Icon(Icons.search, color: _mutedText),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: _mutedText),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
          filled: true,
          fillColor: _surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      child: Row(
        children: [
          IconButton(
            icon: _buildSortIcon(),
            onPressed: _toggleSortOrder,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: _buildFilterIcon(),
            onPressed: _openFiltersSheet,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = _selectedTabIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = index;
                          _filteredProducts = _filterProducts(_products);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6288D5)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : _colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return RefreshIndicator(
      color: const Color(0xFF6288D5),
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return ProductCard(
            product: product,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(
                    product: product,
                    similarProducts: _products
                        .where((p) => p.id != product.id)
                        .take(10)
                        .toList(),
                  ),
                ),
              );
            },
            onAddToCart: () {},
            showMessages: true,
          );
        },
      ),
    );
  }

  void _syncFilterBounds(List<Product> products) {
    if (products.isEmpty) {
      _priceMinBound = 0;
      _priceMaxBound = 0;
      _priceRange = const RangeValues(0, 0);
      _priceMaxUnlimited = true;
      _minRating = 0;
      _onlyDiscounted = false;
      _filtersInitialized = true;
      return;
    }

    final prices =
        products.map((p) => p.bestSupplier.pricePerUnit.toDouble()).toList();
    final priceMax = prices.reduce(max);

    _priceMinBound = 0;
    _priceMaxBound = priceMax;

    if (!_filtersInitialized) {
      _priceRange = RangeValues(0, priceMax);
      _priceMaxUnlimited = true;
      _minRating = 0;
      _onlyDiscounted = false;
      _filtersInitialized = true;
      return;
    }

    _priceRange = RangeValues(
      _priceRange.start.clamp(0, priceMax),
      _priceRange.end.clamp(0, priceMax),
    );
    if (_priceRange.start > _priceRange.end) {
      _priceRange = RangeValues(0, priceMax);
    }
    _minRating = _minRating.clamp(0.0, 5.0);
  }

  List<Product> _filterProducts(
    List<Product> source, {
    RangeValues? priceRange,
    double? minRating,
    int? selectedTabIndex,
    bool? onlyDiscounted,
    bool? priceMaxUnlimited,
    String? searchQuery,
  }) {
    if (source.isEmpty) return [];
    final range = priceRange ?? _priceRange;
    final rating = minRating ?? _minRating;
    final tabIndex = selectedTabIndex ?? _selectedTabIndex;
    final discountOnly = onlyDiscounted ?? _onlyDiscounted;
    final maxUnlimited = priceMaxUnlimited ?? _priceMaxUnlimited;
    final query = searchQuery ?? _searchQuery;

    final filtered = source.where((product) {
      if (!_matchesSearch(product, query)) return false;
      if (!_matchesSelectedCategory(product, tabIndex)) return false;
      final supplier = product.bestSupplier;
      final price = supplier.pricePerUnit.toDouble();
      if (price < range.start) return false;
      if (!maxUnlimited && price > range.end) return false;
      if (product.rating < rating) return false;
      if (discountOnly && !_hasDiscount(product)) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      int compare;
      switch (_sortField) {
        case SortField.price:
          compare = a.bestSupplier.pricePerUnit
              .compareTo(b.bestSupplier.pricePerUnit);
          break;
        case SortField.rating:
          compare = a.rating.compareTo(b.rating);
          break;
      }
      return _sortAscending ? compare : -compare;
    });

    return filtered;
  }

  bool _matchesSelectedCategory(Product product, int tabIndex) {
    if (tabIndex <= 0 || tabIndex >= _tabs.length) return true;
    final selected = _tabs[tabIndex].toLowerCase();
    return product.categories.any((category) {
      final normalized = category.toLowerCase();
      return normalized == selected ||
          normalized.contains(selected) ||
          selected.contains(normalized);
    });
  }

  bool _hasDiscount(Product product) {
    if (product.characteristics.isEmpty) return false;
    for (final entry in product.characteristics.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value.toLowerCase();
      if (!key.contains('скид')) continue;
      final digits = RegExp(r'\d+').firstMatch(value)?.group(0);
      if (digits != null) {
        final parsed = int.tryParse(digits) ?? 0;
        if (parsed > 0) return true;
      }
      if (value.contains('%') || value.contains('yes') || value.contains('true')) {
        return true;
      }
    }
    return false;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _filteredProducts = _filterProducts(_products);
    });
  }

  Map<String, String> _buildSearchIndex(List<Product> products) {
    final index = <String, String>{};
    for (final product in products) {
      index[product.id] = _buildProductSearchText(product);
    }
    return index;
  }

  String _buildProductSearchText(Product product) {
    final buffer = StringBuffer();
    buffer
      ..write(product.name)
      ..write(' ')
      ..write(product.description)
      ..write(' ')
      ..write(product.ingredients);
    for (final category in product.categories) {
      buffer
        ..write(' ')
        ..write(category);
    }
    for (final entry in product.characteristics.entries) {
      buffer
        ..write(' ')
        ..write(entry.key)
        ..write(' ')
        ..write(entry.value);
    }
    for (final supplier in product.suppliers) {
      buffer
        ..write(' ')
        ..write(supplier.name);
    }
    return buffer.toString().toLowerCase();
  }

  bool _matchesSearch(Product product, String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) return true;
    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return true;
    final haystack = _searchIndex[product.id] ?? _buildProductSearchText(product);
    return tokens.every(haystack.contains);
  }

  void _openFiltersSheet() {
    if (!_filtersInitialized) return;
    final initialRange = _priceRange;
    final initialRating = _minRating;
    final initialOnlyDiscounted = _onlyDiscounted;
    final initialMaxUnlimited = _priceMaxUnlimited;
    final initialSortField = _sortField;
    final initialSortAscending = _sortAscending;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        RangeValues priceRange = initialRange;
        double minRating = initialRating;
        bool onlyDiscounted = initialOnlyDiscounted;
        bool maxUnlimited = initialMaxUnlimited;
        SortField sortField = initialSortField;
        bool sortAscending = initialSortAscending;
        final fromController = TextEditingController(
          text: initialRange.start.toInt().toString(),
        );
        final toController = TextEditingController(
          text: initialMaxUnlimited ? '' : initialRange.end.toInt().toString(),
        );

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final previewCount = _filterProducts(
              _products,
              priceRange: priceRange,
              minRating: minRating,
              onlyDiscounted: onlyDiscounted,
              priceMaxUnlimited: maxUnlimited,
            ).length;
            final priceMin = _priceMinBound;
            final priceMax = _priceMaxBound;
            final bottomInset = MediaQuery.of(context).padding.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _borderColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Фильтры',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            priceRange = RangeValues(0, priceMax);
                            minRating = 0;
                            onlyDiscounted = false;
                            maxUnlimited = true;
                            sortField = SortField.price;
                            sortAscending = true;
                            fromController.text = '0';
                            toController.text = '';
                          });
                        },
                        child: const Text('Сбросить'),
                      ),
                    ],
                  ),
                  _buildFilterSectionTitle('Цена за шт.'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInputPill(
                        label: 'от',
                        controller: fromController,
                        onChanged: (value) {
                          final parsed = value.isEmpty ? 0 : int.tryParse(value);
                          if (parsed == null) return;
                          final clamped = parsed
                              .clamp(0, priceMax.toInt())
                              .toDouble();
                          setSheetState(() {
                            priceRange = RangeValues(
                              clamped,
                              max(clamped, priceRange.end),
                            );
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildInputPill(
                        label: 'до',
                        controller: toController,
                        hintText: '\u221E',
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setSheetState(() {
                              maxUnlimited = true;
                              priceRange = RangeValues(priceRange.start, priceMax);
                            });
                            return;
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null) return;
                          final clamped =
                              parsed.clamp(0, priceMax.toInt()).toDouble();
                          setSheetState(() {
                            maxUnlimited = false;
                            priceRange = RangeValues(
                              min(priceRange.start, clamped),
                              clamped,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RangeSlider(
                    values: priceRange,
                    min: priceMin,
                    max: priceMax,
                    divisions: _calculateDivisions(priceMin, priceMax),
                    onChanged: (values) {
                      setSheetState(() {
                        maxUnlimited = false;
                        priceRange = RangeValues(
                          values.start.clamp(0, priceMax),
                          values.end.clamp(0, priceMax),
                        );
                        fromController.text =
                            priceRange.start.toInt().toString();
                        toController.text = priceRange.end.toInt().toString();
                      });
                    },
                    activeColor: const Color(0xFF6288D5),
                    labels: RangeLabels(
                      '${priceRange.start.toInt()} \u20B8',
                      maxUnlimited ? '\u221E' : '${priceRange.end.toInt()} \u20B8',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterSectionTitle('Сортировка'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSortChip(
                          label: 'Цена',
                          selected: sortField == SortField.price,
                          onTap: () => setSheetState(() {
                            sortField = SortField.price;
                          }),
                        ),
                        _buildSortChip(
                          label: 'Рейтинг',
                          selected: sortField == SortField.rating,
                          onTap: () => setSheetState(() {
                            sortField = SortField.rating;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterSectionTitle('Порядок'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: _surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildSortOrderOption(
                          label: 'По возрастанию',
                          icon: Icons.arrow_upward,
                          selected: sortAscending,
                          onTap: () => setSheetState(() {
                            sortAscending = true;
                          }),
                        ),
                        Divider(height: 1, color: _borderColor),
                        _buildSortOrderOption(
                          label: 'По убыванию',
                          icon: Icons.arrow_downward,
                          selected: !sortAscending,
                          onTap: () => setSheetState(() {
                            sortAscending = false;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterSectionTitle('Рейтинг'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildValuePill(
                        'от',
                        minRating.toStringAsFixed(1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: minRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          label: minRating.toStringAsFixed(1),
                          onChanged: (value) {
                            setSheetState(() {
                              minRating = value;
                            });
                          },
                          activeColor: const Color(0xFF6288D5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterSectionTitle('Выгодные предложения'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Только со скидкой',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Switch(
                          value: onlyDiscounted,
                          onChanged: (value) {
                            setSheetState(() {
                              onlyDiscounted = value;
                            });
                          },
                          activeColor: const Color(0xFF6288D5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _priceRange = priceRange;
                          _priceMaxUnlimited = maxUnlimited;
                          _minRating = minRating;
                          _onlyDiscounted = onlyDiscounted;
                          _sortField = sortField;
                          _sortAscending = sortAscending;
                          _filteredProducts = _filterProducts(_products);
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6288D5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text('Показать $previewCount'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.tune),
        if (_hasActiveFilters)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF6288D5),
                shape: BoxShape.circle,
                border: Border.all(color: _cardBg, width: 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSortIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.swap_vert, color: _colorScheme.onSurface),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: _cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final rotate = Tween<double>(begin: -0.1, end: 0.0)
                    .animate(animation);
                final scale = Tween<double>(begin: 0.75, end: 1.0)
                    .animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: RotationTransition(
                    turns: rotate,
                    child: ScaleTransition(
                      scale: scale,
                      child: child,
                    ),
                  ),
                );
              },
              child: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                key: ValueKey<bool>(_sortAscending),
                size: 12,
                color: _colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      _filteredProducts = _filterProducts(_products);
    });
  }

  Widget _buildSortChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const activeColor = Color(0xFF6288D5);
    final borderColor = selected ? activeColor : _borderColor;
    final bgColor = selected
        ? activeColor.withValues(alpha: 0.15)
        : _surfaceVariant;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: bgColor,
        side: BorderSide(color: borderColor, width: 1),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? activeColor : _colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSortOrderOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const activeColor = Color(0xFF6288D5);
    return ListTile(
      dense: true,
      leading: Icon(icon, color: selected ? activeColor : _mutedText, size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? _colorScheme.onSurface : _mutedText,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: activeColor, size: 20)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildValuePill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: _mutedText),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPill({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? hintText,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _surfaceVariant,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: _mutedText),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: TextStyle(color: _mutedText),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '\u20B8',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _calculateDivisions(double minValue, double maxValue) {
    final range = (maxValue - minValue).round();
    if (range <= 0) return null;
    return range > 100 ? 100 : range;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

}


