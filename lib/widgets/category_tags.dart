import 'package:flutter/material.dart';

class CategoryTags extends StatelessWidget {
  final List<String> categories;

  const CategoryTags({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map((category) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EFFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6288D5),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
