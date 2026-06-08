import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_color_palette.dart';
import '../../services/localization/localization_extension.dart';
import '../../widgets/messages/top_message.dart';
import '../../widgets/navigation/role_internal_nav_bar.dart';

/// Одноразовый показ резервных backup-кодов 2FA.
class TwoFactorBackupCodesView extends StatelessWidget {
  const TwoFactorBackupCodesView({super.key, required this.codes, this.onDone});

  final List<String> codes;
  final VoidCallback? onDone;

  static const _monoStyle = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  String get _joinedCodes => codes.join('\n');

  String get _fileContent =>
      'Резервные коды двухфакторной аутентификации\n'
      'Сохраните их в надёжном месте - каждый код можно использовать только один раз.\n'
      '\n'
      '$_joinedCodes\n';

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _joinedCodes));
    if (!context.mounted) return;
    showTopMessage(
      context,
      'Коды скопированы в буфер обмена',
      backgroundColor: context.colorPalette.success,
    );
  }

  Future<void> _saveToFile(BuildContext context) async {
    final palette = context.colorPalette;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'backup_codes_$timestamp';
    final bytes = Uint8List.fromList(utf8.encode(_fileContent));
    try {
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'txt',
        mimeType: MimeType.text,
      );
      if (!context.mounted) return;
      showTopMessage(
        context,
        'Файл с кодами сохранён',
        backgroundColor: palette.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      showTopMessage(
        context,
        'Не удалось сохранить файл: $e',
        backgroundColor: palette.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: palette.card,
        elevation: 0,
        title: Text(
          'Резервные коды',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Резервные коды двухфакторной аутентификации',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _WarningBanner(
                message:
                    'Сохраните коды в безопасном месте — они показываются один раз. Каждый код можно использовать только однократно для входа, если потерян доступ к почте.',
              ),
              const SizedBox(height: 20),
              _CodesGrid(codes: codes),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(context.l10n.twoFactorCopyAll),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.primary,
                        side: BorderSide(color: palette.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveToFile(context),
                      icon: const Icon(Icons.download_outlined),
                      label: Text(context.l10n.twoFactorSaveFile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (onDone != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onDone,
                    style: TextButton.styleFrom(
                      foregroundColor: cs.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Готово',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.35, color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodesGrid extends StatelessWidget {
  const _CodesGrid({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Узкий экран - один столбец, иначе два.
          final isWide = constraints.maxWidth >= 360;
          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final code in codes) _CodeTile(code: code)],
            );
          }
          final left = <Widget>[];
          final right = <Widget>[];
          for (var i = 0; i < codes.length; i++) {
            final tile = _CodeTile(code: codes[i]);
            if (i.isEven) {
              left.add(tile);
            } else {
              right.add(tile);
            }
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: left,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: right,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  const _CodeTile({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SelectableText(
        code,
        style: TwoFactorBackupCodesView._monoStyle.copyWith(
          color: cs.onSurface,
        ),
      ),
    );
  }
}
