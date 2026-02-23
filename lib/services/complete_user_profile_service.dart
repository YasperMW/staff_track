import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_storage.dart';

class CompleteUserProfile {
  final String userId;
  final String employeeNumber;
  final String? nationalId;
  final String firstName;
  final String surname;
  final String? otherNames;
  final String? suffix;
  final String? dateOfBirth;
  final String? gender;
  final String? homeOfOrigin;
  final String? traditionalAuthority;
  final String? district;
  final String? currentAddress;
  final String? contactNumber;
  final String email;
  final String? maritalStatus;
  final String? spouseName;
  final String? spouseContact;
  final String? dateOfEmployment;
  final String? designationId;
  final String? departmentId;
  final bool isHeadOfDepartment;
  final String? phone;
  final String roleId;
  final String status;
  final String? profilePhotoUrl;
  final String? blacklistedAt;
  final String? blacklistedReason;
  final String? registrationTimestamp;
  final bool selfieVerified;
  final String? lastLoginAt;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? deletedBy;
  final String roleName;
  final String? departmentName;
  final String? designationName;

  CompleteUserProfile({
    required this.userId,
    required this.employeeNumber,
    this.nationalId,
    required this.firstName,
    required this.surname,
    this.otherNames,
    this.suffix,
    this.dateOfBirth,
    this.gender,
    this.homeOfOrigin,
    this.traditionalAuthority,
    this.district,
    this.currentAddress,
    this.contactNumber,
    required this.email,
    this.maritalStatus,
    this.spouseName,
    this.spouseContact,
    this.dateOfEmployment,
    this.designationId,
    this.departmentId,
    required this.isHeadOfDepartment,
    this.phone,
    required this.roleId,
    required this.status,
    this.profilePhotoUrl,
    this.blacklistedAt,
    this.blacklistedReason,
    this.registrationTimestamp,
    required this.selfieVerified,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.deletedBy,
    required this.roleName,
    this.departmentName,
    this.designationName,
  });

  factory CompleteUserProfile.fromJson(Map<String, dynamic> json) {
    return CompleteUserProfile(
      userId: json['user_id'] as String,
      employeeNumber: json['employee_number'] as String,
      nationalId: json['national_id'] as String?,
      firstName: json['first_name'] as String,
      surname: json['surname'] as String,
      otherNames: json['other_names'] as String?,
      suffix: json['suffix'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      homeOfOrigin: json['home_of_origin'] as String?,
      traditionalAuthority: json['traditional_authority'] as String?,
      district: json['district'] as String?,
      currentAddress: json['current_address'] as String?,
      contactNumber: json['contact_number'] as String?,
      email: json['email'] as String,
      maritalStatus: json['marital_status'] as String?,
      spouseName: json['spouse_name'] as String?,
      spouseContact: json['spouse_contact'] as String?,
      dateOfEmployment: json['date_of_employment'] as String?,
      designationId: json['designation_id'] as String?,
      departmentId: json['department_id'] as String?,
      isHeadOfDepartment: json['is_head_of_department'] as bool? ?? false,
      phone: json['phone'] as String?,
      roleId: json['role_id'] as String,
      status: json['status'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      blacklistedAt: json['blacklisted_at'] as String?,
      blacklistedReason: json['blacklisted_reason'] as String?,
      registrationTimestamp: json['registration_timestamp'] as String?,
      selfieVerified: json['selfie_verified'] as bool? ?? false,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
      deletedBy: json['deleted_by'] as String?,
      roleName: json['role_name'] as String,
      departmentName: json['department_name'] as String?,
      designationName: json['designation_name'] as String?,
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
      'national_id': nationalId,
      'first_name': firstName,
      'surname': surname,
      'other_names': otherNames,
      'suffix': suffix,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'home_of_origin': homeOfOrigin,
      'traditional_authority': traditionalAuthority,
      'district': district,
      'current_address': currentAddress,
      'contact_number': contactNumber,
      'email': email,
      'marital_status': maritalStatus,
      'spouse_name': spouseName,
      'spouse_contact': spouseContact,
      'date_of_employment': dateOfEmployment,
      'designation_id': designationId,
      'department_id': departmentId,
      'is_head_of_department': isHeadOfDepartment,
      'phone': phone,
      'role_id': roleId,
      'status': status,
      'profile_photo_url': profilePhotoUrl,
      'blacklisted_at': blacklistedAt,
      'blacklisted_reason': blacklistedReason,
      'registration_timestamp': registrationTimestamp,
      'selfie_verified': selfieVerified,
      'last_login_at': lastLoginAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'deleted_by': deletedBy,
      'role_name': roleName,
      'department_name': departmentName,
      'designation_name': designationName,
    };
  }
}

class CompleteUserProfileService {
  static Future<CompleteUserProfile?> getCompleteUserProfile() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/profile/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CompleteUserProfile.fromJson(data);
      } else {
        print('Failed to load complete profile: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching complete user profile: $e');
      return null;
    }
  }
}
