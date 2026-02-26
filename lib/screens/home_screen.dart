import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_provider.dart';
import '../../controllers/attendance_controller.dart';
import '../../models/models.dart';
import '../../widgets/floating_navigation.dart';
import 'staff/dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_attendance_screen.dart';
import 'admin/admin_reports_screen.dart';
import 'admin/admin_requests_screen.dart';
import 'staff/attendance_screen.dart';
import 'staff/reports_screen.dart';
import 'staff/requests_screen.dart';
import 'staff/announcements_screen.dart';
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
      const AnnouncementsScreen(),
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
        icon: _buildNavIcon(2, isAdmin ? Icons.assignment_turned_in : Icons.announcement, isAdmin ? Icons.assignment_turned_in_outlined : Icons.announcement_outlined),
        label: isAdmin ? 'Requests' : 'Announcements',
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
    return FloatingNavigation(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      child: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
