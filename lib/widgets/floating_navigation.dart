import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_provider.dart';
import '../theme/app_theme.dart';

class FloatingNavigation extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNavigation({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingNavigation> createState() => _FloatingNavigationState();
}

class _FloatingNavigationState extends State<FloatingNavigation> {
  List<BottomNavigationBarItem> _getNavItems() {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return [];
    
    final role = user.role.toLowerCase();
    final isAdmin = role.contains('admin') || 
                  role.contains('hr') || 
                  role.contains('manager') ||
                  role.contains('head') ||
                  role.contains('accountant') ||
                  role.contains('finance');

    return [
      BottomNavigationBarItem(
        icon: Icon(
          widget.currentIndex == 0 ? (isAdmin ? Icons.dashboard : Icons.home) : (isAdmin ? Icons.dashboard_outlined : Icons.home_outlined),
          size: 24,
        ),
        label: isAdmin ? 'Dashboard' : 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          widget.currentIndex == 1 ? Icons.access_time : Icons.access_time_outlined,
          size: 24,
        ),
        label: 'Attendance',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          widget.currentIndex == 2 ? (isAdmin ? Icons.assignment_turned_in : Icons.announcement) : (isAdmin ? Icons.assignment_turned_in_outlined : Icons.announcement_outlined),
          size: 24,
        ),
        label: isAdmin ? 'Requests' : 'Announcements',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          widget.currentIndex == 3 ? (isAdmin ? Icons.analytics : Icons.description) : (isAdmin ? Icons.analytics_outlined : Icons.description_outlined),
          size: 24,
        ),
        label: isAdmin ? 'Analytics' : 'Requests',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: widget.child,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: widget.currentIndex,
              onTap: widget.onTap,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.skyBlue,
              unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              items: _getNavItems(),
            ),
          ),
        ),
      ),
    );
  }
}
