import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../services/organization_service.dart';
import '../../models/models.dart';

class UserAttendanceHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserAttendanceHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserAttendanceHistoryScreen> createState() => _UserAttendanceHistoryScreenState();
}

class _UserAttendanceHistoryScreenState extends State<UserAttendanceHistoryScreen> {
  bool _isLoading = false;
  List<AttendanceRecord> _history = [];
  String _displayName = '';
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(_selectedRange!.start);
      final endDate = DateFormat('yyyy-MM-dd').format(_selectedRange!.end);

      final data = await OrganizationService.getUserAttendanceHistory(
        userId: widget.userId,
        startDate: startDate,
        endDate: endDate,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _history = data.history;
        _displayName = data.userName.isNotEmpty ? data.userName : widget.userName;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.skyBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            flexibleSpace: SafeArea(
              child: AppHeader(
                subtitle: _displayName.isNotEmpty ? _displayName : widget.userName,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Attendance History',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.skyBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.skyBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppTheme.skyBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedRange != null
                                    ? '${DateFormat('dd MMM').format(_selectedRange!.start)} - ${DateFormat('dd MMM').format(_selectedRange!.end)}'
                                    : 'Select dates',
                                style: const TextStyle(
                                  color: AppTheme.skyBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_history.isNotEmpty)
                    Text(
                      '${_history.length} records found',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildHistoryList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.skyBlue,
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No attendance records',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _history.map((record) => _buildHistoryItem(record)).toList(),
    );
  }

  Widget _buildHistoryItem(AttendanceRecord record) {
    final hasCheckIn = record.checkInTime != null;
    final hasCheckOut = record.checkOutTime != null;

    Color statusColor;
    String statusText;
    if (!hasCheckIn) {
      statusColor = AppTheme.paleRed;
      statusText = 'Absent';
    } else if (!hasCheckOut) {
      statusColor = AppTheme.lightGold;
      statusText = 'Active';
    } else {
      statusColor = Colors.green;
      statusText = 'Complete';
    }

    final dateStr = DateFormat('EEE, dd MMM yyyy').format(record.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  icon: Icons.login,
                  label: 'Check-in',
                  time: record.checkInTime != null
                      ? DateFormat('HH:mm').format(record.checkInTime!)
                      : '--:--',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildTimeInfo(
                  icon: Icons.logout,
                  label: 'Check-out',
                  time: record.checkOutTime != null
                      ? DateFormat('HH:mm').format(record.checkOutTime!)
                      : '--:--',
                  color: AppTheme.paleRed,
                ),
              ),
              if (record.workHours != null)
                Expanded(
                  child: _buildTimeInfo(
                    icon: Icons.timelapse,
                    label: 'Hours',
                    time: '${record.workHours!.toStringAsFixed(1)}h',
                    color: AppTheme.skyBlue,
                  ),
                ),
            ],
          ),
          if (record.lateReason != null && record.lateReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildReasonChip(
              icon: Icons.warning_amber_rounded,
              text: 'Late: ${record.lateReason}',
              color: AppTheme.lightGold,
            ),
          ],
          if (record.earlyCheckoutReason != null && record.earlyCheckoutReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildReasonChip(
              icon: Icons.exit_to_app,
              text: 'Early out: ${record.earlyCheckoutReason}',
              color: AppTheme.paleRed,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInfo({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReasonChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
