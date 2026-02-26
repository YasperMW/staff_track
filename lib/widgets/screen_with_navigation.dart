import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class ScreenWithNavigation extends StatefulWidget {
  final Widget child;
  final String title;
  final int initialNavIndex;
  final bool showHeader;

  const ScreenWithNavigation({
    super.key,
    required this.child,
    required this.title,
    this.initialNavIndex = 0,
    this.showHeader = true,
  });

  @override
  State<ScreenWithNavigation> createState() => _ScreenWithNavigationState();
}

class _ScreenWithNavigationState extends State<ScreenWithNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialNavIndex;
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showHeader)
              AppHeader(
                subtitle: widget.title,
              ),
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
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

  List<BottomNavigationBarItem> _getNavItems() {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return [];
    
    final isAdmin = user.role.toLowerCase().contains('admin') || 
                  user.role.toLowerCase().contains('hr') || 
                  user.role.toLowerCase().contains('manager');

    return [
      BottomNavigationBarItem(
        icon: Icon(
          _currentIndex == 0 ? (isAdmin ? Icons.dashboard : Icons.home) : (isAdmin ? Icons.dashboard_outlined : Icons.home_outlined),
          size: 24,
        ),
        label: isAdmin ? 'Dashboard' : 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          _currentIndex == 1 ? Icons.access_time : Icons.access_time_outlined,
          size: 24,
        ),
        label: 'Attendance',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          _currentIndex == 2 ? (isAdmin ? Icons.assignment_turned_in : Icons.announcement) : (isAdmin ? Icons.assignment_turned_in_outlined : Icons.announcement_outlined),
          size: 24,
        ),
        label: isAdmin ? 'Requests' : 'Announcements',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          _currentIndex == 3 ? (isAdmin ? Icons.analytics : Icons.description) : (isAdmin ? Icons.analytics_outlined : Icons.description_outlined),
          size: 24,
        ),
        label: isAdmin ? 'Analytics' : 'Requests',
      ),
    ];
  }
}
