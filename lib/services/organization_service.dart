import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_storage.dart';
import '../models/models.dart';

class DepartmentTodaySummary {
  final String departmentId;
  final String departmentName;
  final int totalStaff;
  final int present;
  final int absent;
  final int late;

  DepartmentTodaySummary({
    required this.departmentId,
    required this.departmentName,
    required this.totalStaff,
    required this.present,
    required this.absent,
    required this.late,
  });

  String get name => departmentName;

  factory DepartmentTodaySummary.fromJson(Map<String, dynamic> json) {
    return DepartmentTodaySummary(
      departmentId: json['department_id'] as String? ?? '',
      departmentName: json['name'] as String? ?? 'Unknown',
      totalStaff: (json['total_staff'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
    );
  }
}

class DepartmentAttendanceMember {
  final String userId;
  final String name;
  final String employeeNumber;
  final String role;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;
  final double? workHours;
  final String? shiftType;
  final String? lateReason;
  final String? earlyCheckoutReason;

  DepartmentAttendanceMember({
    required this.userId,
    required this.name,
    required this.employeeNumber,
    required this.role,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.workHours,
    this.shiftType,
    this.lateReason,
    this.earlyCheckoutReason,
  });

  factory DepartmentAttendanceMember.fromJson(Map<String, dynamic> json) {
    return DepartmentAttendanceMember(
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      employeeNumber: json['employee_number'] as String? ?? '',
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? 'Absent',
      checkInTime: json['check_in_time'] as String?,
      checkOutTime: json['check_out_time'] as String?,
      workHours: (json['work_hours'] as num?)?.toDouble(),
      shiftType: json['shift_type'] as String?,
      lateReason: json['late_reason'] as String?,
      earlyCheckoutReason: json['early_checkout_reason'] as String?,
    );
  }
}

class UserAttendanceHistory {
  final String userName;
  final List<AttendanceRecord> history;

  UserAttendanceHistory({
    required this.userName,
    required this.history,
  });

  factory UserAttendanceHistory.fromJson(Map<String, dynamic> json) {
    final List<dynamic> historyList = json['history'] as List<dynamic>? ?? [];
    return UserAttendanceHistory(
      userName: json['user_name'] as String? ?? '',
      history: historyList.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OrganizationService {
  static Future<List<DepartmentTodaySummary>> getAllDepartmentsToday() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/attendance/all-departments-today'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> departments = data['departments'] as List<dynamic>;
      return departments.map((e) => DepartmentTodaySummary.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load departments: ${response.statusCode}');
    }
  }

  static Future<List<DepartmentAttendanceMember>> getDepartmentTodayAttendance(String departmentId) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/attendance/department/$departmentId/today'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> staff = data['staff'] as List<dynamic>;
      return staff.map((e) => DepartmentAttendanceMember.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load department attendance: ${response.statusCode}');
    }
  }

  static Future<UserAttendanceHistory> getUserAttendanceHistory({
    required String userId,
    String? startDate,
    String? endDate,
    int limit = 30,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final Map<String, String> queryParams = {
      'limit': limit.toString(),
    };
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/attendance/user/$userId/history')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserAttendanceHistory.fromJson(data);
    } else {
      throw Exception('Failed to load user history: ${response.statusCode}');
    }
  }

  static Future<List<AppUser>> getAllStaff() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/lookup/all-staff'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load staff: ${response.statusCode}');
    }
  }
}
