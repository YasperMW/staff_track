import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/mock_data.dart';
import 'staff/dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_attendance_screen.dart';
import 'admin/admin_reports_screen.dart';
import 'admin/admin_requests_screen.dart';
import 'staff/attendance_screen.dart';
import 'staff/reports_screen.dart';
import 'staff/requests_screen.dart';
import 'SharedScreens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> _getScreens() {
    final user = MockData.currentUser;
    if (user.isApprover) {
      return [
        const AdminDashboardScreen(),
        const AdminAttendanceScreen(),
        const AdminRequestsScreen(),
        const AdminReportsScreen(),
        const ProfileScreen(),
      ];
    }
    return [
      const DashboardScreen(),
      const AttendanceScreen(),
      const ReportsScreen(),
      const RequestsScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getNavItems() {
    final user = MockData.currentUser;
    final isApprover = user.isApprover;

    return [
      BottomNavigationBarItem(
        icon: _buildNavIcon(0, isApprover ? Icons.dashboard : Icons.home, isApprover ? Icons.dashboard_outlined : Icons.home_outlined),
        label: isApprover ? 'Dashboard' : 'Home',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(1, isApprover ? Icons.access_time : Icons.access_time, isApprover ? Icons.access_time_outlined : Icons.access_time_outlined),
        label: 'Attendance',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(2, isApprover ? Icons.assignment_turned_in : Icons.bar_chart, isApprover ? Icons.assignment_turned_in_outlined : Icons.bar_chart_outlined),
        label: isApprover ? 'Requests' : 'Reports',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(3, isApprover ? Icons.analytics : Icons.description, isApprover ? Icons.analytics_outlined : Icons.description_outlined),
        label: isApprover ? 'Analytics' : 'Requests',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(4, Icons.person, Icons.person_outline),
        label: 'Profile',
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
              color: AppTheme.primaryBlue,
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
          selectedItemColor: AppTheme.primaryBlue,
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
