import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/holidays_service.dart';
import '../models/models.dart';

class SingleDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime) onDateChanged;
  final String? title;

  const SingleDatePicker({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.onDateChanged,
    this.title,
  });

  @override
  State<SingleDatePicker> createState() => _SingleDatePickerState();
}

class _SingleDatePickerState extends State<SingleDatePicker> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  late DateTime _firstDate;
  late DateTime _lastDate;
  List<PublicHoliday> _holidays = [];
  bool _isLoadingHolidays = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = widget.initialDate;
    _firstDate = widget.firstDate ?? DateTime(_currentMonth.year - 1);
    _lastDate = widget.lastDate ?? DateTime(_currentMonth.year + 1);
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() {
      _isLoadingHolidays = true;
    });

    try {
      final holidays = await HolidaysService.getHolidays(year: _currentMonth.year);
      if (mounted) {
        setState(() {
          _holidays = holidays;
          _isLoadingHolidays = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHolidays = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatDay(DateTime date) {
    return DateFormat('d').format(date);
  }

  String _formatWeekday(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  bool _isDateSelectable(DateTime date) {
    return (date.isAfter(_firstDate.subtract(const Duration(days: 1))) ||
            date.isAtSameMomentAs(_firstDate)) &&
        (date.isBefore(_lastDate.add(const Duration(days: 1))) ||
            date.isAtSameMomentAs(_lastDate));
  }

  bool _isDateSelected(DateTime date) {
    return _selectedDate != null && date.isAtSameMomentAs(_selectedDate!);
  }

  bool _isHoliday(DateTime date) {
    return _holidays.any((holiday) => holiday.matchesDate(date));
  }

  PublicHoliday? _getHolidayForDate(DateTime date) {
    try {
      return _holidays.firstWhere((holiday) => holiday.matchesDate(date));
    } catch (e) {
      return null;
    }
  }

  void _selectDate(DateTime date) {
    if (!_isDateSelectable(date)) return;

    setState(() {
      _selectedDate = date;
    });

    widget.onDateChanged(date);
  }

  void _previousMonth() {
    final newMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final yearChanged = newMonth.year != _currentMonth.year;
    setState(() {
      _currentMonth = newMonth;
    });
    if (yearChanged) {
      _loadHolidays();
    }
  }

  void _nextMonth() {
    final newMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    final yearChanged = newMonth.year != _currentMonth.year;
    setState(() {
      _currentMonth = newMonth;
    });
    if (yearChanged) {
      _loadHolidays();
    }
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final days = <DateTime>[];

    // Add padding days from previous month to complete the first week
    final startWeekday = firstDay.weekday;
    for (int i = startWeekday - 1; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }

    // Add all days in the current month
    for (int i = 0; i < lastDay.day; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }

    // Add padding days from next month to complete the last week
    final endWeekday = lastDay.weekday;
    for (int i = 1; i <= 7 - endWeekday; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.skyBlue, AppTheme.lightGold],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title ?? 'Select Date',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Selected Date Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, 
                             color: Colors.white.withValues(alpha: 0.9), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate != null
                              ? _formatDate(_selectedDate!)
                              : 'No date selected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Month Navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left),
                    color: AppTheme.skyBlue,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right),
                    color: AppTheme.skyBlue,
                  ),
                ],
              ),
            ),

            // Weekday Headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Holiday Legend
            if (_holidays.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: AppTheme.lightGold.withValues(alpha: 0.5)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Public Holiday',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Date Tiles Grid
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  for (int week = 0; week < 6; week++) ...[
                    Row(
                      children: [
                        for (int day = 0; day < 7; day++) ...[
                          if (week * 7 + day < _getDaysInMonth().length)
                            Expanded(
                              child: _buildDateTile(_getDaysInMonth()[week * 7 + day]),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ],
                    ),
                    if (week < 5) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedDate != null
                          ? () => Navigator.of(context).pop()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.skyBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile(DateTime date) {
    final isSelectable = _isDateSelectable(date);
    final isSelected = _isDateSelected(date);
    final isCurrentMonth = date.month == _currentMonth.month;
    final isToday = date.isAtSameMomentAs(DateTime.now());
    final isHoliday = _isHoliday(date);
    final holiday = _getHolidayForDate(date);

    Color backgroundColor;
    Color textColor;
    FontWeight fontWeight = FontWeight.normal;
    Border? border;

    if (isSelected) {
      backgroundColor = AppTheme.skyBlue;
      textColor = Colors.white;
      fontWeight = FontWeight.bold;
      border = Border.all(color: Colors.white, width: 2);
    } else if (isHoliday && !isSelected) {
      backgroundColor = AppTheme.lightGold.withValues(alpha: 0.2);
      textColor = AppTheme.paleRed;
      fontWeight = FontWeight.w600;
      border = Border.all(color: AppTheme.lightGold.withValues(alpha: 0.5), width: 1);
    } else if (!isSelectable || !isCurrentMonth) {
      backgroundColor = Colors.transparent;
      textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);
    } else if (isToday) {
      backgroundColor = AppTheme.lightGold.withValues(alpha: 0.1);
      textColor = AppTheme.lightGold;
      fontWeight = FontWeight.w600;
      border = Border.all(color: AppTheme.lightGold, width: 1);
    } else {
      backgroundColor = Colors.transparent;
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    return GestureDetector(
      onTap: isSelectable ? () => _selectDate(date) : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDay(date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: fontWeight,
                    color: textColor,
                  ),
                ),
                if (isToday && !isSelected && !isHoliday)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
            if (isHoliday)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.paleRed,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the single date picker
Future<DateTime?> showSingleDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) async {
  DateTime? selectedDate;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SingleDatePicker(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      onDateChanged: (date) {
        selectedDate = date;
      },
    ),
  );

  return selectedDate;
}
