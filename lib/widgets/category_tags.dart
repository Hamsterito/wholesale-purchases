import 'package:flutter/material.dart';

class CategoryTags extends StatelessWidget {
  final List<String> categories;

  const CategoryTags({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final chipBg = isDark
        ? colorScheme.primary.withValues(alpha: 0.22)
        : colorScheme.surfaceVariant;
    final chipText = isDark ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map((category) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 12,
                color: chipText,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
