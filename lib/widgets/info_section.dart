import 'package:flutter/material.dart';

class InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const InfoSection({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBg = colorScheme.surface;
    final mutedText = colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      color: cardBg,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
