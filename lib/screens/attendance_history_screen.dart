import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/attendance_service.dart';
import '../../controllers/auth_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_header.dart';
import '../../widgets/tile_date_picker.dart';
import '../../widgets/async_content.dart';
import 'home_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceRecord> attendanceHistory = [];
  Map<String, dynamic>? summary;
  bool isLoading = false;
  DateTime? startDate;
  DateTime? endDate;
  final AttendanceService _attendanceService = const AttendanceService();

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final history = await _attendanceService.getAttendanceHistory(
        startDate: startDate?.toIso8601String().split('T')[0],
        endDate: endDate?.toIso8601String().split('T')[0],
      );

      final attendanceSummary = await _attendanceService.getAttendanceSummary(
        startDate: startDate?.toIso8601String().split('T')[0],
        endDate: endDate?.toIso8601String().split('T')[0],
      );

      setState(() {
        attendanceHistory = history;
        summary = attendanceSummary;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Failed to load attendance data: $e');
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showTileDateRangePicker(
      context: context,
      initialStartDate: startDate,
      initialEndDate: endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      title: 'Filter Attendance History',
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _loadAttendanceData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });
    _loadAttendanceData();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.paleRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(
        title: 'Attendance History',
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Filter by date range',
          ),
          if (startDate != null && endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDateFilter,
              tooltip: 'Clear filter',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendanceData,
        child: Column(
          children: [
            if (summary != null) _buildSummaryCard(),
            if (startDate != null && endDate != null) _buildDateFilterInfo(),
            Expanded(
              child: AsyncContent(
                isLoading: isLoading,
                isEmpty: attendanceHistory.isEmpty,
                loading: const Center(child: CircularProgressIndicator()),
                empty: _buildEmptyState(),
                builder: _buildAttendanceList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Calculate proper working days and attendance from the history data
    int totalWorkingDays = 0;
    int presentDays = 0;
    int onTimeDays = 0;
    int lateDays = 0;
    double totalWorkHours = 0;
    double totalOvertimeHours = 0;
    final Set<DateTime> processedDays = {};
    
    // Determine date range
    DateTime start;
    if (startDate != null) {
      start = startDate!;
    } else if (attendanceHistory.isEmpty) {
      start = DateTime.now();
    } else {
      start = attendanceHistory.map((r) => r.date).reduce((a, b) => a.isBefore(b) ? a : b);
    }
    final DateTime end = endDate ?? DateTime.now();
    
    // Count working days in the selected period (excluding weekends)
    for (DateTime day = start; 
         day.isBefore(end.add(const Duration(days: 1))); 
         day = day.add(const Duration(days: 1))) {
      if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
        totalWorkingDays++;
      }
    }
    
    // Process attendance records
    for (final record in attendanceHistory) {
      final DateTime recordDate = DateTime(
        record.date.year, 
        record.date.month, 
        record.date.day
      );
      
      if (!processedDays.contains(recordDate)) {
        processedDays.add(recordDate);
        
        // Only count weekdays
        if (record.date.weekday != DateTime.saturday && 
            record.date.weekday != DateTime.sunday) {
          
          if (record.checkInTime != null) {
            // Count all check-ins as present
            presentDays++;
            
            // Check if late (after 9:05 AM to allow 5-minute grace period)
            if (record.checkInTime!.hour > 9 || 
                (record.checkInTime!.hour == 9 && record.checkInTime!.minute > 5)) {
              lateDays++;
            } else {
              onTimeDays++;
            }
            
            // Add work hours and overtime
            if (record.workHours != null) {
              totalWorkHours += record.workHours!;
              if (record.workHours! > 8) {
                totalOvertimeHours += record.workHours! - 8;
              }
            }
          }
        }
      }
    }
    
    final int absentDays = totalWorkingDays - presentDays;
    final double averageWorkHours = presentDays > 0 ? 
        totalWorkHours / presentDays : 0.0;
    final double attendanceRate = totalWorkingDays > 0 ? 
        (presentDays / totalWorkingDays * 100) : 0.0;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.skyBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.skyBlue.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Attendance Summary',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                startDate != null && endDate != null 
                    ? '${DateFormat('MMM d').format(startDate!)} - ${DateFormat('MMM d').format(endDate!)}'
                    : 'This Period',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _enhancedHistorySummaryItem(
                value: '$onTimeDays',
                label: 'On Time',
                percentage: totalWorkingDays > 0 ? '${(onTimeDays / totalWorkingDays * 100).toStringAsFixed(0)}%' : '0%',
                icon: Icons.check_circle_outline,
                color: Colors.white,
              ),
              _enhancedHistorySummaryItem(
                value: '$lateDays',
                label: 'Late',
                percentage: totalWorkingDays > 0 ? '${(lateDays / totalWorkingDays * 100).toStringAsFixed(0)}%' : '0%',
                icon: Icons.access_time,
                color: Colors.white,
              ),
              _enhancedHistorySummaryItem(
                value: '$presentDays',
                label: 'Present',
                percentage: totalWorkingDays > 0 ? '${(presentDays / totalWorkingDays * 100).toStringAsFixed(0)}%' : '0%',
                icon: Icons.person_outline,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAdditionalMetric(
                  'Avg Hours',
                  '${averageWorkHours.toStringAsFixed(1)}h',
                  Icons.schedule,
                ),
              ),
              if (totalOvertimeHours > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAdditionalMetric(
                    'Overtime',
                    '${totalOvertimeHours.toStringAsFixed(1)}h',
                    Icons.access_time,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Attendance Rate: ${attendanceRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedHistorySummaryItem({
    required String value,
    required String label,
    required String percentage,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color.withValues(alpha: 0.9),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          percentage,
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.8),
            size: 16,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilterInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtered: ${DateFormat('MMM d, y').format(startDate!)} - ${DateFormat('MMM d, y').format(endDate!)}',
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            startDate != null && endDate != null
                ? 'Try adjusting the date filter'
                : 'Start checking in to see your history',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: attendanceHistory.length,
      itemBuilder: (context, index) {
        final attendance = attendanceHistory[index];
        return _buildAttendanceCard(attendance);
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord attendance) {
    final attendanceShift = attendance.shiftType ?? 'Unknown Shift';
    final isCurrentShift = attendanceShift == ShiftUtils.getCurrentShift();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAttendanceDetails(attendance),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, y').format(attendance.date),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Shift information
                        Row(
                          children: [
                            Icon(
                              attendanceShift == 'Day Shift' ? Icons.wb_sunny : Icons.nightlight,
                              size: 14,
                              color: isCurrentShift ? AppTheme.skyBlue : AppTheme.lightGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$attendanceShift (${ShiftUtils.getShiftTimeRange(attendanceShift)})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isCurrentShift ? AppTheme.skyBlue : AppTheme.lightGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_getAttendanceStatus(attendance)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(_getAttendanceStatus(attendance)),
                      ),
                    ),
                    child: Text(
                      _getAttendanceStatus(attendance),
                      style: TextStyle(
                        color: _getStatusColor(_getAttendanceStatus(attendance)),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (attendance.checkInTime != null) ...[
                    Icon(Icons.login, color: AppTheme.skyBlue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(attendance.checkInTime!),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ] else ...[
                    Icon(Icons.login, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'No check-in',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(width: 16),
                  if (attendance.checkOutTime != null) ...[
                    Icon(Icons.logout, color: AppTheme.paleRed, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(attendance.checkOutTime!),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ] else ...[
                    Icon(Icons.logout, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'No check-out',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (attendance.workHours != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatWorkHours(attendance.workHours!),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendanceDetails(AttendanceRecord attendance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DateFormat('EEEE, MMM d, y').format(attendance.date),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Status',
                _getAttendanceStatus(attendance),
                _getStatusColor(_getAttendanceStatus(attendance)),
              ),
              if (attendance.checkInTime != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Check In',
                  DateFormat('h:mm a').format(attendance.checkInTime!),
                  Colors.green,
                ),
                if (attendance.location != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${attendance.location}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
              if (attendance.checkOutTime != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Check Out',
                  DateFormat('h:mm a').format(attendance.checkOutTime!),
                  AppTheme.paleRed,
                ),
                if (attendance.location != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${attendance.location}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
              if (attendance.workHours != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Work Hours',
                  _formatWorkHours(attendance.workHours!),
                  Colors.blue,
                ),
              ],
              if (attendance.deviceId != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Device ID',
                  attendance.deviceId!,
                  Colors.grey,
                ),
              ],
              if (attendance.accuracy != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'GPS Accuracy',
                  '${attendance.accuracy!.toStringAsFixed(1)}m',
                  AppTheme.lightGold,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'complete':
        return Colors.green;
      case 'late':
      case 'checked in':
        return AppTheme.lightGold;
      case 'absent':
      case 'not checked in':
        return AppTheme.paleRed;
      case 'half_day':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getAttendanceStatus(AttendanceRecord attendance) {
    if (!attendance.isCheckedIn) {
      return 'NOT CHECKED IN';
    } else if (!attendance.isCheckedOut) {
      return 'CHECKED IN';
    } else {
      return 'COMPLETE';
    }
  }

  String _formatWorkHours(double hours) {
    if (hours < 1) {
      // Show minutes for less than 1 hour
      final minutes = (hours * 60).round();
      return '${minutes}m';
    } else {
      // Show hours for 1 hour or more
      return '${hours.toStringAsFixed(1)}h';
    }
  }
}

class _AttendanceHistoryBottomNavigation extends StatelessWidget {
  const _AttendanceHistoryBottomNavigation();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final isAdmin = user.role.toLowerCase().contains('admin') ||
        user.role.toLowerCase().contains('hr') ||
        user.role.toLowerCase().contains('manager');

    const currentIndex = 1;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
        selectedItemColor: AppTheme.skyBlue,
        unselectedItemColor: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.4),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              0,
              isAdmin ? Icons.dashboard : Icons.home,
              isAdmin ? Icons.dashboard_outlined : Icons.home_outlined,
              currentIndex,
            ),
            label: isAdmin ? 'Dashboard' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              1,
              Icons.access_time,
              Icons.access_time_outlined,
              currentIndex,
            ),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              2,
              isAdmin ? Icons.assignment_turned_in : Icons.bar_chart,
              isAdmin
                  ? Icons.assignment_turned_in_outlined
                  : Icons.bar_chart_outlined,
              currentIndex,
            ),
            label: isAdmin ? 'Requests' : 'Reports',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              3,
              isAdmin ? Icons.analytics : Icons.description,
              isAdmin ? Icons.analytics_outlined : Icons.description_outlined,
              currentIndex,
            ),
            label: isAdmin ? 'Analytics' : 'Requests',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    int currentIndex,
  ) {
    final isActive = currentIndex == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: AppTheme.skyBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(height: 4),
        Icon(isActive ? activeIcon : inactiveIcon),
      ],
    );
  }
}
