import 'dart:async';
import 'package:flutter/material.dart';

import '../../theme/app_color_palette.dart';

/// Корневой Overlay для top-message. Живёт выше Navigator, монтируется в MaterialApp.builder.
final GlobalKey<OverlayState> rootMessageOverlayKey = GlobalKey<OverlayState>();

OverlayEntry? _topMessageEntry;
Timer? _topMessageTimer;
GlobalKey<_TopMessageBannerState>? _topMessageKey;

// Если true, NavigatorObserver не закрывает баннер при смене маршрута.
bool _currentMessagePersists = false;

@visibleForTesting
bool debugTopMessageHasState() =>
    _topMessageEntry != null ||
    _topMessageTimer != null ||
    _topMessageKey != null;

@visibleForTesting
void debugTopMessageReset() {
  _topMessageTimer?.cancel();
  _topMessageTimer = null;
  _topMessageEntry = null;
  _topMessageKey = null;
  _currentMessagePersists = false;
}

/// Явно закрывает активный top-message. Игнорирует persistAcrossNavigation.
/// immediate: true убирает без анимации, false запускает реверс ~180 мс.
void dismissTopMessage({bool immediate = false}) {
  // Отменяем таймер до hide(), чтобы не дёрнул hide() второй раз.
  _topMessageTimer?.cancel();
  _topMessageTimer = null;

  final state = _topMessageKey?.currentState;
  if (state != null) {
    state.hide(immediate: immediate);
    return;
  }

  // State уже нет, но в ссылках мог остаться хвост - подчищаем руками.
  _topMessageEntry?.remove();
  _topMessageEntry = null;
  _topMessageKey = null;
  _currentMessagePersists = false;
}

// Закрытие от NavigatorObserver - в отличие от публичного, уважает persist-флаг.
void _dismissForNavigation({bool immediate = false}) {
  if (_currentMessagePersists) return;
  dismissTopMessage(immediate: immediate);
}

void showTopMessage(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 2),
  String? actionText,
  VoidCallback? onAction,
  bool showCountdown = false,
  bool showClose = true,
  bool showAtBottom = false,
  double bottomOffset = 0,
  int maxLines = 1,

  /// Если true, баннер не закрывается на навигации - живёт по своему таймеру.
  bool persistAcrossNavigation = false,
}) {
  _topMessageTimer?.cancel();
  _topMessageTimer = null;
  _topMessageKey?.currentState?.hide(immediate: true);
  _topMessageKey = null;
  _topMessageEntry?.remove();
  _topMessageEntry = null;
  _currentMessagePersists = persistAcrossNavigation;

  final overlay =
      rootMessageOverlayKey.currentState ??
      Overlay.of(context, rootOverlay: true);

  void removeEntry() {
    _topMessageEntry?.remove();
    _topMessageEntry = null;
    _topMessageKey = null;
    _currentMessagePersists = false;
  }

  _topMessageKey = GlobalKey<_TopMessageBannerState>();
  VoidCallback? actionCallback;
  if (actionText != null && onAction != null) {
    actionCallback = () {
      _topMessageTimer?.cancel();
      _topMessageTimer = null;
      onAction();
      _topMessageKey?.currentState?.hide();
    };
  }

  _topMessageEntry = OverlayEntry(
    builder: (context) {
      final palette = context.colorPalette;
      final resolvedBackground = backgroundColor ?? palette.accent;
      final mediaPadding = MediaQuery.paddingOf(context);
      final resolvedBottom = showAtBottom
          ? mediaPadding.bottom + 8 + bottomOffset
          : null;
      return Positioned(
        top: showAtBottom ? null : mediaPadding.top + 8,
        bottom: resolvedBottom,
        left: 16,
        right: 16,
        child: _TopMessageBanner(
          key: _topMessageKey,
          message: message,
          backgroundColor: resolvedBackground,
          duration: duration,
          actionText: actionText,
          onAction: actionCallback,
          showCountdown: showCountdown,
          showClose: showClose,
          fromBottom: showAtBottom,
          maxLines: maxLines,
          onDismiss: removeEntry,
        ),
      );
    },
  );

  overlay.insert(_topMessageEntry!);
  if (duration > Duration.zero) {
    _topMessageTimer = Timer(
      duration,
      () => _topMessageKey?.currentState?.hide(),
    );
  }
}

class _TopMessageBanner extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final String? actionText;
  final VoidCallback? onAction;
  final bool showCountdown;
  final bool showClose;
  final bool fromBottom;
  final int maxLines;
  final VoidCallback onDismiss;

  const _TopMessageBanner({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.duration,
    this.actionText,
    this.onAction,
    required this.showCountdown,
    required this.showClose,
    required this.fromBottom,
    required this.maxLines,
    required this.onDismiss,
  });

  @override
  State<_TopMessageBanner> createState() => _TopMessageBannerState();
}

class _TopMessageBannerState extends State<_TopMessageBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _fade;
  bool _isHiding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final beginOffset = widget.fromBottom
        ? const Offset(0, 0.3)
        : const Offset(0, -0.3);
    _offset = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(curve);
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _isHiding) {
        widget.onDismiss();
      }
    });
    _controller.forward();
  }

  void hide({bool immediate = false}) {
    if (_isHiding) return;
    _isHiding = true;
    if (immediate) {
      widget.onDismiss();
      return;
    }
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final hasAction = widget.actionText != null && widget.onAction != null;
    final showCountdown =
        widget.showCountdown && widget.duration > Duration.zero;
    final showClose = widget.showClose;
    const countdownSize = 28.0;
    const bannerPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    final bannerHeight = countdownSize + bannerPadding.vertical;
    // Белый поверх цветного фона - контраст в обеих темах.
    const textColor = Colors.white;
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            padding: bannerPadding,
            height: bannerHeight,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                if (showCountdown) ...[
                  _CountdownRing(
                    duration: widget.duration,
                    color: textColor,
                    textColor: textColor,
                    size: countdownSize,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    widget.message,
                    maxLines: widget.maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasAction) ...[
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: widget.onAction,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        widget.actionText!,
                        style: const TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                if (showClose) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => hide(),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, color: textColor, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownRing extends StatefulWidget {
  const _CountdownRing({
    required this.duration,
    required this.color,
    required this.textColor,
    this.size = 28,
  });

  final Duration duration;
  final Color color;
  final Color textColor;
  final double size;

  @override
  State<_CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<_CountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
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
      builder: (context, _) {
        final progress = 1.0 - _controller.value;
        final secondsLeft = (widget.duration.inSeconds * progress).ceil().clamp(
          0,
          99,
        );
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.4,
                  color: widget.color,
                  backgroundColor: widget.color.withValues(alpha: 0.25),
                ),
              ),
              Text(
                '$secondsLeft',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: widget.textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// NavigatorObserver, закрывающий активный top-message при смене корневого маршрута.
/// Уважает persistAcrossNavigation. Подключается через MaterialApp.navigatorObservers.
class TopMessageNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _dismissForNavigation();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _dismissForNavigation();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _dismissForNavigation();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _dismissForNavigation();
  }
}
