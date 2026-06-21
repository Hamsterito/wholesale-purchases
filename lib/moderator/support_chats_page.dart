import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_color_palette.dart';

import '../models/message.dart';
import '../models/support_message.dart';
import '../services/api/api_service.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../services/storage/auth_storage.dart';
import '../services/message/message_localization.dart';
import '../widgets/chat/chat_thread_view.dart';
import '../widgets/chat/adapters.dart';
import '../widgets/moderator/moderator_empty_state.dart';
import '../widgets/profile/user_avatar.dart';
import 'suppliers_directory_page.dart';

class ModeratorSupportChatsPage extends StatefulWidget {
  const ModeratorSupportChatsPage({super.key});

  @override
  State<ModeratorSupportChatsPage> createState() =>
      _ModeratorSupportChatsPageState();
}

class _ModeratorSupportChatsPageState extends State<ModeratorSupportChatsPage> {
  List<SupportChatSummary> _chats = [];
  bool _isLoading = true;
  String? _error;
  bool _showHistory = false;

  StreamSubscription<Map<String, dynamic>>? _eventsSubscription;
  Timer? _eventsReconnectTimer;
  int _eventsReconnectAttempt = 0;

  @override
  void initState() {
    super.initState();
    _loadChats().whenComplete(_startEventsStream);
  }

  void _startEventsStream() {
    _eventsReconnectTimer?.cancel();
    _eventsSubscription?.cancel();

    if (!mounted) return;
    _eventsSubscription = ApiService.moderatorSupportEvents().listen(
      (event) {
        if (!mounted) return;
        final kind = event['kind']?.toString();
        if (kind == 'connected') {
          _eventsReconnectAttempt = 0;
          return;
        }
        _eventsReconnectAttempt = 0;
        _loadChats(silent: true);
      },
      onError: (_) {
        if (!mounted) return;
        _scheduleEventsReconnect();
      },
      onDone: () {
        if (!mounted) return;
        _scheduleEventsReconnect();
      },
      cancelOnError: true,
    );
  }

  void _scheduleEventsReconnect() {
    _eventsReconnectTimer?.cancel();
    _eventsReconnectAttempt += 1;
    if (_eventsReconnectAttempt > 6) {
      _eventsReconnectAttempt = 6;
    }
    final delay = Duration(seconds: _eventsReconnectAttempt * 2);
    _eventsReconnectTimer = Timer(delay, () {
      if (!mounted) return;
      _startEventsStream();
    });
  }

  Future<void> _loadChats({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final chats = await ApiService.getModeratorSupportChats();
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = context.l10n.getString('auto_neUdalosZagruzitChaty');
        });
      }
    } finally {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _displayName(SupportChatSummary chat) {
    final base = chat.userName.trim();
    if (base.isNotEmpty) return base;
    return context.l10n.moderatorUserLabel(chat.userId.toString());
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$dd.$mo $hh:$mm';
  }

  String _subtitle(SupportChatSummary chat) {
    return chat.userEmail.trim();
  }

  Widget _statusChip(SupportChatSummary chat) {
    final isOpen = chat.isOpen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? context.colorPalette.success.withValues(alpha: 0.15)
            : context.colorPalette.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? context.l10n.getString('auto_otkryt') : context.l10n.getString('auto_zakryt_1'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen
              ? context.colorPalette.success
              : context.colorPalette.error,
        ),
      ),
    );
  }

  List<SupportChatSummary> get _visibleChats {
    if (_showHistory) {
      return _chats.where((chat) => !chat.isOpen).toList();
    }
    return _chats.where((chat) => chat.isOpen).toList();
  }

  Widget _buildFilterButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedBackground = context.colorPalette.accent;
    final selectedForeground = Colors.white;
    final unselectedBackground = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.55)
        : context.colorPalette.accentMist;
    final unselectedForeground = isDark
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.95)
        : context.colorPalette.muted;
    final borderColor = selected
        ? selectedBackground.withValues(alpha: isDark ? 0.98 : 0.9)
        : isDark
        ? colorScheme.outline.withValues(alpha: 0.75)
        : context.colorPalette.line;

    return Expanded(
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: selected ? selectedBackground : unselectedBackground,
          foregroundColor: selected ? selectedForeground : unselectedForeground,
          elevation: selected ? 1 : 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor, width: 1.1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTopPanel(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          _buildFilterButton(
            label: context.l10n.getString('auto_otkrytye'),
            selected: !_showHistory,
            onTap: () => setState(() => _showHistory = false),
          ),
          const SizedBox(width: 10),
          _buildFilterButton(
            label: context.l10n.getString('auto_istoriya'),
            selected: _showHistory,
            onTap: () => setState(() => _showHistory = true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleChats = _visibleChats;
    final chatTileColor = context.colorPalette.card;
    final chatTileBorderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.78)
        : colorScheme.outlineVariant.withValues(alpha: 0.95);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.supportChatsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.suppliersListTitle,
            icon: const Icon(Icons.business_center_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadChats,
                            child: Text(context.l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadChats,
                    child: visibleChats.isEmpty
                        ? ModeratorEmptyState(
                            message: _showHistory
                                ? context.l10n.getString('auto_zakrytyhChatovPokaNet')
                                : context.l10n.getString('auto_otkrytyhChatovSeychasN'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: visibleChats.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final chat = visibleChats[index];
                              return ListTile(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ModeratorSupportDialogPage(
                                            chat: chat,
                                          ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  await _loadChats(silent: true);
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: chatTileBorderColor,
                                    width: 1.15,
                                  ),
                                ),
                                tileColor: chatTileColor,
                                leading: UserAvatar(
                                  avatarUrl: chat.userAvatarUrl,
                                  displayName: _displayName(chat),
                                  radius: 20,
                                ),
                                title: Text(
                                  _displayName(chat),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _subtitle(chat),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatTime(chat.lastMessageAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _statusChip(chat),
                                  ],
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

  @override
  void dispose() {
    _eventsReconnectTimer?.cancel();
    _eventsSubscription?.cancel();
    super.dispose();
  }
}

class ModeratorSupportDialogPage extends StatefulWidget {
  const ModeratorSupportDialogPage({super.key, required this.chat});

  final SupportChatSummary chat;

  @override
  State<ModeratorSupportDialogPage> createState() =>
      _ModeratorSupportDialogPageState();
}

class _ModeratorSupportDialogPageState
    extends State<ModeratorSupportDialogPage> {
  static const _uuid = Uuid();

  List<SupportMessage> _messages = const [];
  SupportChat? _chat;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isClosing = false;
  String? _error;

  StreamSubscription<Map<String, dynamic>>? _eventsSubscription;
  Timer? _eventsReconnectTimer;
  int _eventsReconnectAttempt = 0;

  bool get _isChatClosed => _chat?.isClosed ?? !widget.chat.isOpen;
  bool get _isChatOpen => !_isChatClosed;

  @override
  void initState() {
    super.initState();
    _chat = _summaryToChat(widget.chat);
    _loadThread().whenComplete(_startEventsStream);
  }

  void _startEventsStream() {
    _eventsReconnectTimer?.cancel();
    _eventsSubscription?.cancel();
    if (!mounted) return;

    _eventsSubscription = ApiService.moderatorSupportEvents().listen(
      (event) {
        if (!mounted) return;
        final kind = event['kind']?.toString();
        if (kind == 'connected') {
          _eventsReconnectAttempt = 0;
          return;
        }
        _eventsReconnectAttempt = 0;
        // Подписываемся без chatId-фильтра - один сокет шарится со списком.
        // Чужой чат отфильтрует _loadThread.
        _loadThread(silent: true);
      },
      onError: (_) {
        if (!mounted) return;
        _scheduleEventsReconnect();
      },
      onDone: () {
        if (!mounted) return;
        _scheduleEventsReconnect();
      },
      cancelOnError: true,
    );
  }

  void _scheduleEventsReconnect() {
    _eventsReconnectTimer?.cancel();
    _eventsReconnectAttempt += 1;
    if (_eventsReconnectAttempt > 6) _eventsReconnectAttempt = 6;
    final delay = Duration(seconds: _eventsReconnectAttempt * 2);
    _eventsReconnectTimer = Timer(delay, () {
      if (!mounted) return;
      _startEventsStream();
    });
  }

  /// Превращает summary из списка чатов в SupportChat для UI.
  /// Нужно, чтобы страница отрисовалась со статусом и темой до загрузки треда.
  SupportChat _summaryToChat(SupportChatSummary summary) {
    return SupportChat(
      id: summary.chatId,
      userId: summary.userId,
      status: summary.status,
      category: summary.category,
      subject: summary.subject,
      closeReason: summary.closeReason,
      createdAt: summary.createdAt,
      closedAt: summary.closedAt,
      closedByUserId: null,
    );
  }

  Future<void> _loadThread({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final thread = await ApiService.getModeratorSupportThread(
        chatId: widget.chat.chatId,
      );
      if (!mounted) return;
      setState(() {
        _messages = thread.messages;
        if (thread.chat != null) _chat = thread.chat;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _error = context.l10n.getString('auto_neUdalosZagruzitSoobsh'));
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessageText(String rawText) async {
    final moderatorId = AuthStorage.userId ?? 0;
    if (moderatorId <= 0) {
      _showSnack(
        context.l10n.getString('auto_neUdalosOpredelitSotru'),
        severity: MessageSeverity.error,
      );
      return;
    }
    if (_isChatClosed) {
      _showSnack(context.l10n.getString('auto_chatUzheZakryt'), severity: MessageSeverity.warning);
      return;
    }
    final text = rawText.trim();
    if (text.isEmpty) {
      _showSnack(context.l10n.getString('auto_vvediteSoobshchenie'), severity: MessageSeverity.warning);
      return;
    }

    setState(() => _isSending = true);
    try {
      final sent = await ApiService.sendSupportMessage(
        userId: widget.chat.userId,
        chatId: widget.chat.chatId,
        senderRole: 'moderator',
        senderUserId: moderatorId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, sent];
      });
      // Свежий thread прилетит через SSE - лишний fetch только забивает
      // лимит соединений в Chrome.
    } catch (e) {
      if (!mounted) return;
      // sendSupportMessage пробрасывает текст ошибки от сервера -
      // показываем именно его (например, «Чат закрыт»).
      var msg = e.toString();
      const prefix = 'Exception: ';
      if (msg.startsWith(prefix)) msg = msg.substring(prefix.length);
      _showSnack(
        msg.trim().isEmpty ? context.l10n.getString('auto_neUdalosOtpravitSoobsh') : msg,
        severity: MessageSeverity.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _closeChat() async {
    final moderatorId = AuthStorage.userId ?? 0;
    if (moderatorId <= 0) {
      _showSnack(
        context.l10n.getString('auto_neUdalosOpredelitSotru'),
        severity: MessageSeverity.error,
      );
      return;
    }
    if (_isChatClosed) {
      _showSnack(context.l10n.getString('auto_chatUzheZakryt'), severity: MessageSeverity.warning);
      return;
    }

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
title: Text(context.l10n.closeChatTitle),
           content: TextField(
             controller: reasonController,
             maxLines: 3,
             decoration: InputDecoration(
               hintText: context.l10n.getString('auto_prichinaZakrytiyaNeobya'),
             ),
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: Text(context.l10n.cancel),
             ),
             FilledButton(
               onPressed: () => Navigator.pop(context, reasonController.text),
               child: Text(context.l10n.closeChatButton),
             ),
          ],
        );
      },
    );
    reasonController.dispose();
    if (reason == null) return;

    setState(() => _isClosing = true);
    try {
      final closed = await ApiService.closeModeratorSupportChat(
        chatId: widget.chat.chatId,
        moderatorId: moderatorId,
        reason: reason.trim().isEmpty ? null : reason.trim(),
      );
      if (!mounted) return;
      setState(() => _chat = closed);
      _showSnack(context.l10n.getString('auto_chatZakryt'));
      await _loadThread(silent: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack(context.l10n.getString('auto_neUdalosZakrytChat'), severity: MessageSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _isClosing = false);
      }
    }
  }

  void _showSnack(
    String message, {
    MessageSeverity severity = MessageSeverity.info,
  }) {
    final msg = Message(
      id: _uuid.v4(),
      type: MessageType.notification,
      severity: severity,
      title: '',
      body: message,
      timestamp: DateTime.now(),
      language: MessageLocalizationManager.getCurrentLanguage(),
    );
    AppMessageSnackBar.show(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userName = widget.chat.userName.trim().isEmpty
        ? context.l10n.moderatorUserLabel(widget.chat.userId.toString())
        : widget.chat.userName;
    final userEmail = widget.chat.userEmail.trim();
    final moderatorId = AuthStorage.userId ?? 0;

    final composerEnabled = _isChatOpen && !_isSending;
    final composerHint = _isChatClosed ? context.l10n.getString('auto_chatZakryt') : context.l10n.getString('auto_otvetitPolzovatelyu');

    return Scaffold(
      // resizeToAvoidBottomInset = true по умолчанию - Scaffold поднимает
      // body над клавиатурой, композер остаётся sticky.
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (userEmail.isNotEmpty)
              Text(
                userEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          // Чип «Чат открыт/закрыт» - компактно справа от заголовка.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isChatClosed
                    ? context.colorPalette.error.withValues(alpha: 0.15)
                    : context.colorPalette.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _isChatClosed ? context.l10n.getString('auto_chatZakryt') : context.l10n.getString('auto_chatOtkryt'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _isChatClosed
                      ? context.colorPalette.error
                      : context.colorPalette.success,
                ),
              ),
            ),
          ),
          if (_isClosing)
            const Padding(
              padding: EdgeInsets.only(right: 16, left: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _isChatClosed ? null : _closeChat,
              tooltip: _isChatClosed ? context.l10n.getString('auto_chatUzheZakryt') : context.l10n.getString('auto_zakrytChat'),
              icon: const Icon(Icons.lock_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isChatClosed && (_chat?.closeReason.trim().isNotEmpty ?? false))
            Container(
              width: double.infinity,
              color: context.colorPalette.error.withValues(alpha: 0.08),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Text(
                context.l10n.supportCloseReason(_chat!.closeReason),
                style: TextStyle(
                  color: context.colorPalette.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: ChatThreadView(
              messages: chatBubblesFromSupportMessages(
                _messages,
                counterpartName: userName,
              ),
              currentUserId: moderatorId,
              counterpartName: userName,
              onSend: _sendMessageText,
              onRetrySend: (bubble) => _sendMessageText(bubble.body),
              onLoadMore: () {},
              onRetry: _loadThread,
              isInitialLoading: _isLoading,
              isLoadingMore: false,
              isComposerEnabled: composerEnabled,
              composerHint: composerHint,
              error: _error,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventsReconnectTimer?.cancel();
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
