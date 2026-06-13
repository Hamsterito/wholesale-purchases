import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/api/api_service.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../services/store/favorites_store.dart';
import '../services/store/supplier_stats_store.dart';
import '../theme/app_color_palette.dart';
import '../utils/rating_format.dart';
import '../utils/search_normalizer.dart';
import '../widgets/product/product_card.dart';
import '../widgets/smooth_sheet.dart';
import '../widgets/messages/top_message.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import 'product_detail_page.dart';

enum _SortField { price, rating }

class _FilterCacheKey {
  final int productCount;
  final double rangeStart;
  final double rangeEnd;
  final bool maxUnlimited;
  final double minRating;
  final int tabIndex;
  final String searchQuery;
  final _SortField sortField;
  final bool sortAscending;

  const _FilterCacheKey({
    required this.productCount,
    required this.rangeStart,
    required this.rangeEnd,
    required this.maxUnlimited,
    required this.minRating,
    required this.tabIndex,
    required this.searchQuery,
    required this.sortField,
    required this.sortAscending,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _FilterCacheKey) return false;
    return productCount == other.productCount &&
        rangeStart == other.rangeStart &&
        rangeEnd == other.rangeEnd &&
        maxUnlimited == other.maxUnlimited &&
        minRating == other.minRating &&
        tabIndex == other.tabIndex &&
        searchQuery == other.searchQuery &&
        sortField == other.sortField &&
        sortAscending == other.sortAscending;
  }

  @override
  int get hashCode => Object.hash(
    productCount,
    rangeStart,
    rangeEnd,
    maxUnlimited,
    minRating,
    tabIndex,
    searchQuery,
    sortField,
    sortAscending,
  );
}

class SupplierProfilePage extends StatefulWidget {
  final String supplierId;
  final Supplier? initialSupplier;

  const SupplierProfilePage({
    super.key,
    required this.supplierId,
    this.initialSupplier,
  });

  @override
  State<SupplierProfilePage> createState() => _SupplierProfilePageState();
}

class _SupplierProfilePageState extends State<SupplierProfilePage> {
  Supplier? _supplier;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;

  // Поиск
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  Map<String, String> _searchIndex = {};

  // Фильтры
  int _selectedTabIndex = 0;
  List<String> _tabs = [];
  bool _filtersInitialized = false;
  double _priceMinBound = 0;
  double _priceMaxBound = 0;
  RangeValues _priceRange = const RangeValues(0, 0);
  bool _priceMaxUnlimited = true;
  double _minRating = 0;
  _SortField _sortField = _SortField.price;
  bool _sortAscending = true;

  List<Product>? _filterCache;
  _FilterCacheKey? _filterCacheKey;

  late final VoidCallback _favoritesListener;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => context.colorPalette.card;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _borderColor => _colorScheme.outlineVariant;
  Color get _surfaceVariant => _colorScheme.surfaceContainerHighest;

  bool get _hasActiveFilters {
    if (!_filtersInitialized) return false;
    final priceChanged =
        _priceRange.start > 0 ||
        (!_priceMaxUnlimited && _priceRange.end < _priceMaxBound);
    return priceChanged || _minRating > 0;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSupplier != null) {
      _supplier = widget.initialSupplier;
    }
    _isFavorite = FavoritesStore.instance.containsSupplier(widget.supplierId);
    _favoritesListener = () {
      final isFav = FavoritesStore.instance.containsSupplier(widget.supplierId);
      if (isFav != _isFavorite && mounted) {
        setState(() => _isFavorite = isFav);
      }
    };
    FavoritesStore.instance.addListener(_favoritesListener);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabs.isEmpty) {
      _tabs = [context.l10n.getString('auto_vse_1')];
    }
  }

  @override
  void dispose() {
    FavoritesStore.instance.removeListener(_favoritesListener);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getSupplier(widget.supplierId),
        ApiService.getSupplierCatalog(widget.supplierId, page: 1, limit: 100),
      ]);
      if (!mounted) return;
      final supplier = results[0] as Supplier;
      final catalogData = results[1] as Map<String, dynamic>;
      final products = catalogData['products'] as List<Product>;
      final searchIndex = _buildSearchIndex(products);
      // Кешируем свежие rating/reviewCount, чтобы остальные экраны (карточка
      // товара, избранное) показывали те же цифры, что и шапка профиля.
      SupplierStatsStore.instance.update(supplier);
      setState(() {
        _supplier = supplier;
        _allProducts = products;
        _searchIndex = searchIndex;
        _filterCache = null;
        _filterCacheKey = null;
        _syncFilterBounds(products);
        _buildCategoryTabs(products);
        _filteredProducts = _filterProducts(products);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _resolveErrorMessage(e);
      });
    }
  }

  void _buildCategoryTabs(List<Product> products) {
    final tabs = <String>[context.l10n.getString('auto_vse_1')];
    final seen = <String>{};
    for (final product in products) {
      for (final cat in product.categories) {
        final key = cat.trim();
        if (key.isNotEmpty && seen.add(key.toLowerCase())) {
          tabs.add(key);
        }
      }
    }
    _tabs = tabs;
  }

  String _resolveErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains(context.l10n.getString('auto_postavshchikNeNayden'))) return context.l10n.getString('auto_postavshchikNeNayden');
    if (message.contains(context.l10n.getString('auto_vremyaOzhidaniya'))) {
      return context.l10n.getString('auto_vremyaOzhidaniyaIsteklo');
    }
    if (message.contains('SocketException') ||
        message.contains('NetworkException') ||
        message.contains('Failed host lookup')) {
      return context.l10n.getString('auto_netPodklyucheniyaKInte');
    }
    return context.l10n.getString('auto_neUdalosZagruzitDannye');
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  void _toggleFavorite() {
    final supplier = _supplier;
    if (supplier == null) return;
    final palette = context.colorPalette;
    final added = FavoritesStore.instance.toggleSupplier(supplier);
    setState(() => _isFavorite = added);
    showTopMessage(
      context,
      added ? context.l10n.getString('auto_dobavlenoVIzbrannoe') : context.l10n.getString('auto_udalenoIzIzbrannogo'),
      backgroundColor: added ? palette.accent : palette.error,
    );
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
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: const RoleInternalNavBar(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _supplier == null) {
      return Center(
        child: CircularProgressIndicator(color: context.colorPalette.accent),
      );
    }
    if (_errorMessage != null && _supplier == null) {
      return _buildErrorState();
    }
    if (!_isLoading && _filteredProducts.isEmpty) {
      return Center(
        child: Text(
          _allProducts.isEmpty
              ? context.l10n.getString('auto_netTovarovOtEtogoPost')
              : context.l10n.getString('auto_tovaryNeNaydeny'),
          style: TextStyle(color: _mutedText, fontSize: 16),
        ),
      );
    }
    return _buildProductGrid();
  }

  Widget _buildHeader() {
    final supplier = _supplier;
    final palette = context.colorPalette;
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: [
          // Кнопка назад
          IconButton(
            icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
            tooltip: context.l10n.getString('auto_nazad'),
          ),
          // Название компании в центре + общий рейтинг рядом со звездой.
          Expanded(
            child: supplier == null
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          supplier.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded, size: 16, color: palette.star),
                      const SizedBox(width: 2),
                      Text(
                        formatRating(supplier.rating),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
          ),
          // Сердечко
          Semantics(
            label: _isFavorite
                ? context.l10n.getString('auto_udalitIzIzbrannogo')
                : context.l10n.getString('auto_dobavitVIzbrannoe'),
            button: true,
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: palette.accent,
              ),
              onPressed: _toggleFavorite,
              tooltip: _isFavorite
                  ? context.l10n.getString('auto_udalitIzIzbrannogo')
                  : context.l10n.getString('auto_dobavitVIzbrannoe'),
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
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: context.l10n.getString('auto_poisk'),
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
                          _filteredProducts = _filterProducts(_allProducts);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.colorPalette.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : _colorScheme.onSurface,
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
      color: context.colorPalette.accent,
      onRefresh: _onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 327,
          crossAxisSpacing: 15,
          mainAxisSpacing: 10,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return ProductCard(
            product: product,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(
                  product: product,
                  similarProducts: _allProducts
                      .where((p) => p.id != product.id)
                      .take(10)
                      .toList(),
                ),
              ),
            ),
            onAddToCart: () {},
            showMessages: true,
            computeDeliveryDateFromRemaining: true,
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    final palette = context.colorPalette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: palette.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? context.l10n.getString('auto_proizoshlaOshibka'),
              style: TextStyle(
                fontSize: 16,
                color: palette.ink,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.l10n.getString('auto_povtorit'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.getString('auto_vernutsya'),
                style: TextStyle(color: palette.muted, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Фильтрация и поиск

  void _syncFilterBounds(List<Product> products) {
    if (products.isEmpty) {
      _priceMinBound = 0;
      _priceMaxBound = 0;
      _priceRange = const RangeValues(0, 0);
      _priceMaxUnlimited = true;
      _minRating = 0;
      _filtersInitialized = true;
      return;
    }
    final prices = products
        .map((p) => p.bestSupplier.pricePerUnit.toDouble())
        .toList();
    final priceMax = prices.reduce(max);
    _priceMinBound = 0;
    _priceMaxBound = priceMax;
    if (!_filtersInitialized) {
      _priceRange = RangeValues(0, priceMax);
      _priceMaxUnlimited = true;
      _minRating = 0;
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
    bool? priceMaxUnlimited,
    String? searchQuery,
  }) {
    if (source.isEmpty) return [];
    final range = priceRange ?? _priceRange;
    final rating = minRating ?? _minRating;
    final tabIndex = selectedTabIndex ?? _selectedTabIndex;
    final maxUnlimited = priceMaxUnlimited ?? _priceMaxUnlimited;
    final query = searchQuery ?? _searchQuery;

    final isDefaultCall =
        priceRange == null &&
        minRating == null &&
        selectedTabIndex == null &&
        priceMaxUnlimited == null &&
        searchQuery == null &&
        identical(source, _allProducts);

    if (isDefaultCall) {
      final key = _FilterCacheKey(
        productCount: source.length,
        rangeStart: range.start,
        rangeEnd: range.end,
        maxUnlimited: maxUnlimited,
        minRating: rating,
        tabIndex: tabIndex,
        searchQuery: query,
        sortField: _sortField,
        sortAscending: _sortAscending,
      );
      if (_filterCacheKey == key && _filterCache != null) {
        return _filterCache!;
      }
      final result = _computeFiltered(
        source,
        range: range,
        rating: rating,
        tabIndex: tabIndex,
        maxUnlimited: maxUnlimited,
        query: query,
      );
      _filterCache = result;
      _filterCacheKey = key;
      return result;
    }

    return _computeFiltered(
      source,
      range: range,
      rating: rating,
      tabIndex: tabIndex,
      maxUnlimited: maxUnlimited,
      query: query,
    );
  }

  List<Product> _computeFiltered(
    List<Product> source, {
    required RangeValues range,
    required double rating,
    required int tabIndex,
    required bool maxUnlimited,
    required String query,
  }) {
    final filtered = source.where((product) {
      if (!_matchesSearch(product, query)) return false;
      if (!_matchesCategory(product, tabIndex)) return false;
      final price = product.bestSupplier.pricePerUnit.toDouble();
      if (price < range.start) return false;
      if (!maxUnlimited && price > range.end) return false;
      if (product.rating < rating) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      int compare;
      switch (_sortField) {
        case _SortField.price:
          compare = a.bestSupplier.pricePerUnit.compareTo(
            b.bestSupplier.pricePerUnit,
          );
          break;
        case _SortField.rating:
          compare = a.rating.compareTo(b.rating);
          break;
      }
      return _sortAscending ? compare : -compare;
    });

    return filtered;
  }

  bool _matchesCategory(Product product, int tabIndex) {
    if (tabIndex <= 0 || tabIndex >= _tabs.length) return true;
    final selected = _tabs[tabIndex].trim().toLowerCase();
    return product.categories.any(
      (cat) => cat.trim().toLowerCase() == selected,
    );
  }

  Map<String, String> _buildSearchIndex(List<Product> products) {
    final index = <String, String>{};
    for (final product in products) {
      final buffer = StringBuffer();
      buffer
        ..write(product.name)
        ..write(' ')
        ..write(product.description);
      for (final cat in product.categories) {
        buffer
          ..write(' ')
          ..write(cat);
      }
      index[product.id] = SearchNormalizer.buildSearchText(buffer.toString());
    }
    return index;
  }

  bool _matchesSearch(Product product, String query) {
    final tokens = SearchNormalizer.tokenizeQuery(query);
    if (tokens.isEmpty) return true;
    final haystack = _searchIndex[product.id] ?? product.name;
    return SearchNormalizer.matchesTokens(haystack, tokens);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.isEmpty) {
      _applySearchQuery(value);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _applySearchQuery(value);
    });
  }

  void _applySearchQuery(String value) {
    if (_searchQuery == value) return;
    setState(() {
      _searchQuery = value;
      _filteredProducts = _filterProducts(_allProducts);
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      _filteredProducts = _filterProducts(_allProducts);
    });
  }

  void _openFiltersSheet() {
    if (!_filtersInitialized) return;
    final initialRange = _priceRange;
    final initialRating = _minRating;
    final initialMaxUnlimited = _priceMaxUnlimited;
    final initialSortField = _sortField;
    final initialSortAscending = _sortAscending;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: smoothBottomSheetController(context),
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        RangeValues priceRange = initialRange;
        double minRating = initialRating;
        bool maxUnlimited = initialMaxUnlimited;
        _SortField sortField = initialSortField;
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
              _allProducts,
              priceRange: priceRange,
              minRating: minRating,
              priceMaxUnlimited: maxUnlimited,
            ).length;
            final priceMin = _priceMinBound;
            final priceMax = _priceMaxBound;
            final bottomInset = MediaQuery.paddingOf(context).bottom;

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
                      Text(context.l10n.getString('auto_filtry'),
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
                             maxUnlimited = true;
                             sortField = _SortField.price;
                             sortAscending = true;
                             fromController.text = '0';
                             toController.text = '';
                           });
                         },
                         child: Text(context.l10n.supplierProfileReset),
                       ),
                    ],
                  ),
                  _buildFilterSectionTitle(context.l10n.getString('auto_tsenaZaSht')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInputPill(
                        label: context.l10n.getString('auto_ot'),
                        controller: fromController,
                        onChanged: (value) {
                          final parsed = value.isEmpty
                              ? 0
                              : int.tryParse(value);
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
                        label: context.l10n.getString('auto_do'),
                        controller: toController,
                        hintText: '∞',
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setSheetState(() {
                              maxUnlimited = true;
                              priceRange = RangeValues(
                                priceRange.start,
                                priceMax,
                              );
                            });
                            return;
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null) return;
                          final clamped = parsed
                              .clamp(0, priceMax.toInt())
                              .toDouble();
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
                        fromController.text = priceRange.start
                            .toInt()
                            .toString();
                        toController.text = priceRange.end.toInt().toString();
                      });
                    },
                    activeColor: context.colorPalette.accent,
                    labels: RangeLabels(
                      '${priceRange.start.toInt()} ₸',
                      maxUnlimited ? '∞' : '${priceRange.end.toInt()} ₸',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterSectionTitle(context.l10n.getString('auto_sortirovka')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip(
                        label: context.l10n.getString('auto_tsena'),
                        selected: sortField == _SortField.price,
                        onTap: () =>
                            setSheetState(() => sortField = _SortField.price),
                      ),
                      _buildSortChip(
                        label: context.l10n.getString('auto_reyting'),
                        selected: sortField == _SortField.rating,
                        onTap: () =>
                            setSheetState(() => sortField = _SortField.rating),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterSectionTitle(context.l10n.getString('auto_poryadok')),
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
                          label: context.l10n.getString('auto_poVozrastaniyu'),
                          icon: Icons.arrow_upward,
                          selected: sortAscending,
                          onTap: () =>
                              setSheetState(() => sortAscending = true),
                        ),
                        Divider(height: 1, color: _borderColor),
                        _buildSortOrderOption(
                          label: context.l10n.getString('auto_poUbyvaniyu'),
                          icon: Icons.arrow_downward,
                          selected: !sortAscending,
                          onTap: () =>
                              setSheetState(() => sortAscending = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterSectionTitle(context.l10n.getString('auto_reyting')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildValuePill(context.l10n.getString('auto_ot'), minRating.toStringAsFixed(1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: minRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          label: minRating.toStringAsFixed(1),
                          onChanged: (value) =>
                              setSheetState(() => minRating = value),
                          activeColor: context.colorPalette.accent,
                        ),
                      ),
                    ],
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
                          _sortField = sortField;
                          _sortAscending = sortAscending;
                          _filteredProducts = _filterProducts(_allProducts);
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorPalette.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(context.l10n.supplierProfilePreviewShow(previewCount)),
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
                color: context.colorPalette.accent,
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
                final rotate = Tween<double>(
                  begin: -0.1,
                  end: 0.0,
                ).animate(animation);
                final scale = Tween<double>(
                  begin: 0.75,
                  end: 1.0,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: RotationTransition(
                    turns: rotate,
                    child: ScaleTransition(scale: scale, child: child),
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
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildSortChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final activeColor = context.colorPalette.accent;
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
    final activeColor = context.colorPalette.accent;
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
          ? Icon(Icons.check, color: activeColor, size: 20)
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
          Text(label, style: TextStyle(fontSize: 13, color: _mutedText)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
            Text(label, style: TextStyle(fontSize: 13, color: _mutedText)),
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
              '₸',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
}
