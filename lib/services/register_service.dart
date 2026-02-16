import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/mock_data.dart';

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
      if (first is Map && first['msg'] != null) return first['msg'] as String;
      return first.toString();
    }
    return 'Registration failed';
  } catch (_) {
    return 'Registration failed';
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
    required String yearsInService,
    required String designation,
    required String role,
    required String department,
    required bool isHeadOfDepartment,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
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
          'years_in_service': yearsInService,
          'designation': designation,
          'role': role,
          'department': department,
          'is_head_of_department': isHeadOfDepartment,
          'password': password,
        }),
      );
      
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
    return MockData.roles;
  }

  List<String> getDepartments() {
    return MockData.departments;
  }
}
