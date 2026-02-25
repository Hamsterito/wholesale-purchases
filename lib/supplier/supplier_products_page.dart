import 'package:flutter/material.dart';
import '../models/supplier_product.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../utils/auto_refresh.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/smart_image.dart';
import 'supplier_product_wizard.dart';

class SupplierProductsPage extends StatefulWidget {
  const SupplierProductsPage({super.key});

  @override
  State<SupplierProductsPage> createState() => _SupplierProductsPageState();
}

class _SupplierProductsPageState extends State<SupplierProductsPage>
    with AutoRefreshMixin<SupplierProductsPage> {
  List<SupplierProduct> _products = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  final Set<String> _deletingIds = <String>{};
  String? _error;

  int? get _userId => AuthStorage.userId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    startAutoRefresh();
  }

  Future<void> _loadProducts({bool showLoading = true}) async {
    final userId = _userId;
    if (userId == null || userId == 0) {
      setState(() {
        _error = 'Вы не авторизованы. Пожалуйста, войдите.';
        _isLoading = false;
      });
      return;
    }
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final products = await ApiService.getSupplierProducts(userId: userId);
      if (!mounted) return;
      setState(() {
        _products = products;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!showLoading) return;
      setState(() {
        _error = 'Не удалось загрузить товары';
      });
    }

    if (!mounted || !showLoading) return;
    setState(() => _isLoading = false);
  }

  Future<void> _openProductWizard({SupplierProduct? product}) async {
    final userId = _userId;
    if (userId == null || userId == 0) {
      _showSnack('Требуется авторизация');
      return;
    }

    final result = await Navigator.push<SupplierProduct>(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierProductWizardPage(product: product),
      ),
    );

    if (result == null) return;

    setState(() => _isSubmitting = true);
    try {
      if (product == null) {
        await ApiService.createSupplierProduct(product: result, userId: userId);
        _showSnack('Товар отправлен на модерацию');
      } else {
        await ApiService.updateSupplierProduct(product: result, userId: userId);
        _showSnack('Изменения отправлены на модерацию');
      }
      await _loadProducts();
    } catch (e) {
      _showSnack(_extractErrorMessage(e, fallback: 'Ошибка операции'));
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  Future<void> _deleteProduct(SupplierProduct product) async {
    final userId = _userId;
    if (userId == null || userId == 0) {
      _showSnack('Требуется авторизация');
      return;
    }
    if (_deletingIds.contains(product.id)) {
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить товар?'),
          content: Text('Товар "${product.name}" будет удалён безвозвратно.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (approved != true || !mounted) {
      return;
    }

    setState(() {
      _deletingIds.add(product.id);
    });

    try {
      await ApiService.deleteSupplierProduct(
        productId: product.id,
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _products.removeWhere((item) => item.id == product.id);
      });
      _showSnack('Товар удалён');
    } catch (_) {
      _showSnack('Не удалось удалить товар');
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(product.id);
        });
      }
    }
  }

  String _extractErrorMessage(Object error, {required String fallback}) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return fallback;
    }

    const exceptionPrefix = 'Exception:';
    final normalized = raw.startsWith(exceptionPrefix)
        ? raw.substring(exceptionPrefix.length).trim()
        : raw;
    if (normalized.isEmpty) {
      return fallback;
    }

    return normalized;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Одобрен';
      case 'rejected':
        return 'Отклонён';
      default:
        return 'На проверке';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.error_outline_rounded;
      default:
        return Icons.hourglass_bottom_rounded;
    }
  }

  Widget _buildProductCard(
    SupplierProduct product, {
    required bool isDeleting,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(product.moderationStatus);
    final imagePath = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : '';
    final stockQuantityLabel = '${product.stockQuantity} шт.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmartImage(
                  path: imagePath,
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(16),
                  placeholder: Container(
                    color: colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name.isEmpty ? 'Без названия' : product.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _BadgeChip(
                            label: _statusLabel(product.moderationStatus),
                            icon: _statusIcon(product.moderationStatus),
                            foregroundColor: statusColor,
                            backgroundColor: statusColor.withValues(
                              alpha: 0.12,
                            ),
                            borderColor: statusColor.withValues(alpha: 0.3),
                          ),
                          if (product.categories.isNotEmpty)
                            _BadgeChip(
                              label: product.categories.first,
                              icon: Icons.sell_outlined,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description.isEmpty
                            ? 'Описание пока не добавлено'
                            : product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.payments_outlined,
                    label: 'Цена',
                    value: '${product.pricePerUnit} \u20B8',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Мин. партия',
                    value: '${product.minQuantity} шт.',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.all_inbox_outlined,
                    label: 'Остаток',
                    value: stockQuantityLabel,
                  ),
                ),
              ],
            ),
            if (product.categories.length > 1) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.categories
                    .skip(1)
                    .take(3)
                    .map((category) => _BadgeChip(label: category))
                    .toList(),
              ),
            ],
            if (product.moderationComment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.38),
                    width: 1.15,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      product.moderationStatus == 'rejected'
                          ? Icons.report_problem_outlined
                          : Icons.info_outline_rounded,
                      size: 18,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.moderationComment,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting || isDeleting
                        ? null
                        : () => _openProductWizard(product: product),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Редактировать'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isSubmitting || isDeleting
                        ? null
                        : () => _deleteProduct(product),
                    icon: isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(isDeleting ? 'Удаление...' : 'Удалить'),
                    style: FilledButton.styleFrom(
                      foregroundColor: const Color(0xFFB91C1C),
                      backgroundColor: const Color(
                        0xFFEF4444,
                      ).withValues(alpha: 0.15),
                      disabledForegroundColor: colorScheme.onSurfaceVariant,
                      disabledBackgroundColor:
                          colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> onAutoRefresh() async {
    if (_isLoading || _isSubmitting || _deletingIds.isNotEmpty) return;
    await _loadProducts(showLoading: false);
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои товары'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: _products.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 42,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Пока нет товаров',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавьте первый товар и отправьте его на модерацию.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _openProductWizard(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Добавить товар'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      itemCount: _products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final isDeleting = _deletingIds.contains(product.id);

                        return _buildProductCard(
                          product,
                          isDeleting: isDeleting,
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting || _deletingIds.isNotEmpty
            ? null
            : () => _openProductWizard(),
        tooltip: 'Добавить товар',
        backgroundColor: const Color(0xFF6288D5),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 7),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: foregroundColor ?? colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor ?? colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
