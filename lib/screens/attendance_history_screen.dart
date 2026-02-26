import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/auth_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
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
      final history = await AttendanceController.getAttendanceHistory(
        startDate: startDate?.toIso8601String().split('T')[0],
        endDate: endDate?.toIso8601String().split('T')[0],
      );

      final attendanceSummary = await AttendanceController.getAttendanceSummary(
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
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
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
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
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
            // Summary Card
            if (summary != null) _buildSummaryCard(),
            
            // Date Filter Info
            if (startDate != null && endDate != null) _buildDateFilterInfo(),
            
            // Attendance List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : attendanceHistory.isEmpty
                      ? _buildEmptyState()
                      : _buildAttendanceList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _AttendanceHistoryBottomNavigation(),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Days',
                    '${summary!['total_days']}',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Present',
                    '${summary!['present_days']}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Late',
                    '${summary!['late_days']}',
                    Icons.access_time,
                    AppTheme.lightGold,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Avg Hours',
                    '${summary!['average_work_hours'].toStringAsFixed(1)}',
                    Icons.schedule,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            if (summary!['total_overtime_hours'] > 0) ...[
              const SizedBox(height: 12),
              _buildSummaryItem(
                'Total Overtime',
                '${summary!['total_overtime_hours'].toStringAsFixed(1)} hours',
                Icons.access_time,
                AppTheme.paleRed,
              ),
            ],
          ],
        ),
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
                  Text(
                    DateFormat('EEEE, MMM d, y').format(attendance.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                    Icon(Icons.login, color: Colors.green, size: 16),
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
                      '${attendance.workHours!.toStringAsFixed(2)} hours',
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
                  '${attendance.workHours!.toStringAsFixed(2)} hours',
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
