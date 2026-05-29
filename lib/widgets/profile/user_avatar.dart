import 'package:flutter/material.dart';

import '../../services/app_logger.dart';
import '../../theme/app_color_palette.dart';

/// Единая точка отображения аватарки пользователя.
/// При ошибке загрузки картинки откатывается к placeholder, а не падает.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    this.radius = 20,
  });

  final String? avatarUrl;
  final String displayName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final url = avatarUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final placeholder = _buildPlaceholder(palette);

    if (!hasUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: palette.accentSoft,
        child: placeholder,
      );
    }

    final diameter = radius * 2;

    // Image.network с errorBuilder вместо foregroundImage: даёт доступ к
    // объекту ошибки (для лога) и не оставляет в imageCache застрявший
    // failed-результат на всю сессию - при следующем ребилде Flutter
    // перезапросит картинку.
    return CircleAvatar(
      radius: radius,
      backgroundColor: palette.accentSoft,
      child: ClipOval(
        child: Image.network(
          url,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return placeholder;
          },
          errorBuilder: (context, error, stackTrace) {
            AppLogger.warning(
              'Не удалось загрузить аватарку: $url ($error)',
              scope: 'avatar',
            );
            // Сбрасываем failed-запись, чтобы повторный показ этого URL
            // (после восстановления сети или перезапуска бэкенда) снова
            // попытался загрузиться, а не отдавал кэшированную ошибку.
            _evictFailedImage(url);
            return placeholder;
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AppColorPalette palette) {
    final initial = _firstLetter(displayName);
    if (initial == null) {
      return Icon(
        Icons.person,
        size: radius * 0.9,
        color: palette.onAccentSoft,
      );
    }
    return Text(
      initial,
      style: TextStyle(
        fontSize: radius * 0.8,
        fontWeight: FontWeight.w600,
        color: palette.onAccentSoft,
      ),
    );
  }

  static void _evictFailedImage(String url) {
    // evict нельзя вызывать прямо в билде - откладываем на конец кадра.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NetworkImage(url).evict();
    });
  }

  static String? _firstLetter(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.characters.first.toUpperCase();
  }
}
