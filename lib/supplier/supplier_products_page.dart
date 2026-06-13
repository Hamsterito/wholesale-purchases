import 'package:flutter/material.dart';
import '../models/supplier_product.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../theme/app_color_palette.dart';
import '../utils/auto_refresh.dart';
import '../widgets/smart_image.dart';
import '../widgets/messages/top_message.dart';
import 'supplier_product_wizard.dart';
import 'supplier_qa_page.dart';

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
  final Set<String> _expandedDescriptionIds = <String>{};
  String? _error;

  int? get _userId => AuthStorage.userId;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

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
        _error = context.l10n.unauthorizedError;
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
        _error = context.l10n.failedToLoadProducts;
      });
    }

    if (!mounted || !showLoading) return;
    setState(() => _isLoading = false);
  }

  Future<void> _openProductWizard({SupplierProduct? product}) async {
    final userId = _userId;
    if (userId == null || userId == 0) {
      _showSnack(context.l10n.loginRequired, isError: true);
      return;
    }

    final result = await Navigator.push<SupplierProduct>(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierProductWizardPage(product: product),
      ),
    );

    if (result == null) return;

    if (!mounted) return;
    setState(() => _isSubmitting = true);
    try {
      if (product == null) {
        await ApiService.createSupplierProduct(product: result, userId: userId);
        if (!mounted) return;
        _showSnack(context.l10n.productSentForModeration);
      } else {
        await ApiService.updateSupplierProduct(product: result, userId: userId);
        if (!mounted) return;
        _showSnack(context.l10n.productChangesSentForModeration);
      }
      await _loadProducts();
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        _extractErrorMessage(e, fallback: context.l10n.getString('auto_oshibkaOperatsii')),
        isError: true,
      );
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  Future<void> _deleteProduct(SupplierProduct product) async {
    final userId = _userId;
    if (userId == null || userId == 0) {
      _showSnack(context.l10n.getString('auto_trebuetsyaAvtorizatsiya'), isError: true);
      return;
    }
    if (_deletingIds.contains(product.id)) {
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(context.l10n.deleteProduct),
          content: Text(
            '${context.l10n.product} "${product.name}" ${context.l10n.delete.toLowerCase()}. '
            '${l10n.deleteProductConfirm}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColorPalette.of(context).error,
              ),
              child: Text(context.l10n.delete),
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
      final deleteResult = await ApiService.deleteSupplierProduct(
        productId: product.id,
        userId: userId,
      );
      if (!mounted) return;

      final action = deleteResult['action'] as String?;
      final hiddenMessage = deleteResult['hiddenMessage'] as String?;

      setState(() {
        if (action == 'hidden_from_catalog') {
          _products = _products.map((item) {
            if (item.id != product.id) {
              return item;
            }
            return item.copyWith(
              moderationStatus: 'rejected',
              moderationComment: hiddenMessage?.isNotEmpty == true
                  ? hiddenMessage
                  : context.l10n.getString('auto_tovarSnyatSPublikatsii'),
              stockQuantity: 0,
            );
          }).toList();
          return;
        }

        _products.removeWhere((item) => item.id == product.id);
      });

      if (action == 'hidden_from_catalog') {
        _showSnack(
          hiddenMessage?.isNotEmpty == true
              ? hiddenMessage!
              : context.l10n.getString('auto_tovarSnyatSPublikatsii_1'),
        );
      } else {
        _showSnack(context.l10n.getString('auto_tovarUdalyon'));
      }
    } catch (e) {
      _showSnack(
        _extractErrorMessage(e, fallback: context.l10n.couldNotDeleteProduct),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(product.id);
        });
      }
    }
  }

  void _navigateToQA(SupplierProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierQAPage(productIdFilter: product.id),
      ),
    );
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

  void _showSnack(String message, {bool isError = false}) {
    final palette = context.colorPalette;
    showTopMessage(
      context,
      message,
      backgroundColor: isError ? palette.error : palette.accent,
    );
  }

  Color _statusColor(String status) {
    final palette = AppColorPalette.of(context);
    switch (status) {
      case 'approved':
        return palette.success;
      case 'rejected':
        return palette.error;
      default:
        return palette.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return context.l10n.approved;
      case 'rejected':
        return context.l10n.rejected;
      default:
        return context.l10n.pending;
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

  bool _isDescriptionExpanded(String productId) {
    return _expandedDescriptionIds.contains(productId);
  }

  void _toggleDescription(String productId) {
    setState(() {
      if (_expandedDescriptionIds.contains(productId)) {
        _expandedDescriptionIds.remove(productId);
      } else {
        _expandedDescriptionIds.add(productId);
      }
    });
  }

  Widget _buildProductCard(
    SupplierProduct product, {
    required bool isDeleting,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppColorPalette.of(context);
    final statusColor = _statusColor(product.moderationStatus);
    final imagePath = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : '';
    final stockQuantityLabel = '${product.stockQuantity} шт.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
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
                  width: 96,
                  height: 108,
                  borderRadius: BorderRadius.circular(18),
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
                      const SizedBox(),
                      Row(
                        children: [
Expanded(
                          child: Text(
                            product.name.isEmpty
                                    ? context.l10n.noTitle
                                    : product.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: _isSubmitting || isDeleting
                                ? null
                                : () => _deleteProduct(product),
                            icon: isDeleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 22,
                                  ),
                            color: palette.error,
                            iconSize: 16,
                            constraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _ExpandableDescription(
                        text: product.description.isEmpty
                            ? context.l10n.noDescription
                            : product.description,
                        isExpanded: _isDescriptionExpanded(product.id),
                        onToggle: () => _toggleDescription(product.id),
                        textColor: colorScheme.onSurfaceVariant,
                        actionColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BadgeChip(
                  label: _statusLabel(product.moderationStatus),
                  icon: _statusIcon(product.moderationStatus),
                  foregroundColor: statusColor,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  borderColor: statusColor.withValues(alpha: 0.3),
                ),
                ...product.categories.map(
                  (category) =>
                      _BadgeChip(label: category, icon: Icons.sell_outlined),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.payments_outlined,
                    label: context.l10n.getString('auto_tsena'),
                    value: '${product.pricePerUnit} \u20B8',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.inventory_2_outlined,
                    label: context.l10n.getString('auto_minPartiya'),
                    value: '${product.minQuantity} шт.',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.all_inbox_outlined,
                    label: context.l10n.getString('auto_ostatok'),
                    value: stockQuantityLabel,
                  ),
                ),
              ],
            ),

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
                    label: Text(context.l10n.edit),
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
                  child: FilledButton.icon(
                    onPressed: _isSubmitting || isDeleting
                        ? null
                        : () => _navigateToQA(product),
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Q&A'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isDark
                          ? palette.accentMist
                          : palette.accent,
                      foregroundColor: Colors.white,
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
      appBar: AppBar(title: Text(context.l10n.myProducts)),
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
                        Text(
                          context.l10n.getString('auto_pokaNetTovarov'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.getString('auto_dobavtePervyyTovarIOt'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _openProductWizard(),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.l10n.add),
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
        tooltip: context.l10n.getString('auto_dobavitTovar'),
        backgroundColor: _isDark
            ? AppColorPalette.of(context).accentMist
            : AppColorPalette.of(context).accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

class _ExpandableDescription extends StatelessWidget {
  const _ExpandableDescription({
    required this.text,
    required this.isExpanded,
    required this.onToggle,
    required this.textColor,
    required this.actionColor,
  });

  static const int _collapsedMaxLines = 3;

  final String text;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Color textColor;
  final Color actionColor;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: textColor, height: 1.35);
    final actionStyle = TextStyle(
      color: actionColor,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final direction = Directionality.of(context);

        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: direction,
          maxLines: _collapsedMaxLines,
        )..layout(maxWidth: maxWidth);
        final hasOverflow = textPainter.didExceedMaxLines;

        // Резервируем высоту 3 строк, чтобы теги ниже не подскакивали при коротком описании.
        final lineHeightPainter = TextPainter(
          text: TextSpan(text: 'Ag', style: style),
          textDirection: direction,
        )..layout();
        final reservedTextHeight =
            lineHeightPainter.height * _collapsedMaxLines;

final actionPainter = TextPainter(
           text: TextSpan(text: context.l10n.moreLabel, style: actionStyle),
           textDirection: direction,
         )..layout();
         final actionHeight = actionPainter.height;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: isExpanded ? 0 : reservedTextHeight,
                ),
                child: Text(
                  text,
                  maxLines: isExpanded ? null : _collapsedMaxLines,
                  overflow: isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.clip,
                  style: style,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Слот фиксированной высоты: кнопка «Подробнее» либо пустота той же высоты.
            SizedBox(
              height: actionHeight,
              child: hasOverflow
                  ? GestureDetector(
                      onTap: onToggle,
                      child: Text(
                        isExpanded ? context.l10n.lessLabel : context.l10n.moreLabel,
                        style: actionStyle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
