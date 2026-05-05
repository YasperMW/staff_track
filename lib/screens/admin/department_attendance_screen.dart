import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../services/organization_service.dart';
import 'user_attendance_history_screen.dart';

class DepartmentAttendanceScreen extends StatefulWidget {
  final String departmentId;
  final String departmentName;

  const DepartmentAttendanceScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  State<DepartmentAttendanceScreen> createState() => _DepartmentAttendanceScreenState();
}

class _DepartmentAttendanceScreenState extends State<DepartmentAttendanceScreen> {
  bool _isLoading = false;
  List<DepartmentAttendanceMember> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final data = await OrganizationService.getDepartmentTodayAttendance(widget.departmentId);
      if (!mounted) return;
      setState(() {
        _staff = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = _staff.where((s) => s.status == 'Present' || s.status == 'Completed').length;
    final absent = _staff.where((s) => s.status == 'Absent').length;
    final late = _staff.where((s) => s.status == 'Late').length;
    final total = _staff.length;

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
                subtitle: widget.departmentName,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _loadAttendance,
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
                        "Today's Attendance",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (total > 0) ...[
                        _buildSummaryRow(present, absent, late, total),
                        const SizedBox(height: 24),
                      ],
                      _buildStaffList(),
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

  Widget _buildSummaryRow(int present, int absent, int late, int total) {
    return Row(
      children: [
        _buildSummaryCard('Present', present, Colors.green),
        const SizedBox(width: 12),
        _buildSummaryCard('Absent', absent, AppTheme.paleRed),
        const SizedBox(width: 12),
        _buildSummaryCard('Late', late, AppTheme.lightGold),
      ],
    );
  }

  Widget _buildSummaryCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
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

  Widget _buildStaffList() {
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

    if (_staff.isEmpty) {
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
              'No staff in this department',
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
      children: _staff.map((member) => _buildStaffItem(member)).toList(),
    );
  }

  Widget _buildStaffItem(DepartmentAttendanceMember member) {
    Color statusColor;
    switch (member.status) {
      case 'Present':
        statusColor = Colors.green;
        break;
      case 'Completed':
        statusColor = Colors.green;
        break;
      case 'Late':
        statusColor = AppTheme.lightGold;
        break;
      case 'Absent':
        statusColor = AppTheme.paleRed;
        break;
      default:
        statusColor = Colors.grey;
    }

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
              style: const TextStyle(color: AppTheme.skyBlue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserAttendanceHistoryScreen(
                      userId: member.userId,
                      userName: member.name,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (member.role.isNotEmpty)
                    Text(
                      member.role,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  if (member.checkInTime != null || member.checkOutTime != null)
                    Text(
                      [
                        if (member.checkInTime != null) 'In: ${member.checkInTime}',
                        if (member.checkOutTime != null) 'Out: ${member.checkOutTime}',
                      ].join('  '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLightBlue,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              member.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
