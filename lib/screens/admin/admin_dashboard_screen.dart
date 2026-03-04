import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../controllers/auth_provider.dart';
import '../../models/models.dart';
import '../../services/requests_service.dart';
import '../../services/announcements_service.dart';
import 'package:intl/intl.dart';
import '../../controllers/attendance_controller.dart';
import '../check_in_out_screen.dart';
import 'announcements_management_screen.dart';
import 'admin_requests_screen.dart';
import 'admin_leave_policies_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Timer _timer;
  String _timeString = '';
  AttendanceRecord? todayAttendance;
  bool isLoadingAttendance = false;
  int _pendingLeaveCount = 0;
  int _pendingWfhCount = 0;
  int _pendingShiftChangeCount = 0;
  int _teamTotalStaff = 0;
  int _teamPresentCount = 0;
  int _teamLateCount = 0;
  int _teamAbsentCount = 0;
  bool _isLoadingTeamAttendance = false;
  List<TeamAttendanceMember> _teamAttendance = [];
  List<Announcement> _recentAnnouncements = [];
  bool _isLoadingAnnouncements = false;

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    _loadTodayAttendance();
    _loadRequestsSummary();
    _loadTeamTodaySummary();
    _loadTeamTodayList();
    _loadRecentAnnouncements();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      isLoadingAttendance = true;
    });

    try {
      final attendance = await AttendanceController.getTodayAttendance();
      setState(() {
        todayAttendance = attendance;
        isLoadingAttendance = false;
      });
    } catch (e) {
      setState(() {
        isLoadingAttendance = false;
      });
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

  Future<void> _loadRequestsSummary() async {
    try {
      final summary = await RequestsService.getRequestsSummary();
      int leave = 0;
      int wfh = 0;
      int shift = 0;

      for (final item in summary.byType) {
        final type = item.type.toLowerCase();
        if (type.contains('wfh')) {
          wfh += item.count;
        } else if (type.contains('shift')) {
          shift += item.count;
        } else {
          leave += item.count;
        }
      }

      if (!mounted) return;

      setState(() {
        _pendingLeaveCount = leave;
        _pendingWfhCount = wfh;
        _pendingShiftChangeCount = shift;
      });
    } catch (e) {
      //error
    }
  }

  Future<void> _loadTeamTodaySummary() async {
    try {
      final summary = await AttendanceController.getTeamTodaySummary();
      if (!mounted) return;
      setState(() {
        _teamTotalStaff = (summary['total_staff'] as num?)?.toInt() ?? 0;
        _teamPresentCount = (summary['present'] as num?)?.toInt() ?? 0;
        _teamLateCount = (summary['late'] as num?)?.toInt() ?? 0;
        _teamAbsentCount = (summary['absent'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      //error
    }
  }

  Future<void> _loadTeamTodayList() async {
    setState(() {
      _isLoadingTeamAttendance = true;
    });

    try {
      final list = await AttendanceController.getTeamTodayList();
      if (!mounted) return;
      setState(() {
        _teamAttendance = list;
        _isLoadingTeamAttendance = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTeamAttendance = false;
      });
    }
  }

  Future<void> _loadRecentAnnouncements() async {
    setState(() {
      _isLoadingAnnouncements = true;
    });

    try {
      final announcements = await AnnouncementsService.getAnnouncements(limit: 5);
      if (!mounted) return;
      setState(() {
        _recentAnnouncements = announcements.take(3).toList(); // Show only 3 recent announcements
        _isLoadingAnnouncements = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAnnouncements = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadTodayAttendance(),
      _loadRequestsSummary(),
      _loadTeamTodaySummary(),
      _loadTeamTodayList(),
      _loadRecentAnnouncements(),
    ]);
  }

  String _getAttendanceStatusText() {
    if (todayAttendance == null) {
      return 'Ready to check in';
    } else if (!todayAttendance!.isCheckedIn) {
      return 'Not checked in today';
    } else if (todayAttendance!.isCheckedIn && !todayAttendance!.isCheckedOut) {
      return 'Currently working';
    } else {
      return 'Completed for today';
    }
  }

  String _getButtonText() {
    if (todayAttendance == null || !todayAttendance!.isCheckedIn) {
      return 'Clock In';
    } else if (todayAttendance!.isCheckedIn && !todayAttendance!.isCheckedOut) {
      return 'Clock Out';
    } else {
      return 'View Details';
    }
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.skyBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      _buildQuickAnalyticsSnapshot(context),
                      const SizedBox(height: 32),
                      _buildRecentAnnouncementsCard(context),
                      const SizedBox(height: 32),
                      // Holidays card removed; holidays now appear within announcements
                      _buildRequestsSummaryCard(context),
                      const SizedBox(height: 32),
                      _buildTeamAttendanceHeader(context),
                      const SizedBox(height: 16),
                      _buildTeamAttendanceList(context),
                      const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockInCard() {
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
            color: AppTheme.skyBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.white.withValues(alpha: 0.9), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Office - Main Building',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _getAttendanceStatusText(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckInOutScreen(),
                        ),
                      ).then((_) => _loadTodayAttendance());
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              fontFamily: 'Poppins',
            ),
            children: [
              const TextSpan(text: 'Admin Dashboard, '),
              TextSpan(
                text: context.watch<AuthProvider>().user?.name ?? 'Admin',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' 🏥'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppTheme.lightGold, AppTheme.paleRed],
                ),
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Team Requests',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.paleRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Action Required',
                        style: TextStyle(color: AppTheme.paleRed, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildRequestStat(_pendingLeaveCount, 'Leave')),
                Expanded(child: _buildRequestStat(_pendingWfhCount, 'WFH')),
                Expanded(child: _buildRequestStat(_pendingShiftChangeCount, 'Shift Change')),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminRequestsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.paleRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Review All Requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminLeavePoliciesScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.skyBlue,
                  side: const BorderSide(color: AppTheme.skyBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Manage Leave Policies',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestStat(int count, String label) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$count',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildQuickAnalyticsSnapshot(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticCard(
            context,
            Icons.group,
            '$_teamPresentCount/$_teamTotalStaff',
            'Staff Present',
            AppTheme.skyBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticCard(
            context,
            Icons.warning_amber_rounded,
            '$_teamLateCount',
            'Late Arrivals',
            AppTheme.paleRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticCard(
            context,
            Icons.person_off,
            '$_teamAbsentCount',
            'Absent',
            AppTheme.paleRed,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticCard(BuildContext context, IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textLightBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnnouncementsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppTheme.skyBlue, AppTheme.lightGold],
                ),
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Announcements',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.skyBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Latest 3',
                        style: TextStyle(color: AppTheme.skyBlue, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoadingAnnouncements)
              const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.skyBlue),
                ),
              )
            else if (_recentAnnouncements.isEmpty)
              Column(
                children: [
                  Icon(
                    Icons.announcement_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No announcements yet',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: _recentAnnouncements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final announcement = entry.value;
                  final typeColor = Color(int.parse(announcement.typeColor.replaceFirst('#', '0xFF')));
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < _recentAnnouncements.length - 1 ? 16.0 : 0.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getAnnouncementTypeIcon(announcement.type),
                              color: typeColor,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  announcement.title,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  announcement.targetAudience,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              announcement.typeDisplay.split(' ')[1],
                              style: TextStyle(
                                fontSize: 8,
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnnouncementsManagementScreen(),
                    ),
                  ).then((_) => _loadRecentAnnouncements());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.skyBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Manage Announcements',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAnnouncementTypeIcon(String type) {
    switch (type) {
      case 'urgent':
        return Icons.warning;
      case 'policy':
        return Icons.policy;
      case 'event':
        return Icons.celebration;
      default:
        return Icons.announcement;
    }
  }

  // Holidays card removed

  Color _getHolidayTypeColor(String? type) {
    switch (type) {
      case 'national':
        return AppTheme.skyBlue;
      case 'religious':
        return AppTheme.paleRed;
      default:
        return AppTheme.lightGold;
    }
  }

  IconData _getHolidayTypeIcon(String? type) {
    switch (type) {
      case 'national':
        return Icons.flag;
      case 'religious':
        return Icons.church;
      default:
        return Icons.event;
    }
  }

  Widget _buildTeamAttendanceHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'My Team Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Row(
                children: [
                  Text('Live View', style: TextStyle(color: AppTheme.skyBlue)),
                  Icon(Icons.chevron_right, size: 18, color: AppTheme.skyBlue),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamAttendanceList(BuildContext context) {
    if (_isLoadingTeamAttendance) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.skyBlue,
          ),
        ),
      );
    }

    if (_teamAttendance.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No team attendance data available',
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
      children: _teamAttendance
          .map((member) => _buildTeamAttendanceItem(context, member))
          .toList(),
    );
  }

  Widget _buildTeamAttendanceItem(BuildContext context, TeamAttendanceMember member) {
    final Color statusColor = member.status == 'Present'
        ? Colors.green
        : (member.status == 'Absent' ? AppTheme.paleRed : AppTheme.lightGold);

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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.1),
            child: Text(
              member.name.isNotEmpty ? member.name[0] : '?',
              style: const TextStyle(color: AppTheme.skyBlue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (member.role.isNotEmpty)
                  Text(
                    member.role,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                member.status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              if (member.checkInTime != null || member.checkOutTime != null)
                Text(
                  [
                    if (member.checkInTime != null) 'In: ${member.checkInTime}',
                    if (member.checkOutTime != null) 'Out: ${member.checkOutTime}',
                  ].join('  '),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textLightBlue,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
