import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import 'auth_storage.dart';
import 'notifications_service.dart';

class AnnouncementsService {

  static Future<List<Announcement>> getAnnouncements({
    int? limit,
    int? offset,
    bool? activeOnly,
    String? department,
    String? role,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      
      final queryParams = <String, String>{
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
        if (activeOnly != null) 'active_only': activeOnly.toString(),
        if (department != null) 'department': department,
        if (role != null) 'role': role,
      };

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/announcements').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Announcement.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load announcements');
      }
    } catch (e) {
      // Return mock data for development
      return _getMockAnnouncements();
    }
  }

  static Future<Announcement> createAnnouncement({
    required String title,
    required String message,
    required String type,
    String? targetDepartment,
    String? targetRole,
    bool isActive = true,
    DateTime? expiresAt,
    String? attachmentUrl,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/announcements'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'message': message,
          'type': type,
          'target_department': targetDepartment,
          'target_role': targetRole,
          'is_active': isActive,
          'expires_at': expiresAt?.toIso8601String(),
          'attachment_url': attachmentUrl,
        }),
      );

      if (response.statusCode == 201) {
        return Announcement.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create announcement');
      }
    } catch (e) {
      // Return mock announcement for development
      final mockAnnouncement = Announcement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        targetDepartment: targetDepartment,
        targetRole: targetRole,
        isActive: isActive,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
        attachmentUrl: attachmentUrl,
      );
      return mockAnnouncement;
    }
  }

  static Future<Announcement> updateAnnouncement({
    required String id,
    String? title,
    String? message,
    String? type,
    String? targetDepartment,
    String? targetRole,
    bool? isActive,
    DateTime? expiresAt,
    String? attachmentUrl,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/api/announcements/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (title != null) 'title': title,
          if (message != null) 'message': message,
          if (type != null) 'type': type,
          if (targetDepartment != null) 'target_department': targetDepartment,
          if (targetRole != null) 'target_role': targetRole,
          if (isActive != null) 'is_active': isActive,
          if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
          if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        }),
      );

      if (response.statusCode == 200) {
        return Announcement.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update announcement');
      }
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  static Future<void> deleteAnnouncement(String id) async {
    try {
      final token = await AuthStorage.getToken();
      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/api/announcements/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete announcement');
      }
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  static Future<List<Announcement>> getActiveAnnouncements({
    String? department,
    String? role,
  }) async {
    return getAnnouncements(
      activeOnly: true,
      department: department,
      role: role,
      limit: 50,
    );
  }

  static Future<List<Announcement>> getMyAnnouncements({
    String? department,
    String? role,
  }) async {
    return getAnnouncements(
      activeOnly: true,
      department: department,
      role: role,
      limit: 20,
    );
  }

  static Future<void> sendAnnouncementNotifications(Announcement announcement) async {
    try {
      // Send notifications based on target audience
      if (announcement.targetDepartment == null) {
        // Send to all staff
        await NotificationsService.sendAnnouncementNotificationToAll(announcement);
      } else if (announcement.targetRole == null) {
        // Send to entire department
        await NotificationsService.sendAnnouncementNotificationToDepartment(
          announcement, 
          announcement.targetDepartment!,
        );
      } else {
        // Send to specific role in department
        await NotificationsService.sendAnnouncementNotificationToRole(
          announcement,
          announcement.targetDepartment!,
          announcement.targetRole!,
        );
      }
    } catch (e) {
      throw Exception('Error sending announcement notifications: $e');
    }
  }

  // Mock data for development
  static List<Announcement> _getMockAnnouncements() {
    final now = DateTime.now();
    return [
      Announcement(
        id: '1',
        title: 'Welcome to Staff Track System',
        message: 'We are pleased to announce the launch of our new staff attendance and management system. Please familiarize yourself with the features and reach out to HR if you need assistance.',
        type: 'general',
        targetDepartment: null, // All staff
        isActive: true,
        createdAt: now.subtract(const Duration(days: 7)),
        createdBy: 'HR Admin',
      ),
      Announcement(
        id: '2',
        title: 'New Attendance Policy Update',
        message: 'Effective immediately, all staff must clock in within 15 minutes of their shift start time. Late arrivals will be recorded and may affect performance evaluations.',
        type: 'policy',
        targetDepartment: null, // All staff
        isActive: true,
        createdAt: now.subtract(const Duration(days: 3)),
        createdBy: 'HR Admin',
      ),
      Announcement(
        id: '3',
        title: 'System Maintenance Scheduled',
        message: 'The Staff Track system will undergo maintenance this weekend from Saturday 10 PM to Sunday 2 AM. Please plan your attendance accordingly.',
        type: 'urgent',
        targetDepartment: null, // All staff
        isActive: true,
        expiresAt: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
        createdBy: 'IT Department',
      ),
      Announcement(
        id: '4',
        title: 'Medical Department Meeting',
        message: 'All medical staff are required to attend a mandatory meeting on Friday at 2 PM in Conference Room A. New patient care protocols will be discussed.',
        type: 'event',
        targetDepartment: 'Medical',
        isActive: true,
        createdAt: now.subtract(const Duration(hours: 6)),
        createdBy: 'Medical Director',
      ),
      Announcement(
        id: '5',
        title: 'Nursing Shift Schedule Update',
        message: 'Please note the updated nursing shift schedule for next month. Changes have been made to accommodate the new staff members. Check your personal schedules.',
        type: 'general',
        targetDepartment: 'Nursing',
        targetRole: 'Nurse',
        isActive: true,
        createdAt: now.subtract(const Duration(hours: 12)),
        createdBy: 'Head Nurse',
      ),
      Announcement(
        id: '6',
        title: 'Expired Announcement Example',
        message: 'This announcement has expired and should not be shown.',
        type: 'general',
        targetDepartment: null,
        isActive: true,
        expiresAt: now.subtract(const Duration(days: 1)), // Expired
        createdAt: now.subtract(const Duration(days: 5)),
        createdBy: 'HR Admin',
      ),
    ];
  }

  // Helper to get available departments
  static List<String> getAvailableDepartments() {
    return [
      'Medical',
      'Nursing',
      'Pharmacy',
      'Laboratory',
      'Radiology',
      'Administration',
      'Finance',
      'IT',
      'Human Resources',
      'Facilities',
      'Catering',
      'Security',
    ];
  }

  // Helper to get available roles
  static List<String> getAvailableRoles() {
    return [
      'Doctor',
      'Nurse',
      'Pharmacist',
      'Lab Technician',
      'Radiologist',
      'Administrator',
      'Accountant',
      'IT Support',
      'HR Manager',
      'Facility Manager',
      'Security Officer',
      'Cleaner',
      'Cook',
      'Receptionist',
    ];
  }
}
