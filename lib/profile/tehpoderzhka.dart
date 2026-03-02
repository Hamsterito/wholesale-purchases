import 'dart:async';

import 'package:flutter/material.dart';

import '../models/support_message.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'support_chat_page.dart';
import '../widgets/main_bottom_nav.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static const Color _primaryColor = Color(0xFF6288D5);
  static const Color _primaryDark = Color(0xFF4F6FBF);
  static const int _supportStartHour = 9;
  static const int _supportEndHour = 21;
  static const Duration _supportUtcOffset = Duration(hours: 5);

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _selectedCategory;
  bool _isLoadingThread = true;
  bool _isSending = false;
  String? _threadError;
  SupportChat? _chat;

  StreamSubscription<Map<String, dynamic>>? _eventsSubscription;
  Timer? _eventsReconnectTimer;
  int _eventsReconnectAttempt = 0;

  bool get _hasOpenChat => _chat?.isOpen ?? false;
  bool get _isChatClosed => _chat?.isClosed ?? false;
  DateTime get _supportNow => DateTime.now().toUtc().add(_supportUtcOffset);

  bool get _isSupportOnlineNow {
    final now = _supportNow;
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _supportStartHour * 60;
    final endMinutes = _supportEndHour * 60;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  String get _supportAvailabilityText => _isSupportOnlineNow
      ? 'Операторы онлайн. Обычно отвечаем быстро.'
      : 'Сейчас офлайн. Ответим в рабочее время.';

  String get _messageHintText =>
      _hasOpenChat ? 'Введите сообщение' : 'Опишите проблему';

  final List<String> _categories = const [
    'Проблема с заказом',
    'Проблема с оплатой',
    'Технические неполадки',
    'Вопрос о товаре',
    'Другое',
  ];

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
          _threadError = 'Не удалось определить пользователя';
          _isLoadingThread = false;
        });
      }
      return;
    }

    if (!silent) {
      setState(() {
        _isLoadingThread = true;
        _threadError = null;
      });
    }

    try {
      final thread = await ApiService.getSupportThread(userId: userId);
      if (!mounted) return;

      setState(() {
        _chat = thread.chat;
        _threadError = null;

        final category = _chat?.category.trim();
        if (_selectedCategory == null &&
            category != null &&
            category.isNotEmpty &&
            _categories.contains(category)) {
          _selectedCategory = category;
        }

        final subject = _chat?.subject.trim();
        if (_subjectController.text.trim().isEmpty &&
            subject != null &&
            subject.isNotEmpty) {
          _subjectController.text = subject;
        }
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _threadError = 'Не удалось загрузить обращение';
        });
      }
    } finally {
      if (mounted && !silent) {
        setState(() {
          _isLoadingThread = false;
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

  Future<void> _submit() async {
    final userId = AuthStorage.userId ?? 0;
    if (userId <= 0) {
      _showSnack('Не удалось определить пользователя', isError: true);
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _showSnack('Введите сообщение', isError: true);
      return;
    }

    final category = _selectedCategory;
    final subject = _subjectController.text.trim();
    final isNewChat = !_hasOpenChat;
    final resolvedCategory = category ?? _chat?.category.trim();
    final resolvedSubject = subject.isNotEmpty
        ? subject
        : (_chat?.subject.trim() ?? '');

    if (isNewChat && (resolvedCategory == null || resolvedSubject.isEmpty)) {
      _showSnack(
        'Для нового обращения заполните категорию и тему',
        isError: true,
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ApiService.sendSupportMessage(
        userId: userId,
        chatId: _hasOpenChat ? _chat!.id : null,
        senderRole: 'user',
        senderUserId: userId,
        category: resolvedCategory,
        subject: resolvedSubject.isEmpty ? null : resolvedSubject,
        text: message,
      );

      if (!mounted) return;
      _messageController.clear();
      _showSnack(
        isNewChat
            ? 'Обращение отправлено в техподдержку'
            : 'Сообщение отправлено',
      );
      await _loadThread(silent: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Не удалось отправить обращение', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _openChatPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UserSupportChatPage()));
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : _primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = theme.scaffoldBackgroundColor;
    final cardBackground = colorScheme.surface;
    final textPrimary = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;
    final fieldFill = isDark
        ? const Color(0xFF171D28)
        : const Color(0xFFF4F6FB);
    final fieldBorder = isDark
        ? colorScheme.outlineVariant
        : const Color(0xFFE1E7F3);
    final cardShadow = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : const Color(0x14000000);
    final baseFieldDecoration = _baseFieldDecoration(
      fillColor: fieldFill,
      borderColor: fieldBorder,
      focusColor: _primaryColor,
      hintColor: textMuted,
    );

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Техподдержка',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryColor, _primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cardShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.message, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Свяжитесь с нами',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _supportAvailabilityText,
                    style: const TextStyle(
                      color: Color(0xFFE3ECFF),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContactItem(Icons.phone, '+7 (777) 123-45-67'),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.email, 'support@mansamart.kz'),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    Icons.access_time,
                    'Пн-Вс: 09:00 - 21:00 (UTC+5)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: fieldBorder),
                boxShadow: [
                  BoxShadow(
                    color: cardShadow,
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _hasOpenChat
                              ? 'Продолжить обращение'
                              : 'Отправить обращение',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                          ),
                        ),
                      ),
                      if (_isLoadingThread)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  if (_threadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _threadError!,
                        style: const TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ),
                  if (_chat != null) ...[
                    const SizedBox(height: 4),
                    if (_hasOpenChat)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF7E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFB7EBCF)),
                        ),
                        child: const Text(
                          'Активный чат открыт',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A7F4B),
                          ),
                        ),
                      ),
                    if (_isChatClosed) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Предыдущее обращение закрыто. Если вопрос актуален, отправьте новое.',
                        style: TextStyle(color: textMuted),
                      ),
                    ],
                    if (_isChatClosed &&
                        _chat!.closeReason.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Причина закрытия: ${_chat!.closeReason}',
                        style: TextStyle(
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (_hasOpenChat) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openChatPage,
                          icon: const Icon(Icons.chat_bubble_outline, size: 20),
                          label: const Text(
                            'Открыть чат с техподдержкой',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadowColor: _primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Категория обращения',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    hint: Text(
                      'Выберите категорию',
                      style: TextStyle(color: textMuted),
                    ),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    menuMaxHeight: 260,
                    dropdownColor: cardBackground,
                    elevation: 10,
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: baseFieldDecoration,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Тема обращения',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    keyboardType: TextInputType.text,
                    decoration: baseFieldDecoration.copyWith(
                      hintText: 'Введите тему',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Сообщение',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    keyboardType: TextInputType.text,
                    maxLines: 5,
                    decoration: baseFieldDecoration.copyWith(
                      hintText: _messageHintText,
                      contentPadding: const EdgeInsets.all(16),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        shadowColor: _primaryColor.withValues(alpha: 0.3),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Отправить',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  InputDecoration _baseFieldDecoration({
    required Color fillColor,
    required Color borderColor,
    required Color focusColor,
    required Color hintColor,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintStyle: TextStyle(color: hintColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focusColor, width: 1.4),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  @override
  void dispose() {
    _eventsReconnectTimer?.cancel();
    _eventsSubscription?.cancel();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
