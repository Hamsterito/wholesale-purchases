import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/supplier_stats_store.dart';
import '../theme/app_color_palette.dart';
import '../utils/rating_format.dart';
import '../utils/ru_plural.dart';
import 'rating_stars.dart';
import 'smart_image.dart';

/// Шапка профиля поставщика. Логотип 48×48, имя 15sp w600, рейтинг и отзывы.
/// Используется внутри карточки товара и для переиспользования в избранном.
class SupplierProfileHeader extends StatelessWidget {
  const SupplierProfileHeader({
    super.key,
    required this.supplier,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.showChevron = true,
  });

  final Supplier supplier;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            SupplierLogo(logoUrl: supplier.logoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SupplierRatingRow(supplier: supplier),
                ],
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: palette.muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Логотип поставщика 48×48 со скруглением 8.
/// При пустом/null/whitespace logoUrl рисуется Icons.store_outlined на accentMist.
class SupplierLogo extends StatelessWidget {
  const SupplierLogo({super.key, required this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final placeholder = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: palette.accentMist,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.store_outlined, size: 24, color: palette.muted),
    );

    // SmartImage сам триммит путь и показывает placeholder для пустой строки,
    // поэтому передаём logoUrl ?? '' и единый плейсхолдер для всех null/пустых/whitespace.
    return SizedBox(
      width: 48,
      height: 48,
      child: SmartImage(
        path: logoUrl ?? '',
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        placeholder: placeholder,
      ),
    );
  }
}

/// Строка рейтинга со звёздами, числом и количеством отзывов.
class SupplierRatingRow extends StatelessWidget {
  const SupplierRatingRow({super.key, required this.supplier});

  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    return AnimatedBuilder(
      animation: SupplierStatsStore.instance,
      builder: (context, _) {
        final rating = SupplierStatsStore.instance.rating(
          supplier.id,
          fallback: supplier.rating,
        );
        final reviewCount = SupplierStatsStore.instance.reviewCount(
          supplier.id,
          fallback: supplier.reviewCount,
        );
        return Row(
          children: [
            RatingStars(
              rating: rating,
              filledColor: palette.star,
              emptyColor: palette.muted,
              size: 13,
              spacing: 1,
            ),
            const SizedBox(width: 4),
            Text(
              formatRating(rating),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                reviewsLabel(reviewCount),
                style: TextStyle(fontSize: 11, color: palette.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
