import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_color_palette.dart';

import '../models/message.dart';
import '../models/support_message.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import '../services/message/message_service_adapters.dart';
import '../services/message/message_store.dart';
import '../services/message/message_localization.dart';
import '../widgets/chat/chat_thread_view.dart';
import '../widgets/chat/adapters.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';

class UserSupportChatPage extends StatefulWidget {
  const UserSupportChatPage({super.key, this.chatId});

  final int? chatId;

  @override
  State<UserSupportChatPage> createState() => _UserSupportChatPageState();
}

class _UserSupportChatPageState extends State<UserSupportChatPage> {
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
          _error = context.l10n.getString('auto_neUdalosOpredelitPolzo');
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

      setState(() {
        _chat = thread.chat;
        _messages = thread.messages;
        _error = null;
      });

      // Дублируем сообщения в MessageStore для аналитики, в фоне.
      unawaited(_logSupportMessagesAsMessages(thread.messages));
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = context.l10n.getString('auto_neUdalosZagruzitChat');
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

    _eventsSubscription = ApiService.supportEvents(userId: userId).listen(
      (event) {
        if (!mounted) return;
        final kind = event['kind']?.toString();
        if (kind == 'connected') {
          _eventsReconnectAttempt = 0;
          return;
        }
        _eventsReconnectAttempt = 0;
        // Шарим один SSE-стрим без chatId-фильтра, чтобы он мог быть
        // переиспользован соседними страницами и не съедал лишние
        // сокеты. Когда событие касается чужого чата - _loadThread
        // просто перезапросит наш и ничего не изменит.
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

  Future<void> _sendMessageText(String rawText) async {
    final userId = AuthStorage.userId ?? 0;
    if (userId <= 0) {
      _showSnack(
        context.l10n.getString('auto_neUdalosOpredelitPolzo'),
        severity: MessageSeverity.error,
      );
      return;
    }

    if (!_isChatOpen) {
      _showSnack(
        context.l10n.getString('auto_chatZakrytSozdayteNovo'),
        severity: MessageSeverity.warning,
      );
      return;
    }

    final text = rawText.trim();
    if (text.isEmpty) {
      _showSnack(context.l10n.getString('auto_vvediteSoobshchenie'), severity: MessageSeverity.warning);
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
      });
      // Свежий thread прилетит через SSE - лишний fetch только забивает
      // лимит соединений в Chrome.
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        context.l10n.getString('auto_neUdalosOtpravitSoobsh'),
        severity: MessageSeverity.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// Сохраняет сообщения в MessageStore для аналитики. Ошибки не пробрасываем.
  Future<void> _logSupportMessagesAsMessages(
    List<SupportMessage> messages,
  ) async {
    try {
      for (final supportMsg in messages) {
        final Message standardized = SupportChatAdapter.fromSupportMessage(
          supportMsg,
        );
        await MessageStore.save(standardized);
      }
    } catch (_) {
      // Молчим: логирование чата не должно ломать UI
    }
  }

  void _showSnack(
    String message, {
    MessageSeverity severity = MessageSeverity.info,
  }) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.getString('auto_chatSTehpodderzhkoy'))),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Загрузка/ошибка фетча - централизованные состояния на всю страницу.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadThread,
                child: Text(context.l10n.getString('auto_povtorit')),
              ),
            ],
          ),
        ),
      );
    }
    if (_chat == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.chatId == null
                ? context.l10n.getString('auto_aktivnogoChataNetSnach')
                : context.l10n.getString('auto_chatNeNayden'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final userId = AuthStorage.userId ?? 0;
    final composerEnabled = _isChatOpen && !_isSending;

    return Column(
      children: [
        _buildStatusBanner(context),
        Expanded(
          child: ChatThreadView(
            messages: chatBubblesFromSupportMessages(_messages),
            currentUserId: userId,
            counterpartName: context.l10n.getString('auto_podderzhka'),
            onSend: _sendMessageText,
            onRetrySend: (bubble) => _sendMessageText(bubble.body),
            onLoadMore: () {},
            isInitialLoading: false,
            isLoadingMore: false,
            isComposerEnabled: composerEnabled,
            composerHint: _isChatOpen ? context.l10n.getString('auto_vvediteSoobshchenie') : context.l10n.getString('auto_chatZakryt'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    final closed = _isChatClosed;
    final reason = _chat?.closeReason.trim() ?? '';
    return Container(
      width: double.infinity,
      color: closed
          ? context.colorPalette.error.withValues(alpha: 0.12)
          : context.colorPalette.info.withValues(alpha: 0.12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Text(
        closed
            ? 'Чат закрыт${reason.isEmpty ? '' : '. Причина: $reason'}'
            : context.l10n.getString('auto_chatOtkrytTehpodderzhka'),
        style: TextStyle(
          color: closed
              ? context.colorPalette.error
              : context.colorPalette.info,
          fontWeight: FontWeight.w600,
        ),
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
