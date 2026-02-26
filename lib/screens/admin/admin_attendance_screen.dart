import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/floating_navigation.dart';
import '../check_in_out_screen.dart';
import '../home_screen.dart';
import '../../controllers/attendance_controller.dart';
import '../../models/models.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  Map<String, dynamic>? teamSummary;
  bool isLoadingTeam = false;
  List<TeamAttendanceMember> _teamAttendance = [];
  bool _isLoadingStaff = false;

  @override
  void initState() {
    super.initState();
    _loadTeamSummary();
    _loadStaffList();
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
      final data = await AttendanceController.getTeamTodaySummary();
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
      final list = await AttendanceController.getTeamTodayList();
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
    return FloatingNavigation(
      currentIndex: 1, // Attendance is index 1 for admin
      onTap: (index) {
        if (index == 1) {
          // Already on attendance screen, do nothing
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialIndex: index),
          ),
        );
      },
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.skyBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Personal & Team status',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildCheckInButton(context),
                            ],
                          ),
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
              ],
            ),
          ),
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


  Widget _buildSummaryStats(BuildContext context) {
    final int present = (teamSummary?['present'] as num?)?.toInt() ?? 0;
    final int absent = (teamSummary?['absent'] as num?)?.toInt() ?? 0;
    final int late = (teamSummary?['late'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        _buildStatCard(context, 'Present', '$present', Colors.green),
        const SizedBox(width: 12),
        _buildStatCard(context, 'Absent', '$absent', AppTheme.paleRed),
        const SizedBox(width: 12),
        _buildStatCard(context, 'Late', '$late', AppTheme.lightGold),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
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
    bool isPresent = member.status == 'Present';
    Color statusColor = member.status == 'Present'
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
                  style: const TextStyle(fontSize: 10, color: AppTheme.textLightBlue),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

