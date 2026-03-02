import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final Color? halfColor;
  final double spacing;

  const RatingStars({
    super.key,
    required this.rating,
    required this.filledColor,
    required this.emptyColor,
    this.maxStars = 5,
    this.size = 14,
    this.halfColor,
    this.spacing = 0,
  });

  double get _clampedRating => rating.clamp(0, maxStars).toDouble();

  double _starFill(int index) {
    final remaining = _clampedRating - index;
    if (remaining >= 0.75) {
      return 1;
    }
    if (remaining >= 0.25) {
      return 0.5;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final fill = _starFill(index);
        final icon = fill == 1
            ? Icons.star_rounded
            : fill == 0.5
            ? Icons.star_half_rounded
            : Icons.star_outline_rounded;
        final color = fill == 1
            ? filledColor
            : fill == 0.5
            ? (halfColor ?? filledColor)
            : emptyColor;
        return Padding(
          padding: EdgeInsets.only(right: index == maxStars - 1 ? 0 : spacing),
          child: Icon(icon, size: size, color: color),
        );
      }),
    );
  }
}
