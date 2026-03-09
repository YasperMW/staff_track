import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/attendance_service.dart';
import '../../models/models.dart';
import '../../widgets/app_header.dart';
import '../check_in_out_screen.dart';
import '../attendance_history_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRecord> attendanceHistory = [];
  bool isLoading = false;
  final AttendanceService _attendanceService = const AttendanceService();
  Map<String, dynamic>? summary;

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
      final history =
          await _attendanceService.getAttendanceHistory(limit: 10);
      final summaryData = await _attendanceService.getAttendanceSummary();
      
      setState(() {
        attendanceHistory = history;
        summary = summaryData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadAttendanceData();
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
            flexibleSpace: const SafeArea(
              child: AppHeader(
                subtitle: 'Attendance',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.skyBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Your attendance history',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          _buildCheckInButton(context),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                      _buildFilterButton(context),
                      const SizedBox(height: 24),
                      _buildHistoryList(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (attendanceHistory.isEmpty) {
      return _buildEmptyState(context, 'No attendance records found');
    }
    return Column(
      children: attendanceHistory.map((attendance) => _buildHistoryItem(context, attendance)).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.2),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.skyBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.skyBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CheckInOutScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.login, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Check In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final DateTime now = DateTime.now();
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final DateTime today = now;
    
    // Calculate working days in current month (excluding weekends)
    int workingDaysInMonth = 0;
    for (DateTime day = firstDayOfMonth; 
         day.isBefore(today.add(const Duration(days: 1))); 
         day = day.add(const Duration(days: 1))) {
      if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
        workingDaysInMonth++;
      }
    }
    
    // Count actual attendance from history
    int presentDays = 0;
    int onTimeDays = 0;
    int lateDays = 0;
    final Set<DateTime> checkedInDays = {};
    
    for (final record in attendanceHistory) {
      if (record.checkInTime != null) {
        final DateTime checkInDate = DateTime(
          record.date.year, 
          record.date.month, 
          record.date.day
        );
        
        if (!checkedInDays.contains(checkInDate)) {
          checkedInDays.add(checkInDate);
          
          // Check if it's a working day (exclude weekends)
          if (record.date.weekday != DateTime.saturday && 
              record.date.weekday != DateTime.sunday) {
            
            // Count all check-ins as present
            presentDays++;
            
            // Check if late (after 9:05 AM to allow 5-minute grace period)
            if (record.checkInTime!.hour > 9 || 
                (record.checkInTime!.hour == 9 && record.checkInTime!.minute > 5)) {
              lateDays++;
            } else {
              onTimeDays++;
            }
          }
        }
      }
    }
    
    final int absentDays = workingDaysInMonth - presentDays;
    final double attendanceRate = workingDaysInMonth > 0 ? 
        (presentDays / workingDaysInMonth * 100) : 0.0;
    
    return Container(
      width: double.infinity,
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
                'This Month',
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
              _EnhancedSummaryItem(
                value: '$onTimeDays',
                label: 'On Time',
                percentage: workingDaysInMonth > 0 ? '${(onTimeDays / workingDaysInMonth * 100).toStringAsFixed(0)}%' : '0%',
                icon: Icons.check_circle_outline,
                color: Colors.white,
              ),
              _EnhancedSummaryItem(
                value: '$lateDays',
                label: 'Late',
                percentage: workingDaysInMonth > 0 ? '${(lateDays / workingDaysInMonth * 100).toStringAsFixed(0)}%' : '0%',
                icon: Icons.access_time,
                color: Colors.white,
              ),
              _EnhancedSummaryItem(
                value: '$presentDays',
                label: 'Present',
                percentage: workingDaysInMonth > 0 ? '${(presentDays / workingDaysInMonth * 100).toStringAsFixed(0)}%' : '0%',
                icon: Icons.person_outline,
                color: Colors.white,
              ),
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

  Widget _buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AttendanceHistoryScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'View Full History',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, AttendanceRecord attendance) {
    bool isOnTime = attendance.checkInTime != null && attendance.checkInTime!.hour < 9;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEE, MMM d').format(attendance.date),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnTime ? AppTheme.skyBlue.withValues(alpha: 0.1) : AppTheme.lightGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOnTime ? 'On Time' : 'Late',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOnTime ? AppTheme.skyBlue : AppTheme.lightGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: AppTheme.textLightBlue),
              const SizedBox(width: 8),
              Text(
                '${attendance.checkInTime != null ? DateFormat('h:mm a').format(attendance.checkInTime!) : '--:--'} - ${attendance.checkOutTime != null ? DateFormat('h:mm a').format(attendance.checkOutTime!) : '--:--'}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textLightBlue),
              const SizedBox(width: 4),
              Text(
                attendance.location ?? 'Office',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            attendance.workHours != null ? '${attendance.workHours!.toStringAsFixed(1)}h total' : '--:-- total',
            style: const TextStyle(
              color: AppTheme.skyBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedSummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final String percentage;
  final IconData icon;
  final Color color;

  const _EnhancedSummaryItem({
    required this.value,
    required this.label,
    required this.percentage,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha:0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
