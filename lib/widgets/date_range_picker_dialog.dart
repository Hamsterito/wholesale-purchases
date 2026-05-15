import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

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

  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (filter) {
      case 'Сегодня':
        start = DateTime(now.year, now.month, now.day);
        end = start;
        break;
      case 'Неделя':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        final endOfWeek = start.add(const Duration(days: 6));
        end = now.isBefore(endOfWeek) ? now : endOfWeek;
        break;
      case 'Месяц':
        start = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        end = now.isBefore(lastDayOfMonth) ? now : lastDayOfMonth;
        break;
      case 'Квартал':
        end = DateTime(now.year, now.month, now.day);
        start = end.subtract(const Duration(days: 89));
        break;
      default:
        return;
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
      return 'Выберите диапазон дат';
    }
    final start = _formatDate(_selectedRange.startDate!);
    final end = _selectedRange.endDate != null
        ? _formatDate(_selectedRange.endDate!)
        : start;
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Выберите диапазон дат',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            // Быстрые фильтры
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickFilterButton(
                  label: 'Сегодня',
                  onTap: () => _applyQuickFilter('Сегодня'),
                  primaryColor: Theme.of(context).primaryColor,
                ),
                _QuickFilterButton(
                  label: 'Неделя',
                  onTap: () => _applyQuickFilter('Неделя'),
                  primaryColor: Theme.of(context).primaryColor,
                ),
                _QuickFilterButton(
                  label: 'Месяц',
                  onTap: () => _applyQuickFilter('Месяц'),
                  primaryColor: Theme.of(context).primaryColor,
                ),
                _QuickFilterButton(
                  label: 'Квартал',
                  onTap: () => _applyQuickFilter('Квартал'),
                  primaryColor: Theme.of(context).primaryColor,
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
                headerStyle: DateRangePickerHeaderStyle(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                monthCellStyle: DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  todayTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  disabledDatesTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                yearCellStyle: DateRangePickerYearCellStyle(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  todayTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                selectionTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                rangeTextStyle: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                selectionColor: Theme.of(context).primaryColor,
                startRangeSelectionColor: Theme.of(context).primaryColor,
                endRangeSelectionColor: Theme.of(context).primaryColor,
                rangeSelectionColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                todayHighlightColor: Theme.of(context).primaryColor,
                monthViewSettings: DateRangePickerMonthViewSettings(
                  viewHeaderStyle: DateRangePickerViewHeaderStyle(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getSelectedRangeText(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
                  child: const Text('Очистить'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
