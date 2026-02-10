import 'package:flutter/material.dart';
import 'category_products_page.dart';

enum CategoryFilter { all, drinks, vegetables, bread, dairy, meat }

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CategoryCardData {
  const _CategoryCardData({
    required this.title,
    required this.imagePath,
    required this.keywords,
    required this.tint,
    this.height,
  });

  final String title;
  final String imagePath;
  final List<String> keywords;
  final Color tint;
  final double? height;

  String get routeTitle => title.replaceAll('\n', ' ');
}

class _CatalogPageState extends State<CatalogPage> {
  CategoryFilter _selectedFilter = CategoryFilter.all;
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  void _onFilterTapped(CategoryFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  bool _shouldShowCategory(CategoryFilter category) {
    if (_selectedFilter == CategoryFilter.all) return true;
    return _selectedFilter == category;
  }

  List<String> _tokenizeQuery(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) return const [];
    return normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  bool _matchesSearch(_CategoryCardData data, List<String> tokens) {
    if (tokens.isEmpty) return true;
    final buffer = StringBuffer()..write(data.title);
    for (final keyword in data.keywords) {
      buffer
        ..write(' ')
        ..write(keyword);
    }
    final haystack = buffer.toString().toLowerCase();
    return tokens.every(haystack.contains);
  }

  void _openCategory(_CategoryCardData data) {
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

  String _filterLabel(CategoryFilter filter) {
    switch (filter) {
      case CategoryFilter.all:
        return 'Все';
      case CategoryFilter.drinks:
        return 'Напитки';
      case CategoryFilter.vegetables:
        return 'Овощи и фрукты';
      case CategoryFilter.bread:
        return 'Хлеб';
      case CategoryFilter.dairy:
        return 'Молочка';
      case CategoryFilter.meat:
        return 'Мясо';
    }
  }

  void _openFilterMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Фильтры каталога',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final filter in CategoryFilter.values)
                ListTile(
                  title: Text(_filterLabel(filter)),
                  trailing: _selectedFilter == filter
                      ? const Icon(Icons.check, color: Color(0xFF6288D5))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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
            Expanded(child: _buildCategoryList()),
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
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilterMenu,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('Все', CategoryFilter.all),
                  const SizedBox(width: 12),
                  _buildFilterButton('Напитки', CategoryFilter.drinks),
                  const SizedBox(width: 12),
                  _buildFilterButton('Овощи фрукты', CategoryFilter.vegetables),
                  const SizedBox(width: 12),
                  _buildFilterButton('Хлеб', CategoryFilter.bread),
                  const SizedBox(width: 12),
                  _buildFilterButton('Молочка', CategoryFilter.dairy),
                  const SizedBox(width: 12),
                  _buildFilterButton('Мясо', CategoryFilter.meat),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, CategoryFilter filter) {
    bool isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _onFilterTapped(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6288D5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final breadTint = Colors.orange[200]!;
    final vegetablesTint = Colors.green[300]!;
    final dairyTint = Colors.brown[100]!;
    final dairyLightTint = Colors.yellow[100]!;
    final meatTint = Colors.pink[100]!;
    final waterTint = Colors.blue[100]!;
    final juiceTint = Colors.orange[100]!;
    final sodaTint = Colors.blue[200]!;
    final tokens = _tokenizeQuery(_searchQuery);

    List<_CategoryCardData> filterCards(List<_CategoryCardData> items) {
      if (tokens.isEmpty) return items;
      return items.where((item) => _matchesSearch(item, tokens)).toList();
    }

    final breadCards = filterCards([
      _CategoryCardData(
        title: 'Выпечка\nот Манса',
        imagePath: 'assets/catalog/bakery_pastry.jpg',
        keywords: const ['выпечка', 'пекарня', 'булочки', 'круассан'],
        tint: breadTint,
      ),
      _CategoryCardData(
        title: 'Хлеб',
        imagePath: 'assets/catalog/bread.jpg',
        keywords: const ['хлеб', 'батон', 'багет'],
        tint: breadTint,
      ),
      _CategoryCardData(
        title: 'Выпечка и\nпироги',
        imagePath: 'assets/catalog/pie.jpg',
        keywords: const ['выпечка', 'пирог', 'пироги'],
        tint: breadTint,
      ),
    ]);

    final vegetablesCards = filterCards([
      _CategoryCardData(
        title: 'Фрукты, ягоды',
        imagePath: 'assets/catalog/fruits_berries.jpg',
        keywords: const ['фрукты', 'ягоды', 'фрукт', 'ягода'],
        tint: vegetablesTint,
        height: 120,
      ),
      _CategoryCardData(
        title: 'Овощи, грибы и\nзелень',
        imagePath: 'assets/catalog/vegetables_greens.jpg',
        keywords: const ['овощи', 'грибы', 'зелень', 'овощ', 'гриб'],
        tint: vegetablesTint,
        height: 120,
      ),
    ]);

    final dairyCardsRow1 = filterCards([
      _CategoryCardData(
        title: 'Сыр',
        imagePath: 'assets/catalog/cheese.jpg',
        keywords: const ['сыр'],
        tint: dairyTint,
      ),
      _CategoryCardData(
        title: 'Творог,\nсметана',
        imagePath: 'assets/catalog/cottage_cheese.jpg',
        keywords: const ['творог', 'сметана', 'кисломолочные'],
        tint: dairyTint,
      ),
      _CategoryCardData(
        title: 'Йогурт и\nдесерты',
        imagePath: 'assets/catalog/yogurt_dessert.jpg',
        keywords: const ['йогурт', 'десерт', 'десерты'],
        tint: dairyTint,
      ),
    ]);

    final dairyCardsRow2 = filterCards([
      _CategoryCardData(
        title: 'Молоко\nкисломолочные\nпродукты',
        imagePath: 'assets/catalog/milk.jpg',
        keywords: const ['молоко', 'кефир', 'ряженка', 'айран'],
        tint: dairyLightTint,
      ),
      _CategoryCardData(
        title: 'Масло и яйца',
        imagePath: 'assets/catalog/butter_eggs.jpg',
        keywords: const ['масло', 'яйца', 'яйцо'],
        tint: dairyLightTint,
      ),
    ]);

    final meatCards = filterCards([
      _CategoryCardData(
        title: 'Мясо и\nптица',
        imagePath: 'assets/catalog/meat.jpg',
        keywords: const [
          'мясо',
          'птица',
          'курица',
          'говядина',
          'свинина',
        ],
        tint: meatTint,
      ),
      _CategoryCardData(
        title: 'Колбасы и\nсосиски',
        imagePath: 'assets/catalog/sausages.jpg',
        keywords: const ['колбаса', 'колбасы', 'сосиски', 'сардельки'],
        tint: meatTint,
      ),
      _CategoryCardData(
        title: 'Мясные\nделикатесы',
        imagePath: 'assets/catalog/deli_meats.jpg',
        keywords: const ['деликатесы', 'ветчина', 'бекон', 'хамон'],
        tint: meatTint,
      ),
    ]);

    final drinksCards = filterCards([
      _CategoryCardData(
        title: 'Вода',
        imagePath: 'assets/catalog/water.jpg',
        keywords: const ['вода', 'минеральная'],
        tint: waterTint,
      ),
      _CategoryCardData(
        title: 'Соки',
        imagePath: 'assets/catalog/juice.jpg',
        keywords: const ['сок', 'соки', 'juice'],
        tint: juiceTint,
      ),
      _CategoryCardData(
        title: 'Газировка',
        imagePath: 'assets/catalog/soda.jpg',
        keywords: const ['газировка', 'газированный', 'лимонад', 'soda'],
        tint: sodaTint,
      ),
    ]);

    final hasResults =
        (_shouldShowCategory(CategoryFilter.bread) && breadCards.isNotEmpty) ||
        (_shouldShowCategory(CategoryFilter.vegetables) &&
            vegetablesCards.isNotEmpty) ||
        (_shouldShowCategory(CategoryFilter.dairy) &&
            (dairyCardsRow1.isNotEmpty || dairyCardsRow2.isNotEmpty)) ||
        (_shouldShowCategory(CategoryFilter.meat) && meatCards.isNotEmpty) ||
        (_shouldShowCategory(CategoryFilter.drinks) && drinksCards.isNotEmpty);

    if (!hasResults) {
      return Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: _mutedText, fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_shouldShowCategory(CategoryFilter.bread) &&
            breadCards.isNotEmpty) ...[
          _buildCategoryTitle('Хлеб и пекарня'),
          const SizedBox(height: 12),
          _buildCategoryRow(_sortRow(breadCards)),
          const SizedBox(height: 24),
        ],
        if (_shouldShowCategory(CategoryFilter.vegetables) &&
            vegetablesCards.isNotEmpty) ...[
          _buildCategoryTitle('Свежие овощи и фрукты'),
          const SizedBox(height: 12),
          _buildCategoryRow(_sortRow(vegetablesCards)),
          const SizedBox(height: 24),
        ],
        if (_shouldShowCategory(CategoryFilter.dairy) &&
            (dairyCardsRow1.isNotEmpty || dairyCardsRow2.isNotEmpty)) ...[
          _buildCategoryTitle('Молоко, яйца и сыр'),
          const SizedBox(height: 12),
          if (dairyCardsRow1.isNotEmpty)
            _buildCategoryRow(_sortRow(dairyCardsRow1)),
          const SizedBox(height: 12),
          if (dairyCardsRow2.isNotEmpty)
            _buildCategoryRow(_sortRow(dairyCardsRow2)),
          const SizedBox(height: 24),
        ],
        if (_shouldShowCategory(CategoryFilter.meat) &&
            meatCards.isNotEmpty) ...[
          _buildCategoryTitle('Мясная лавка'),
          const SizedBox(height: 12),
          _buildCategoryRow(_sortRow(meatCards)),
          const SizedBox(height: 24),
        ],
        if (_shouldShowCategory(CategoryFilter.drinks) &&
            drinksCards.isNotEmpty) ...[
          _buildCategoryTitle('Напитки'),
          const SizedBox(height: 12),
          _buildCategoryRow(_sortRow(drinksCards)),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _colorScheme.onSurface,
      ),
    );
  }

  Widget _buildCategoryCard(_CategoryCardData data) {
    final radius = BorderRadius.circular(14);
    final overlayBase = _isDark
        ? Color.lerp(data.tint, Colors.black, 0.35)!
        : Color.lerp(data.tint, Colors.black, 0.7)!;
    final overlayStart = overlayBase.withValues(alpha: _isDark ? 0.45 : 0.6);
    final overlayMid = overlayBase.withValues(alpha: _isDark ? 0.28 : 0.35);
    final titleColor = Colors.white;

    bool isPressed = false;

    return Expanded(
      child: StatefulBuilder(
        builder: (context, setInnerState) {
          return AnimatedScale(
            scale: isPressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              height: data.height ?? 100,
              decoration: BoxDecoration(
                borderRadius: radius,
                color: _cardBg,
                boxShadow: [
                  BoxShadow(
                    color: _shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openCategory(data),
                  onHighlightChanged: (value) {
                    setInnerState(() => isPressed = value);
                  },
                  splashColor: Colors.white.withValues(alpha: 0.12),
                  highlightColor: Colors.white.withValues(alpha: 0.06),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          data.imagePath,
                          fit: BoxFit.cover,
                          alignment: Alignment.centerRight,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                overlayStart,
                                overlayMid,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryRow(List<Widget> cards) {
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          cards[i],
        ],
      ],
    );
  }

  List<Widget> _sortRow(List<_CategoryCardData> data) {
    final items = [...data];
    items.sort((a, b) => a.routeTitle.compareTo(b.routeTitle));
    final ordered = _sortAscending ? items : items.reversed.toList();
    return ordered.map(_buildCategoryCard).toList();
  }

  Widget _buildSortIcon() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.swap_vert, color: colorScheme.onSurface),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
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
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
