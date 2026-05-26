import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color_palette.dart';

/// Состояние доставки пузыря в чат-ленте.
enum ChatBubbleDeliveryState { pending, sent, failed }

/// Минимальная модель пузыря для ChatThreadView. clientId нужен для
/// сопоставления оптимистичной отправки с серверным ответом.
class ChatBubbleData {
  final String id;
  final String? clientId;
  final int senderId;
  final String body;
  final DateTime createdAt;
  final ChatBubbleDeliveryState deliveryState;
  final String? avatarUrl;

  const ChatBubbleData({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.clientId,
    this.deliveryState = ChatBubbleDeliveryState.sent,
    this.avatarUrl,
  });
}

/// Лента чата с композером. AppBar - на стороне страницы.
class ChatThreadView extends StatefulWidget {
  const ChatThreadView({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.counterpartName,
    required this.onSend,
    required this.onRetrySend,
    required this.onLoadMore,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.isComposerEnabled,
    required this.composerHint,
    this.error,
    this.onRetry,
    this.composerMaxLength,
    this.composerCounterThreshold,
  });

  final List<ChatBubbleData> messages;
  final int currentUserId;
  final String counterpartName;

  /// Отправка сообщения. Триминг и валидацию делает страница.
  final Future<void> Function(String text) onSend;

  /// Повторная отправка failed-пузыря.
  final void Function(ChatBubbleData bubble) onRetrySend;

  /// Подгрузка более старой страницы при приближении к верху.
  final VoidCallback onLoadMore;

  /// Повтор начальной загрузки. Если не задан - используется onLoadMore.
  final VoidCallback? onRetry;

  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isComposerEnabled;
  final String composerHint;

  /// Текст ошибки начальной загрузки. Если не null - рендерим error-state.
  final String? error;

  /// Жёсткий лимит длины ввода через LengthLimitingTextInputFormatter.
  final int? composerMaxLength;

  /// Порог, после которого появляется счётчик символов length/max.
  /// Без composerMaxLength не имеет смысла.
  final int? composerCounterThreshold;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Триггер для load-more: чтобы не дёргать onLoadMore в каждом скролл-тике.
  bool _isLoadMoreInFlight = false;

  // На пустой ленте maxScrollExtent == 0 - считаем, что мы внизу, чтобы
  // первое сообщение красиво появилось в зоне видимости.
  bool _isAtBottom = true;

  // Исходящие пузыри, которые уже мигали enter-анимацией. На повторных
  // rebuild'ах и рециклинге ListView анимация не должна перезапускаться.
  final Set<String> _seenOutgoingIds = <String>{};

  // Композер дизейблится не только пропом, но и при загрузке/ошибке.
  bool get _composerEnabled =>
      widget.isComposerEnabled &&
      !widget.isInitialLoading &&
      widget.error == null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _composerController.addListener(_onComposerChanged);
    // Уже отрендеренные исходящие - считаем виденными, чтобы история не
    // мигала enter-анимацией при заходе на экран.
    for (final m in widget.messages) {
      if (m.senderId == widget.currentUserId) {
        _seenOutgoingIds.add(m.id);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoadingMore && !widget.isLoadingMore) {
      _isLoadMoreInFlight = false;
    }

    // Снимок позиции до перестройки списка.
    final wasAtBottom = _isAtBottom;
    final hasNewMessages = widget.messages.length > oldWidget.messages.length;

    if (hasNewMessages && wasAtBottom) {
      // Ждём пересборку, иначе maxScrollExtent ещё не учёл новые сообщения.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _composerController
      ..removeListener(_onComposerChanged)
      ..dispose();
    super.dispose();
  }

  void _onComposerChanged() {
    // Перерисовываем для активации/деактивации кнопки отправки.
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    // 32 px - пользователь «у дна», даже если докрутил почти до самого низа.
    _isAtBottom = position.pixels >= position.maxScrollExtent - 32;

    if (widget.isLoadingMore || _isLoadMoreInFlight) return;
    // Верх списка - самые старые сообщения. Отсюда подгружаем старую страницу.
    if (position.pixels <= 80) {
      _isLoadMoreInFlight = true;
      widget.onLoadMore();
    }
  }

  Future<void> _handleSend() async {
    final text = _composerController.text;
    if (text.trim().isEmpty) return;
    if (!_composerEnabled) return;

    // Очищаем поле сразу - страница сама создаст оптимистичный пузырь.
    _composerController.clear();
    await widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(child: _buildBody(colorScheme)),
        _buildComposer(colorScheme),
      ],
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (widget.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.error != null) {
      return _ErrorState(
        message: widget.error!,
        onRetry: widget.onRetry ?? widget.onLoadMore,
      );
    }
    if (widget.messages.isEmpty) {
      return _EmptyState(counterpartName: widget.counterpartName);
    }
    return _buildMessagesList(colorScheme);
  }

  Widget _buildMessagesList(ColorScheme colorScheme) {
    // Разворачиваем плоский список сообщений в render-слоты: разделители дней
    // и пузыри с разметкой кластеризации. Пересчитывается на каждый build -
    // это O(n) и проще, чем держать кэш.
    final slots = _buildRenderSlots(widget.messages, widget.currentUserId);
    // +1 если рендерим верхний лоадер для пагинации.
    final headerSlot = widget.isLoadingMore ? 1 : 0;
    final itemCount = slots.length + headerSlot;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (headerSlot == 1 && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final slot = slots[index - headerSlot];
        if (slot is _DaySeparatorSlot) {
          return _DaySeparator(day: slot.day);
        }
        final bubbleSlot = slot as _BubbleSlot;
        final bubble = _MessageBubble(
          slot: bubbleSlot,
          colorScheme: colorScheme,
          onRetrySend: widget.onRetrySend,
        );
        // Анимируем только первое появление исходящего пузыря.
        if (bubbleSlot.isOutgoing &&
            !_seenOutgoingIds.contains(bubbleSlot.bubble.id)) {
          _seenOutgoingIds.add(bubbleSlot.bubble.id);
          return _AnimatedOutgoingBubble(
            key: ValueKey('outgoing-anim-${bubbleSlot.bubble.id}'),
            child: bubble,
          );
        }
        return bubble;
      },
    );
  }

  Widget _buildComposer(ColorScheme colorScheme) {
    final hasText = _composerController.text.trim().isNotEmpty;
    final canSend = _composerEnabled && hasText;

    final maxLength = widget.composerMaxLength;
    final counterThreshold = widget.composerCounterThreshold;
    // Считаем по UTF-16 как LengthLimitingTextInputFormatter, иначе порог
    // обрезки и порог счётчика разойдутся на эмодзи.
    final currentLength = _composerController.text.length;
    // Счётчик появляется только при приближении к лимиту.
    final showCounter =
        maxLength != null &&
        counterThreshold != null &&
        currentLength > counterThreshold;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _composerController,
                    enabled: _composerEnabled,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 5,
                    inputFormatters: maxLength != null
                        ? [LengthLimitingTextInputFormatter(maxLength)]
                        : null,
                    decoration: InputDecoration(
                      hintText: widget.composerHint,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(
                  enabled: canSend,
                  onPressed: _handleSend,
                  colorScheme: colorScheme,
                ),
              ],
            ),
            if (showCounter)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Text(
                  '$currentLength/$maxLength',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colorPalette.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Render-слоты ленты

/// Базовый класс слота. Используется при сборке списка через ListView.builder.
abstract class _RenderSlot {
  const _RenderSlot();
}

/// Разделитель календарного дня (в локальной таймзоне устройства).
class _DaySeparatorSlot extends _RenderSlot {
  final DateTime day;
  const _DaySeparatorSlot(this.day);
}

/// Один пузырь с метаданными о его положении в кластере.
class _BubbleSlot extends _RenderSlot {
  final ChatBubbleData bubble;
  final bool isOutgoing;
  final bool isFirstInCluster;
  final bool isLastInCluster;
  const _BubbleSlot({
    required this.bubble,
    required this.isOutgoing,
    required this.isFirstInCluster,
    required this.isLastInCluster,
  });
}

/// Развернуть плоский список сообщений в последовательность render-слотов.
/// Сообщения от одного автора в пределах 5 минут считаются одним кластером.
List<_RenderSlot> _buildRenderSlots(
  List<ChatBubbleData> messages,
  int currentUserId,
) {
  final slots = <_RenderSlot>[];
  for (var i = 0; i < messages.length; i++) {
    final m = messages[i];
    final prev = i > 0 ? messages[i - 1] : null;
    final next = i < messages.length - 1 ? messages[i + 1] : null;

    // Разделитель дня - на старте ленты и при смене календарного дня.
    if (prev == null || !_isSameLocalDay(prev.createdAt, m.createdAt)) {
      slots.add(_DaySeparatorSlot(m.createdAt.toLocal()));
    }

    final isFirstInCluster =
        prev == null ||
        prev.senderId != m.senderId ||
        !_isSameLocalDay(prev.createdAt, m.createdAt) ||
        _gapSeconds(prev.createdAt, m.createdAt) >= 300;

    final isLastInCluster =
        next == null ||
        next.senderId != m.senderId ||
        !_isSameLocalDay(next.createdAt, m.createdAt) ||
        _gapSeconds(m.createdAt, next.createdAt) >= 300;

    slots.add(
      _BubbleSlot(
        bubble: m,
        isOutgoing: m.senderId == currentUserId,
        isFirstInCluster: isFirstInCluster,
        isLastInCluster: isLastInCluster,
      ),
    );
  }
  return slots;
}

bool _isSameLocalDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

int _gapSeconds(DateTime a, DateTime b) => b.difference(a).inSeconds.abs();

String _formatHm(DateTime dt) {
  final local = dt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Локализованная подпись разделителя дня. intl в зависимостях нет, поэтому
/// используем ручную таблицу русских месяцев в родительном падеже.
String _formatDayLabel(DateTime day, DateTime now) {
  const months = <String>[
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  final local = day.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final that = DateTime(local.year, local.month, local.day);
  if (that == today) return 'Сегодня';
  if (that == yesterday) return 'Вчера';
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDayLabel(day, DateTime.now()),
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.slot,
    required this.colorScheme,
    required this.onRetrySend,
  });

  final _BubbleSlot slot;
  final ColorScheme colorScheme;
  final void Function(ChatBubbleData) onRetrySend;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = slot.isOutgoing;
    final data = slot.bubble;

    final bubbleColor = isOutgoing
        ? colorScheme.primary
        : colorScheme.surfaceContainer;
    final textColor = isOutgoing
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    // Внутри кластера сжимаем отступ; между кластерами оставляем воздух.
    final topPadding = slot.isFirstInCluster ? 8.0 : 2.0;

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          data.body,
          style: TextStyle(color: textColor, fontSize: 14, height: 1.3),
        ),
      ),
    );

    final timeAndDelivery = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatHm(data.createdAt),
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          // Иконка доставки только для pending/failed; sent - без иконки.
          if (isOutgoing &&
              data.deliveryState != ChatBubbleDeliveryState.sent) ...[
            const SizedBox(width: 4),
            _DeliveryIcon(
              state: data.deliveryState,
              colorScheme: colorScheme,
              onRetry: () => onRetrySend(data),
            ),
          ],
        ],
      ),
    );

    final bubbleColumn = Column(
      crossAxisAlignment: isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [bubble, timeAndDelivery],
    );

    // Аватар - только у нижнего пузыря кластера на стороне собеседника.
    final showAvatar = !isOutgoing && slot.isLastInCluster;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isOutgoing
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isOutgoing) ...[
            SizedBox(
              width: 32,
              child: showAvatar
                  ? _Avatar(url: data.avatarUrl)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubbleColumn),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasUrl = url != null && url!.isNotEmpty;
    return CircleAvatar(
      radius: 16,
      backgroundColor: cs.surfaceContainerHighest,
      backgroundImage: hasUrl ? NetworkImage(url!) : null,
      child: hasUrl
          ? null
          : Icon(Icons.person, size: 18, color: cs.onSurfaceVariant),
    );
  }
}

class _DeliveryIcon extends StatelessWidget {
  const _DeliveryIcon({
    required this.state,
    required this.colorScheme,
    required this.onRetry,
  });

  final ChatBubbleDeliveryState state;
  final ColorScheme colorScheme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ChatBubbleDeliveryState.pending:
        return Icon(
          Icons.access_time,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        );
      case ChatBubbleDeliveryState.sent:
        // sent не рисуем: время уже сигнализирует, что сообщение отправлено.
        return const SizedBox.shrink();
      case ChatBubbleDeliveryState.failed:
        // Тап-таргет 44×44 - иконка ошибки в IconButton с фиксированным размером.
        return SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tooltip: 'Повторить отправку',
            onPressed: onRetry,
            icon: Icon(Icons.error_outline, color: colorScheme.error),
          ),
        );
    }
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.onPressed,
    required this.colorScheme,
  });

  final bool enabled;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: enabled
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: Icon(Icons.send, color: colorScheme.onPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.counterpartName});

  final String counterpartName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Сообщений пока нет',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Напишите первое сообщение${counterpartName.isNotEmpty ? ' - $counterpartName ответит здесь' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

/// Enter-анимация исходящего пузыря: 200 мс easeOut, opacity 0→1 и сдвиг
/// (0,8)→(0,0). Ключ задаётся снаружи, чтобы анимация не перезапускалась.
class _AnimatedOutgoingBubble extends StatefulWidget {
  const _AnimatedOutgoingBubble({super.key, required this.child});

  final Widget child;

  @override
  State<_AnimatedOutgoingBubble> createState() =>
      _AnimatedOutgoingBubbleState();
}

class _AnimatedOutgoingBubbleState extends State<_AnimatedOutgoingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    // Абсолютный сдвиг в px, не FractionalTranslation.
    _offset = Tween<Offset>(
      begin: const Offset(0, 8),
      end: Offset.zero,
    ).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(offset: _offset.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}
