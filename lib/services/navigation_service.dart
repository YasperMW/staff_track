import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/SharedScreens/notifications_screen.dart';
import '../screens/admin/admin_requests_screen.dart';
import '../screens/admin/announcements_management_screen.dart';
import '../screens/admin/admin_attendance_screen.dart';
import '../screens/check_in_out_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/staff/announcements_screen.dart';
import '../screens/staff/attendance_screen.dart';
import '../screens/staff/requests_screen.dart';
import '../screens/staff/dashboard_screen.dart';
import '../screens/attendance_history_screen.dart';

class NotificationNavigationService {
  static void handleNotificationClick(BuildContext context, Map<String, dynamic> data) {
    final String? screen = data['screen'];
    final String? type = data['type'];
    final String? id = data['id'];
    
    if (screen != null) {
      _navigateToScreen(context, screen, type, id);
    } else if (type != null) {
      _navigateByNotificationType(context, type, data);
    } else {
      // Default navigation to notifications screen
      _navigateToScreen(context, 'notifications', null, null);
    }
  }

  static void _navigateToScreen(BuildContext context, String screen, String? type, String? id) {
    switch (screen.toLowerCase()) {
      case 'home':
      case 'dashboard':
        _navigateToHome(context, 0);
        break;
      case 'attendance':
        _navigateToHome(context, 1);
        break;
      case 'requests':
        _navigateToHome(context, 3);
        break;
      case 'announcements':
        _navigateToHome(context, 2);
        break;
      case 'notifications':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
        break;
      case 'check_in_out':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckInOutScreen()),
        );
        break;
      case 'attendance_history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AttendanceHistoryScreen()),
        );
        break;
      default:
        _navigateToHome(context, 0);
    }
  }

  static void _navigateByNotificationType(BuildContext context, String type, Map<String, dynamic> data) {
    switch (type.toLowerCase()) {
      case 'attendance_reminder':
      case 'check_in_reminder':
      case 'check_out_reminder':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckInOutScreen()),
        );
        break;
      
      case 'request_submitted':
      case 'request_approved':
      case 'request_denied':
      case 'request_escalated':
        _navigateToHome(context, 3); // Requests tab
        break;
      
      case 'announcement':
      case 'urgent_announcement':
      case 'policy_announcement':
        _navigateToHome(context, 2); // Announcements tab
        break;
      
      case 'geofence_violation':
      case 'security_alert':
        _navigateToHome(context, 1); // Attendance tab
        break;
      
      case 'leave_policy_update':
      case 'policy_change':
        _navigateToHome(context, 2); // Announcements tab
        break;
      
      case 'system_update':
      case 'maintenance':
      case 'account_update':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
        break;
      
      default:
        _navigateToHome(context, 0);
    }
  }

  static void _navigateToHome(BuildContext context, int initialIndex) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(initialIndex: initialIndex),
      ),
      (route) => false,
    );
  }
}
