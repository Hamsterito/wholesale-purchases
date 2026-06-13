import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/support_message.dart';
import '../services/api/api_service.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../services/storage/auth_storage.dart';
import '../services/message/message_localization.dart';
import '../theme/app_color_palette.dart';
import '../utils/search_normalizer.dart';
import '../widgets/messages/app_message_snackbar.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../widgets/moderator/supplier_search_field.dart';
import '../widgets/profile/user_avatar.dart';
import 'support_chats_page.dart';
import 'widgets/two_factor_admin_disable_tile.dart';

/// Каталог поставщиков для модератора. По тапу открывает support-чат
/// с поставщиком (создаёт новый, если открытого ещё нет).
class SuppliersDirectoryPage extends StatefulWidget {
  const SuppliersDirectoryPage({super.key});

  @override
  State<SuppliersDirectoryPage> createState() => _SuppliersDirectoryPageState();
}

class _SuppliersDirectoryPageState extends State<SuppliersDirectoryPage> {
  static const int _pageSize = 50;
  static const Duration _skeletonCap = Duration(milliseconds: 1500);
  // Подгружаем следующую страницу за 200 px до низа списка.
  static const double _loadMoreThreshold = 200;
  // 300 мс дебаунс поиска: запросы и фильтрация откладываются после ввода.
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<SupplierDirectoryEntry> _items = const [];
  int _offset = 0;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _showSkeletons = true;
  String? _error;
  bool _accessDenied = false;

  // Активный запрос для отображения списка. На сервер уходит как введено.
  String _activeQuery = '';
  // Сырой текст поля для эхо в empty-state, без нормализации.
  String _rawQuery = '';
  // Токены активного запроса для клиентского фоллбэка.
  List<String> _queryTokens = const [];

  Timer? _skeletonTimer;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    final role = AuthStorage.role?.trim().toLowerCase();
    if (role != 'moderator' && role != 'super_admin') {
      // Каталог только для модератора/super_admin - иначе access denied.
      _accessDenied = true;
      _isInitialLoading = false;
      _showSkeletons = false;
      return;
    }
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMore || _isInitialLoading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      _skeletonTimer?.cancel();
      setState(() {
        _isInitialLoading = true;
        _showSkeletons = true;
        _error = null;
      });
      _skeletonTimer = Timer(_skeletonCap, () {
        if (!mounted) return;
        setState(() => _showSkeletons = false);
      });
    }

    // Сохраняем активный запрос - поздний ответ для устаревшего запроса
    // не должен перетереть актуальные данные.
    final requestQuery = _activeQuery;
    try {
      final page = await ApiService.getSuppliersDirectory(
        offset: 0,
        limit: _pageSize,
        query: requestQuery.isEmpty ? null : requestQuery,
      );
      if (!mounted) return;
      if (requestQuery != _activeQuery) return;
      _skeletonTimer?.cancel();
      setState(() {
        _items = _sortByCompanyName(page.items);
        _offset = page.items.length;
        _hasMore = page.hasMore;
        _isInitialLoading = false;
        _showSkeletons = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (requestQuery != _activeQuery) return;
      _skeletonTimer?.cancel();
      setState(() {
        _isInitialLoading = false;
        _showSkeletons = false;
        _error = _humanizeError(e);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final requestQuery = _activeQuery;
    try {
      final page = await ApiService.getSuppliersDirectory(
        offset: _offset,
        limit: _pageSize,
        query: requestQuery.isEmpty ? null : requestQuery,
      );
      if (!mounted) return;
      // Запрос сменился во время загрузки - выкидываем результат.
      if (requestQuery != _activeQuery) {
        setState(() => _isLoadingMore = false);
        return;
      }
      // Дедуп по supplierId на случай гонок и пересечений страниц.
      final seen = {for (final s in _items) s.supplierId};
      final fresh = page.items.where((s) => !seen.contains(s.supplierId));
      final merged = [..._items, ...fresh];
      setState(() {
        _items = _sortByCompanyName(merged);
        _offset += page.items.length;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      // На ошибке догрузки оставляем уже загруженный список - следующий
      // скролл попробует снова.
      setState(() => _isLoadingMore = false);
    }
  }

  List<SupplierDirectoryEntry> _sortByCompanyName(
    List<SupplierDirectoryEntry> entries,
  ) {
    final copy = [...entries];
    copy.sort((a, b) {
      // Case-insensitive ascending по companyName. toLowerCase в Dart
      // корректно работает для кириллицы.
      return a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase());
    });
    return copy;
  }

  String _humanizeError(Object error) {
    var msg = error.toString();
    const prefix = 'Exception: ';
    if (msg.startsWith(prefix)) msg = msg.substring(prefix.length);
    return msg.trim().isEmpty ? context.l10n.suppliersLoadFailed : msg;
  }

  Future<void> _onSupplierTap(SupplierDirectoryEntry supplier) async {
    final moderatorId = AuthStorage.userId;
    if (moderatorId == null || moderatorId <= 0) {
      _showSnack(context.l10n.sessionExpiredLoginAgain, isError: true);
      return;
    }

    // Сбрасываем последнюю ошибку API, чтобы getLastErrorMessage не отдал
    // stale-сообщение при следующей попытке.
    ApiService.clearLastErrorMessage();

    // Шаг 1: peek - есть ли уже открытый чат? Если да, открываем сразу
    // без диалога подтверждения.
    SupportChat? chat;
    try {
      chat = await ApiService.findOrCreateModeratorSupportChatWithUser(
        moderatorId: moderatorId,
        targetUserId: supplier.supplierId,
        peek: true,
      );
    } catch (_) {
      if (!mounted) return;
      final apiMessage = ApiService.getLastErrorMessage();
_showSnack(
        apiMessage?.body.isNotEmpty == true
            ? apiMessage!.body
            : context.l10n.chatOpenFailed,
        isError: true,
      );
      return;
    }

    if (!mounted) return;

    // Шаг 2: открытого чата нет - спрашиваем подтверждение, и только при
    // согласии создаём новый.
    if (chat == null) {
      final confirmed = await _confirmCreateChat(supplier);
      if (!mounted) return;
      if (confirmed != true) return;

      try {
        chat = await ApiService.findOrCreateModeratorSupportChatWithUser(
          moderatorId: moderatorId,
          targetUserId: supplier.supplierId,
        );
      } catch (_) {
        if (!mounted) return;
        final apiMessage = ApiService.getLastErrorMessage();
        _showSnack(
          apiMessage?.body.isNotEmpty == true
              ? apiMessage!.body
              : context.l10n.chatCreateFailed,
          isError: true,
        );
        return;
      }

      if (!mounted || chat == null) return;
    }

    // Собираем минимальный SupportChatSummary для существующей страницы
    // диалога. Имя/email/роль берём из записи поставщика в каталоге.
    final summary = SupportChatSummary(
      chatId: chat.id,
      userId: chat.userId,
      status: chat.isOpen ? 'open' : 'closed',
      category: chat.category,
      subject: chat.subject,
      userName: supplier.displayName,
      userEmail: supplier.email ?? '',
      userRole: 'supplier',
      supplierName: supplier.companyName,
      lastMessage: '',
      lastSenderRole: 'user',
      createdAt: chat.createdAt,
      lastMessageAt: chat.createdAt,
      closedAt: chat.closedAt,
      closeReason: chat.closeReason,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModeratorSupportDialogPage(chat: summary),
      ),
    );
  }

  Future<bool?> _confirmCreateChat(SupplierDirectoryEntry supplier) {
    final palette = context.colorPalette;
    final textTheme = Theme.of(context).textTheme;
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.card,
title: Text(context.l10n.createChatTitle),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 context.l10n.createChatConfirm,
                 style: textTheme.bodyMedium?.copyWith(color: palette.ink),
               ),
            const SizedBox(height: 12),
            Text(
              supplier.companyName,
              style: textTheme.titleSmall?.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              supplier.displayName,
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
        ),
actions: [
           TextButton(
             onPressed: () => Navigator.of(dialogContext).pop(false),
             child: Text(context.l10n.cancel),
           ),
           FilledButton(
             onPressed: () => Navigator.of(dialogContext).pop(true),
             child: Text(context.l10n.createChatButton),
           ),
         ],
      ),
    );
  }

  void _showSnack(String body, {bool isError = false}) {
    if (!mounted) return;
    final msg = Message(
      id: const Uuid().v4(),
      type: MessageType.notification,
      severity: isError ? MessageSeverity.error : MessageSeverity.info,
      title: '',
      body: body,
      timestamp: DateTime.now(),
      language: MessageLocalizationManager.getCurrentLanguage(),
    );
    AppMessageSnackBar.show(context, msg);
  }

  void _onSearchChanged(String value) {
    // Сохраняем сырой текст для эхо в empty-state.
    _rawQuery = value;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      _commitQuery(value);
    });
  }

  void _commitQuery(String value) {
    final trimmed = value.trim();
    if (trimmed == _activeQuery) {
      // Запрос не изменился - нечего обновлять.
      return;
    }
    _activeQuery = trimmed;
    _queryTokens = trimmed.isEmpty
        ? const []
        : SearchNormalizer.tokenizeQuery(trimmed);
    // При смене запроса сбрасываем пагинацию.
    _offset = 0;
    _hasMore = true;
    _load(reset: true);
  }

  // Клиентский фоллбэк-фильтр: применяется поверх ответа сервера.
  List<SupplierDirectoryEntry> _visibleItems() {
    if (_queryTokens.isEmpty) return _items;
    return _items
        .where((entry) {
          final haystack = SearchNormalizer.buildSearchText(
            '${entry.displayName} ${entry.companyName}',
          );
          return SearchNormalizer.matchesTokens(haystack, _queryTokens);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

    return Scaffold(
      backgroundColor: palette.bgTop,
      appBar: AppBar(title: Text(context.l10n.suppliersListTitle)),
      body: SafeArea(child: _buildBody(palette)),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }

  Widget _buildBody(AppColorPalette palette) {
    if (_accessDenied) {
      return const _AccessDeniedState();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SupplierSearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(child: _buildContent(palette)),
      ],
    );
  }

  Widget _buildContent(AppColorPalette palette) {
    if (_isInitialLoading) {
      return _showSkeletons
          ? _SuppliersSkeletonList(palette: palette)
          : const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: () => _load(reset: true));
    }
    final visible = _visibleItems();
    if (visible.isEmpty) {
      // Для активного поискового запроса - особое эхо, иначе обычный empty.
      if (_activeQuery.isNotEmpty) {
        return _SearchEmptyState(query: _rawQuery);
      }
      return _EmptyState(onRetry: () => _load(reset: true));
    }
return RefreshIndicator(
      color: palette.accent,
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: visible.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= visible.length) {
            return _LoadMoreIndicator(visible: _isLoadingMore);
          }
          final supplier = visible[index];
          return RepaintBoundary(
            child: _SupplierListItem(
              supplier: supplier,
              onTap: () => _onSupplierTap(supplier),
            ),
          );
        },
      ),
    );
  }
}

class _SupplierListItem extends StatelessWidget {
  const _SupplierListItem({required this.supplier, required this.onTap});

  final SupplierDirectoryEntry supplier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  UserAvatar(
                    avatarUrl: supplier.avatarUrl,
                    displayName: supplier.companyName,
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          supplier.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          supplier.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: TwoFactorAdminDisableTile(
              targetUserId: supplier.supplierId,
              targetUserName: supplier.companyName,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(height: 24);
    final palette = context.colorPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: palette.primary,
          ),
        ),
      ),
    );
  }
}

class _SuppliersSkeletonList extends StatelessWidget {
  const _SuppliersSkeletonList({required this.palette});

  final AppColorPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 64,
        decoration: BoxDecoration(
          color: palette.bgBottom,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: palette.muted),
            const SizedBox(height: 16),
            Text(
              context.l10n.suppliersNotFound,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;

    final trimmed = query.trim();
    final message = trimmed.isEmpty
        ? context.l10n.searchNoResults
        : context.l10n.searchNoResultsFor(query);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: palette.muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: palette.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedState extends StatelessWidget {
  const _AccessDeniedState();

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: palette.error),
            const SizedBox(height: 12),
            Text(
              context.l10n.suppliersCatalogAccessDenied,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
