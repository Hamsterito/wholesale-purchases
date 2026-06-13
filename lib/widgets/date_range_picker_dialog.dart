import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../theme/app_color_palette.dart';

class CustomDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialRange;

  const CustomDateRangePickerDialog({super.key, this.initialRange});

  @override
  State<CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();
}

class _QuickFilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color primaryColor;

  const _QuickFilterButton({
    required this.label,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: primaryColor.withValues(alpha: 0.2),
        highlightColor: primaryColor.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
child: Text(
             label,
             style: TextStyle(
               fontSize: 14,
               fontWeight: FontWeight.w500,
               color: primaryColor,
             ),
           ),
         ),
       ),
     );
   }
 }

 enum _QuickFilterType { today, week, month, quarter }

class _CustomDateRangePickerDialogState
    extends State<CustomDateRangePickerDialog> {
  late DateRangePickerController _controller;
  late PickerDateRange _selectedRange;

  @override
  void initState() {
    super.initState();
    _controller = DateRangePickerController();
    if (widget.initialRange != null) {
      _selectedRange = PickerDateRange(
        widget.initialRange!.start,
        widget.initialRange!.end,
      );
      _controller.selectedRange = _selectedRange;
    } else {
      _selectedRange = PickerDateRange(null, null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      _selectedRange = args.value;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedRange = PickerDateRange(null, null);
    });
  }

void _applyQuickFilter(_QuickFilterType filter) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (filter) {
      case _QuickFilterType.today:
        start = DateTime(now.year, now.month, now.day);
        end = start;
        break;
      case _QuickFilterType.week:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        final endOfWeek = start.add(const Duration(days: 6));
        end = now.isBefore(endOfWeek) ? now : endOfWeek;
        break;
      case _QuickFilterType.month:
        start = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        end = now.isBefore(lastDayOfMonth) ? now : lastDayOfMonth;
        break;
      case _QuickFilterType.quarter:
        end = DateTime(now.year, now.month, now.day);
        start = end.subtract(const Duration(days: 89));
        break;
    }

    setState(() {
      _selectedRange = PickerDateRange(start, end);
      _controller.selectedRange = _selectedRange;
    });
  }

  void _saveSelection() {
    DateTimeRange? range;
    if (_selectedRange.startDate != null) {
      final start = _selectedRange.startDate!;
      final end = _selectedRange.endDate ?? start;
      range = DateTimeRange(start: start, end: end);
    }
    Navigator.of(context).pop(range);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _getSelectedRangeText() {
    if (_selectedRange.startDate == null) {
      return context.l10n.selectDateRange;
    }
    final start = _formatDate(_selectedRange.startDate!);
    final end = _selectedRange.endDate != null
        ? _formatDate(_selectedRange.endDate!)
        : start;
    return '$start - $end';
  }

@override
  Widget build(BuildContext context) {
    final palette = AppColorPalette.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.dateRangePickerTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 16),
            // Быстрые фильтры
Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 _QuickFilterButton(
                   label: context.l10n.dateRangePickerToday,
                   onTap: () => _applyQuickFilter(_QuickFilterType.today),
                   primaryColor: palette.accent,
                 ),
                 _QuickFilterButton(
                   label: context.l10n.dateRangePickerWeek,
                   onTap: () => _applyQuickFilter(_QuickFilterType.week),
                   primaryColor: palette.accent,
                 ),
                 _QuickFilterButton(
                   label: context.l10n.dateRangePickerMonth,
                   onTap: () => _applyQuickFilter(_QuickFilterType.month),
                   primaryColor: palette.accent,
                 ),
                 _QuickFilterButton(
                   label: context.l10n.dateRangePickerQuarter,
                   onTap: () => _applyQuickFilter(_QuickFilterType.quarter),
                   primaryColor: palette.accent,
                 ),
               ],
             ),
            const SizedBox(height: 16),
            SizedBox(
              height: 380,
              child: SfDateRangePicker(
                controller: _controller,
                selectionMode: DateRangePickerSelectionMode.range,
                initialSelectedRange: _selectedRange,
                onSelectionChanged: _onSelectionChanged,
                maxDate: DateTime.now(),
                showNavigationArrow: true,
                navigationMode: DateRangePickerNavigationMode.snap,
                backgroundColor: palette.card,
                headerStyle: DateRangePickerHeaderStyle(
                  backgroundColor: palette.card,
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: palette.accent,
                  ),
                ),
                monthCellStyle: DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: palette.ink,
                  ),
                  todayTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                  disabledDatesTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: palette.muted.withValues(alpha: 0.5),
                  ),
                ),
                yearCellStyle: DateRangePickerYearCellStyle(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: palette.ink,
                  ),
                  todayTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),
                selectionTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.card,
                ),
                rangeTextStyle: TextStyle(fontSize: 16, color: palette.ink),
                selectionColor: palette.accent,
                startRangeSelectionColor: palette.accent,
                endRangeSelectionColor: palette.accent,
                rangeSelectionColor: palette.accentMist,
                todayHighlightColor: palette.accent,
                monthViewSettings: DateRangePickerMonthViewSettings(
                  viewHeaderStyle: DateRangePickerViewHeaderStyle(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.muted,
                    ),
                  ),
                  enableSwipeSelection: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.accentMist,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: palette.accent),
                  const SizedBox(width: 8),
                  Text(
                    _getSelectedRangeText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: palette.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: _clearSelection,
                  child: Text(
                    context.l10n.dateRangePickerClear,
                    style: TextStyle(color: palette.accent),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    context.l10n.cancel,
                    style: TextStyle(color: palette.accent),
                  ),
                ),
                const SizedBox(width: 12),
               ElevatedButton(
                   onPressed: _saveSelection,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: palette.accent,
                     foregroundColor: palette.card,
                     padding: const EdgeInsets.symmetric(
                       horizontal: 16,
                       vertical: 12,
                     ),
                   ),
                   child: Text(context.l10n.save),
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
