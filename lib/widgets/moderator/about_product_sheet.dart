import 'package:flutter/material.dart';

import '../../models/language.dart';
import '../../models/supplier_product.dart';
import '../../services/localization/localization_extension.dart';
import '../../theme/app_color_palette.dart';
import '../../utils/characteristic_sections.dart';
import '../smooth_sheet.dart';

/// Bottom sheet «О товаре»: табы «Характеристики»/«Описание» с прокруткой
/// по якорям. Принимает готовые секции - подходит и покупателю, и модератору.
void showAboutProductSheet({
  required BuildContext context,
  required List<CharacteristicSection> sections,
  required String description,
  SupplierProduct? supplierProduct,
}) {
  final palette = context.colorPalette;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: palette.card,
    isScrollControlled: true,
    transitionAnimationController: smoothBottomSheetController(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        // Snap к initialChildSize - короткий свайп вниз возвращает к исходной высоте.
        initialChildSize: 0.94,
        minChildSize: 0.6,
        maxChildSize: 0.94,
        snap: true,
        snapSizes: const [0.94],
        builder: (context, scrollController) {
          return AboutProductSheet(
            sections: sections,
            description: description,
            supplierProduct: supplierProduct,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

/// Содержимое bottom sheet - вынесено, чтобы можно было встраивать в свой DraggableScrollableSheet.
class AboutProductSheet extends StatefulWidget {
  const AboutProductSheet({
    super.key,
    required this.sections,
    required this.description,
    required this.scrollController,
    this.supplierProduct,
  });

  final List<CharacteristicSection> sections;
  final String description;
  final ScrollController scrollController;
  final SupplierProduct? supplierProduct;

  @override
  State<AboutProductSheet> createState() => _AboutProductSheetState();
}

class _AboutProductSheetState extends State<AboutProductSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey _characteristicsKey = GlobalKey();
  final GlobalKey _descriptionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabTapped);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabTapped);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTapped() {
    if (!_tabController.indexIsChanging) return;
    final targetKey = _tabController.index == 0
        ? _characteristicsKey
        : _descriptionKey;
    final ctx = targetKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final hasContent =
        widget.sections.isNotEmpty || widget.description.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: palette.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.getString('auto_oTovare'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: palette.ink),
                tooltip: context.l10n.getString('auto_zakryt'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.supplierProduct != null) ...[
            Text(
              widget.supplierProduct!.localizedName(context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            if (context.currentLanguage == LanguageCode.kazakh && widget.supplierProduct!.nameKk.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'RU: ${widget.supplierProduct!.name}',
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              )
            else if (context.currentLanguage != LanguageCode.kazakh && widget.supplierProduct!.nameKk.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'КК: ${widget.supplierProduct!.nameKk}',
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              ),
            const SizedBox(height: 12),
            if (widget.supplierProduct!.categories.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in widget.supplierProduct!.categories)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Text(
                        context.currentLanguage == LanguageCode.kazakh && widget.supplierProduct!.categoryKk.isNotEmpty 
                            ? widget.supplierProduct!.categoryKk 
                            : category,
                        style: TextStyle(fontSize: 13, color: palette.ink),
                      ),
                    ),
                ],
              ),
              if (context.currentLanguage == LanguageCode.kazakh && widget.supplierProduct!.categoryKk.isNotEmpty && widget.supplierProduct!.categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'RU: ${widget.supplierProduct!.categories.first}',
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                )
              else if (context.currentLanguage != LanguageCode.kazakh && widget.supplierProduct!.categoryKk.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'КК: ${widget.supplierProduct!.categoryKk}',
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            Divider(height: 1, thickness: 1, color: palette.line),
            const SizedBox(height: 12),
          ],
          if (hasContent)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: palette.accent,
              indicatorWeight: 3,
              labelColor: palette.ink,
              unselectedLabelColor: palette.muted,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: context.l10n.getString('auto_harakteristiki')),
                Tab(text: context.l10n.getString('auto_opisanie_1')),
              ],
            ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: !hasContent
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        context.l10n.getString('auto_netDannyhOTovare'),
                        style: TextStyle(fontSize: 14, color: palette.muted),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.sections.isNotEmpty) ...[
                          KeyedSubtree(
                            key: _characteristicsKey,
                            child: _CharacteristicsList(
                              sections: widget.sections,
                              supplierProduct: widget.supplierProduct,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else
                          KeyedSubtree(
                            key: _characteristicsKey,
                            child: const SizedBox.shrink(),
                          ),
                        Padding(
                          key: _descriptionKey,
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            context.l10n.getString('auto_opisanie_1'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        _DescriptionBlock(
                          description: widget.description,
                          supplierProduct: widget.supplierProduct,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ));
  }
}

class _CharacteristicsList extends StatelessWidget {
  const _CharacteristicsList({required this.sections, this.supplierProduct});

  final List<CharacteristicSection> sections;
  final SupplierProduct? supplierProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          _CharacteristicSectionView(
            section: sections[i],
            supplierProduct: supplierProduct,
          ),
          if (i != sections.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  const _DescriptionBlock({required this.description, this.supplierProduct});

  final String description;
  final SupplierProduct? supplierProduct;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final isKk = context.currentLanguage == LanguageCode.kazakh;
    final primaryDesc = isKk && supplierProduct != null && supplierProduct!.descriptionKk.trim().isNotEmpty
        ? supplierProduct!.descriptionKk.trim()
        : description;
        
    final secondaryDesc = isKk && supplierProduct != null && supplierProduct!.descriptionKk.trim().isNotEmpty
        ? 'RU: $description'
        : (supplierProduct != null && supplierProduct!.descriptionKk.trim().isNotEmpty ? 'КК: ${supplierProduct!.descriptionKk.trim()}' : null);

    final isPlaceholder = shouldShowDescriptionPlaceholder(primaryDesc);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isPlaceholder
              ? Text(
                  context.l10n.getString('auto_opisanieNeUkazano'),
                  style: TextStyle(fontSize: 14, color: palette.muted),
                )
              : Text(
                  primaryDesc,
                  softWrap: true,
                  style: TextStyle(fontSize: 14, color: palette.ink, height: 1.4),
                ),
          if (!isPlaceholder && secondaryDesc != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                secondaryDesc,
                style: TextStyle(fontSize: 13, color: palette.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _CharacteristicSectionView extends StatelessWidget {
  const _CharacteristicSectionView({required this.section, this.supplierProduct});

  final CharacteristicSection section;
  final SupplierProduct? supplierProduct;

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final items = section.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            section.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
        ),
        for (var i = 0; i < items.length; i++) ...[
          _buildItem(palette, items[i]),
          if (i != items.length - 1)
            Divider(height: 1, thickness: 1, color: palette.line),
        ],
      ],
    );
  }

  Widget _buildItem(AppColorPalette palette, CharacteristicItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              item.primaryKey,
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.primaryValue,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 14, color: palette.ink),
                ),
                if (item.secondaryValue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.secondaryValue!,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
