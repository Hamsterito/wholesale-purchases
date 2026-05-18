import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final Color? halfColor;
  final double spacing;
  final bool showContainer;
  final bool showLabel;

  const RatingStars({
    super.key,
    required this.rating,
    required this.filledColor,
    required this.emptyColor,
    this.maxStars = 5,
    this.size = 14,
    this.halfColor,
    this.spacing = 0,
    this.showContainer = false,
    this.showLabel = false,
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

  Widget _buildStars() {
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

  @override
  Widget build(BuildContext context) {
    if (!showContainer) {
      return _buildStars();
    }

    // Красивый контейнер со звёздами и рейтингом
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStars(),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size + 2,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
