import 'package:flutter/material.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';

class ExpandableTextBlock extends StatefulWidget {
  const ExpandableTextBlock(
    this.text, {
    super.key,
    required this.textStyle,
    required this.actionColor,
    this.collapsedMaxLines = 3,
    this.moreLabel,
    this.lessLabel,
    this.actionFontSize = 12,
    this.onExpansionChanged,
  });

  final String text;
  final TextStyle textStyle;
  final Color actionColor;
  final int collapsedMaxLines;
  final String? moreLabel;
  final String? lessLabel;
  final double actionFontSize;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<ExpandableTextBlock> createState() => _ExpandableTextBlockState();
}

class _ExpandableTextBlockState extends State<ExpandableTextBlock> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant ExpandableTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && _isExpanded) {
      _isExpanded = false;
      widget.onExpansionChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.textStyle),
          textDirection: Directionality.of(context),
          maxLines: widget.collapsedMaxLines,
        )..layout(
          maxWidth: constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width,
        );

        final hasOverflow = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: widget.textStyle,
                maxLines: _isExpanded ? null : widget.collapsedMaxLines,
                overflow: _isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.clip,
              ),
            ),
            if (hasOverflow) ...[
              const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                    widget.onExpansionChanged?.call(_isExpanded);
                  },
                child: Text(
                  _isExpanded
                      ? (widget.lessLabel ?? context.l10n.getString('auto_svernut'))
                      : (widget.moreLabel ?? context.l10n.getString('auto_podrobnee')),
                  style: TextStyle(
                    color: widget.actionColor,
                    fontSize: widget.actionFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
