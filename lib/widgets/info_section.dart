import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';

class InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const InfoSection({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

    return Container(
      width: double.infinity,
      color: palette.card,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(fontSize: 13, color: palette.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
