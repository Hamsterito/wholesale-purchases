import 'dart:async';
import 'package:flutter/material.dart';

OverlayEntry? _topMessageEntry;
Timer? _topMessageTimer;
GlobalKey<_TopMessageBannerState>? _topMessageKey;

void showTopMessage(
  BuildContext context,
  String message, {
  Color backgroundColor = const Color(0xFF6288D5),
  Duration duration = const Duration(seconds: 2),
  String? actionText,
  VoidCallback? onAction,
  bool showCountdown = false,
  bool showClose = true,
  bool showAtBottom = false,
  double bottomOffset = 0,
  int maxLines = 1,
}) {
  _topMessageTimer?.cancel();
  _topMessageTimer = null;
  _topMessageKey?.currentState?.hide(immediate: true);
  _topMessageKey = null;
  _topMessageEntry?.remove();
  _topMessageEntry = null;

  final overlay = Overlay.of(context, rootOverlay: true);

  void removeEntry() {
    _topMessageEntry?.remove();
    _topMessageEntry = null;
    _topMessageKey = null;
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
      final mediaPadding = MediaQuery.of(context).padding;
      final resolvedBottom =
          showAtBottom ? mediaPadding.bottom + 8 + bottomOffset : null;
      return Positioned(
        top: showAtBottom ? null : mediaPadding.top + 8,
        bottom: resolvedBottom,
        left: 16,
        right: 16,
        child: _TopMessageBanner(
          key: _topMessageKey,
          message: message,
          backgroundColor: backgroundColor,
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
    _offset = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curve);
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
    final hasAction = widget.actionText != null && widget.onAction != null;
    final showCountdown =
        widget.showCountdown && widget.duration > Duration.zero;
    final showClose = widget.showClose;
    const countdownSize = 28.0;
    const bannerPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    final bannerHeight = countdownSize + bannerPadding.vertical;
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
                  color: Colors.black.withValues(alpha: 0.2),
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
                    color: Colors.white,
                    textColor: Colors.white,
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
                      color: Colors.white,
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
                          color: Colors.white,
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
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.white, size: 18),
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
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
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
        final secondsLeft =
            (widget.duration.inSeconds * progress).ceil().clamp(0, 99);
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
