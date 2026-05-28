import 'package:flutter/material.dart';

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
    final initial = _firstLetter(displayName);

    // foregroundImage (а не backgroundImage) - чтобы при ошибке загрузки
    // child остался виден.
    return CircleAvatar(
      radius: radius,
      backgroundColor: palette.accentSoft,
      foregroundImage: hasUrl ? NetworkImage(url) : null,
      onForegroundImageError: hasUrl ? (_, __) {} : null,
      child: initial == null
          ? Icon(
              Icons.person,
              size: radius * 0.9,
              color: palette.onAccentSoft,
            )
          : Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w600,
                color: palette.onAccentSoft,
              ),
            ),
    );
  }

  static String? _firstLetter(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.characters.first.toUpperCase();
  }
}
