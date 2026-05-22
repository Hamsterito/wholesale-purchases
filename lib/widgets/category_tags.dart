import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';

class CategoryTags extends StatelessWidget {
  final List<String> categories;
  final WrapAlignment alignment;

  const CategoryTags({
    super.key,
    required this.categories,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

    return Container(
      width: double.infinity,
      color: palette.card,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: alignment,
        children: categories.map((category) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 12,
                color: palette.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
