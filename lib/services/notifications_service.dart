import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import 'auth_storage.dart';
import 'holidays_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

class NotificationsService {
  static Future<List<NotificationItem>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (unreadOnly) 'unread_only': 'true',
      };

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/notifications').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Notifications data: $data'); // Debug print
        return data.map((item) {
          print('Processing notification item: $item'); // Debug print
          return NotificationItem.fromJson(item);
        }).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading notifications: $e');
    }
  }

  static Future<NotificationItem> createNotification({
    required String title,
    required String message,
    required String type,
    String? recipientUserId,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'message': message,
          'type': type,
          'recipient_user_id': recipientUserId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return NotificationItem.fromJson(data);
      } else {
        throw Exception('Failed to create notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final token = await AuthStorage.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    try {
      final token = await AuthStorage.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final token = await AuthStorage.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['unread_count'] as int;
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      final token = await AuthStorage.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  // Holiday-specific notification methods
  static Future<void> sendHolidayNotificationToAll(PublicHoliday holiday) async {
    try {
      await createNotification(
        title: '🎉 Public Holiday: ${holiday.name}',
        message: 'Reminder: ${holiday.name} will be observed on ${DateFormat('MMMM d, yyyy').format(holiday.date)}. Please plan accordingly.',
        type: 'holiday',
      );
    } catch (e) {
      throw Exception('Error sending holiday notification: $e');
    }
  }

  static Future<void> sendUpcomingHolidayNotifications() async {
    try {
      final upcomingHolidays = await HolidaysService.getUpcomingHolidays(monthsAhead: 1);
      
      for (final holiday in upcomingHolidays) {
        final daysUntil = holiday.date.difference(DateTime.now()).inDays;
        
        if (daysUntil <= 7 && daysUntil > 0) {
          String message;
          if (daysUntil == 1) {
            message = 'Tomorrow is ${holiday.name}! Please make necessary arrangements.';
          } else if (daysUntil <= 3) {
            message = '${holiday.name} is coming up in $daysUntil days! Please plan accordingly.';
          } else {
            message = '${holiday.name} will be observed in $daysUntil days on ${DateFormat('EEEE, MMMM d').format(holiday.date)}.';
          }
          
          await createNotification(
            title: '📅 Upcoming Holiday: ${holiday.name}',
            message: message,
            type: 'holiday_reminder',
          );
        }
      }
    } catch (e) {
      throw Exception('Error sending upcoming holiday notifications: $e');
    }
  }

  static Future<void> sendHolidayScheduleChangeNotification(PublicHoliday holiday) async {
    try {
      await createNotification(
        title: '📝 Holiday Schedule Update',
        message: 'Holiday schedule updated: ${holiday.name} on ${DateFormat('MMMM d, yyyy').format(holiday.date)}. Please check your work schedule.',
        type: 'holiday_update',
      );
    } catch (e) {
      throw Exception('Error sending holiday schedule change notification: $e');
    }
  }

  // Announcement-specific notification methods
  static Future<void> sendAnnouncementNotificationToTarget(Announcement announcement) async {
    try {
      await createNotification(
        title: announcement.typeDisplay,
        message: announcement.message,
        type: 'announcement',
        recipientUserId: null, // Will be handled by backend to send to target audience
      );
    } catch (e) {
      throw Exception('Error sending announcement notification: $e');
    }
  }

  static Future<void> sendAnnouncementNotificationToAll(Announcement announcement) async {
    try {
      await createNotification(
        title: '${announcement.typeDisplay} - ${announcement.targetAudience}',
        message: announcement.message,
        type: 'announcement',
        recipientUserId: null, // Will be handled by backend to send to all
      );
    } catch (e) {
      throw Exception('Error sending announcement notification to all: $e');
    }
  }

  static Future<void> sendAnnouncementNotificationToDepartment(Announcement announcement, String department) async {
    try {
      await createNotification(
        title: '${announcement.typeDisplay} - $department',
        message: announcement.message,
        type: 'announcement',
        recipientUserId: null, // Will be handled by backend to send to department
      );
    } catch (e) {
      throw Exception('Error sending announcement notification to department: $e');
    }
  }

  static Future<void> sendAnnouncementNotificationToRole(Announcement announcement, String department, String role) async {
    try {
      await createNotification(
        title: '${announcement.typeDisplay} - $department - $role',
        message: announcement.message,
        type: 'announcement',
        recipientUserId: null, // Will be handled by backend to send to role
      );
    } catch (e) {
      throw Exception('Error sending announcement notification to role: $e');
    }
  }
}
