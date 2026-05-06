import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_provider.dart';
import '../../controllers/attendance_provider.dart';
import '../../widgets/floating_navigation.dart';
import 'staff/dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_attendance_screen.dart';
import 'admin/admin_reports_screen.dart';
import 'admin/admin_requests_screen.dart';
import 'staff/attendance_screen.dart';
import 'staff/requests_screen.dart';
import 'staff/announcements_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    Future.microtask(() {
      if (mounted) {
        context.read<AttendanceProvider>().loadTodayAttendance();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    return FloatingNavigation(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
