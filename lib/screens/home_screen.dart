import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_provider.dart';
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
