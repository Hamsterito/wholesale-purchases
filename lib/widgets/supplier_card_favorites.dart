import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_color_palette.dart';
import '../utils/ru_plural.dart';
import 'rating_stars.dart';
import 'smart_image.dart';

/// Компактная карточка поставщика для списка избранных компаний.
/// Показывает логотип, название, рейтинг и кнопку удаления из избранного.
class SupplierCardFavorites extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const SupplierCardFavorites({
    super.key,
    required this.supplier,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Логотип компании
              _SupplierLogo(logoUrl: supplier.logoUrl, palette: palette),
              const SizedBox(width: 12),

              // Название и рейтинг
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
                    _RatingRow(supplier: supplier, palette: palette),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Кнопка удаления из избранного
              _RemoveButton(onRemove: onRemove, palette: palette),
            ],
          ),
        ),
      ),
    );
  }
}

/// Логотип поставщика 48×48 с закруглёнными углами.
class _SupplierLogo extends StatelessWidget {
  final String? logoUrl;
  final AppColorPalette palette;

  const _SupplierLogo({required this.logoUrl, required this.palette});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: SmartImage(
        path: logoUrl ?? '',
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        placeholder: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.accentMist,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.store_outlined, size: 24, color: palette.muted),
        ),
      ),
    );
  }
}

/// Строка с рейтингом и количеством отзывов.
class _RatingRow extends StatelessWidget {
  final Supplier supplier;
  final AppColorPalette palette;

  const _RatingRow({required this.supplier, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RatingStars(
          rating: supplier.rating,
          filledColor: palette.star,
          emptyColor: palette.muted,
          size: 13,
          spacing: 1,
        ),
        const SizedBox(width: 4),
        Text(
          supplier.rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            reviewsLabel(supplier.reviewCount),
            style: TextStyle(fontSize: 11, color: palette.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Кнопка удаления компании из избранного.
class _RemoveButton extends StatelessWidget {
  final VoidCallback onRemove;
  final AppColorPalette palette;

  const _RemoveButton({required this.onRemove, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Удалить из избранного',
      button: true,
      child: IconButton(
        onPressed: onRemove,
        icon: Icon(Icons.close, size: 20, color: palette.muted),
        tooltip: 'Удалить из избранного',
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.all(4),
        ),
      ),
    );
  }
}
