import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../check_in_out_screen.dart';
import '../../services/attendance_service.dart';
import '../../models/models.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? teamSummary;
  bool isLoadingTeam = false;
  List<TeamAttendanceMember> _teamAttendance = [];
  bool _isLoadingStaff = false;
  final AttendanceService _attendanceService = const AttendanceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTeamSummary();
    _loadStaffList();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTeamSummary();
      _loadStaffList();
    }
  }

  Future<void> _onRefresh() async {
    await _loadTeamSummary();
    await _loadStaffList();
  }

  Future<void> _loadTeamSummary() async {
    setState(() {
      isLoadingTeam = true;
    });

    try {
      final data = await _attendanceService.getTeamTodaySummary();
      if (!mounted) return;
      setState(() {
        teamSummary = data;
        isLoadingTeam = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingTeam = false;
      });
    }
  }

  Future<void> _loadStaffList() async {
    setState(() {
      _isLoadingStaff = true;
    });

    try {
      final list = await _attendanceService.getTeamTodayList();
      if (!mounted) return;
      setState(() {
        _teamAttendance = list;
        _isLoadingStaff = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStaff = false;
      });
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
                      Text(
                        'Personal & Team status',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildCheckInButton(context),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Team Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryStats(context),
                      const SizedBox(height: 16),
                      _buildStaffList(context),
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


  Widget _buildSummaryStats(BuildContext context) {
    final int present = (teamSummary?['present'] as num?)?.toInt() ?? 0;
    final int absent = (teamSummary?['absent'] as num?)?.toInt() ?? 0;
    final int late = (teamSummary?['late'] as num?)?.toInt() ?? 0;
    final int totalTeamMembers = present + absent + late;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_outlined,
                color: AppTheme.skyBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Today's Team Status",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalTeamMembers Members',
                  style: TextStyle(
                    color: AppTheme.skyBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _enhancedTeamStatCard(
                context: context,
                label: 'Present',
                value: '$present',
                percentage: totalTeamMembers > 0 ? '${(present / totalTeamMembers * 100).toStringAsFixed(0)}%' : '0%',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _enhancedTeamStatCard(
                context: context,
                label: 'Absent',
                value: '$absent',
                percentage: totalTeamMembers > 0 ? '${(absent / totalTeamMembers * 100).toStringAsFixed(0)}%' : '0%',
                icon: Icons.cancel_outlined,
                color: AppTheme.paleRed,
              ),
              const SizedBox(width: 12),
              _enhancedTeamStatCard(
                context: context,
                label: 'Late',
                value: '$late',
                percentage: totalTeamMembers > 0 ? '${(late / totalTeamMembers * 100).toStringAsFixed(0)}%' : '0%',
                icon: Icons.access_time,
                color: AppTheme.lightGold,
              ),
            ],
          ),
          if (totalTeamMembers > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AppTheme.skyBlue.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Team Attendance Rate: ${((present + late) / totalTeamMembers * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppTheme.skyBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _enhancedTeamStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required String percentage,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList(BuildContext context) {
    if (_isLoadingStaff) {
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
          .map((member) => _buildStaffItem(context, member))
          .toList(),
    );
  }

  Widget _buildStaffItem(BuildContext context, TeamAttendanceMember member) {
    Color statusColor = member.status == 'Present'
        ? Colors.green
        : (member.status == 'Absent' ? AppTheme.paleRed : AppTheme.lightGold);

    return GestureDetector(
      onTap: () => _showAttendanceDetailDialog(context, member),
      child: Container(
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (member.lateReason != null || member.earlyCheckoutReason != null)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: (member.lateReason != null ? AppTheme.lightGold : AppTheme.paleRed).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          member.lateReason != null ? Icons.warning_amber_rounded : Icons.exit_to_app,
                          size: 12,
                          color: member.lateReason != null ? AppTheme.lightGold : AppTheme.paleRed,
                        ),
                      ),
                    Text(
                      member.status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                if (member.checkInTime != null || member.checkOutTime != null)
                  Text(
                    [
                      if (member.checkInTime != null) 'In: ${member.checkInTime}',
                      if (member.checkOutTime != null) 'Out: ${member.checkOutTime}',
                    ].join('  '),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textLightBlue),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceDetailDialog(BuildContext context, TeamAttendanceMember member) {
    final theme = Theme.of(context);
    final statusColor = member.status == 'Present'
        ? Colors.green
        : (member.status == 'Absent' ? AppTheme.paleRed : AppTheme.lightGold);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.1),
              child: Text(
                member.name.isNotEmpty ? member.name[0] : '?',
                style: const TextStyle(color: AppTheme.skyBlue, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (member.role.isNotEmpty)
                    Text(
                      member.role,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  member.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Details
              _buildDetailRow(
                context: context,
                icon: Icons.login_rounded,
                label: 'Check-in Time',
                value: member.checkInTime ?? 'Not checked in',
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context: context,
                icon: Icons.logout_rounded,
                label: 'Check-out Time',
                value: member.checkOutTime ?? 'Not checked out',
                color: AppTheme.paleRed,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context: context,
                icon: Icons.schedule,
                label: 'Shift Type',
                value: member.shiftType ?? 'Day Shift',
                color: AppTheme.skyBlue,
              ),
              if (member.workHours != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  context: context,
                  icon: Icons.timelapse,
                  label: 'Work Hours',
                  value: '${member.workHours!.toStringAsFixed(1)} hrs',
                  color: AppTheme.lightGold,
                ),
              ],

              // Late Reason
              if (member.lateReason != null && member.lateReason!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildReasonCard(
                  context: context,
                  icon: Icons.warning_amber_rounded,
                  title: 'Late Check-in Reason',
                  reason: member.lateReason!,
                  color: AppTheme.lightGold,
                ),
              ],

              // Early Checkout Reason
              if (member.earlyCheckoutReason != null && member.earlyCheckoutReason!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildReasonCard(
                  context: context,
                  icon: Icons.exit_to_app,
                  title: 'Early Check-out Reason',
                  reason: member.earlyCheckoutReason!,
                  color: AppTheme.paleRed,
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

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String reason,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

