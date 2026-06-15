import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../models/review_entry.dart';
import '../models/question.dart';
import '../services/api/api_service.dart';
import '../services/store/cart_store.dart';
import '../services/store/favorites_store.dart';
import '../services/store/supplier_stats_store.dart';
import '../widgets/pages/category_tags.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../core/ui/theme/app_dimensions.dart';
import '../core/ui/widgets/thumb_zone_builder.dart';
import '../widgets/pages/product_image_carousel.dart';
import '../widgets/pages/rating_section.dart';
import '../theme/app_color_palette.dart';
import '../utils/characteristic_sections.dart';
import '../utils/delivery_schedule.dart';
import '../utils/rating_format.dart';
import '../widgets/pages/similar_products_carousel.dart';
import '../widgets/profile/user_avatar.dart';
import '../widgets/smooth_sheet.dart';
import '../widgets/messages/top_message.dart';
import '../widgets/product/rating_stars.dart';
import 'reviews_page.dart';
import 'questions_page.dart';
import 'supplier_profile_page.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import '../utils/date_formatter.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final List<Product> similarProducts;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.similarProducts = const [],
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  static const double _bottomMessageOffset = 150;
  static const double _stickyBottomVisibilityOffset = 128;
  static const String _shareStubUrl =
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
  final Map<String, int> _supplierQuantities = {};
  final Map<String, bool> _supplierAdded = {};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _similarProductsKey = GlobalKey();
  List<ReviewEntry> _productReviews = const <ReviewEntry>[];
  // Стартуем с true - тогда первый кадр сразу рисует CircularProgressIndicator,
  // не дожидаясь setState из отложенного _loadProductReviews.
  bool _isLoadingReviews = true;
  List<Question> _productQuestions = [];
  bool _isLoadingQuestions = true;
  int _totalQuestions = 0;
  // True после первой успешной загрузки вопросов. Дальше счётчик во вкладке
  // «Вопросы (N)» берём из _totalQuestions, а не из widget.product.questionCount,
  // чтобы при возврате с QuestionsPage не откатываться к устаревшему каталогу.
  bool _hasLoadedQuestionsOnce = false;
  TabController? _tabController;
  // Индекс активной вкладки в отдельном ValueNotifier - меняется на
  // переключении табов, без полного setState всей страницы.
  late final ValueNotifier<int> _selectedTabIndex;
  bool _isFavorite = false;
  // Избранное компании-поставщика - отдельный флаг, не связанный с избранным товара.
  bool _isSupplierFavorite = false;
  // ValueNotifier - меняются на скролле, без полного setState.
  final ValueNotifier<bool> _showPersistentPriceBar = ValueNotifier(true);
  final ValueNotifier<bool> _showScrollToTopButton = ValueNotifier(false);
  // Дроссель для скролла: пересчёт только при сдвиге более 4 px.
  double _lastScrollOffset = 0;
  // Абсолютный offset секции «Похожие товары» от начала прокручиваемого
  // контента. Считается один раз после layout - на скролле сравниваем
  // позицию со scroll offset, без findRenderObject и localToGlobal.
  double? _similarProductsScrollOffset;
  late final VoidCallback _favoritesListener;
  String? _selectedSupplierId;
  late final PageController _pageController;
  // Контроллеры превью отзывов и вопросов держим в State, иначе на каждом
  // ребилде создавался бы новый PageController - сбрасывалась позиция и
  // плодились ChangeNotifier'ы.
  late final PageController _reviewsPreviewController;
  late final PageController _questionsPreviewController;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  AppColorPalette get _palette => context.colorPalette;

  Color get _pageBg => _palette.bgTop;
  Color get _cardBg => _palette.card;
  Color get _mutedText => _palette.muted;
  Color get _shadowColor => _palette.shadow;
  FavoritesStore get _favoritesStore => FavoritesStore.instance;
  int get _resolvedReviewCount => _productReviews.isNotEmpty
      ? _productReviews.length
      : widget.product.reviewCount;
  // До первой успешной загрузки берём счётчик из каталога,
  // чтобы вкладка «Вопросы (N)» не моргала нулём.
  int get _resolvedQuestionCount =>
      _hasLoadedQuestionsOnce ? _totalQuestions : widget.product.questionCount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedTabIndex = ValueNotifier<int>(_tabController!.index);
    _tabController!.addListener(_onTabIndexChanged);
    _scrollController.addListener(_handleScroll);
    _pageController = PageController();
    _reviewsPreviewController = PageController(viewportFraction: 0.94);
    _questionsPreviewController = PageController(viewportFraction: 0.94);
    _isFavorite = _favoritesStore.contains(widget.product.id);
    _favoritesListener = () {
      final isFav = _favoritesStore.contains(widget.product.id);
      final supplierId = _selectedSupplierId;
      final isSupplierFav =
          supplierId != null && _favoritesStore.containsSupplier(supplierId);
      if (!mounted) return;
      if (isFav != _isFavorite || isSupplierFav != _isSupplierFavorite) {
        setState(() {
          _isFavorite = isFav;
          _isSupplierFavorite = isSupplierFav;
        });
      }
    };
    _favoritesStore.addListener(_favoritesListener);
    for (var supplier in widget.product.suppliers) {
      _supplierQuantities[supplier.id] = supplier.minQuantity;
      _supplierAdded[supplier.id] = false;
    }
    if (widget.product.suppliers.isNotEmpty) {
      _selectedSupplierId = widget.product.bestSupplier.id;
      _isSupplierFavorite = _favoritesStore.containsSupplier(
        _selectedSupplierId!,
      );
    }
    // Откладываем сетевые загрузки на следующий кадр - первый билд страницы
    // не блокируется, секции отзывов/вопросов сразу показывают индикатор
    // загрузки благодаря _isLoadingReviews/_isLoadingQuestions = true.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadProductReviews();
      _loadProductQuestions();
      _refreshSupplierStats();
      _updateBottomAffordances();
    });
  }

  @override
  void dispose() {
    _tabController!.removeListener(_onTabIndexChanged);
    _tabController!.dispose();
    _selectedTabIndex.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    _reviewsPreviewController.dispose();
    _questionsPreviewController.dispose();
    _favoritesStore.removeListener(_favoritesListener);
    _showPersistentPriceBar.dispose();
    _showScrollToTopButton.dispose();
    super.dispose();
  }

  void _onTabIndexChanged() {
    if (_tabController!.indexIsChanging) return;
    if (_selectedTabIndex.value == _tabController!.index) return;
    _selectedTabIndex.value = _tabController!.index;
  }

  @override
  void didUpdateWidget(covariant ProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      final isFav = _favoritesStore.contains(widget.product.id);
      if (isFav != _isFavorite) {
        setState(() {
          _isFavorite = isFav;
        });
      }
      _supplierQuantities.clear();
      _supplierAdded.clear();
      for (final supplier in widget.product.suppliers) {
        _supplierQuantities[supplier.id] = supplier.minQuantity;
        _supplierAdded[supplier.id] = false;
      }
      _selectedSupplierId = widget.product.suppliers.isEmpty
          ? null
          : widget.product.bestSupplier.id;
      _isSupplierFavorite = _selectedSupplierId == null
          ? false
          : _favoritesStore.containsSupplier(_selectedSupplierId!);
      _loadProductReviews();
      _refreshSupplierStats();
      _similarProductsScrollOffset = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateBottomAffordances();
      });
    }
  }

  // setState может изменить layout выше «Похожих товаров» (отзывы пришли,
  // например), поэтому сбрасываем кэш - пересчёт на следующем кадре.
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _similarProductsScrollOffset = null;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    if ((offset - _lastScrollOffset).abs() < 4) return;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;
    _updateBottomAffordances(scrollDelta: delta);
  }

  // Кэшируем offset секции «Похожие товары» одноразово после layout.
  // На скролле сравниваем pixels со scrollOffset - без обхода рендер-дерева.
  void _measureSimilarProductsOffset() {
    final ctx = _similarProductsKey.currentContext;
    if (ctx == null) return;
    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(renderBox);
    if (viewport == null) return;
    _similarProductsScrollOffset = viewport
        .getOffsetToReveal(renderBox, 0)
        .offset;
  }

  void _updateBottomAffordances({double? scrollDelta}) {
    if (!_scrollController.hasClients) return;

    if (_similarProductsScrollOffset == null) {
      _measureSimilarProductsOffset();
    }

    bool isAtSimilarProducts = false;
    final similarOffset = _similarProductsScrollOffset;
    if (similarOffset != null) {
      final position = _scrollController.position;
      // Нижняя кромка вьюпорта дошла до секции с поправкой на высоту
      // блока цены - прячем кнопку, чтобы не перекрывать первый ряд.
      final viewportEnd = position.pixels + position.viewportDimension;
      isAtSimilarProducts =
          viewportEnd >= similarOffset + _stickyBottomVisibilityOffset;
    }

    final nextShowPriceBar = !isAtSimilarProducts;
    bool nextShowScrollToTop = _showScrollToTopButton.value;

    if (!isAtSimilarProducts) {
      nextShowScrollToTop = false;
    } else if (scrollDelta != null && scrollDelta < 0) {
      nextShowScrollToTop = true;
    } else if (scrollDelta != null && scrollDelta > 0) {
      nextShowScrollToTop = false;
    }

    // Меняем notifier напрямую - без setState всей страницы.
    _showPersistentPriceBar.value = nextShowPriceBar;
    _showScrollToTopButton.value = nextShowScrollToTop;
  }

  Future<void> _scrollToTop() async {
    _showScrollToTopButton.value = false;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  // Подтягиваем актуальный rating/reviewCount поставщика и кешируем в SupplierStatsStore.
  // Цифры на странице обновятся через AnimatedBuilder, и тот же кеш увидит избранное.
  Future<void> _refreshSupplierStats() async {
    final supplierId = _selectedSupplierId;
    if (supplierId == null) return;
    try {
      final fresh = await ApiService.getSupplier(supplierId);
      if (!mounted) return;
      SupplierStatsStore.instance.update(fresh);
    } catch (_) {
      // Молча игнорируем - отобразим то, что пришло вместе с товаром.
    }
  }

  Future<void> _loadProductReviews() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviews = await ApiService.getProductReviews(
        productId: widget.product.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _productReviews = reviews;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _productReviews = const <ReviewEntry>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _loadProductQuestions() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingQuestions = true;
    });
    try {
      final data = await ApiService.getProductQuestions(
        productId: widget.product.id,
        page: 1,
        limit: 20,
      );
      if (!mounted) {
        return;
      }
      final questions = (data['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList();
      setState(() {
        _productQuestions = questions;
        _totalQuestions = data['total'] as int;
        _hasLoadedQuestionsOnce = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _productQuestions = [];
        _totalQuestions = 0;
        _hasLoadedQuestionsOnce = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingQuestions = false;
        });
      }
    }
  }

  void _updateQuantity(String supplierId, int delta) {
    final supplier = widget.product.suppliers.firstWhere(
      (s) => s.id == supplierId,
    );
    if (!supplier.isAvailable) {
      return;
    }
    final currentQty = _supplierQuantities[supplierId] ?? supplier.minQuantity;
    final newQty = currentQty + delta;
    final maxQuantity = supplier.maxQuantity;
    final effectiveMax =
        maxQuantity != null && maxQuantity < supplier.minQuantity
        ? supplier.minQuantity
        : maxQuantity;
    if (newQty < supplier.minQuantity || newQty == currentQty) {
      return;
    }
    if (effectiveMax != null && newQty > effectiveMax) {
      return;
    }
    setState(() {
      _supplierQuantities[supplierId] = newQty;
    });
  }

  void _addToCart(Supplier supplier) {
    if (!supplier.isAvailable) {
      showTopMessage(
        context,
        context.l10n.getString('auto_netVNalichii'),
        backgroundColor: _palette.error,
        showAtBottom: true,
        bottomOffset: _bottomMessageOffset,
      );
      return;
    }
    final quantity = _supplierQuantities[supplier.id] ?? supplier.minQuantity;
    setState(() {
      _supplierAdded[supplier.id] = true;
    });
    CartStore.instance.addOrUpdate(
      product: widget.product,
      supplier: supplier,
      quantity: quantity,
    );
    showTopMessage(
      context,
      context.l10n.productDetailAddedToCart(widget.product.name),
      backgroundColor: _palette.accent,
      showAtBottom: true,
      bottomOffset: _bottomMessageOffset,
    );
  }

  void _removeFromCart(Supplier supplier) {
    setState(() {
      _supplierAdded[supplier.id] = false;
    });
    CartStore.instance.removeItem(
      supplierId: supplier.id,
      productId: widget.product.id,
    );
    showTopMessage(
      context,
      context.l10n.productDetailRemovedFromCart(widget.product.name),
      backgroundColor: _palette.error,
      showAtBottom: true,
      bottomOffset: _bottomMessageOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Фиксированный padding под максимальную высоту bottom bar.
    // Анимировать его вместе со скроллом дорого - layout пересчитывался бы каждый кадр.
    final bottomScrollPadding = MediaQuery.viewPaddingOf(context).bottom + 150;

    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomScrollPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(),
                  _buildTitleBlock(),
                  _buildAvailabilitySection(),
                  _buildStatsButtonsRow(),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        // TabBar остаётся на card, как заголовок секции.
                        // Превью под ним - на bgTop, чтобы карточки отзывов
                        // и вопросов (palette.card) контрастировали с фоном,
                        // как на страницах reviews_page и questions_page.
                        Container(
                          color: _cardBg,
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: _palette.accent,
                            indicatorWeight: 3,
                            labelColor: _palette.ink,
                            unselectedLabelColor: _palette.muted,
                            labelStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            tabs: [
                              Tab(text: context.l10n.productTabReviews(_resolvedReviewCount)),
                              Tab(text: context.l10n.productTabQuestions(_resolvedQuestionCount)),
                            ],
                          ),
                        ),
                        Container(
                          color: _pageBg,
                          child: ValueListenableBuilder<int>(
                            valueListenable: _selectedTabIndex,
                            builder: (context, index, _) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: index == 0
                                    ? _buildReviewsPreview()
                                    : _buildQuestionsPreview(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildAboutProductTile(),
                  if (widget.similarProducts.isNotEmpty)
                    SimilarProductsCarousel(
                      key: _similarProductsKey,
                      products: widget.similarProducts,
                      onProductTap: (product) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              product: product,
                              similarProducts: widget.similarProducts
                                  .where((p) => p.id != product.id)
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: RepaintBoundary(
        child: ValueListenableBuilder<bool>(
          valueListenable: _showScrollToTopButton,
          builder: (context, visible, _) {
            // Один AnimatedSwitcher вместо Scale+Opacity - один кадр анимации.
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: visible
                  ? _ScrollTopButton(
                      key: const ValueKey('scroll-top-fab'),
                      color: _colorScheme.primary,
                      onTap: _scrollToTop,
                    )
                  : const SizedBox.shrink(key: ValueKey('scroll-top-empty')),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      color: _cardBg,
      child: Stack(
        children: [
          ProductImageCarousel(imageUrls: widget.product.imageUrls),
          Positioned(
            top: 0,
            left: 12,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildIconPill(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconPill(
                      icon: _isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      iconColor: _isFavorite ? _palette.error : null,
                      onTap: () {
                        final added = _favoritesStore.toggle(widget.product);
                        setState(() {
                          _isFavorite = added;
                        });
                        if (added) {
                          showTopMessage(
                            context,
                            '\u0414\u043e\u0431\u0430\u0432\u043b\u0435\u043d\u043e \u0432 \u0438\u0437\u0431\u0440\u0430\u043d\u043d\u043e\u0435',
                            backgroundColor: _palette.accent,
                            showAtBottom: true,
                            bottomOffset: _bottomMessageOffset,
                          );
                        } else {
                          showTopMessage(
                            context,
                            '\u0423\u0434\u0430\u043b\u0435\u043d\u043e \u0438\u0437 \u0438\u0437\u0431\u0440\u0430\u043d\u043d\u043e\u0433\u043e',
                            backgroundColor: _palette.error,
                            showAtBottom: true,
                            duration: const Duration(seconds: 3),
                            showClose: true,
                            bottomOffset: _bottomMessageOffset,
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildIconPill(
                      icon: Icons.share_rounded,
                      onTap: _shareProductStub,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPill({
    required IconData icon,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final palette = context.colorPalette;
    final resolvedColor = iconColor ?? palette.accent;

    return Material(
      color: palette.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: Icon(icon, color: resolvedColor, size: 26)),
        ),
      ),
    );
  }

  // Заголовок товара. Под рейтингом и названием - компактная строка:
  // слева иконки доставки/развоза, справа теги категорий.
  Widget _buildTitleBlock() {
    final palette = context.colorPalette;
    final supplier = widget.product.suppliers.isEmpty
        ? null
        : widget.product.suppliers.firstWhere(
            (s) => s.id == _selectedSupplierId,
            orElse: () => widget.product.bestSupplier,
          );
    final raw = supplier == null
        ? ''
        : (supplier.deliveryDate.trim().isNotEmpty
              ? supplier.deliveryDate
              : supplier.deliveryBadge);
    final schedule = DeliverySchedule.decode(raw);
    final deliveryDate = schedule != null
        ? formatDeliveryDateShort(schedule, DateTime.now())
        : (raw.trim().isEmpty ? null : raw);
    final deliveryTime = schedule != null
        ? formatDeliveryTimeShort(schedule)
        : null;
    final hasInfoLine =
        deliveryDate != null ||
        deliveryTime != null ||
        widget.product.categories.isNotEmpty;

    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingSection(
            rating: widget.product.rating,
            reviewCount: _resolvedReviewCount,
            onTap: _openReviews,
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: palette.ink,
            ),
          ),
          if (hasInfoLine) ...[
            const SizedBox(height: 8),
            // Дата/время доставки слева, теги - отдельной строкой ниже.
            if (deliveryDate != null || deliveryTime != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (deliveryDate != null) ...[
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 16,
                      color: palette.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      deliveryDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ],
                  if (deliveryTime != null) ...[
                    const SizedBox(width: 10),
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: palette.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      deliveryTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ],
                ],
              ),
            if (widget.product.categories.isNotEmpty) ...[
              if (deliveryDate != null || deliveryTime != null)
                const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: CategoryTags(
                  categories: widget.product.categories,
                  alignment: WrapAlignment.start,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Объединённая карточка: верхняя часть «О товаре» с превью характеристик
  // и кнопкой «Подробнее» (тап → bottom sheet с табами), под разделителем -
  // компактная плашка поставщика (название, «Поставщик ⭐ rating» и сердечко).
  Widget _buildAboutProductTile() {
    final palette = context.colorPalette;
    final sections = buildCharacteristicSections(widget.product);
    final hasDescription = !shouldShowDescriptionPlaceholder(
      widget.product.description,
    );
    final hasAbout = sections.isNotEmpty || hasDescription;
    final supplier = widget.product.suppliers.isEmpty
        ? null
        : widget.product.suppliers.firstWhere(
            (s) => s.id == _selectedSupplierId,
            orElse: () => widget.product.bestSupplier,
          );
    if (!hasAbout && supplier == null) {
      return const SizedBox.shrink();
    }
    final preview = _buildPreviewLines(sections);

    return Container(
      color: _cardBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: palette.bgTop,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasAbout)
              InkWell(
                onTap: _openAboutProductSheet,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.getString('auto_oTovare'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: palette.ink,
                              ),
                            ),
                            if (preview.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                preview,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.muted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.getString('auto_podrobnee'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: palette.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.chevron_right, color: palette.muted),
                    ],
                  ),
                ),
              ),
            if (hasAbout && supplier != null)
              Divider(height: 1, thickness: 1, color: palette.line),
            if (supplier != null) _buildSupplierRow(supplier, palette),
          ],
        ),
      ),
    );
  }

  // Компактная плашка поставщика внутри объединённой карточки.
  // Фон card создаёт лёгкий контраст с обёрткой bgTop в обеих темах,
  // как на референсе. Имя слева, под ним «Поставщик ⭐ rating», справа сердечко.
  Widget _buildSupplierRow(Supplier supplier, AppColorPalette palette) {
    return AnimatedBuilder(
      animation: SupplierStatsStore.instance,
      builder: (context, _) {
        final rating = SupplierStatsStore.instance.rating(
          supplier.id,
          fallback: supplier.rating,
        );
        // Название компании из свежего профиля - оно может отличаться от
        // supplier.name из каталога, который мог сохраниться с именем поставщика.
        final companyName = SupplierStatsStore.instance.name(
          supplier.id,
          fallback: supplier.name,
        );
        return Material(
          color: palette.card,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
          child: InkWell(
            onTap: () => _openSupplierProfile(supplier),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  UserAvatar(
                    avatarUrl: supplier.avatarUrl,
                    displayName: companyName,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          companyName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              context.l10n.getString('auto_postavshchik'),
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: palette.star,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              formatRating(rating),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: palette.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _isSupplierFavorite
                        ? context.l10n.getString('auto_udalitIzIzbrannogo')
                        : context.l10n.getString('auto_dobavitVIzbrannoe'),
                    onPressed: () => _toggleSupplierFavorite(supplier),
                    icon: Icon(
                      _isSupplierFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: palette.accent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Собирает короткий превью характеристик в одну строку через «·».
  // Берём первые 3-4 пары из всех непустых разделов.
  String _buildPreviewLines(List<CharacteristicSection> sections) {
    final parts = <String>[];
    outer:
    for (final section in sections) {
      for (final item in section.items) {
        if (item.key.isEmpty) {
          // Раздел «Состав»: значение само по себе достаточно информативно.
          parts.add(item.value);
        } else {
          parts.add('${item.key} — ${item.value}');
        }
        if (parts.length >= 4) break outer;
      }
    }
    return parts.join(' · ');
  }

  void _openAboutProductSheet() {
    final palette = context.colorPalette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.card,
      isScrollControlled: true,
      transitionAnimationController: smoothBottomSheetController(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          // Snap к initialChildSize - короткий свайп вниз возвращает к исходной высоте.
          initialChildSize: 0.94,
          minChildSize: 0.6,
          maxChildSize: 0.94,
          snap: true,
          snapSizes: const [0.94],
          builder: (context, scrollController) {
            return _AboutProductSheet(
              product: widget.product,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  void _toggleSupplierFavorite(Supplier supplier) {
    final added = _favoritesStore.toggleSupplier(supplier);
    setState(() {
      _isSupplierFavorite = added;
    });
    showTopMessage(
      context,
      added ? context.l10n.getString('auto_dobavlenoVIzbrannoe') : context.l10n.getString('auto_udalenoIzIzbrannogo'),
      backgroundColor: added ? _palette.accent : _palette.error,
    );
  }

  Widget _buildAvailabilitySection() {
    if (widget.product.suppliers.isEmpty) {
      return Container(
        color: _cardBg,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        child: Text(
          context.l10n.getString('auto_netVNalichii'),
          style: TextStyle(
            color: _palette.error,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final supplier = widget.product.suppliers.firstWhere(
      (s) => s.id == _selectedSupplierId,
      orElse: () => widget.product.bestSupplier,
    );
    final isAvailable = supplier.isAvailable;
    return Container(
      color: _cardBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.productPricePerUnit(supplier.pricePerUnit.toString()),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _palette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // Тот же оттенок, что у тегов категорий, чтобы плашки совпадали.
                  color: isAvailable
                      ? _palette.accentSoft
                      : _palette.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isAvailable
                      ? context.l10n.productInStock(supplier.stockQuantity)
                      : context.l10n.getString('auto_netVNalichii'),
                  style: TextStyle(
                    color: isAvailable ? _palette.accent : _palette.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Открывает страницу профиля поставщика.
  void _openSupplierProfile(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierProfilePage(
          supplierId: supplier.id,
          initialSupplier: supplier,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (widget.product.suppliers.isEmpty) {
      return const RoleInternalNavBar(currentIndex: null);
    }

    final supplier = widget.product.suppliers.firstWhere(
      (s) => s.id == _selectedSupplierId,
      orElse: () => widget.product.bestSupplier,
    );
    final quantity =
        _supplierQuantities[supplier.id] ??
        (supplier.isAvailable ? supplier.minQuantity : 0);
    final totalPrice = supplier.getTotalPrice(quantity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _showPersistentPriceBar,
          builder: (context, show, child) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 1, end: show ? 1 : 0),
              builder: (context, value, _) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: value,
                    child: IgnorePointer(
                      ignoring: value < 0.02,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 28),
                        child: Opacity(
                          opacity: value.clamp(0, 1),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _buildPriceBar(supplier, quantity, totalPrice),
            ),
          ),
        ),
        const RoleInternalNavBar(currentIndex: null),
      ],
    );
  }

  Widget _buildPriceBar(Supplier supplier, int quantity, int totalPrice) {
    final isAvailable = supplier.isAvailable;
    final isAdded = (_supplierAdded[supplier.id] ?? false) && isAvailable;
    const outOfStockButtonWidth = 164.0;
    const outOfStockButtonHeight = 57.0;
    final barColor = !isAvailable ? _palette.muted : _palette.accent;
    final accentColor = barColor;

    return ThumbZoneBuilder(
      child: Container(
        decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: barColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: !isAvailable
              ? null
              : () {
                  if (isAdded) {
                    _removeFromCart(supplier);
                  } else {
                    _addToCart(supplier);
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${supplier.pricePerUnit} \u20B8/\u0448\u0442',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable
                          ? '\u041c\u0438\u043d\u0438\u043c\u0443\u043c: ${supplier.minQuantity} \u0448\u0442.'
                          : '\u041d\u0435\u0442 \u0432 \u043d\u0430\u043b\u0438\u0447\u0438\u0438',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Center(
                    child: isAvailable
                        ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            switchOutCurve: const Interval(
                              0.0,
                              0.3,
                              curve: Curves.easeIn,
                            ),
                            switchInCurve: const Interval(
                              0.7,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.7,
                                    end: 1.0,
                                  ).animate(animation),
                                  child: RotationTransition(
                                    turns: Tween<double>(
                                      begin: -0.05,
                                      end: 0.0,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Icon(
                              isAdded ? Icons.close : Icons.check,
                              key: ValueKey<bool>(isAdded),
                              size: 20,
                              color: Colors.white,
                            ),
                          )
                        : const SizedBox(
                            width: outOfStockButtonWidth,
                            height: outOfStockButtonHeight,
                            child: Center(
                              child: Text(
                                '\u041d\u0435\u0442 \u0432 \u043d\u0430\u043b\u0438\u0447\u0438\u0438',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                if (isAvailable) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _HoldRepeatIconButton(
                          icon: Icons.remove,
                          onPressed: () => _updateQuantity(supplier.id, -1),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalPrice \u20B8',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$quantity \u0448\u0442.',
                              style: TextStyle(fontSize: 13, color: _mutedText),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        _HoldRepeatIconButton(
                          icon: Icons.add,
                          onPressed: () => _updateQuantity(supplier.id, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ));
  }

  List<T> _randomPreview<T>(List<T> source, int count) {
    if (source.length <= count) return source;
    final shuffled = List<T>.from(source)..shuffle();
    return shuffled.take(count).toList();
  }

  void _openReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsPage(
          product: widget.product,
          initialReviews: _productReviews,
        ),
      ),
    );
  }

  Widget _buildReviewsPreview() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }
    final preview = _randomPreview(_productReviews, 5);

    if (preview.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_outline,
        title: context.l10n.getString('auto_otzyvovPokaNet'),
        subtitle: context.l10n.getString('auto_otsenitTovarMozhnoTolk'),
      );
    }

    return ExpandablePageView.builder(
      controller: _reviewsPreviewController,
      itemCount: preview.length,
      padEnds: false,
      physics: const BouncingScrollPhysics(),
      animationDuration: const Duration(milliseconds: 300),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
          child: ReviewPreviewCard(
            review: preview[index],
            onOpenAll: _openReviews,
          ),
        );
      },
    );
  }

  Widget _buildQuestionsPreview() {
    if (_isLoadingQuestions) {
      return const Center(child: CircularProgressIndicator());
    }
    final preview = _randomPreview(_productQuestions, 3);

    if (preview.isEmpty) {
      return _buildEmptyState(
        icon: Icons.help_outline,
        title: context.l10n.getString('auto_voprosovPoTovaruEshche'),
        subtitle: context.l10n.getString('auto_budtePervym'),
        showButton: true,
        buttonText: context.l10n.getString('auto_zadatVopros'),
        onButtonPressed: _openAllQuestions,
      );
    }

    return ExpandablePageView.builder(
      controller: _questionsPreviewController,
      itemCount: preview.length,
      padEnds: false,
      physics: const BouncingScrollPhysics(),
      animationDuration: const Duration(milliseconds: 300),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
          child: QuestionPreviewCard(
            question: preview[index],
            onOpenAll: _openAllQuestions,
          ),
        );
      },
    );
  }

  Widget _buildStatsButtonsRow() {
    final palette = context.colorPalette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 12, 5, 8),
      child: Row(
        children: [
          _buildStatButton(
            onTap: _openReviews,
            icon: Icons.star_rounded,
            iconColor: palette.accent,
            value: widget.product.rating.toStringAsFixed(1),
            label: context.l10n.productReviewsLabel(_resolvedReviewCount),
          ),
          const SizedBox(width: 12),
          _buildStatButton(
            onTap: _openAllQuestions,
            icon: Icons.mode_comment_outlined,
            iconColor: palette.accent,
            value: '$_resolvedQuestionCount',
            label: context.l10n.getString('auto_voprosov'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    final palette = context.colorPalette;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: palette.accent, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: palette.muted,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showButton = false,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    final palette = context.colorPalette;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: palette.accentMist,
            child: Icon(icon, size: 40, color: palette.accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: palette.muted, height: 1.4),
            textAlign: TextAlign.center,
          ),
          if (showButton) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onButtonPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: palette.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonText!,
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openAllQuestions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionsPage(
          productId: widget.product.id,
          productName: widget.product.name,
          productImage: widget.product.imageUrls.isNotEmpty
              ? widget.product.imageUrls.first
              : '',
        ),
      ),
    );
    if (!mounted) return;
    // Пользователь мог задать вопрос - перезагружаем счётчик и превью.
    _loadProductQuestions();
  }

  Future<void> _shareProductStub() async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _shareStubUrl,
      subject: widget.product.name,
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    );
  }
}

/// Bottom sheet «О товаре»: заголовок с крестиком, табы «Характеристики»/«Описание»,
/// прокручиваемое содержимое. Содержимое табов переиспользуем: _CharacteristicsTab и _DescriptionTab.
class _AboutProductSheet extends StatefulWidget {
  const _AboutProductSheet({
    required this.product,
    required this.scrollController,
  });

  final Product product;
  final ScrollController scrollController;

  @override
  State<_AboutProductSheet> createState() => _AboutProductSheetState();
}

class _AboutProductSheetState extends State<_AboutProductSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // Ключи якорей: используются для скролла к секциям при тапе по табам.
  final GlobalKey _characteristicsKey = GlobalKey();
  final GlobalKey _descriptionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabTapped);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabTapped);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTapped() {
    if (!_tabController.indexIsChanging) return;
    final targetKey = _tabController.index == 0
        ? _characteristicsKey
        : _descriptionKey;
    final ctx = targetKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final sections = buildCharacteristicSections(widget.product);
    final description = widget.product.description;
    final hasContent = sections.isNotEmpty || description.trim().isNotEmpty;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppDimensions.minBottomSafePadding),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: palette.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.getString('auto_oTovare'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: palette.ink),
                tooltip: context.l10n.getString('auto_zakryt'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasContent)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: palette.accent,
              indicatorWeight: 3,
              labelColor: palette.ink,
              unselectedLabelColor: palette.muted,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: context.l10n.getString('auto_harakteristiki')),
                Tab(text: context.l10n.getString('auto_opisanie_1')),
              ],
            ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: !hasContent
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        context.l10n.getString('auto_netDannyhOTovare'),
                        style: TextStyle(fontSize: 14, color: palette.muted),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (sections.isNotEmpty) ...[
                          KeyedSubtree(
                            key: _characteristicsKey,
                            child: _CharacteristicsTab(sections: sections),
                          ),
                          const SizedBox(height: 24),
                        ] else
                          KeyedSubtree(
                            key: _characteristicsKey,
                            child: const SizedBox.shrink(),
                          ),
                        // Заголовок раздела «Описание» в общем потоке скролла,
                        // ниже всех характеристик.
                        Padding(
                          key: _descriptionKey,
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            context.l10n.getString('auto_opisanie_1'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        _DescriptionTab(description: description),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ));
  }
}

/// Содержимое таба «Характеристики»: вертикальный список разделов.
/// Каждый раздел - заголовок 16sp w600 и пары «название → значение»,
/// разделённые тонкой линией. Запись с пустым ключом (раздел «Состав»)
/// рендерится одной строкой во всю ширину.
class _CharacteristicsTab extends StatelessWidget {
  const _CharacteristicsTab({required this.sections});

  final List<CharacteristicSection> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          _CharacteristicSectionView(section: sections[i]),
          if (i != sections.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// Содержимое таба «Описание»: либо текст product.description без обрезки,
/// либо плейсхолдер «Описание не указано», если строка пуста или whitespace-only.
class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final isPlaceholder = shouldShowDescriptionPlaceholder(description);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isPlaceholder
          ? Text(
              context.l10n.getString('auto_opisanieNeUkazano'),
              style: TextStyle(fontSize: 14, color: palette.muted),
            )
          : Text(
              description,
              softWrap: true,
              style: TextStyle(fontSize: 14, color: palette.ink, height: 1.4),
            ),
    );
  }
}

/// Один раздел: заголовок и список пар.
class _CharacteristicSectionView extends StatelessWidget {
  const _CharacteristicSectionView({required this.section});

  final CharacteristicSection section;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final items = section.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            section.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
        ),
        for (var i = 0; i < items.length; i++) ...[
          _buildItem(palette, items[i]),
          if (i != items.length - 1)
            Divider(height: 1, thickness: 1, color: palette.line),
        ],
      ],
    );
  }

  Widget _buildItem(AppColorPalette palette, MapEntry<String, String> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              item.key,
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              item.value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewPreviewCard extends StatefulWidget {
  final ReviewEntry review;
  final VoidCallback onOpenAll;

  const ReviewPreviewCard({
    super.key,
    required this.review,
    required this.onOpenAll,
  });

  @override
  State<ReviewPreviewCard> createState() => _ReviewPreviewCardState();
}

class _ReviewPreviewCardState extends State<ReviewPreviewCard> {
  bool _isExpanded = false;

  String _reviewerName(ReviewEntry review) {
    final normalized = review.reviewerName.trim();
    if (normalized.isEmpty) {
      return context.l10n.getString('auto_pokupatel');
    }
    return normalized;
  }

  String _formatDate(DateTime value) {
    return DateFormatter.formatDate(value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final name = _reviewerName(widget.review);
    final text = widget.review.reviewText.trim().isEmpty
        ? context.l10n.getString('auto_bezTeksta')
        : widget.review.reviewText.trim();
    final dateStr = _formatDate(widget.review.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: widget.review.userAvatarUrl,
                displayName: name,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ),
              ),
              RatingStars(
                rating: widget.review.rating.toDouble(),
                size: 16,
                spacing: 2,
                filledColor: palette.star,
                emptyColor: palette.line,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: palette.ink,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (_hasLongText(text) && !_isExpanded)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = true),
              child: Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: Text(
                  context.l10n.getString('auto_podrobnee'),
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          if (!_isLongTextButCollapsed(text))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: widget.onOpenAll,
                child: Text(
                  context.l10n.getString('auto_pereytiKoVsemOtzyvam'),
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasLongText(String text) {
    return text.split('\n').length > 3 || text.length > 150;
  }

  bool _isLongTextButCollapsed(String text) {
    return _hasLongText(text) && !_isExpanded;
  }
}

class QuestionPreviewCard extends StatefulWidget {
  final Question question;
  final VoidCallback onOpenAll;

  const QuestionPreviewCard({
    super.key,
    required this.question,
    required this.onOpenAll,
  });

  @override
  State<QuestionPreviewCard> createState() => _QuestionPreviewCardState();
}

class _QuestionPreviewCardState extends State<QuestionPreviewCard> {
  bool _isExpanded = false;

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final name = widget.question.userName;
    final date = _formatDate(widget.question.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: widget.question.userAvatarUrl,
                displayName: name,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.question.questionText,
            style: TextStyle(
              fontSize: 15,
              color: palette.ink,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (_hasLongText(widget.question.questionText) && !_isExpanded)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = true),
              child: Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Text(
                  context.l10n.getString('auto_podrobnee'),
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          if (!_isLongTextButCollapsed(widget.question.questionText))
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: GestureDetector(
                onTap: widget.onOpenAll,
                child: Text(
                  context.l10n.getString('auto_pereytiKoVsemVoprosam'),
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasLongText(String text) {
    return text.split('\n').length > 3 || text.length > 150;
  }

  bool _isLongTextButCollapsed(String text) {
    return _hasLongText(text) && !_isExpanded;
  }
}

class _HoldRepeatIconButton extends StatefulWidget {
  const _HoldRepeatIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_HoldRepeatIconButton> createState() => _HoldRepeatIconButtonState();
}

class _HoldRepeatIconButtonState extends State<_HoldRepeatIconButton> {
  Timer? _repeatTimer;

  void _startRepeat() {
    if (widget.onPressed == null) return;
    widget.onPressed!();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted || widget.onPressed == null) {
        _stopRepeat();
        return;
      }
      widget.onPressed!();
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRepeat(),
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: IconButton(
        icon: Icon(widget.icon, size: 18),
        onPressed: widget.onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

/// Кнопка «вверх» без Material/Hero/elevation - стандартный FAB лагал
/// при появлении/исчезновении на скролле.
class _ScrollTopButton extends StatelessWidget {
  const _ScrollTopButton({super.key, required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2, bottom: 8),
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
