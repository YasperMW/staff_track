import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_provider.dart';
import '../../controllers/attendance_provider.dart';
import '../../controllers/navigation_provider.dart';
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<NavigationProvider>().setIndex(widget.initialIndex);
      }
    });

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
                  user.role.toLowerCase().contains('manager') ||
                  user.role.toLowerCase().contains('head') ||
                  user.role.toLowerCase().contains('accountant') ||
                  user.role.toLowerCase().contains('finance');
    
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
    final currentIndex = context.watch<NavigationProvider>().currentIndex;
    return FloatingNavigation(
      currentIndex: currentIndex,
      onTap: (index) {
        context.read<NavigationProvider>().setIndex(index);
      },
      child: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
    );
  }
}
