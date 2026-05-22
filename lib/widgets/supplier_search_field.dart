import 'package:flutter/material.dart';

import '../theme/app_color_palette.dart';

/// Поле поиска для каталога поставщиков. Дебаунс — на стороне страницы.
class SupplierSearchField extends StatefulWidget {
  const SupplierSearchField({
    super.key,
    this.controller,
    required this.onChanged,
  });

  final TextEditingController? controller;
  final ValueChanged<String> onChanged;

  @override
  State<SupplierSearchField> createState() => _SupplierSearchFieldState();
}

class _SupplierSearchFieldState extends State<SupplierSearchField> {
  late TextEditingController _controller;
  // Внутренний контроллер создаём, если внешний не пришёл; его же и освобождаем.
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final external = widget.controller;
    if (external == null) {
      _controller = TextEditingController();
      _ownsController = true;
    } else {
      _controller = external;
    }
  }

  @override
  void didUpdateWidget(covariant SupplierSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == oldWidget.controller) return;

    if (_ownsController) {
      _controller.dispose();
      _ownsController = false;
    }
    final external = widget.controller;
    if (external == null) {
      _controller = TextEditingController();
      _ownsController = true;
    } else {
      _controller = external;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    // controller.clear() не триггерит onChanged — будим страницу руками.
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        return TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: cs.onSurface),
          cursorColor: palette.primary,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Поиск по поставщикам',
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
            prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Очистить',
                    icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                    onPressed: _handleClear,
                  )
                : null,
            filled: true,
            fillColor: palette.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.primary, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}
