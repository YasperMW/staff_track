import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_storage.dart';

class LeavePolicyItem {
  final String? roleName;
  final String? departmentName;
  final String leaveType;
  final int allocatedDays;
  final int bonusDays;

  LeavePolicyItem({
    required this.roleName,
    required this.departmentName,
    required this.leaveType,
    required this.allocatedDays,
    required this.bonusDays,
  });

  factory LeavePolicyItem.fromJson(Map<String, dynamic> json) {
    return LeavePolicyItem(
      roleName: json['role_name'] as String?,
      departmentName: json['department_name'] as String?,
      leaveType: json['leave_type'] as String,
      allocatedDays: (json['allocated_days'] as num?)?.toInt() ?? 0,
      bonusDays: (json['bonus_days'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeavePolicyService {
  static Future<List<LeavePolicyItem>> listPolicies() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/leave/policies'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => LeavePolicyItem.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to list policies: ${response.statusCode}');
    }
  }

  static Future<void> applyPolicy({
    required String leaveType,
    required int allocatedDays,
    int bonusDays = 0,
    String? roleName,
    String? departmentName,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/leave/policies/apply'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'leave_type': leaveType,
        'allocated_days': allocatedDays,
        'bonus_days': bonusDays,
        'role_name': roleName,
        'department_name': departmentName,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to apply policy: ${response.statusCode}');
    }
  }
}
