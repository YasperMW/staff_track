import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_attendance_screen.dart';
import '../screens/admin/admin_requests_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/staff/dashboard_screen.dart';
import '../screens/staff/attendance_screen.dart';
import '../screens/staff/announcements_screen.dart';
import '../screens/staff/requests_screen.dart';

class AppNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
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

  Widget _buildNavIcon(int index, IconData activeIcon, IconData inactiveIcon) {
    return Icon(
      widget.currentIndex == index ? activeIcon : inactiveIcon,
      size: 24,
    );
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

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    
    return Scaffold(
      body: IndexedStack(
        index: widget.currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
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
