import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_provider.dart';
import '../../controllers/attendance_provider.dart';
import '../../models/models.dart';
import '../../widgets/app_header.dart';
import '../../widgets/async_content.dart';
import '../check_in_out_screen.dart';
import '../attendance_history_screen.dart';
import '../../services/reminder_integration_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  late Timer _timer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceProvider = context.read<AttendanceProvider>();
      attendanceProvider.loadTodayAttendance();
      attendanceProvider.loadRecentAttendance(limit: 5);
      attendanceProvider.loadProfileMetrics();
      
      // Schedule daily reminders after loading data
      _scheduleDailyReminders();
    });
  }

  String _getAttendanceStatusText() {
    final todayAttendance =
        context.watch<AttendanceProvider>().todayAttendance;
    if (todayAttendance == null) {
      return 'Ready to check in';
    } else if (!todayAttendance.isCheckedIn) {
      return 'Not checked in today';
    } else if (todayAttendance.isCheckedIn && !todayAttendance.isCheckedOut) {
      return 'Currently working';
    } else {
      return 'Completed for today';
    }
  }

  String _getButtonText() {
    final todayAttendance =
        context.watch<AttendanceProvider>().todayAttendance;
    if (todayAttendance == null || !todayAttendance.isCheckedIn) {
      return 'Check In';
    } else if (todayAttendance.isCheckedIn && !todayAttendance.isCheckedOut) {
      return 'Check Out';
    } else {
      return 'View Details';
    }
  }

  bool _shouldDisableCheckIn() {
    final todayAttendance =
        context.watch<AttendanceProvider>().todayAttendance;
    // Disable if user has completed both check-in and check-out for today's shift
    return todayAttendance != null && 
           todayAttendance.isCheckedIn && 
           todayAttendance.isCheckedOut;
  }

  String _getNextShiftMessage() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour < 6) {
      return 'Check-in available at 6:00 AM for Day Shift';
    } else if (hour < 16) {
      return 'Check-in available at 4:30 PM for Night Shift';
    } else {
      return 'Check-in available tomorrow at 6:00 AM for Day Shift';
    }
  }

  /// Schedule daily attendance reminders
  Future<void> _scheduleDailyReminders() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      
      if (user == null) return;

      // Schedule daily check-in and check-out reminders
      await ReminderIntegrationService.scheduleDailyAttendanceReminders(
        userName: user.name,
        checkInTime: const TimeOfDay(hour: 6, minute: 0), // 6:00 AM
        checkOutTime: const TimeOfDay(hour: 14, minute: 30), // 2:30 PM
      );

    } catch (e) {
      debugPrint('Error scheduling daily reminders: $e');
    }
  }

  /// Schedule reminders after successful check-in or check-out
  Future<void> _scheduleAttendanceReminders() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      final attendanceProvider = context.read<AttendanceProvider>();
      final todayAttendance = attendanceProvider.todayAttendance;

      if (user == null || todayAttendance == null) return;

      // Schedule check-out reminder 15 minutes before shift end
      if (todayAttendance.isCheckedIn && !todayAttendance.isCheckedOut) {
        // Estimate shift end time (you can customize this logic)
        final now = DateTime.now();
        final shiftEndTime = now.add(const Duration(hours: 8)); // Assuming 8-hour shift
        
        await ReminderIntegrationService.scheduleCheckOutReminders(
          checkOutTime: shiftEndTime,
          userName: user.name,
          userId: user.id,
        );
      }

      // Schedule tomorrow's check-in reminder
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowCheckIn = DateTime(
        tomorrow.year, tomorrow.month, tomorrow.day,
        6, 0, // 6:00 AM for day shift
      );
      
      await ReminderIntegrationService.scheduleCheckInReminders(
        checkInTime: tomorrowCheckIn,
        userName: user.name,
        userId: user.id,
      );

    } catch (e) {
      debugPrint('Error scheduling attendance reminders: $e');
    }
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = _formatDateTime(now);
    if (mounted) {
      setState(() {
        _timeString = formattedTime;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss a').format(dateTime);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final attendanceProvider = context.read<AttendanceProvider>();
      attendanceProvider.loadTodayAttendance();
      attendanceProvider.loadRecentAttendance(limit: 5);
      attendanceProvider.loadProfileMetrics();
      _scheduleDailyReminders();
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
            flexibleSpace: const SafeArea(
              child: AppHeader(
                subtitle: 'Dashboard',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildGreeting(context),
                const SizedBox(height: 24),
                _buildClockInCard(),
                const SizedBox(height: 24),
                _buildStatsRow(context),
                const SizedBox(height: 32),
                _buildRecentActivityHeader(context),
                const SizedBox(height: 16),
                _buildRecentActivityList(context),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: const TextStyle(
            color: AppTheme.textLightBlue,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'Poppins', // Since we use GoogleFonts Poppins
            ),
            children: [
              TextSpan(text: '${_getGreeting()}, '),
              TextSpan(
                text: context.watch<AuthProvider>().user?.name ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' 👋'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClockInCard() {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final todayAttendance = attendanceProvider.todayAttendance;
    final buttonText = _getButtonText();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.skyBlue, AppTheme.lightGold],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.skyBlue.withValues(alpha:0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha:0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.white.withValues(alpha:0.9), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'St. John\'s Mission Hospital',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _getAttendanceStatusText(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _shouldDisableCheckIn() ? null : () {
                          if (todayAttendance == null || !todayAttendance.isCheckedIn) {
                            // Check in
                            final attendanceProvider = context.read<AttendanceProvider>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CheckInOutScreen(),
                              ),
                            ).then(
                              (_) {
                                if (mounted) {
                                  attendanceProvider.loadTodayAttendance();
                                  // Schedule reminders after check-in
                                  _scheduleAttendanceReminders();
                                }
                              },
                            );
                          } else if (todayAttendance.isCheckedIn && !todayAttendance.isCheckedOut) {
                            // Check out
                            final attendanceProvider = context.read<AttendanceProvider>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CheckInOutScreen(),
                              ),
                            ).then(
                              (_) {
                                if (mounted) {
                                  attendanceProvider.loadTodayAttendance();
                                  // Schedule reminders after check-out
                                  _scheduleAttendanceReminders();
                                }
                              },
                            );
                          } else {
                            // View details (already completed)
                            final attendanceProvider = context.read<AttendanceProvider>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CheckInOutScreen(),
                              ),
                            ).then(
                              (_) {
                                if (mounted) {
                                  attendanceProvider.loadTodayAttendance();
                                }
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _shouldDisableCheckIn() ? Colors.grey[300] : Colors.white,
                          foregroundColor: _shouldDisableCheckIn() ? Colors.grey[600] : AppTheme.skyBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              buttonText == 'Check In'
                                  ? Icons.login
                                  : buttonText == 'Check Out'
                                      ? Icons.logout
                                      : Icons.visibility,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              buttonText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_shouldDisableCheckIn()) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getNextShiftMessage(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final metrics = attendanceProvider.profileMetrics;

    // Show loading state while metrics are being fetched
    if (attendanceProvider.isLoadingMetrics) {
      return Row(
        children: [
          Expanded(child: _buildLoadingStatCard(context)),
          const SizedBox(width: 12),
          Expanded(child: _buildLoadingStatCard(context)),
          const SizedBox(width: 12),
          Expanded(child: _buildLoadingStatCard(context)),
        ],
      );
    }
    
    // Show error state if metrics failed to load
    if (attendanceProvider.metricsError != null || metrics == null) {
      return Row(
        children: [
          Expanded(child: _buildStatCard(context, Icons.access_time, '--', 'Days Present This Year', AppTheme.skyBlue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(context, Icons.trending_up, '--', 'On Time', AppTheme.lightGold)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(context, Icons.calendar_today, '--', 'Leave Left', AppTheme.lightGold)),
        ],
      );
    }
    
    // Show days present this year (working days since January 1st)
    final workingDays = metrics['working_days'] as int? ?? 0;
    final workingDaysStr = workingDays > 0 ? '$workingDays days' : '0 days';
    
    final onTimeDays = metrics['on_time_days'] as int? ?? 0;
    final onTimeDaysStr = onTimeDays > 0 ? '$onTimeDays days' : '0 days';

    final lateDays = metrics['late_days'] as int? ?? 0;
    final lateDaysStr = lateDays > 0 ? '$lateDays days' : '0 days';
    
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, Icons.access_time, workingDaysStr, 'Days Present This Year', AppTheme.skyBlue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, Icons.trending_up, onTimeDaysStr, 'On Time Days', AppTheme.lightGold)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, Icons.calendar_today, lateDaysStr, 'Days Arrived Late', AppTheme.lightGold)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value, String label, Color color) {
    return Container(
      height: 120, // Fixed height for all cards
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textLightBlue,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatCard(BuildContext context) {
    return Container(
      height: 120, // Match the fixed height of regular cards
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 11,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AttendanceHistoryScreen(),
              ),
            );
          },
          child: const Row(
            children: [
              Text('View all', style: TextStyle(color: AppTheme.skyBlue)),
              Icon(Icons.chevron_right, size: 18, color: AppTheme.skyBlue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();

    return AsyncContent(
      isLoading: attendanceProvider.isLoadingRecent,
      isEmpty: attendanceProvider.recentAttendance.isEmpty,
      loading: const Center(child: CircularProgressIndicator()),
      empty: Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      builder: () => Column(
        children: attendanceProvider.recentAttendance
            .map((attendance) => _buildAttendanceItem(context, attendance))
            .toList(),
      ),
    );
  }

  Widget _buildAttendanceItem(BuildContext context, AttendanceRecord attendance) {
    final attendanceShift = attendance.shiftType ?? 'Unknown Shift';
    final isCurrentShift = attendanceShift == ShiftUtils.getCurrentShift();
    
    // Check if attendance is from today and has been active for more than 24 hours without check-out
    final now = DateTime.now();
    final isToday = attendance.date.year == now.year && 
                   attendance.date.month == now.month && 
                   attendance.date.day == now.day;
    
    String statusText = 'Complete';
    Color statusColor = AppTheme.skyBlue;
    Color statusBgColor = AppTheme.skyBlue.withValues(alpha: 0.1);
    String? activeHoursText;
    
    if (!attendance.isCheckedOut && attendance.checkInTime != null) {
      final durationSinceCheckIn = now.difference(attendance.checkInTime!);
      
      if (isToday) {
        statusText = 'Active';
        statusColor = AppTheme.paleRed;
        statusBgColor = AppTheme.paleRed.withValues(alpha: 0.1);
        activeHoursText = _formatDuration(durationSinceCheckIn);
      } else {
        statusText = 'No Check Out';
        statusColor = AppTheme.paleRed;
        statusBgColor = AppTheme.paleRed.withValues(alpha: 0.1);
        // Don't show active hours for "No Check Out" status
      }
    } else if (attendance.isCheckedOut) {
      statusText = 'Complete';
      statusColor = AppTheme.skyBlue;
      statusBgColor = AppTheme.skyBlue.withValues(alpha: 0.1);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d').format(attendance.date),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Shift information
                  Row(
                    children: [
                      Icon(
                        attendanceShift == 'Day Shift' ? Icons.wb_sunny : Icons.nightlight,
                        size: 12,
                        color: isCurrentShift ? AppTheme.skyBlue : AppTheme.lightGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        attendanceShift,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isCurrentShift ? AppTheme.skyBlue : AppTheme.lightGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (attendance.checkInTime != null)
            Text(
              'In: ${DateFormat('h:mm a').format(attendance.checkInTime!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLightBlue,
              ),
            ),
          if (attendance.checkOutTime != null)
            Text(
              'Out: ${DateFormat('h:mm a').format(attendance.checkOutTime!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLightBlue,
              ),
            ),
          if (activeHoursText != null)
            Text(
              'Active: $activeHoursText',
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
