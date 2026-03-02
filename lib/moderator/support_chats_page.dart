import 'dart:async';

import 'package:flutter/material.dart';

import '../models/support_message.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/main_bottom_nav.dart';

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
          _error = 'Не удалось загрузить чаты техподдержки';
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
    return 'Пользователь #${chat.userId}';
  }

  String _avatarText(SupportChatSummary chat) {
    final label = _displayName(chat).trim();
    if (label.isEmpty) return '?';
    return label.substring(0, 1).toUpperCase();
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
    final parts = <String>[];
    if (chat.userEmail.trim().isNotEmpty) {
      parts.add(chat.userEmail.trim());
    }

    final message = chat.lastMessage.trim();
    if (message.isNotEmpty) {
      parts.add(message);
    } else {
      parts.add('Нет текста сообщения');
    }
    return parts.join(' | ');
  }

  Widget _statusChip(SupportChatSummary chat) {
    final isOpen = chat.isOpen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFDDF7E8) : const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'Открыт' : 'Закрыт',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen ? const Color(0xFF1A7F4B) : const Color(0xFFB42318),
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
    final selectedBackground = const Color(0xFF6288D5);
    final selectedForeground = Colors.white;
    final unselectedBackground = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.55)
        : const Color(0xFFE9EFFB);
    final unselectedForeground = isDark
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.95)
        : const Color(0xFF4B5A78);
    final borderColor = selected
        ? selectedBackground.withValues(alpha: isDark ? 0.98 : 0.9)
        : isDark
        ? colorScheme.outline.withValues(alpha: 0.75)
        : const Color(0xFFC9D5ED);

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleChats = _visibleChats;
    final chatTileColor = isDark
        ? colorScheme.surfaceContainerLow.withValues(alpha: 0.34)
        : colorScheme.surface;
    final chatTileBorderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.78)
        : colorScheme.outlineVariant.withValues(alpha: 0.95);

    return Scaffold(
      appBar: AppBar(title: const Text('Чаты техподдержки')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _buildFilterButton(
                  label: 'Открытые',
                  selected: !_showHistory,
                  onTap: () => setState(() => _showHistory = false),
                ),
                const SizedBox(width: 10),
                _buildFilterButton(
                  label: 'История',
                  selected: _showHistory,
                  onTap: () => setState(() => _showHistory = true),
                ),
              ],
            ),
          ),
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
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadChats,
                    child: visibleChats.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 140),
                              Center(
                                child: Text(
                                  _showHistory
                                      ? 'Закрытых чатов пока нет'
                                      : 'Открытых чатов сейчас нет',
                                ),
                              ),
                            ],
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
                                          ModeratorSupportDialogPage(chat: chat),
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
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  foregroundColor: colorScheme.primary,
                                  child: Text(_avatarText(chat)),
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
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SupportMessage> _messages = [];
  SupportChat? _chat;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isClosing = false;
  String? _error;

  StreamSubscription<Map<String, dynamic>>? _eventsSubscription;
  Timer? _eventsReconnectTimer;
  int _eventsReconnectAttempt = 0;

  bool get _isChatClosed => _chat?.isClosed ?? !widget.chat.isOpen;

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
    _eventsSubscription =
        ApiService.moderatorSupportEvents(chatId: widget.chat.chatId).listen(
          (event) {
            if (!mounted) return;
            final kind = event['kind']?.toString();
            if (kind == 'connected') {
              _eventsReconnectAttempt = 0;
              return;
            }
            _eventsReconnectAttempt = 0;
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
    if (_eventsReconnectAttempt > 6) {
      _eventsReconnectAttempt = 6;
    }

    final delay = Duration(seconds: _eventsReconnectAttempt * 2);
    _eventsReconnectTimer = Timer(delay, () {
      if (!mounted) return;
      _startEventsStream();
    });
  }

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

      final previousCount = _messages.length;
      setState(() {
        _messages = thread.messages;
        if (thread.chat != null) {
          _chat = thread.chat;
        }
        _error = null;
      });

      if (!silent) {
        _scrollToBottom(jump: true);
      } else if (_messages.length > previousCount) {
        _scrollToBottom();
      }
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = 'Не удалось загрузить сообщения';
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

  Future<void> _sendMessage() async {
    final moderatorId = AuthStorage.userId ?? 0;
    if (moderatorId <= 0) {
      _showSnack('Не удалось определить сотрудника техподдержки');
      return;
    }

    if (_isChatClosed) {
      _showSnack('Чат уже закрыт');
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _showSnack('Введите сообщение');
      return;
    }

    setState(() {
      _isSending = true;
    });

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
        _messageController.clear();
      });
      _scrollToBottom();
      await _loadThread(silent: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Не удалось отправить сообщение');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _closeChat() async {
    final moderatorId = AuthStorage.userId ?? 0;
    if (moderatorId <= 0) {
      _showSnack('Не удалось определить сотрудника техподдержки');
      return;
    }
    if (_isChatClosed) {
      _showSnack('Чат уже закрыт');
      return;
    }

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Закрыть чат'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Причина закрытия (необязательно)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, reasonController.text),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();
    if (reason == null) return;

    setState(() {
      _isClosing = true;
    });

    try {
      final closed = await ApiService.closeModeratorSupportChat(
        chatId: widget.chat.chatId,
        moderatorId: moderatorId,
        reason: reason.trim().isEmpty ? null : reason.trim(),
      );
      if (!mounted) return;

      setState(() {
        _chat = closed;
      });
      _showSnack('Чат закрыт');
      await _loadThread(silent: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Не удалось закрыть чат');
    } finally {
      if (mounted) {
        setState(() {
          _isClosing = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$dd.$mo $hh:$mm';
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(position);
      } else {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userName = widget.chat.userName.trim().isEmpty
        ? 'Пользователь #${widget.chat.userId}'
        : widget.chat.userName;

    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        actions: [
          if (_isClosing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _isChatClosed ? null : _closeChat,
              tooltip: _isChatClosed ? 'Чат уже закрыт' : 'Закрыть чат',
              icon: const Icon(Icons.lock_outline),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Text(
                  widget.chat.userEmail,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isChatClosed
                        ? const Color(0xFFFFE5E5)
                        : const Color(0xFFDDF7E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _isChatClosed ? 'Чат закрыт' : 'Чат открыт',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isChatClosed
                          ? const Color(0xFFB42318)
                          : const Color(0xFF1A7F4B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isChatClosed && (_chat?.closeReason.trim().isNotEmpty ?? false))
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF4F4),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Text(
                'Причина закрытия: ${_chat!.closeReason}',
                style: const TextStyle(
                  color: Color(0xFF9F1239),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
                            onPressed: _loadThread,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadThread,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isModerator = message.isFromModerator;
                        final align = isModerator
                            ? Alignment.centerRight
                            : Alignment.centerLeft;
                        final bubbleColor = isModerator
                            ? colorScheme.primary
                            : colorScheme.surface;
                        final textColor = isModerator
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface;

                        final header = <String>[];
                        if (message.category.trim().isNotEmpty) {
                          header.add(message.category.trim());
                        }
                        if (message.subject.trim().isNotEmpty) {
                          header.add(message.subject.trim());
                        }

                        return Align(
                          alignment: align,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 340),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isModerator
                                      ? Colors.transparent
                                      : colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (header.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        header.join(' | '),
                                        style: TextStyle(
                                          color: textColor.withValues(
                                            alpha: 0.72,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    message.text,
                                    style: TextStyle(color: textColor),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatTime(message.createdAt),
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.72),
                                      fontSize: 11,
                                    ),
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
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isChatClosed,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _isChatClosed
                            ? 'Чат закрыт'
                            : 'Ответить пользователю',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isSending || _isChatClosed)
                          ? null
                          : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
