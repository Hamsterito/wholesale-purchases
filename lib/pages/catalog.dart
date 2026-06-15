import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../services/api/api_service.dart';
import 'category_products_page.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../core/ui/theme/app_dimensions.dart';

// RegExp вызываются на каждом keystroke в поиске и при парсинге keywords
// при загрузке категорий - выносим в top-level final, чтобы не пересоздавать.
final RegExp _kCatalogTokenSplit = RegExp(r'\s+');
final RegExp _kCatalogKeywordSeparator = RegExp(r'[;,|]');

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

  // Debounce поискового ввода: ребилд списка категорий не на каждом keystroke,
  // а через 300мс после последнего изменения.
  Timer? _searchDebounce;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => context.colorPalette.card;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _surfaceVariant => _colorScheme.surfaceContainerHighest;
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
      for (final part in value.toString().split(_kCatalogKeywordSeparator)) {
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
    if (normalized.contains(context.l10n.getString('auto_napit'))) {
      return Colors.blue[100]!;
    }
    if (normalized.contains(context.l10n.getString('auto_ovoshch')) || normalized.contains(context.l10n.getString('auto_frukt'))) {
      return Colors.green[300]!;
    }
    if (normalized.contains(context.l10n.getString('auto_hleb')) || normalized.contains(context.l10n.getString('auto_pekar'))) {
      return Colors.orange[200]!;
    }
    if (normalized.contains(context.l10n.getString('auto_moloch'))) {
      return Colors.yellow[100]!;
    }
    if (normalized.contains(context.l10n.getString('auto_myas')) || normalized.contains(context.l10n.getString('auto_ptits'))) {
      return Colors.pink[100]!;
    }
    return Colors.blue[100]!;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
      });
    });
  }

  List<String> _tokenizeQuery(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }
    return normalized
        .split(_kCatalogTokenSplit)
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
        bottom: false,
        minimum: const EdgeInsets.only(bottom: AppDimensions.minBottomSafePadding),
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
              context.l10n.getString('auto_katalog'),
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
          hintText: context.l10n.getString('auto_poiskKategoriy'),
          hintStyle: TextStyle(color: _mutedText),
          prefixIcon: Icon(Icons.search, color: _mutedText),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: _mutedText),
                  onPressed: () {
                    _searchDebounce?.cancel();
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
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
      return Center(
        child: CircularProgressIndicator(color: context.colorPalette.accent),
      );
    }

    if (_mainCategories.isEmpty) {
      return Center(
        child: Text(
          context.l10n.getString('auto_netKategoriy'),
          style: TextStyle(color: _mutedText, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    final visible = _visibleMainCategories();
    if (visible.isEmpty) {
      return Center(
        child: Text(
          context.l10n.getString('auto_nichegoNeNaydeno'),
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
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) => _buildMainCategoryCard(visible[index]),
    );
  }

  Widget _buildMainCategoryCard(_MainCategoryData data) {
    final radius = BorderRadius.circular(14);
    final overlayStart = Colors.black.withValues(alpha: _isDark ? 0.7 : 0.6);
    final overlayMid = Colors.black.withValues(alpha: _isDark ? 0.3 : 0.2);

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
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  cacheWidth: 800,
                  cacheHeight: 600,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [overlayStart, overlayMid, Colors.transparent],
                    stops: const [0.0, 0.45, 1.0],
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
    _searchDebounce?.cancel();
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

  // Debounce поискового ввода: ребилд списка подкатегорий выполняется
  // через 300мс после последнего изменения, а не на каждом keystroke.
  Timer? _searchDebounce;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);

  ColorScheme get _colorScheme => Theme.of(context).colorScheme;

  List<String> _tokenizeQuery(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }
    return normalized
        .split(_kCatalogTokenSplit)
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
                _searchDebounce?.cancel();
                _searchDebounce = Timer(_searchDebounceDuration, () {
                  if (!mounted) return;
                  setState(() {
                    _searchQuery = value;
                  });
                });
              },
              decoration: InputDecoration(
                hintText: context.l10n.getString('auto_poiskPodkategoriy'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchDebounce?.cancel();
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                filled: true,
                fillColor: _colorScheme.surfaceContainerHighest,
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
                      context.l10n.getString('auto_nichegoNeNaydeno'),
                      style: TextStyle(
                        color: _colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16 + AppDimensions.minBottomSafePadding),
                    itemCount: subcategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildSubcategoryTile(subcategories[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryTile(_SubcategoryData data) {
    return Material(
      color: context.colorPalette.card,
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
                  child: Image.asset(
                    data.imagePath,
                    fit: BoxFit.cover,
                    cacheWidth: 400,
                    cacheHeight: 320,
                  ),
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
