import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'attendance_screen.dart';
import 'reports_screen.dart';
import 'requests_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AttendanceScreen(),
    const ReportsScreen(),
    const RequestsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
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
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          items: [
            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentIndex == 0)
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
                ],
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentIndex == 1)
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.access_time_outlined),
                ],
              ),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentIndex == 2)
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.bar_chart_outlined),
                ],
              ),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentIndex == 3)
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(_currentIndex == 3 ? Icons.description : Icons.description_outlined),
                ],
              ),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentIndex == 4)
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(_currentIndex == 4 ? Icons.person : Icons.person_outline),
                ],
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
