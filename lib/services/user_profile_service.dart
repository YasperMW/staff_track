import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class UserProfile {
  final String userId;
  final String employeeNumber;
  final String firstName;
  final String surname;
  final String? otherNames;
  final String email;
  final String? phone;
  final String roleName;
  final String? departmentName;
  final String? designation;
  final String status;
  final String? profilePhotoUrl;
  final String? lastLoginAt;
  final String createdAt;

  UserProfile({
    required this.userId,
    required this.employeeNumber,
    required this.firstName,
    required this.surname,
    this.otherNames,
    required this.email,
    this.phone,
    required this.roleName,
    this.departmentName,
    this.designation,
    required this.status,
    this.profilePhotoUrl,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      employeeNumber: json['employee_number'] as String,
      firstName: json['first_name'] as String,
      surname: json['surname'] as String,
      otherNames: json['other_names'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      roleName: json['role_name'] as String,
      departmentName: json['department_name'] as String?,
      designation: json['designation'] as String?,
      status: json['status'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  String get fullName {
    final parts = [firstName, surname];
    if (otherNames != null && otherNames!.isNotEmpty) {
      parts.insert(1, otherNames!);
    }
    return parts.where((s) => s.isNotEmpty).join(' ');
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'employee_number': employeeNumber,
      'first_name': firstName,
      'surname': surname,
      'other_names': otherNames,
      'email': email,
      'phone': phone,
      'role_name': roleName,
      'department_name': departmentName,
      'designation': designation,
      'status': status,
      'profile_photo_url': profilePhotoUrl,
      'last_login_at': lastLoginAt,
      'created_at': createdAt,
    };
  }
}

class UserProfileService {
  static Future<UserMetrics?> getUserMetrics(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/my-profile-metrics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('User metrics response: ${response.body}');
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserMetrics.fromJson(data);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<UserProfile?> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserProfile.fromJson(data);
      } else {
        if (kDebugMode) {
        print('Failed to load profile: ${response.statusCode}');

          print('Response body: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user profile: $e');
      }
      return null;
    }
  }

  static Future<bool> updateProfilePhoto(String token, String photoUrl) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/profile/update-photo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'profile_photo_url': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        if (kDebugMode) {
          print('Failed to update profile photo: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile photo: $e');
      }
      return false;
    }
  }

  static Future<bool> updateProfile(String token, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        if (kDebugMode) {
          print('Failed to update profile: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      return false;
    }
  }
}

class UserMetrics {
  final int workingDays;
  final double onTimeRate;
  final int leaveUsed;
  final int year;

  UserMetrics({
    required this.workingDays,
    required this.onTimeRate,
    required this.leaveUsed,
    required this.year,
  });

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  factory UserMetrics.fromJson(Map<String, dynamic> json) {
    return UserMetrics(
      workingDays: (json['working_days'] as num?)?.toInt() ?? 0,
      onTimeRate: _parseDouble(json['on_time_rate']),
      leaveUsed: (json['leave_used'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
    );
  }
}
