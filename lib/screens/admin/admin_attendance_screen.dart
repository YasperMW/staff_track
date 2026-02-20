import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../check_in_out_screen.dart';
import '../../controllers/attendance_controller.dart';
import '../../models/models.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  Map<String, dynamic>? summary;
  bool isLoading = false;
  Map<String, dynamic>? teamSummary;
  bool isLoadingTeam = false;
  List<TeamAttendanceMember> _teamAttendance = [];
  bool _isLoadingStaff = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadTeamSummary();
    _loadStaffList();
  }

  Future<void> _loadSummary() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await AttendanceController.getAttendanceSummary();
      if (!mounted) return;
      setState(() {
        summary = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadSummary();
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(
                  subtitle: 'HR Admin Portal',
                ),
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
                      const SizedBox(height: 24),
                      Text(
                        'Your Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPersonalSummaryCard(),
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
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
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

  Widget _buildPersonalSummaryCard() {
    final int totalDays = (summary?['total_days'] as num?)?.toInt() ?? 0;
    final int presentDays = (summary?['present_days'] as num?)?.toInt() ?? 0;
    final int lateDays = (summary?['late_days'] as num?)?.toInt() ?? 0;
    final int absentDays = totalDays - presentDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PersonalSummaryItem(value: '$presentDays', label: 'Present'),
          _PersonalSummaryItem(value: '$lateDays', label: 'Late'),
          _PersonalSummaryItem(value: '$absentDays', label: 'Absent'),
        ],
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
        _buildStatCard(context, 'Absent', '$absent', Colors.red),
        const SizedBox(width: 12),
        _buildStatCard(context, 'Late', '$late', Colors.orange),
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
            color: AppTheme.primaryBlue,
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
        : (member.status == 'Absent' ? Colors.red : Colors.orange);

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
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
            child: Text(
              member.name.isNotEmpty ? member.name[0] : '?',
              style: const TextStyle(color: AppTheme.primaryBlue),
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

class _PersonalSummaryItem extends StatelessWidget {
  final String value;
  final String label;

  const _PersonalSummaryItem({required this.value, required this.label});

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
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
