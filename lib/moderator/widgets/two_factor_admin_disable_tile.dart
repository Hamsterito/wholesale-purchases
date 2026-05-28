import 'package:flutter/material.dart';

import '../../services/api/two_factor_api.dart';
import '../../theme/app_color_palette.dart';
import '../../widgets/messages/top_message.dart';

/// Сигнатура загрузчика статуса - в проде TwoFactorApi.getStatus, в тестах фейк.
typedef TwoFactorStatusLoader =
    Future<TwoFactorStatus> Function({int? targetUserId});

/// Сигнатура admin-disable - точка инъекции для тестов.
typedef TwoFactorAdminDisableFn = Future<void> Function(int targetUserId);

/// Модераторский тайл принудительного отключения 2FA у целевого пользователя.
class TwoFactorAdminDisableTile extends StatefulWidget {
  const TwoFactorAdminDisableTile({
    super.key,
    required this.targetUserId,
    this.targetUserName,
    this.onDisabled,
    @visibleForTesting this.statusLoader,
    @visibleForTesting this.adminDisable,
  });

  final int targetUserId;

  /// Имя пользователя - подставляется в текст диалога подтверждения.
  final String? targetUserName;

  /// Колбэк после успешного отключения. Тайл сам перезагружает статус и скрывается.
  final VoidCallback? onDisabled;

  /// Точка инъекции для виджет-тестов; null - реальный TwoFactorApi.getStatus.
  final TwoFactorStatusLoader? statusLoader;

  /// Точка инъекции для виджет-тестов; null - TwoFactorApi.adminDisable.
  final TwoFactorAdminDisableFn? adminDisable;

  @override
  State<TwoFactorAdminDisableTile> createState() =>
      _TwoFactorAdminDisableTileState();
}

class _TwoFactorAdminDisableTileState extends State<TwoFactorAdminDisableTile> {
  bool _loading = true;
  bool _failed = false;
  TwoFactorStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void didUpdateWidget(covariant TwoFactorAdminDisableTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // targetUserId мог смениться при переиспользовании в списке.
    if (oldWidget.targetUserId != widget.targetUserId) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final loader = widget.statusLoader ?? TwoFactorApi.getStatus;
      final status = await loader(targetUserId: widget.targetUserId);
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _confirmAndDisable() async {
    if (_busy) return;
    final name = widget.targetUserName?.trim();
    final confirmText = (name != null && name.isNotEmpty)
        ? 'Это удалит все backup-коды и доверенные устройства пользователя $name. '
              'Действие нельзя отменить.'
        : 'Это удалит все backup-коды и доверенные устройства пользователя. '
              'Действие нельзя отменить.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogPalette = dialogContext.colorPalette;
        return AlertDialog(
          backgroundColor: dialogPalette.card,
          title: const Text('Отключить 2FA?'),
          content: Text(confirmText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: dialogPalette.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Отключить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final disable = widget.adminDisable ?? TwoFactorApi.adminDisable;
      await disable(widget.targetUserId);
      if (!mounted) return;
      _showTop('Двухфакторная аутентификация отключена');
      widget.onDisabled?.call();
      // После успеха перечитываем статус - тайл скроется сам (enabled=false).
      await _loadStatus();
    } on TwoFactorForbiddenException {
      if (!mounted) return;
      _showTop('Действие доступно только модераторам', isError: true);
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      _showTop(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showTop('Не удалось отключить 2FA', isError: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Молчаливо прячемся: ошибка загрузки или 2FA выключена.
    if (_failed) return const SizedBox.shrink();
    final status = _status;
    if (status == null || !status.enabled) return const SizedBox.shrink();

    final palette = context.colorPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _confirmAndDisable,
          icon: _busy
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.error),
                  ),
                )
              : Icon(Icons.shield_moon_outlined, color: palette.error),
          label: Text(
            'Отключить двухфакторную аутентификацию',
            style: TextStyle(color: palette.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: palette.error.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
