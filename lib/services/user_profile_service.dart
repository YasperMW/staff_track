import 'dart:convert';
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
}

class UserProfileService {
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
        print('Failed to load profile: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
}
