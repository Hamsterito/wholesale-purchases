import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_color_palette.dart';
import '../product/supplier_profile_header.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';

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

    // Логотип и строка рейтинга переиспользуются из supplier_profile_header.dart,
    // чтобы стиль карточки поставщика не разъезжался при правках в одном месте.
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
              const SizedBox(width: 8),

              _RemoveButton(onRemove: onRemove, palette: palette),
            ],
          ),
        ),
      ),
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
      label: context.l10n.getString('auto_udalitIzIzbrannogo'),
      button: true,
      child: IconButton(
        onPressed: onRemove,
        icon: Icon(Icons.close, size: 20, color: palette.muted),
        tooltip: context.l10n.getString('auto_udalitIzIzbrannogo'),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.all(4),
        ),
      ),
    );
  }
}
