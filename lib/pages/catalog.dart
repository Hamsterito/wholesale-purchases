import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'category_products_page.dart';
import '../widgets/main_bottom_nav.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _SubcategoryData {
  const _SubcategoryData({
    required this.title,
    required this.imagePath,
    required this.keywords,
    required this.tint,
  });

  final String title;
  final String imagePath;
  final List<String> keywords;
  final Color tint;

  String get routeTitle => title.replaceAll('\n', ' ');
}

class _MainCategoryData {
  const _MainCategoryData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.tint,
    required this.subcategories,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final Color tint;
  final List<_SubcategoryData> subcategories;
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<_MainCategoryData> _mainCategories = const <_MainCategoryData>[];
  bool _isLoadingCategories = true;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _surfaceVariant => _colorScheme.surfaceVariant;
  Color get _shadowColor => _isDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.05);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final tree = await ApiService.getCatalogCategoryTree();
      if (!mounted) {
        return;
      }

      final parsed = _mapMainCategoriesFromApi(tree);
      setState(() {
        _mainCategories = parsed;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mainCategories = const <_MainCategoryData>[];
        _isLoadingCategories = false;
      });
    }
  }

  List<_MainCategoryData> _mapMainCategoriesFromApi(
    List<Map<String, dynamic>> rows,
  ) {
    final entries = <MapEntry<int, _MainCategoryData>>[];

    for (final row in rows) {
      final title = _readString(row['name']);
      if (title.isEmpty) {
        continue;
      }
      final subRows = row['subcategories'];
      if (subRows is! List) {
        continue;
      }

      final tint = _tintForCategoryName(title);
      final subEntries = <MapEntry<int, _SubcategoryData>>[];
      for (final sub in subRows) {
        if (sub is! Map) {
          continue;
        }
        final subMap = Map<String, dynamic>.from(sub);
        final subTitle = _readString(subMap['name']);
        if (subTitle.isEmpty) {
          continue;
        }
        final subImageRaw = _readString(subMap['imagePath']);
        final subImage = subImageRaw.startsWith('assets/')
            ? subImageRaw
            : 'assets/catalog/water.jpg';
        final keywords = _readKeywords(subMap['keywords'], fallback: subTitle);

        subEntries.add(
          MapEntry(
            _toSortOrder(subMap['sortOrder']),
            _SubcategoryData(
              title: subTitle,
              imagePath: subImage,
              keywords: keywords,
              tint: tint,
            ),
          ),
        );
      }

      if (subEntries.isEmpty) {
        continue;
      }
      subEntries.sort((a, b) => a.key.compareTo(b.key));
      final subcategories = subEntries
          .map((entry) => entry.value)
          .toList(growable: false);

      final subtitleRaw = _readString(row['subtitle']);
      final subtitle = subtitleRaw.isEmpty ? title : subtitleRaw;

      final imagePathRaw = _readString(row['imagePath']);
      final imagePath = imagePathRaw.startsWith('assets/')
          ? imagePathRaw
          : subcategories.first.imagePath;

      entries.add(
        MapEntry(
          _toSortOrder(row['sortOrder']),
          _MainCategoryData(
            title: title,
            subtitle: subtitle,
            imagePath: imagePath,
            tint: tint,
            subcategories: subcategories,
          ),
        ),
      );
    }

    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => entry.value).toList(growable: false);
  }

  String _readString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  int _toSortOrder(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _readKeywords(Object? value, {required String fallback}) {
    final result = <String>[];
    if (value is List) {
      for (final item in value) {
        final normalized = item.toString().trim();
        if (normalized.isNotEmpty) {
          result.add(normalized);
        }
      }
    } else if (value != null) {
      for (final part in value.toString().split(RegExp(r'[;,|]'))) {
        final normalized = part.trim();
        if (normalized.isNotEmpty) {
          result.add(normalized);
        }
      }
    }

    if (result.isNotEmpty) {
      return result;
    }
    return <String>[fallback];
  }

  Color _tintForCategoryName(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('напит')) {
      return Colors.blue[100]!;
    }
    if (normalized.contains('овощ') || normalized.contains('фрукт')) {
      return Colors.green[300]!;
    }
    if (normalized.contains('хлеб') || normalized.contains('пекар')) {
      return Colors.orange[200]!;
    }
    if (normalized.contains('молоч')) {
      return Colors.yellow[100]!;
    }
    if (normalized.contains('мяс') || normalized.contains('птиц')) {
      return Colors.pink[100]!;
    }
    return Colors.blue[100]!;
  }

  List<_MainCategoryData> _buildMainCategories() {
    final breadTint = Colors.orange[200]!;
    final vegetablesTint = Colors.green[300]!;
    final dairyTint = Colors.yellow[100]!;
    final meatTint = Colors.pink[100]!;
    final waterTint = Colors.blue[100]!;

    return [
      _MainCategoryData(
        title: 'Напитки',
        subtitle: 'Вода, соки, газировка',
        imagePath: 'assets/catalog/water.jpg',
        tint: waterTint,
        subcategories: [
          _SubcategoryData(
            title: 'Вода',
            imagePath: 'assets/catalog/water.jpg',
            keywords: const ['вода', 'минеральная'],
            tint: Colors.blue[100]!,
          ),
          _SubcategoryData(
            title: 'Соки',
            imagePath: 'assets/catalog/juice.jpg',
            keywords: const ['сок', 'соки', 'juice'],
            tint: Colors.orange[100]!,
          ),
          _SubcategoryData(
            title: 'Газировка',
            imagePath: 'assets/catalog/soda.jpg',
            keywords: const ['газировка', 'газированный', 'лимонад', 'soda'],
            tint: Colors.blue[200]!,
          ),
        ],
      ),
      _MainCategoryData(
        title: 'Овощи и фрукты',
        subtitle: 'Фрукты, ягоды, овощи и зелень',
        imagePath: 'assets/catalog/fruits_berries.jpg',
        tint: vegetablesTint,
        subcategories: [
          _SubcategoryData(
            title: 'Фрукты, ягоды',
            imagePath: 'assets/catalog/fruits_berries.jpg',
            keywords: const ['фрукты', 'ягоды', 'фрукт', 'ягода'],
            tint: vegetablesTint,
          ),
          _SubcategoryData(
            title: 'Овощи, грибы и зелень',
            imagePath: 'assets/catalog/vegetables_greens.jpg',
            keywords: const ['овощи', 'грибы', 'зелень', 'овощ', 'гриб'],
            tint: vegetablesTint,
          ),
        ],
      ),
      _MainCategoryData(
        title: 'Хлеб и пекарня',
        subtitle: 'Хлеб, булочки, пироги',
        imagePath: 'assets/catalog/bakery_pastry.jpg',
        tint: breadTint,
        subcategories: [
          _SubcategoryData(
            title: 'Выпечка от Манса',
            imagePath: 'assets/catalog/bakery_pastry.jpg',
            keywords: const ['выпечка', 'пекарня', 'булочки', 'круассан'],
            tint: breadTint,
          ),
          _SubcategoryData(
            title: 'Хлеб',
            imagePath: 'assets/catalog/bread.jpg',
            keywords: const ['хлеб', 'батон', 'багет'],
            tint: breadTint,
          ),
          _SubcategoryData(
            title: 'Выпечка и пироги',
            imagePath: 'assets/catalog/pie.jpg',
            keywords: const ['выпечка', 'пирог', 'пироги'],
            tint: breadTint,
          ),
        ],
      ),
      _MainCategoryData(
        title: 'Молочная продукция',
        subtitle: 'Молоко, сыр, йогурты и яйца',
        imagePath: 'assets/catalog/milk.jpg',
        tint: dairyTint,
        subcategories: [
          _SubcategoryData(
            title: 'Сыр',
            imagePath: 'assets/catalog/cheese.jpg',
            keywords: const ['сыр'],
            tint: Colors.brown[100]!,
          ),
          _SubcategoryData(
            title: 'Творог, сметана',
            imagePath: 'assets/catalog/cottage_cheese.jpg',
            keywords: const ['творог', 'сметана', 'кисломолочные'],
            tint: Colors.brown[100]!,
          ),
          _SubcategoryData(
            title: 'Йогурт и десерты',
            imagePath: 'assets/catalog/yogurt_dessert.jpg',
            keywords: const ['йогурт', 'десерт', 'десерты'],
            tint: Colors.brown[100]!,
          ),
          _SubcategoryData(
            title: 'Молоко и кисломолочные продукты',
            imagePath: 'assets/catalog/milk.jpg',
            keywords: const ['молоко', 'кефир', 'ряженка', 'айран'],
            tint: dairyTint,
          ),
          _SubcategoryData(
            title: 'Масло и яйца',
            imagePath: 'assets/catalog/butter_eggs.jpg',
            keywords: const ['масло', 'яйца', 'яйцо'],
            tint: dairyTint,
          ),
        ],
      ),
      _MainCategoryData(
        title: 'Мясо и птица',
        subtitle: 'Мясо, колбасы и деликатесы',
        imagePath: 'assets/catalog/meat.jpg',
        tint: meatTint,
        subcategories: [
          _SubcategoryData(
            title: 'Мясо и птица',
            imagePath: 'assets/catalog/meat.jpg',
            keywords: const ['мясо', 'птица', 'курица', 'говядина', 'свинина'],
            tint: meatTint,
          ),
          _SubcategoryData(
            title: 'Колбасы и сосиски',
            imagePath: 'assets/catalog/sausages.jpg',
            keywords: const ['колбаса', 'колбасы', 'сосиски', 'сардельки'],
            tint: meatTint,
          ),
          _SubcategoryData(
            title: 'Мясные деликатесы',
            imagePath: 'assets/catalog/deli_meats.jpg',
            keywords: const ['деликатесы', 'ветчина', 'бекон', 'хамон'],
            tint: meatTint,
          ),
        ],
      ),
    ];
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  List<String> _tokenizeQuery(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }
    return normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  bool _matchesMainCategory(_MainCategoryData data, List<String> tokens) {
    if (tokens.isEmpty) {
      return true;
    }

    final buffer = StringBuffer()
      ..write(data.title)
      ..write(' ')
      ..write(data.subtitle);

    for (final sub in data.subcategories) {
      buffer
        ..write(' ')
        ..write(sub.title);
      for (final keyword in sub.keywords) {
        buffer
          ..write(' ')
          ..write(keyword);
      }
    }

    final haystack = buffer.toString().toLowerCase();
    return tokens.every(haystack.contains);
  }

  List<_MainCategoryData> _visibleMainCategories() {
    final tokens = _tokenizeQuery(_searchQuery);
    final filtered = _mainCategories
        .where((item) => _matchesMainCategory(item, tokens))
        .toList(growable: false);

    final sorted = [...filtered];
    sorted.sort((a, b) => a.title.compareTo(b.title));
    return sorted;
  }

  void _openMainCategory(_MainCategoryData category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SubcategoriesPage(category: category),
      ),
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
            Expanded(child: _buildMainCategoryList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Каталог',
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
          hintText: 'Поиск категорий...',
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

  Widget _buildMainCategoryList() {
    if (_isLoadingCategories) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6288D5)),
      );
    }

    if (_mainCategories.isEmpty) {
      return Center(
        child: Text(
          'Нет категорий',
          style: TextStyle(color: _mutedText, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    final visible = _visibleMainCategories();
    if (visible.isEmpty) {
      return Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: _mutedText, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) => _buildMainCategoryCard(visible[index]),
    );
  }

  Widget _buildMainCategoryCard(_MainCategoryData data) {
    final radius = BorderRadius.circular(14);
    final overlayBase = _isDark
        ? Color.lerp(data.tint, Colors.black, 0.35)!
        : Color.lerp(data.tint, Colors.black, 0.7)!;
    final overlayStart = overlayBase.withValues(alpha: _isDark ? 0.45 : 0.6);
    final overlayMid = overlayBase.withValues(alpha: _isDark ? 0.28 : 0.35);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openMainCategory(data),
        splashColor: Colors.white.withValues(alpha: 0.12),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: _shadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  data.imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [overlayStart, overlayMid, Colors.transparent],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SubcategoriesPage extends StatefulWidget {
  const _SubcategoriesPage({required this.category});

  final _MainCategoryData category;

  @override
  State<_SubcategoriesPage> createState() => _SubcategoriesPageState();
}

class _SubcategoriesPageState extends State<_SubcategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  ColorScheme get _colorScheme => Theme.of(context).colorScheme;

  List<String> _tokenizeQuery(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }
    return normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  bool _matchesSubcategory(_SubcategoryData data, List<String> tokens) {
    if (tokens.isEmpty) {
      return true;
    }

    final buffer = StringBuffer()..write(data.title);
    for (final keyword in data.keywords) {
      buffer
        ..write(' ')
        ..write(keyword);
    }
    final haystack = buffer.toString().toLowerCase();
    return tokens.every(haystack.contains);
  }

  List<_SubcategoryData> _visibleSubcategories() {
    final tokens = _tokenizeQuery(_searchQuery);
    final filtered = widget.category.subcategories
        .where((item) => _matchesSubcategory(item, tokens))
        .toList();

    filtered.sort((a, b) => a.title.compareTo(b.title));
    return filtered;
  }

  void _openSubcategory(_SubcategoryData data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductsPage(
          title: data.routeTitle,
          keywords: data.keywords,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = _visibleSubcategories();

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск подкатегорий...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                filled: true,
                fillColor: _colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: subcategories.isEmpty
                ? Center(
                    child: Text(
                      'Ничего не найдено',
                      style: TextStyle(
                        color: _colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: subcategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildSubcategoryTile(subcategories[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSubcategoryTile(_SubcategoryData data) {
    return Material(
      color: _colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openSubcategory(data),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 92,
                  height: 72,
                  child: Image.asset(data.imagePath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.keywords.take(3).join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: _colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

