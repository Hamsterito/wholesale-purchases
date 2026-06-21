import 'package:flutter_project/services/localization/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_color_palette.dart';
import '../models/message.dart';
import '../models/supplier_product.dart';
import '../utils/characteristic_sections.dart';
import '../utils/delivery_schedule.dart';
import '../widgets/moderator/about_product_sheet.dart';
import '../widgets/moderator/moderator_empty_state.dart';
import '../services/message/message_localization.dart';
import 'support_chats_page.dart';
import 'suppliers_directory_page.dart';
import '../services/api/api_service.dart';
import '../services/localization/localization_extension.dart';
import '../services/notification_service.dart';
import '../services/storage/auth_storage.dart';
import '../widgets/expandable_text_block.dart';
import '../widgets/smart_image.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  static final RegExp _whitespaceRegExp = RegExp(r'\s+');

  List<SupplierProduct> _products = [];
  String _statusFilter = 'pending';
  bool _isLoading = true;
  String? _error;
  final Set<String> _updatingIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    NotificationService().markAllModerationsAsViewed();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
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
      setState(() => _error = AppLocalizations.current.getString('auto_ne_udalos_zagruzit_tovary'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return AppLocalizations.current.getString('auto_odobreno');
      case 'rejected':
        return AppLocalizations.current.getString('auto_otkloneno');
      default:
        return AppLocalizations.current.getString('auto_na_moderatsii');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return context.colorPalette.success;
      case 'rejected':
        return context.colorPalette.error;
      default:
        return context.colorPalette.warning;
    }
  }

  Future<void> _updateStatus(SupplierProduct product, String status) async {
    final requireComment = status == 'rejected';
    final comment = await _askComment(
      title: status == 'approved' ? AppLocalizations.current.getString('auto_odobrit_tovar') : AppLocalizations.current.getString('auto_otklonit_tovar'),
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
      if (!mounted) return;
      await _loadProducts();
      if (!mounted) return;
      _showSnack(status == 'approved' ? AppLocalizations.current.getString('auto_tovar_odobren') : AppLocalizations.current.getString('auto_tovar_otklonen'));
    } catch (e) {
      _showSnack(
        _extractErrorMessage(e, fallback: AppLocalizations.current.getString('auto_oshibka_pri_obnovlenii_statusa')),
        severity: MessageSeverity.error,
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
      _showSnack(
        AppLocalizations.current.getString('auto_ne_udalos_opredelit_moderatora'),
        severity: MessageSeverity.error,
      );
      return;
    }
    if (_updatingIds.contains(product.id)) {
      return;
    }

    final reason = await _askComment(
      title: AppLocalizations.current.getString('auto_udalit_tovar_za_narushenie'),
      requireComment: true,
      hintText: AppLocalizations.current.getString('auto_prichina_udaleniya_dlya_postavschik'),
      submitLabel: AppLocalizations.current.getString('auto_udalit'),
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
      if (!mounted) return;
      await _loadProducts();
      if (!mounted) return;
      final supplierNotified = result['supplierNotified'] == true;
      _showSnack(
        supplierNotified
            ? AppLocalizations.current.getString('auto_tovar_udalen_postavschik_uvedomlen')
            : AppLocalizations.current.getString('auto_tovar_udalen'),
      );
    } catch (e) {
      _showSnack(
        _extractErrorMessage(e, fallback: AppLocalizations.current.getString('auto_ne_udalos_udalit_tovar')),
        severity: MessageSeverity.error,
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
    String? submitLabel,
  }) async {
    final effectiveSubmitLabel = submitLabel ?? AppLocalizations.current.getString('auto_otpravit');
    var draft = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final hint =
            hintText ?? (requireComment ? AppLocalizations.current.getString('auto_prichina_otkloneniya') : AppLocalizations.current.getString('auto_kommentariy'));
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final normalizedDraft = draft.trim();
            final canSubmit = !requireComment || normalizedDraft.isNotEmpty;
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
                  autofocus: true,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 3,
                  maxLines: 5,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (value) {
                    draft = value;
                    setDialogState(() {});
                  },
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
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
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
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: canSubmit
                      ? () => Navigator.of(dialogContext).pop(normalizedDraft)
                      : null,
                  child: Text(effectiveSubmitLabel),
                ),
              ],
            );
          },
        );
      },
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

    return normalized.isEmpty ? fallback : normalized;
  }

  void _showSnack(
    String message, {
    MessageSeverity severity = MessageSeverity.info,
  }) {
    if (!mounted) return;
    final msg = Message(
      id: const Uuid().v4(),
      type: MessageType.notification,
      severity: severity,
      title: '',
      body: message,
      timestamp: DateTime.now(),
      language: MessageLocalizationManager.getCurrentLanguage(),
    );
    AppMessageSnackBar.show(context, msg);
  }

  String _quantityLabel(SupplierProduct product) {
    final maxQuantity = product.maxQuantity;
    if (maxQuantity == null || maxQuantity <= product.minQuantity) {
      return context.l10n.moderationFromMinQty(product.minQuantity);
    }
    return context.l10n.moderationQtyRange(product.minQuantity, maxQuantity);
  }

  // schedule:Пн,Вт,Пт 14:00 → «Пн, Вт, Пт · 14:00», legacy-строки отдаем как есть.
  String _deliveryDisplay(SupplierProduct product) {
    final raw = product.deliveryBadge.trim().isNotEmpty
        ? product.deliveryBadge.trim()
        : product.deliveryDate.trim();
    if (raw.isEmpty) return '';
    final schedule = DeliverySchedule.decode(raw);
    if (schedule == null) return raw;
    final summary = formatScheduleSummary(schedule);
    final time = formatDeliveryTimeShort(schedule);
    if (time == null || time.isEmpty) return summary;
    return context.l10n.moderationSummaryTime(summary, time);
  }

  void _openAboutSheet(SupplierProduct product) {
    showAboutProductSheet(
      context: context,
      sections: buildSupplierProductSections(product, context),
      description: product.description,
      supplierProduct: product,
    );
  }

  // Каждая категория - свой чип. Иконка только у первого, чтобы лента не пестрила.
  List<Widget> _buildCategoryPills(SupplierProduct product, BuildContext context) {
    final localizedCat = product.localizedCategory(context);
    if (localizedCat.isEmpty) {
      return [
        _ModerationInfoPill(
          icon: Icons.category_outlined,
          text: AppLocalizations.current.getString('auto_bez_kategorii'),
        ),
      ];
    }
    return [
      _ModerationInfoPill(
        icon: Icons.category_outlined,
        text: localizedCat,
      ),
    ];
  }

  List<String> _searchTokens(String query) {
    return query
        .toLowerCase()
        .split(_whitespaceRegExp)
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
      product.nameKk,
      product.description,
      product.descriptionKk,
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

  // Дебаунсим ввод 300мс - иначе setState и пересчет фильтра дергаются на каждый
  // символ при быстром наборе.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTopPanel(ColorScheme colorScheme) {
    return Container(
      height: 136,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatusChip(
                  label: AppLocalizations.current.getString('auto_na_proverke'),
                  isActive: _statusFilter == 'pending',
                  onTap: () {
                    setState(() => _statusFilter = 'pending');
                    _loadProducts();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusChip(
                  label: AppLocalizations.current.getString('auto_odobreno'),
                  isActive: _statusFilter == 'approved',
                  onTap: () {
                    setState(() => _statusFilter = 'approved');
                    _loadProducts();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusChip(
                  label: AppLocalizations.current.getString('auto_otkloneno'),
                  isActive: _statusFilter == 'rejected',
                  onTap: () {
                    setState(() => _statusFilter = 'rejected');
                    _loadProducts();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusChip(
                  label: AppLocalizations.current.getString('auto_vse'),
                  isActive: _statusFilter == 'all',
                  onTap: () {
                    setState(() => _statusFilter = 'all');
                    _loadProducts();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.34,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.9),
                ),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: AppLocalizations.current.getString('auto_poisk_tovar_postavschik_kategoriya'),
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.88),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 42,
                    minHeight: 44,
                  ),
                  suffixIcon: _searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: AppLocalizations.current.getString('auto_ochistit'),
                          onPressed: () {
                            _searchDebounce?.cancel();
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleProducts = _applySearch(_products);
    final hasSearchQuery = _searchQuery.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.moderation),
        actions: [
          IconButton(
            tooltip: context.l10n.supportChatsTitle,
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
          IconButton(
            tooltip: context.l10n.suppliersListTitle,
            icon: const Icon(Icons.business_center_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SuppliersDirectoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopPanel(colorScheme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: _products.isEmpty
                        ? ModeratorEmptyState(message: AppLocalizations.current.getString('auto_net_zayavok'))
                        : visibleProducts.isEmpty
                        ? ModeratorEmptyState(
                            message: hasSearchQuery
                                ? AppLocalizations.current.getString('auto_po_vashemu_zaprosu_nichego_ne_nayde')
                                : AppLocalizations.current.getString('auto_net_podhodyaschih_tovarov'),
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
                              return RepaintBoundary(
                                child: Card(
                                  key: ValueKey<String>(
                                    'moderation-${product.id}',
                                  ),
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
                                                      constraints.maxWidth <
                                                      230;
                                                  final title = Text(
                                                    product.localizedName(context),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  );

                                                  if (isCompact) {
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        title,
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        statusChip,
                                                      ],
                                                    );
                                                  }

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: title,
                                                          ),
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
                                        if (product.localizedDescription(context)
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          ExpandableTextBlock(
                                            product.localizedDescription(context).trim(),
                                            collapsedMaxLines: 3,
                                            textStyle: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            actionColor: context.colorPalette.accent,
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
                                            ..._buildCategoryPills(product, context),
                                            _ModerationInfoPill(
                                              icon: Icons.inventory_2_outlined,
                                              text:
                                                  context.l10n.moderationStockQuantity(product.stockQuantity),
                                            ),
                                            if (product.deliveryBadge
                                                    .trim()
                                                    .isNotEmpty ||
                                                product.deliveryDate
                                                    .trim()
                                                    .isNotEmpty)
                                              _ModerationInfoPill(
                                                icon: Icons
                                                    .local_shipping_outlined,
                                                text: _deliveryDisplay(product),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                context.colorPalette.accentMist,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: context.colorPalette.line,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              _ModerationMetricRow(
                                                label: AppLocalizations.current.getString('auto_tsena'),
                                                value:
                                                    context.l10n.moderationPricePerUnit(product.pricePerUnit.toString()),
                                              ),
                                              const SizedBox(height: 8),
                                              _ModerationMetricRow(
                                                label: AppLocalizations.current.getString('auto_partiya'),
                                                value: _quantityLabel(product),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () => _openAboutSheet(product),
                                          child: _ModerationAboutTile(
                                            product: product,
                                            onTap: () => _openAboutSheet(product),
                                          ),
                                        ),
                                        if (product
                                            .moderationComment
                                            .isNotEmpty)
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: statusColor.withValues(
                                                  alpha: 0.35,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              context.l10n.moderationCommentPrefix(product.moderationComment),
                                              style: TextStyle(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final isCompact =
                                                constraints.maxWidth < 320;
                                            final deleteButton = OutlinedButton.icon(
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
                                                side: BorderSide(
                                                  color: context
                                                      .colorPalette
                                                      .error,
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
                                              label: Text(
                                                AppLocalizations.current.getString('moderation_page_auto_14'),
                                              ),
                                            );

                                            // На этапе pending кнопку «Удалить за нарушение»
                                            // не показываем - для отказа есть «Отклонить»,
                                            // удаление имеет смысл только для уже опубликованных
                                            // или ранее отклоненных товаров.
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
                                                  label: Text(context.l10n.moderationApproveProduct),
                                                );
                                            final rejectButton =
                                                OutlinedButton.icon(
                                                  onPressed: isUpdating
                                                      ? null
                                                      : () => _updateStatus(
                                                          product,
                                                          'rejected',
                                                        ),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                        foregroundColor:
                                                            const Color(
                                                              0xFFEF4444,
                                                            ),
                                                        side: BorderSide(
                                                          color: context
                                                              .colorPalette
                                                              .error,
                                                        ),
                                                      ),
                                                  icon: const Icon(
                                                    Icons.highlight_off,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    AppLocalizations.current.getString('moderation_page_auto_15'),
                                                  ),
                                                );

                                            if (isCompact) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  approveButton,
                                                  const SizedBox(height: 8),
                                                  rejectButton,
                                                ],
                                              );
                                            }

                                            return Row(
                                              children: [
                                                Expanded(child: approveButton),
                                                const SizedBox(width: 12),
                                                Expanded(child: rejectButton),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
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
    return Material(
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
  const _ModerationInfoPill({this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.accentMist,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
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

// Плашка-вход в bottom sheet с характеристиками и описанием.
class _ModerationAboutTile extends StatelessWidget {
  const _ModerationAboutTile({required this.product, required this.onTap});

  final SupplierProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _aboutPreview(context, product);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.accentMist,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.current.getString('moderation_page_auto_16'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              AppLocalizations.current.getString('moderation_page_auto_17'),
              style: TextStyle(
                fontSize: 13,
                color: palette.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _aboutPreview(BuildContext context, SupplierProduct product) {
    final sections = buildSupplierProductSections(product, context);
    final parts = <String>[];
    outer:
    for (final section in sections) {
      for (final item in section.items) {
        if (item.key.trim().isEmpty) {
          parts.add(item.value);
        } else {
          parts.add(context.l10n.moderationCharacteristicFormat(item.key, item.value));
        }
        if (parts.length >= 3) break outer;
      }
    }
    return parts.join(AppLocalizations.current.getString('moderation_page_auto_18'));
  }
}
