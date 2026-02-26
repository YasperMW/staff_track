import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_provider.dart';
import '../controllers/attendance_controller.dart';
import '../models/models.dart';
import 'staff/dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_attendance_screen.dart';
import 'admin/admin_reports_screen.dart';
import 'admin/admin_requests_screen.dart';
import 'staff/attendance_screen.dart';
import 'staff/reports_screen.dart';
import 'staff/requests_screen.dart';
import 'check_in_out_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  AttendanceRecord? todayAttendance;
  bool isLoadingAttendance = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadTodayAttendance();
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

  Future<void> _handleQuickCheckInOut() async {
    if (todayAttendance == null || !todayAttendance!.isCheckedIn) {
      // Check in
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CheckInOutScreen(),
        ),
      ).then((_) => _loadTodayAttendance());
    } else if (todayAttendance!.isCheckedIn && !todayAttendance!.isCheckedOut) {
      // Check out
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CheckInOutScreen(),
        ),
      ).then((_) => _loadTodayAttendance());
    }
  }

  List<Widget> _getScreens() {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return [];
    
    final isAdmin = user.role.toLowerCase().contains('admin') || 
                  user.role.toLowerCase().contains('hr') || 
                  user.role.toLowerCase().contains('manager');
    
    if (isAdmin) {
      return [
        const AdminDashboardScreen(),
        const AdminAttendanceScreen(),
        const AdminRequestsScreen(),
        const AdminReportsScreen(),
      ];
    }
    return [
      const DashboardScreen(),
      const AttendanceScreen(),
      const ReportsScreen(),
      const RequestsScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getNavItems() {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return [];
    
    final isAdmin = user.role.toLowerCase().contains('admin') || 
                  user.role.toLowerCase().contains('hr') || 
                  user.role.toLowerCase().contains('manager');

    return [
      BottomNavigationBarItem(
        icon: _buildNavIcon(0, isAdmin ? Icons.dashboard : Icons.home, isAdmin ? Icons.dashboard_outlined : Icons.home_outlined),
        label: isAdmin ? 'Dashboard' : 'Home',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(1, Icons.access_time, Icons.access_time_outlined),
        label: 'Attendance',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(2, isAdmin ? Icons.assignment_turned_in : Icons.bar_chart, isAdmin ? Icons.assignment_turned_in_outlined : Icons.bar_chart_outlined),
        label: isAdmin ? 'Requests' : 'Reports',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(3, isAdmin ? Icons.analytics : Icons.description, isAdmin ? Icons.analytics_outlined : Icons.description_outlined),
        label: isAdmin ? 'Analytics' : 'Requests',
      ),
    ];
  }

  Widget _buildNavIcon(int index, IconData activeIcon, IconData inactiveIcon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentIndex == index)
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: AppTheme.skyBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(height: 4),
        Icon(_currentIndex == index ? activeIcon : inactiveIcon),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: AppTheme.skyBlue,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          items: _getNavItems(),
        ),
      ),
    );
  }
}
