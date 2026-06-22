import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../pages/product_detail_page.dart';
import '../pages/supplier_profile_page.dart';
import '../services/store/favorites_store.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../theme/app_color_palette.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../widgets/product/product_card.dart';
import '../widgets/profile/supplier_card_favorites.dart';

/// Страница избранного с двумя вкладками: товары и компании.
/// Реактивно обновляется при любых изменениях FavoritesStore.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: palette.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: theme.brightness == Brightness.dark ? Brightness.dark : Brightness.light,
        ),
        shape: Border(bottom: BorderSide(color: palette.line)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: palette.ink),
          onPressed: () => Navigator.pop(context),
          tooltip: context.l10n.getString('auto_nazad'),
        ),
        title: Text(
          context.l10n.getString('auto_izbrannoe'),
          style: TextStyle(
            color: palette.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        // TabBar встроен в AppBar для правильного порядка навигации
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: palette.accent,
          labelColor: palette.ink,
          unselectedLabelColor: palette.muted,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              child: Semantics(
                label: context.l10n.getString('auto_vkladkaIzbrannyeTovary'),
                child: Text(context.l10n.favoritesTabProducts),
              ),
            ),
            Tab(
              child: Semantics(
                label: context.l10n.getString('auto_vkladkaIzbrannyeKompani'),
                child: Text(context.l10n.favoritesTabCompanies),
              ),
            ),
          ],
        ),
      ),
      // AnimatedBuilder слушает FavoritesStore - обе вкладки обновляются
      // при любом изменении (добавление/удаление товара или компании)
      body: AnimatedBuilder(
        animation: FavoritesStore.instance,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _ProductsTab(palette: palette),
              _SuppliersTab(palette: palette),
            ],
          );
        },
      ),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }
}

/// Вкладка с избранными товарами.
class _ProductsTab extends StatelessWidget {
  final AppColorPalette palette;

  const _ProductsTab({required this.palette});

  @override
  Widget build(BuildContext context) {
    final allItems = FavoritesStore.instance.items;
    final items = allItems.where((p) => p.isAvailable).toList();

    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.favorite_border,
        message: context.l10n.getString('auto_pokaNetIzbrannyhTovaro'),
        palette: palette,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 338,
        crossAxisSpacing: 15,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return ProductCard(
          product: product,
          onTap: () => _openProduct(context, product, items),
          onAddToCart: () {},
          showMessages: true,
          showFavoritesUndo: true,
        );
      },
    );
  }

  void _openProduct(
    BuildContext context,
    Product product,
    List<Product> items,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          similarProducts: items.where((p) => p.id != product.id).toList(),
        ),
      ),
    );
  }
}

/// Вкладка с избранными компаниями.
class _SuppliersTab extends StatelessWidget {
  final AppColorPalette palette;

  const _SuppliersTab({required this.palette});

  @override
  Widget build(BuildContext context) {
    final suppliers = FavoritesStore.instance.suppliers;

    // Пустое состояние - список не рендерится вообще
    if (suppliers.isEmpty) {
      return _EmptyState(
        icon: Icons.business_outlined,
        message: context.l10n.getString('auto_netIzbrannyhKompaniy'),
        palette: palette,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SupplierCardFavorites(
              supplier: supplier,
              onTap: () => _openSupplierProfile(context, supplier),
              onRemove: () =>
                  FavoritesStore.instance.removeSupplier(supplier.id),
            ),
          ),
        );
      },
    );
  }

  void _openSupplierProfile(BuildContext context, Supplier supplier) {
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
}

/// Универсальное пустое состояние для обеих вкладок.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final AppColorPalette palette;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: palette.muted),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: palette.muted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
