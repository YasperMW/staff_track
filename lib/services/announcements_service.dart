import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        'department': ?department,
        'role': ?role,
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
        if (kDebugMode) {
          print('Announcements data received: ${data.length} items');
        } // Debug print
        return data.map((json) {
          if (kDebugMode) {
            print('Processing announcement: ${json['id']} - ${json['title']}');
          } // Debug print
          return Announcement.fromJson(json);
        }).toList();
      } else {

        throw Exception('Failed to load announcements: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading announcements: $e');
      } // Debug print
      throw Exception('Error loading announcements: $e');
    }
  }

  static Future<Announcement> createAnnouncement({
    required String title,
    required String message,
    required String type,
    List<String>? targetDepartments,  // Changed to support multiple departments
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
          'target_departments': targetDepartments,  // Send as array
          'target_role': targetRole,
          'is_active': isActive,
          'expires_at': expiresAt?.toIso8601String(),
          'attachment_url': attachmentUrl,
          'send_notifications': true,
        }),
      );

      if (response.statusCode == 201) {
        return Announcement.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create announcement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating announcement: $e');
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
          'title': ?title,
          'message': ?message,
          'type': ?type,
          'target_department': ?targetDepartment,
          'target_role': ?targetRole,
          'is_active': ?isActive,
          if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
          'attachment_url': ?attachmentUrl,
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
      'System Admin',
      'HR Admin',
      'Head of Department',
      'HR',
      'Accountant',
      'Principal Hospital Administrator',
      'System Administrator',
      'Staff',
    ];
  }
}
