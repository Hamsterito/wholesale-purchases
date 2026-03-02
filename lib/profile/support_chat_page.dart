import 'dart:async';

import 'package:flutter/material.dart';

import '../models/support_message.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class UserSupportChatPage extends StatefulWidget {
  const UserSupportChatPage({super.key, this.chatId});

  final int? chatId;

  @override
  State<UserSupportChatPage> createState() => _UserSupportChatPageState();
}

class _UserSupportChatPageState extends State<UserSupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SupportMessage> _messages = [];
  SupportChat? _chat;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  StreamSubscription<Map<String, dynamic>>? _eventsSubscription;
  Timer? _eventsReconnectTimer;
  int _eventsReconnectAttempt = 0;

  bool get _isChatOpen => _chat?.isOpen ?? false;
  bool get _isChatClosed => _chat?.isClosed ?? false;

  @override
  void initState() {
    super.initState();
    _loadThread().whenComplete(_startEventsStream);
  }

  Future<void> _loadThread({bool silent = false}) async {
    final userId = AuthStorage.userId ?? 0;
    if (userId <= 0) {
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Не удалось определить пользователя';
        });
      }
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final thread = await ApiService.getSupportThread(
        userId: userId,
        chatId: widget.chatId,
      );
      if (!mounted) return;

      final previousCount = _messages.length;
      setState(() {
        _chat = thread.chat;
        _messages = thread.messages;
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
          _error = 'Не удалось загрузить чат';
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

  void _startEventsStream() {
    _eventsReconnectTimer?.cancel();
    _eventsSubscription?.cancel();

    final userId = AuthStorage.userId ?? 0;
    if (userId <= 0 || !mounted) return;

    _eventsSubscription =
        ApiService.supportEvents(userId: userId, chatId: widget.chatId).listen(
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

  Future<void> _sendMessage() async {
    final userId = AuthStorage.userId ?? 0;
    if (userId <= 0) {
      _showSnack('Не удалось определить пользователя');
      return;
    }

    if (!_isChatOpen) {
      _showSnack('Чат закрыт. Создайте новое обращение.');
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
        userId: userId,
        chatId: _chat?.id,
        senderRole: 'user',
        senderUserId: userId,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Чат с техподдержкой')),
      body: _isLoading
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
          : _chat == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.chatId == null
                      ? 'Активного чата нет. Сначала отправьте обращение в техподдержку.'
                      : 'Чат не найден.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: _isChatClosed
                      ? const Color(0xFFFFF4F4)
                      : const Color(0xFFF3F8FF),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Text(
                    _isChatClosed
                        ? 'Чат закрыт${_chat!.closeReason.trim().isEmpty ? '' : '. Причина: ${_chat!.closeReason}'}'
                        : 'Чат открыт. Техподдержка ответит в этом окне.',
                    style: TextStyle(
                      color: _isChatClosed
                          ? const Color(0xFF9F1239)
                          : const Color(0xFF2457A7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadThread,
                    child: _messages.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 140),
                              Center(child: Text('Сообщений пока нет')),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isUser = !message.isFromModerator;
                              final align = isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft;
                              final bubbleColor = isUser
                                  ? colorScheme.primary
                                  : colorScheme.surface;
                              final textColor = isUser
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface;

                              return Align(
                                alignment: align,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 340,
                                  ),
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
                                        color: isUser
                                            ? Colors.transparent
                                            : colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.text,
                                          style: TextStyle(color: textColor),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatTime(message.createdAt),
                                          style: TextStyle(
                                            color: textColor.withValues(
                                              alpha: 0.72,
                                            ),
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
                            enabled: _isChatOpen,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: _isChatOpen
                                  ? 'Введите сообщение'
                                  : 'Чат закрыт',
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
                            onPressed: (_isSending || !_isChatOpen)
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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

