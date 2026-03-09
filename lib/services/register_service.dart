import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'lookup_service.dart';

class RegisterResponse {
  final bool success;
  final String? message;
  
  RegisterResponse({required this.success, this.message});
}

String _detailFromBody(String body) {
  try {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final detail = data['detail'];
    if (detail == null) return 'Registration failed';
    
    if (detail is String) return detail;
    
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map) {
        // Handle FastAPI validation errors format
        if (first['loc'] is List && first['msg'] is String) {
          final fieldPath = (first['loc'] as List).join('.');
          return 'Validation error in $fieldPath: ${first['msg']}';
        }
        if (first['msg'] != null) return first['msg'] as String;
        if (first['field'] != null && first['message'] != null) {
          return '${first['field']}: ${first['message']}';
        }
      }
      return first.toString();
    }
    
    // Check for common error fields
    if (data['error'] != null) return data['error'].toString();
    if (data['message'] != null) return data['message'].toString();
    
    return 'Registration failed: ${body.substring(0, body.length > 100 ? 100 : body.length)}';
  } catch (e) {
    return 'Registration failed: Unable to parse error response';
  }
}

class RegisterService {
  Future<RegisterResponse> register({
    required String employeeNumber,
    required String nationalId,
    required String suffix,
    required String firstName,
    required String surName,
    required String otherNames,
    required String dateOfBirth,
    required String gender,
    required String email,
    required String phone,
    required String homeOfOrigin,
    required String traditionalAuthority,
    required String district,
    required String currentAddress,
    required String maritalStatus,
    required String spouseName,
    required String spouseContact,
    required String dateOfEmployment,
    required String designationId,
    required String role,
    required String department,
    required String departmentId,
    required bool isHeadOfDepartment,
    required String password,
    required String confirmPassword,
    String? gradeId,
    String? profilePhotoUrl,
  }) async {
    try {
      final requestBody = jsonEncode({
        'employee_number': employeeNumber,
        'national_id': nationalId,
        'suffix': suffix,
        'first_name': firstName,
        'surname': surName,
        'other_names': otherNames,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'email': email,
        'phone': phone,
        'home_of_origin': homeOfOrigin,
        'traditional_authority': traditionalAuthority,
        'district': district,
        'current_address': currentAddress,
        'marital_status': maritalStatus,
        'spouse_name': spouseName,
        'spouse_contact': spouseContact,
        'date_of_employment': dateOfEmployment,
        'designation_id': designationId,
        'role': role,
        'department': department,
        'department_id': departmentId,
        'is_head_of_department': isHeadOfDepartment,
        'password': password,
        'confirm_password': confirmPassword,
        'grade_id': gradeId,
        'profile_photo_url': profilePhotoUrl,
      });

      if (kDebugMode) {
        debugPrint('Registration request body: $requestBody');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );
      
      if (kDebugMode) {
        debugPrint('Registration response status: ${response.statusCode}');
        debugPrint('Registration response body: ${response.body}');
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return RegisterResponse(
          success: responseData['success'] ?? true,
          message: responseData['message'] ?? 'Registration successful',
        );
      } else {
        return RegisterResponse(
          success: false,
          message: _detailFromBody(response.body),
        );
      }
    } catch (e) {
      return RegisterResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  List<String> getRoles() {
    // Use API call directly - return empty list for now since it's async
    return [];
  }

  List<String> getDepartments() {
    // Use API call directly - return empty list for now since it's async
    return [];
  }

  // Future methods for API integration
  static Future<List<String>> getRolesFromAPI() async {
    try {
      final roles = await LookupService.getRoles();
      return roles.map((role) => role.name).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching roles from API: $e');
      }
      return [];
    }
  }

  static Future<List<String>> getDepartmentsFromAPI() async {
    try {
      final departments = await LookupService.getDepartments();
      return departments.map((dept) => dept.name).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching departments from API: $e');
      }
      return [];
    }
  }
}
