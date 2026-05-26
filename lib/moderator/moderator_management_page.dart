import 'dart:async';

import 'package:flutter/material.dart';

import '../login_screen/login.dart';
import '../services/api_service.dart';
import '../theme/app_color_palette.dart';
import '../widgets/phone_input_formatter.dart';
import '../widgets/top_message.dart';
import 'add_moderator_dialog.dart';
import 'moderator_filter.dart';

/// Страница управления модераторами для Super_Admin: список,
/// поиск, добавление и удаление.
class ModeratorManagementPage extends StatefulWidget {
  const ModeratorManagementPage({super.key});

  @override
  State<ModeratorManagementPage> createState() =>
      _ModeratorManagementPageState();
}

class _ModeratorManagementPageState extends State<ModeratorManagementPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Debounce ввода в строке поиска: setState вызывается только спустя
  // 300мс после последнего нажатия, чтобы не фильтровать список на каждом
  // символе.
  Timer? _searchDebounce;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);

  List<Moderator> _moderators = const [];
  bool _isLoading = true;
  String? _error;
  bool _accessDenied = false;
  final Set<int> _busyIds = <int>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchQuery == _searchController.text) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text);
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _accessDenied = false;
    });
    try {
      final list = await ApiService.getModerators();
      if (!mounted) return;
      setState(() {
        _moderators = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // 401/403 от API приходят в виде Exception с текстом - определяем
      // по подстрокам, чтобы показать баннер «Доступ запрещён»
      final raw = e.toString();
      final isAuthError =
          raw.contains('401') ||
          raw.contains('403') ||
          raw.toLowerCase().contains('не авторизован') ||
          raw.toLowerCase().contains('доступ');
      setState(() {
        _isLoading = false;
        _error = _humanize(e);
        _accessDenied = isAuthError;
      });
    }
  }

  String _humanize(Object error) {
    var msg = error.toString();
    const prefix = 'Exception: ';
    if (msg.startsWith(prefix)) msg = msg.substring(prefix.length);
    return msg.trim().isEmpty ? 'Не удалось загрузить модераторов' : msg;
  }

  // Локальные мутации списка без повторной загрузки с сервера
  void _appendLocal(Moderator m) {
    if (_moderators.any((x) => x.id == m.id)) return;
    final next = [..._moderators, m]
      ..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
    setState(() => _moderators = next);
  }

  void _removeLocal(int id) {
    setState(() => _moderators = _moderators.where((m) => m.id != id).toList());
  }

  // Сообщения этой страницы выходят сверху через showTopMessage,
  // чтобы не перекрывать FAB и совпадать с поведением остальных уведомлений.
  void _showTop(String body, {bool isError = false}) {
    if (!mounted) return;
    final palette = context.colorPalette;
    showTopMessage(
      context,
      body,
      backgroundColor: isError ? palette.error : palette.accent,
      duration: Duration(seconds: isError ? 4 : 2),
    );
  }

  Future<void> _openAddDialog() async {
    final created = await showAddModeratorDialog(context);
    if (created == null || !mounted) return;
    _appendLocal(created);
    _showTop('Модератор добавлен');
  }

  Future<void> _confirmAndDelete(Moderator m) async {
    if (_busyIds.contains(m.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = context.colorPalette;
        return AlertDialog(
          backgroundColor: palette.card,
          title: const Text('Удалить модератора?'),
          content: Text(
            '${m.name} (${m.email}) больше не сможет модерировать товары.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: palette.error.withValues(alpha: 0.15),
                foregroundColor: palette.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyIds.add(m.id));
    try {
      await ApiService.deleteModerator(id: m.id);
      if (!mounted) return;
      _removeLocal(m.id);
      _showTop('Модератор удалён');
    } catch (e) {
      if (!mounted) return;
      _showTop(_humanize(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(m.id));
      }
    }
  }

  void _goToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = context.colorPalette;
    final filtered = filterModerators(_moderators, _searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление модераторами'),
        actions: [
          IconButton(
            tooltip: 'Добавить модератора',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: _isLoading || _accessDenied ? null : _openAddDialog,
          ),
        ],
      ),
      body: _accessDenied
          ? _buildAccessDenied(theme, palette)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск по имени или email',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(child: _buildBody(filtered, cs, palette)),
              ],
            ),
      floatingActionButton: _accessDenied
          ? null
          : FloatingActionButton.extended(
              onPressed: _isLoading ? null : _openAddDialog,
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add),
              label: const Text(
                'Добавить',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildBody(
    List<Moderator> filtered,
    ColorScheme cs,
    AppColorPalette palette,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError(cs, palette);
    }
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _searchQuery.isEmpty
                ? 'Модераторы не найдены'
                : 'Ничего не найдено по запросу',
            style: TextStyle(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final m = filtered[i];
          final busy = _busyIds.contains(m.id);
          return RepaintBoundary(
            child: _ModeratorRow(
              moderator: m,
              isBusy: busy,
              onDelete: busy ? null : () => _confirmAndDelete(m),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(ColorScheme cs, AppColorPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: palette.error),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Ошибка',
              style: TextStyle(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied(ThemeData theme, AppColorPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: palette.error),
            const SizedBox(height: 12),
            Text(
              'Доступ запрещён. Войдите снова.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _goToLogin,
              icon: const Icon(Icons.login),
              label: const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeratorRow extends StatelessWidget {
  const _ModeratorRow({
    required this.moderator,
    required this.isBusy,
    required this.onDelete,
  });

  static final RegExp _nonDigitRegExp = RegExp(r'\D');

  final Moderator moderator;
  final bool isBusy;
  final VoidCallback? onDelete;

  // Преобразуем 11 цифр (78001234567) в +7-800-123-45-67 для удобного чтения.
  // Если цифр не 11 или формат не похож на наш - показываем как есть.
  String _displayPhone(String raw) {
    final digits = raw.replaceAll(_nonDigitRegExp, '');
    if (digits.length != 11) return raw;
    return PhoneNumberInputFormatter.formatDigits(digits);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = context.colorPalette;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Аватар с иконкой щита на акцентном фоне
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.verified_user_rounded,
              color: palette.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moderator.name.isEmpty ? 'Без имени' : moderator.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _ContactLine(
                  icon: Icons.alternate_email_rounded,
                  text: moderator.email,
                ),
                if (moderator.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _ContactLine(
                    icon: Icons.phone_outlined,
                    text: _displayPhone(moderator.phone),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Кнопка удаления - с мягкой подложкой error-цвета для контраста
          Material(
            color: palette.error.withValues(alpha: 0.10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onDelete,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Center(
                  child: isBusy
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.error,
                          ),
                        )
                      : Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: palette.error,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
