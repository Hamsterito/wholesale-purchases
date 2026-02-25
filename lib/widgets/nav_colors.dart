import 'package:flutter/material.dart';

class NavColors {
  final Color background;
  final Color foreground;
  final Color foregroundMuted;

  const NavColors({
    required this.background,
    required this.foreground,
    required this.foregroundMuted,
  });

  factory NavColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const brandBlue = Color(0xFF6288D5);
    final background = colorScheme.surface;
    final foreground = brandBlue;
    final foregroundMuted = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.82)
        : Colors.black;

    return NavColors(
      background: background,
      foreground: foreground,
      foregroundMuted: foregroundMuted,
    );
  }
}
