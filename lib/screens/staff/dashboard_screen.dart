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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Timer _timer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    final attendanceProvider = context.read<AttendanceProvider>();
    attendanceProvider.loadTodayAttendance();
    attendanceProvider.loadRecentAttendance(limit: 5);
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
      return 'Clock In';
    } else if (todayAttendance.isCheckedIn && !todayAttendance.isCheckedOut) {
      return 'Clock Out';
    } else {
      return 'View Details';
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
              const TextSpan(text: 'Good Morning, '),
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
                      'Office - Main Building',
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
                  child: ElevatedButton(
                    onPressed: () {
                      if (todayAttendance == null || !todayAttendance.isCheckedIn) {
                        // Check in
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckInOutScreen(),
                          ),
                        ).then(
                          (_) => context
                              .read<AttendanceProvider>()
                              .loadTodayAttendance(),
                        );
                      } else if (todayAttendance.isCheckedIn && !todayAttendance.isCheckedOut) {
                        // Check out
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckInOutScreen(),
                          ),
                        ).then(
                          (_) => context
                              .read<AttendanceProvider>()
                              .loadTodayAttendance(),
                        );
                      } else {
                        // View details (already completed)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckInOutScreen(),
                          ),
                        ).then(
                          (_) => context
                              .read<AttendanceProvider>()
                              .loadTodayAttendance(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.skyBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _getButtonText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, Icons.access_time, '38h 20m', 'This Week', AppTheme.skyBlue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, Icons.trending_up, '96%', 'On Time', AppTheme.lightGold)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, Icons.calendar_today, '12 days', 'Leave Left', AppTheme.lightGold)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textLightBlue,
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
                  color: attendance.isCheckedOut ? AppTheme.skyBlue.withValues(alpha: 0.1) : AppTheme.paleRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  attendance.isCheckedOut ? 'Complete' : 'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: attendance.isCheckedOut ? AppTheme.skyBlue : AppTheme.paleRed,
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
        ],
      ),
    );
  }
}
