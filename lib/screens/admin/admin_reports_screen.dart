import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/floating_navigation.dart';
import '../../services/admin_reports_service.dart';
import '../home_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoadingOverview = false;
  AdminReportsOverview? _overview;
  bool _isLoadingWeekly = false;
  List<WeeklyAttendancePoint> _weeklyPoints = [];
  bool _isLoadingTop = false;
  List<TopPerformer> _topPerformers = [];

  @override
  void initState() {
    super.initState();
    _loadOverview();
    _loadWeekly();
    _loadTopPerformers();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoadingOverview = true;
    });

    try {
      final data = await AdminReportsService.getOverview();
      if (!mounted) return;
      setState(() {
        _overview = data;
        _isLoadingOverview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingOverview = false;
      });
    }
  }

  Future<void> _loadWeekly() async {
    setState(() {
      _isLoadingWeekly = true;
    });

    try {
      final data = await AdminReportsService.getWeeklyAttendance();
      if (!mounted) return;
      setState(() {
        _weeklyPoints = data;
        _isLoadingWeekly = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWeekly = false;
      });
    }
  }

  Future<void> _loadTopPerformers() async {
    setState(() {
      _isLoadingTop = true;
    });

    try {
      final data = await AdminReportsService.getTopPerformers();
      if (!mounted) return;
      setState(() {
        _topPerformers = data;
        _isLoadingTop = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTop = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingNavigation(
      currentIndex: 3, // Analytics/Reports is index 3 for admin
      onTap: (index) {
        if (index == 3) {
          // Already on analytics screen, do nothing
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Department Analytics',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Monthly staff performance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildOverviewCards(context),
                    const SizedBox(height: 24),
                    _buildDepartmentChart(context),
                    const SizedBox(height: 24),
                    _buildTopPerformers(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    if (_isLoadingOverview) {
      return const Row(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.skyBlue,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final avgAttendance = _overview?.avgAttendance ?? 0;
    final totalOt = _overview?.totalOvertimeHours ?? 0;

    return Row(
      children: [
        _buildStatCard(
          context,
          'Avg Attendance',
          '${avgAttendance.toStringAsFixed(1)}%',
          Icons.check_circle_outline,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context,
          'Total OT Hours',
          '${totalOt.toStringAsFixed(1)}h',
          Icons.timer_outlined,
          AppTheme.lightGold,
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLightBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentChart(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
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
          const Text(
            'Weekly Department Attendance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: _isLoadingWeekly
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.skyBlue,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: (_weeklyPoints.isNotEmpty
                            ? _weeklyPoints
                            : [
                                WeeklyAttendancePoint(label: 'Mon', percentage: 0),
                                WeeklyAttendancePoint(label: 'Tue', percentage: 0),
                                WeeklyAttendancePoint(label: 'Wed', percentage: 0),
                                WeeklyAttendancePoint(label: 'Thu', percentage: 0),
                                WeeklyAttendancePoint(label: 'Fri', percentage: 0),
                                WeeklyAttendancePoint(label: 'Sat', percentage: 0),
                                WeeklyAttendancePoint(label: 'Sun', percentage: 0),
                              ])
                        .map((p) {
                      final height = (p.percentage.clamp(0, 100) / 100) * 140;
                      return _buildBar(height, p.label);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.skyBlue.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textLightBlue)),
      ],
    );
  }

  Widget _buildTopPerformers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        if (_isLoadingTop)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.skyBlue,
              ),
            ),
          )
        else if (_topPerformers.isEmpty)
          Text(
            'No performance data available',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
        else
          Column(
            children: _topPerformers
                .map(
                  (p) => _buildPerformerItem(
                    context,
                    p.name,
                    p.role,
                    '${p.attendancePercentage.toStringAsFixed(1)}% Attendance',
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildPerformerItem(BuildContext context, String name, String role, String score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.star, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(role, style: const TextStyle(fontSize: 12, color: AppTheme.textLightBlue)),
              ],
            ),
          ),
          Text(score, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
        ],
      ),
    );
  }
}
