import 'package:flutter/material.dart';

import '../services/templates_store.dart';
import '../theme/app_color_palette.dart';
import 'smart_image.dart';
import 'smooth_sheet.dart';

/// Bottom sheet со списком шаблонов покупок. Apply/rename/delete отдаёт
/// колбэками наружу - координация диалогов и undo живёт в cart_page.
class TemplatesSheet extends StatefulWidget {
  const TemplatesSheet({
    super.key,
    required this.onApply,
    required this.onRename,
    required this.onDelete,
  });

  /// Вызывается при нажатии «Добавить в корзину». Каллер сам решает,
  /// нужно ли подтверждение и как закрывать sheet.
  final Future<void> Function(PurchaseTemplate template) onApply;

  /// Вызывается при выборе «Переименовать» в меню шаблона.
  final Future<void> Function(PurchaseTemplate template) onRename;

  /// Вызывается при выборе «Удалить» в меню шаблона.
  final Future<void> Function(PurchaseTemplate template) onDelete;

  @override
  State<TemplatesSheet> createState() => _TemplatesSheetState();
}

class _TemplatesSheetState extends State<TemplatesSheet> {
  final TemplatesStore _store = TemplatesStore.instance;
  // id раскрытого шаблона - одновременно раскрыт максимум один, чтобы
  // длинные шаблоны не схлопывались друг под другом.
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {
      // Если раскрытый шаблон удалили - закрываем раскрытие.
      final id = _expandedId;
      if (id != null && _store.templates.every((t) => t.id != id)) {
        _expandedId = null;
      }
    });
  }

  void _toggleExpanded(String id) {
    setState(() {
      _expandedId = _expandedId == id ? null : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final templates = _store.templates;

    // Ограничиваем масштабирование текста сверху до 2.0 - иначе длинные
    // строки шаблона ломают вёрстку карточки.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 2.0,
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(palette),
              _buildHeader(context, palette),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  // Для пустого состояния держим один элемент-плейсхолдер,
                  // чтобы не плодить отдельные ветки в build.
                  itemCount: templates.isEmpty ? 1 : templates.length,
                  itemBuilder: (context, index) {
                    if (templates.isEmpty) {
                      return _EmptyState(palette: palette);
                    }
                    final template = templates[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TemplateCard(
                        template: template,
                        palette: palette,
                        expanded: _expandedId == template.id,
                        onToggleExpand: () => _toggleExpanded(template.id),
                        onApply: () => widget.onApply(template),
                        onRename: () => widget.onRename(template),
                        onDelete: () => widget.onDelete(template),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(AppColorPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: palette.line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Шаблоны покупок',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Свернуть',
            icon: Icon(Icons.close, color: palette.muted),
            // Возвращаем minimized=true, чтобы cart_page показал FAB
            // и дал быстро открыть sheet обратно.
            onPressed: () =>
                Navigator.of(context).pop(TemplatesSheetResult.minimized),
          ),
        ],
      ),
    );
  }
}

/// Результат закрытия sheet. minimized - нажат крестик (хотим показать FAB),
/// dismissed/null - обычное закрытие (swipe, тап по затемнению, back).
enum TemplatesSheetResult { minimized, dismissed }

/// Открывает sheet списка шаблонов. minimized - пользователь свернул через крестик.
Future<TemplatesSheetResult?> showTemplatesSheet(
  BuildContext context, {
  required Future<void> Function(PurchaseTemplate template) onApply,
  required Future<void> Function(PurchaseTemplate template) onRename,
  required Future<void> Function(PurchaseTemplate template) onDelete,
}) {
  return showModalBottomSheet<TemplatesSheetResult>(
    context: context,
    isScrollControlled: true,
    transitionAnimationController: smoothBottomSheetController(context),
    backgroundColor: context.colorPalette.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => TemplatesSheet(
      onApply: onApply,
      onRename: onRename,
      onDelete: onDelete,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final AppColorPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 48, color: palette.muted),
          const SizedBox(height: 12),
          Text(
            'Нет сохранённых шаблонов',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Добавьте товары в корзину и сохраните их как шаблон',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  _TemplateCard({
    required this.template,
    required this.palette,
    required this.expanded,
    required this.onToggleExpand,
    required this.onApply,
    required this.onRename,
    required this.onDelete,
  }) : _totalUnits = template.items.fold<int>(0, (s, i) => s + i.quantity),
       _totalAmount = template.items.fold<int>(
         0,
         (s, i) => s + i.pricePerUnit * i.quantity,
       );

  final PurchaseTemplate template;
  final AppColorPalette palette;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onApply;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  // Кэшируем тяжёлые суммы один раз при создании карточки, а не в build.
  final int _totalUnits;
  final int _totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderRow(context),
          // AnimatedSize даёт плавную смену высоты карточки. ClipRect
          // обрезает контент во время сжатия. Без AnimatedSwitcher -
          // он создавал двойную анимацию поверх AnimatedSize и тормозил.
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? _buildItemsList()
                  : const SizedBox(width: double.infinity),
            ),
          ),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return InkWell(
      onTap: onToggleExpand,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _summaryLine(),
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                ],
              ),
            ),
            _buildMenu(context),
            IconButton(
              tooltip: expanded ? 'Свернуть' : 'Раскрыть',
              icon: AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(Icons.keyboard_arrow_down, color: palette.muted),
              ),
              onPressed: onToggleExpand,
            ),
          ],
        ),
      ),
    );
  }

  String _summaryLine() {
    final positions = template.items.length;
    final units = _totalUnits;
    final amount = _formatPrice(_totalAmount);
    return '$positions поз. · $units шт · $amount ₸';
  }

  static String _formatPrice(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      final remaining = str.length - i;
      buf.write(str[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(' ');
    }
    return buf.toString();
  }

  Widget _buildMenu(BuildContext context) {
    return PopupMenuButton<_TemplateAction>(
      tooltip: 'Действия',
      icon: Icon(Icons.more_vert, color: palette.muted),
      color: palette.card,
      onSelected: (action) {
        switch (action) {
          case _TemplateAction.rename:
            onRename();
            break;
          case _TemplateAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _TemplateAction.rename,
          child: Semantics(
            button: true,
            label: 'Переименовать шаблон ${template.name}',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18, color: palette.muted),
                const SizedBox(width: 10),
                Text(
                  'Переименовать',
                  style: TextStyle(color: palette.ink, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: _TemplateAction.delete,
          child: Semantics(
            button: true,
            label: 'Удалить шаблон ${template.name}',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: palette.error),
                const SizedBox(width: 10),
                Text(
                  'Удалить',
                  style: TextStyle(color: palette.error, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: palette.line),
          // shrinkWrap + NeverScrollable - скроллит родительский ListView,
          // вложенный считает высоту по содержимому.
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8),
            itemCount: template.items.length,
            itemBuilder: (context, index) {
              final item = template.items[index];
              return _TemplateItemRow(item: item, palette: palette);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Semantics(
        button: true,
        label: 'Добавить шаблон ${template.name} в корзину',
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Добавить в корзину',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateItemRow extends StatelessWidget {
  const _TemplateItemRow({required this.item, required this.palette});

  final TemplateItem item;
  final AppColorPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: SmartImage(
                path: item.productImageUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.supplierName,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_TemplateCard._formatPrice(item.pricePerUnit)} ₸ · ${item.quantity} шт',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.ink,
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

enum _TemplateAction { rename, delete }
