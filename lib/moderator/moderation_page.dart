import 'package:flutter/material.dart';
import '../models/supplier_product.dart';
import 'support_chats_page.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/smart_image.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  List<SupplierProduct> _products = [];
  String _statusFilter = 'pending';
  bool _isLoading = true;
  String? _error;
  final Set<String> _updatingIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await ApiService.getModerationProducts(
        status: _statusFilter,
      );
      if (!mounted) return;
      setState(() => _products = products);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось загрузить товары');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Одобрено';
      case 'rejected':
        return 'Отклонено';
      default:
        return 'На модерации';
    }
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

  Future<void> _updateStatus(SupplierProduct product, String status) async {
    final requireComment = status == 'rejected';
    final comment = await _askComment(
      title: status == 'approved' ? 'Одобрить товар' : 'Отклонить товар',
      requireComment: requireComment,
    );

    if (!mounted) {
      return;
    }

    if (comment == null) {
      return;
    }

    final normalizedComment = comment.trim().isEmpty ? null : comment.trim();

    setState(() => _updatingIds.add(product.id));
    try {
      await ApiService.updateModerationStatus(
        productId: product.id,
        status: status,
        comment: normalizedComment,
      );
      await _loadProducts();
      _showSnack(status == 'approved' ? 'Товар одобрен' : 'Товар отклонен');
    } catch (e) {
      _showSnack(
        _extractErrorMessage(
          e,
          fallback: 'Ошибка при обновлении статуса',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingIds.remove(product.id));
      }
    }
  }

  Future<void> _deleteProductForViolation(SupplierProduct product) async {
    final moderatorId = AuthStorage.userId ?? 0;
    if (moderatorId <= 0) {
      _showSnack('Не удалось определить модератора');
      return;
    }
    if (_updatingIds.contains(product.id)) {
      return;
    }

    final reason = await _askComment(
      title: 'Удалить товар за нарушение',
      requireComment: true,
      hintText: 'Причина удаления для поставщика',
      submitLabel: 'Удалить',
    );
    if (!mounted || reason == null) {
      return;
    }

    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      return;
    }

    setState(() => _updatingIds.add(product.id));
    try {
      final result = await ApiService.deleteModerationProduct(
        productId: product.id,
        moderatorId: moderatorId,
        reason: normalizedReason,
      );
      await _loadProducts();
      final action = result['action']?.toString() ?? '';
      final supplierNotified = result['supplierNotified'] == true;
      if (action == 'hidden_from_catalog') {
        _showSnack(
          supplierNotified
              ? 'Товар снят с публикации, поставщик уведомлен'
              : 'Товар снят с публикации',
        );
      } else {
        _showSnack(
          supplierNotified ? 'Товар удален, поставщик уведомлен' : 'Товар удален',
        );
      }
    } catch (e) {
      _showSnack(
        _extractErrorMessage(e, fallback: 'Не удалось удалить товар'),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingIds.remove(product.id));
      }
    }
  }

  Future<String?> _askComment({
    required String title,
    required bool requireComment,
    String? hintText,
    String submitLabel = 'Отправить',
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final hint =
            hintText ??
            (requireComment ? 'Причина отклонения' : 'Комментарий');
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final draft = controller.text.trim();
            final canSubmit = !requireComment || draft.isNotEmpty;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Text(title),
              content: SizedBox(
                width: 320,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 3,
                  maxLines: 5,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.86,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.32,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.95,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: canSubmit
                      ? () => Navigator.of(dialogContext).pop(draft)
                      : null,
                  child: Text(submitLabel),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return result;
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

    return normalized.isEmpty ? fallback : normalized;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _quantityLabel(SupplierProduct product) {
    final maxQuantity = product.maxQuantity;
    if (maxQuantity == null || maxQuantity <= product.minQuantity) {
      return 'от ${product.minQuantity} шт.';
    }
    return '${product.minQuantity}-$maxQuantity шт.';
  }

  String _categoriesLabel(SupplierProduct product) {
    if (product.categories.isEmpty) {
      return 'Без категории';
    }
    final preview = product.categories.take(2).join(', ');
    final hidden = product.categories.length - 2;
    if (hidden <= 0) {
      return preview;
    }
    return '$preview +$hidden';
  }

  List<String> _searchTokens(String query) {
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
  }

  bool _matchesSearch(SupplierProduct product, List<String> tokens) {
    if (tokens.isEmpty) {
      return true;
    }

    final haystack = [
      product.name,
      product.description,
      product.supplierName,
      product.moderationComment,
      product.categories.join(' '),
      product.deliveryBadge,
      product.deliveryDate,
    ].join(' ').toLowerCase();

    return tokens.every((token) => haystack.contains(token));
  }

  List<SupplierProduct> _applySearch(List<SupplierProduct> products) {
    final tokens = _searchTokens(_searchQuery);
    if (tokens.isEmpty) {
      return products;
    }
    return products
        .where((product) => _matchesSearch(product, tokens))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleProducts = _applySearch(_products);
    final hasSearchQuery = _searchQuery.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Модерация'),
        actions: [
          IconButton(
            tooltip: 'Чаты техподдержки',
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ModeratorSupportChatsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
              children: [
                _StatusChip(
                  label: 'На проверке',
                  isActive: _statusFilter == 'pending',
                  onTap: () {
                    setState(() => _statusFilter = 'pending');
                    _loadProducts();
                  },
                ),
                _StatusChip(
                  label: 'Одобрено',
                  isActive: _statusFilter == 'approved',
                  onTap: () {
                    setState(() => _statusFilter = 'approved');
                    _loadProducts();
                  },
                ),
                _StatusChip(
                  label: 'Отклонено',
                  isActive: _statusFilter == 'rejected',
                  onTap: () {
                    setState(() => _statusFilter = 'rejected');
                    _loadProducts();
                  },
                ),
                _StatusChip(
                  label: 'Все',
                  isActive: _statusFilter == 'all',
                  onTap: () {
                    setState(() => _statusFilter = 'all');
                    _loadProducts();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.9),
                ),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Поиск: товар, поставщик, категория',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.88),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  suffixIcon: _searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Очистить',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: _products.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('Нет заявок')),
                            ],
                          )
                        : visibleProducts.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Text(
                                  hasSearchQuery
                                      ? 'По вашему запросу ничего не найдено'
                                      : 'Нет подходящих товаров',
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                            itemCount: visibleProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final product = visibleProducts[index];
                              final statusColor = _statusColor(
                                product.moderationStatus,
                              );
                              final isUpdating = _updatingIds.contains(
                                product.id,
                              );
                              final statusLabel = _statusLabel(
                                product.moderationStatus,
                              );
                              final showImage =
                                  product.imageUrls.isNotEmpty &&
                                  product.imageUrls.first.trim().isNotEmpty;
                              final statusChip = DecoratedBox(
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                              return Card(
                                margin: const EdgeInsets.only(top: 1),
                                elevation: 0,
                                shadowColor: colorScheme.shadow.withValues(
                                  alpha: 0.08,
                                ),
                                color: colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (showImage) ...[
                                            SmartImage(
                                              path: product.imageUrls.first,
                                              width: 72,
                                              height: 72,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          Expanded(
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                final isCompact =
                                                    constraints.maxWidth < 230;
                                                final title = Text(
                                                  product.name,
                                                  maxLines: isCompact ? 2 : 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                );

                                                if (isCompact) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      title,
                                                      const SizedBox(height: 8),
                                                      statusChip,
                                                    ],
                                                  );
                                                }

                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(child: title),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Flexible(
                                                          child: Align(
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child: statusChip,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (product.description
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          product.description.trim(),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _ModerationInfoPill(
                                            icon: Icons.storefront_outlined,
                                            text: product.supplierName,
                                          ),
                                          _ModerationInfoPill(
                                            icon: Icons.category_outlined,
                                            text: _categoriesLabel(product),
                                          ),
                                          _ModerationInfoPill(
                                            icon: Icons.inventory_2_outlined,
                                            text:
                                                'Остаток: ${product.stockQuantity} шт.',
                                          ),
                                          if (product.deliveryBadge
                                              .trim()
                                              .isNotEmpty)
                                            _ModerationInfoPill(
                                              icon:
                                                  Icons.local_shipping_outlined,
                                              text: product.deliveryBadge
                                                  .trim(),
                                            )
                                          else if (product.deliveryDate
                                              .trim()
                                              .isNotEmpty)
                                            _ModerationInfoPill(
                                              icon: Icons.schedule_outlined,
                                              text: product.deliveryDate.trim(),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            _ModerationMetricRow(
                                              label: 'Цена',
                                              value:
                                                  '${product.pricePerUnit} ₸ за единицу',
                                            ),
                                            const SizedBox(height: 8),
                                            _ModerationMetricRow(
                                              label: 'Партия',
                                              value: _quantityLabel(product),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (product.moderationComment.isNotEmpty)
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.09,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: statusColor.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            'Комментарий модерации: ${product.moderationComment}',
                                            style: TextStyle(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isCompact =
                                              constraints.maxWidth < 320;
                                          final deleteButton =
                                              OutlinedButton.icon(
                                                onPressed: isUpdating
                                                    ? null
                                                    : () =>
                                                          _deleteProductForViolation(
                                                            product,
                                                          ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFFB91C1C,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                ),
                                                icon: isUpdating
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      )
                                                    : const Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        size: 18,
                                                      ),
                                                label: const Text(
                                                  'Удалить за нарушение',
                                                ),
                                              );

                                          if (product.moderationStatus !=
                                              'pending') {
                                            return SizedBox(
                                              width: double.infinity,
                                              child: deleteButton,
                                            );
                                          }

                                          final approveButton =
                                              ElevatedButton.icon(
                                                onPressed: isUpdating
                                                    ? null
                                                    : () => _updateStatus(
                                                        product,
                                                        'approved',
                                                      ),
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 18,
                                                ),
                                                label: const Text('Одобрить'),
                                              );
                                          final rejectButton =
                                              OutlinedButton.icon(
                                                onPressed: isUpdating
                                                    ? null
                                                    : () => _updateStatus(
                                                        product,
                                                        'rejected',
                                                      ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFFEF4444,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.highlight_off,
                                                  size: 18,
                                                ),
                                                label: const Text('Отклонить'),
                                              );

                                          if (isCompact) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                approveButton,
                                                const SizedBox(height: 8),
                                                rejectButton,
                                                const SizedBox(height: 8),
                                                deleteButton,
                                              ],
                                            );
                                          }

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(child: approveButton),
                                                  const SizedBox(width: 12),
                                                  Expanded(child: rejectButton),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              deleteButton,
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isActive
        ? colorScheme.primary.withValues(alpha: 0.28)
        : colorScheme.outlineVariant;
    final backgroundColor = isActive
        ? colorScheme.primary.withValues(alpha: 0.15)
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModerationInfoPill extends StatelessWidget {
  const _ModerationInfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModerationMetricRow extends StatelessWidget {
  const _ModerationMetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

