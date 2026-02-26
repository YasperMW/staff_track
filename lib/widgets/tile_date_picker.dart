import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/holidays_service.dart';
import '../models/models.dart';

class TileDatePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTimeRange) onDateRangeChanged;
  final String? title;

  const TileDatePicker({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.firstDate,
    this.lastDate,
    required this.onDateRangeChanged,
    this.title,
  });

  @override
  State<TileDatePicker> createState() => _TileDatePickerState();
}

class _TileDatePickerState extends State<TileDatePicker> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _firstDate;
  late DateTime _lastDate;
  String _selectionMode = 'start'; // 'start', 'end', or 'complete'
  List<PublicHoliday> _holidays = [];
  bool _isLoadingHolidays = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _firstDate = widget.firstDate ?? DateTime(_currentMonth.year - 1);
    _lastDate = widget.lastDate ?? DateTime(_currentMonth.year + 1);
    
    // Set initial selection mode
    if (_startDate != null && _endDate != null) {
      _selectionMode = 'complete';
    } else if (_startDate != null) {
      _selectionMode = 'end';
    } else {
      _selectionMode = 'start';
    }
    
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
    if (_startDate == null && _endDate == null) return false;
    if (_startDate != null && _endDate != null) {
      return (date.isAfter(_startDate!.subtract(const Duration(days: 1))) ||
              date.isAtSameMomentAs(_startDate!)) &&
          (date.isBefore(_endDate!.add(const Duration(days: 1))) ||
              date.isAtSameMomentAs(_endDate!));
    }
    if (_startDate != null) {
      return date.isAtSameMomentAs(_startDate!);
    }
    return false;
  }

  bool _isStartDate(DateTime date) {
    return _startDate != null && date.isAtSameMomentAs(_startDate!);
  }

  bool _isEndDate(DateTime date) {
    return _endDate != null && date.isAtSameMomentAs(_endDate!);
  }

  bool _isHoliday(DateTime date) {
    return _holidays.any((holiday) => holiday?.matchesDate(date) ?? false);
  }

  PublicHoliday? _getHolidayForDate(DateTime date) {
    try {
      return _holidays.firstWhere((holiday) => holiday?.matchesDate(date) ?? false);
    } catch (e) {
      return null;
    }
  }

  void _selectDate(DateTime date) {
    if (!_isDateSelectable(date)) return;

    setState(() {
      if (_selectionMode == 'start') {
        _startDate = date;
        _endDate = null;
        _selectionMode = 'end';
      } else if (_selectionMode == 'end') {
        if (date.isBefore(_startDate!)) {
          // If end date is before start date, swap them
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
        _selectionMode = 'complete';
      } else if (_selectionMode == 'complete') {
        // Start over with new selection
        _startDate = date;
        _endDate = null;
        _selectionMode = 'end';
      }
    });

    if (_startDate != null && _endDate != null) {
      widget.onDateRangeChanged(DateTimeRange(start: _startDate!, end: _endDate!));
    }
  }

  void _setSelectionMode(String mode) {
    setState(() {
      _selectionMode = mode;
    });
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
                      widget.title ?? 'Select Date Range',
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
                // Selection Mode Indicators
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _setSelectionMode('start'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectionMode == 'start'
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.play_arrow, 
                                         color: Colors.white.withValues(alpha: 0.9), size: 16),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Start Date',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                        fontWeight: _selectionMode == 'start' 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (_startDate != null)
                                      Text(
                                        _formatDate(_startDate!),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _setSelectionMode('end'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectionMode == 'end'
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.stop, 
                                         color: Colors.white.withValues(alpha: 0.9), size: 16),
                                    const SizedBox(height: 2),
                                    Text(
                                      'End Date',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                        fontWeight: _selectionMode == 'end' 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (_endDate != null)
                                      Text(
                                        _formatDate(_endDate!),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectionMode == 'complete') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, 
                                   color: Colors.white.withValues(alpha: 0.9), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Complete! Tap a date to start over',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_startDate != null && _endDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, 
                             color: Colors.white.withValues(alpha: 0.9), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _startDate == _endDate
                              ? _formatDate(_startDate!)
                              : '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
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
  ]),
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
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startDate != null && _endDate != null
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
    );
  }

  Widget _buildDateTile(DateTime date) {
    final isSelectable = _isDateSelectable(date);
    final isSelected = _isDateSelected(date);
    final isStartDate = _isStartDate(date);
    final isEndDate = _isEndDate(date);
    final isCurrentMonth = date.month == _currentMonth.month;
    final isToday = date.isAtSameMomentAs(DateTime.now());
    final isHoliday = _isHoliday(date);
    final holiday = _getHolidayForDate(date);

    Color backgroundColor;
    Color textColor;
    FontWeight fontWeight = FontWeight.normal;
    Border? border;

    if (isStartDate) {
      backgroundColor = AppTheme.skyBlue;
      textColor = Colors.white;
      fontWeight = FontWeight.bold;
      border = Border.all(color: Colors.white, width: 2);
    } else if (isEndDate) {
      backgroundColor = AppTheme.paleRed;
      textColor = Colors.white;
      fontWeight = FontWeight.bold;
      border = Border.all(color: Colors.white, width: 2);
    } else if (isHoliday && !isSelected) {
      backgroundColor = AppTheme.lightGold.withValues(alpha: 0.2);
      textColor = AppTheme.paleRed;
      fontWeight = FontWeight.w600;
      border = Border.all(color: AppTheme.lightGold.withValues(alpha: 0.5), width: 1);
    } else if (isSelected) {
      backgroundColor = AppTheme.skyBlue.withValues(alpha: 0.1);
      textColor = AppTheme.skyBlue;
      fontWeight = FontWeight.w600;
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

    // Add visual feedback for selection mode
    if (_selectionMode == 'start' && isSelectable && !isSelected && !isHoliday) {
      border = Border.all(color: AppTheme.skyBlue.withValues(alpha: 0.3), width: 1);
    } else if (_selectionMode == 'end' && isSelectable && !isSelected && !isHoliday) {
      border = Border.all(color: AppTheme.paleRed.withValues(alpha: 0.3), width: 1);
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
                if (isStartDate)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                if (isEndDate)
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

// Helper function to show the tile date picker
Future<DateTimeRange?> showTileDateRangePicker({
  required BuildContext context,
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) async {
  DateTimeRange? selectedRange;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => TileDatePicker(
      initialStartDate: initialStartDate,
      initialEndDate: initialEndDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      onDateRangeChanged: (range) {
        selectedRange = range;
      },
    ),
  );

  return selectedRange;
}
