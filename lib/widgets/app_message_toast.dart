import 'dart:async';

import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/app_settings.dart';
import 'app_message_snackbar.dart' show AppMessageMetrics, severityFillColor;

/// Краткосрочный toast по центру экрана. Скрывается автоматически через 2000 мс.
class AppMessageToast {
  AppMessageToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;

  /// Показывает toast; null или whitespace-only message - no-op.
  /// Повторный вызов заменяет текущий toast и сбрасывает таймер.
  static void show(BuildContext context, Message? message) {
    if (message == null) return;
    final t = message.title.trim();
    final b = message.body.trim();
    if (t.isEmpty && b.isEmpty) return;

    _dismissCurrent();

    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(builder: (ctx) => _ToastView(message: message));
    overlay.insert(entry);
    _currentEntry = entry;

    _currentTimer = Timer(const Duration(milliseconds: 2000), _dismissCurrent);
  }

  static void _dismissCurrent() {
    _currentTimer?.cancel();
    _currentTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final t = message.title.trim();
    final b = message.body.trim();
    final text = t.isNotEmpty ? t : b;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Semantics(
          liveRegion: true,
          label: text,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppSettings.themeMode,
                  builder: (ctx, _, __) => _buildBody(ctx, text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String text) {
    final fill = severityFillColor(message.severity, context);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: AppMessageMetrics.padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppMessageMetrics.borderRadius),
          boxShadow: AppMessageMetrics.shadow(context),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
