import 'package:flutter/material.dart';

import '../theme/app_color_palette.dart';

/// Вариант для AnimatedSelectField: значение + подпись.
class SelectOption<T> {
  const SelectOption(this.value, this.label);

  final T value;
  final String label;
}

/// Поле-выпадашка с анимацией. Список всплывает поверх остального контента
/// через Overlay (не раздвигает соседние поля) и анимированно раскрывается
/// и сворачивается обратно.
class AnimatedSelectField<T> extends StatefulWidget {
  const AnimatedSelectField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.decoration,
    this.hintText = '',
    this.textStyle,
    this.hintStyle,
  });

  final T? value;
  final List<SelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final InputDecoration decoration;
  final String hintText;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  @override
  State<AnimatedSelectField<T>> createState() => _AnimatedSelectFieldState<T>();
}

class _AnimatedSelectFieldState<T> extends State<AnimatedSelectField<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  late final AnimationController _controller;
  late final Animation<double> _curve;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    FocusScope.of(context).unfocus();
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _controller.forward();
  }

  // then вызывается уже после завершения анимации сворачивания - чтобы
  // перестроение родителя (onChanged) не прерывало её на полпути.
  void _close({VoidCallback? then}) {
    if (!_isOpen) {
      then?.call();
      return;
    }
    setState(() => _isOpen = false);
    _controller.reverse().whenComplete(() {
      _removeOverlay();
      if (mounted) then?.call();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _select(T value) {
    _close(
      then: () {
        if (value != widget.value) {
          widget.onChanged(value);
        }
      },
    );
  }

  String? get _selectedLabel {
    for (final option in widget.options) {
      if (option.value == widget.value) return option.label;
    }
    return null;
  }

  OverlayEntry _buildOverlay() {
    final palette = context.colorPalette;
    final colorScheme = Theme.of(context).colorScheme;
    final baseTextStyle =
        widget.textStyle ??
        TextStyle(color: colorScheme.onSurface, fontSize: 15);
    final fieldBox = context.findRenderObject() as RenderBox?;
    final fieldWidth = fieldBox?.size.width ?? 0;

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Невидимый барьер: тап мимо списка закрывает его.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            Positioned(
              width: fieldWidth,
              child: CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 8),
                child: FadeTransition(
                  opacity: _curve,
                  child: SizeTransition(
                    sizeFactor: _curve,
                    axisAlignment: -1,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.line),
                          boxShadow: [
                            BoxShadow(
                              color: palette.shadow,
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final option in widget.options)
                              _buildOption(
                                option,
                                baseTextStyle,
                                palette,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOption(
    SelectOption<T> option,
    TextStyle baseTextStyle,
    AppColorPalette palette,
  ) {
    final isSelected = option.value == widget.value;
    return InkWell(
      onTap: () => _select(option.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.label,
                style: baseTextStyle.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, size: 18, color: palette.accent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedLabel = _selectedLabel;
    final hasValue = selectedLabel != null;

    final baseTextStyle =
        widget.textStyle ??
        TextStyle(color: colorScheme.onSurface, fontSize: 15);
    final hintStyle =
        widget.hintStyle ??
        TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15);

    return CompositedTransformTarget(
      link: _link,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _toggle,
        child: InputDecorator(
          isEmpty: false,
          decoration: widget.decoration.copyWith(
            suffixIcon: AnimatedRotation(
              turns: _isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          child: Text(
            hasValue ? selectedLabel : widget.hintText,
            style: hasValue ? baseTextStyle : hintStyle,
          ),
        ),
      ),
    );
  }
}
