import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';

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
    final palette = AppColorPalette.of(context);

    return NavColors(
      background: palette.card,
      foreground: palette.accent,
      foregroundMuted: palette.muted,
    );
  }
}
