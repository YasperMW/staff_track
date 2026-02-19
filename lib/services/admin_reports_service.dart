import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_storage.dart';

class AdminReportsOverview {
  final double avgAttendance;
  final double totalOvertimeHours;

  AdminReportsOverview({
    required this.avgAttendance,
    required this.totalOvertimeHours,
  });

  factory AdminReportsOverview.fromJson(Map<String, dynamic> json) {
    return AdminReportsOverview(
      avgAttendance: (json['avg_attendance'] as num?)?.toDouble() ?? 0,
      totalOvertimeHours: (json['total_overtime_hours'] as num?)?.toDouble() ?? 0,
    );
  }
}

class WeeklyAttendancePoint {
  final String label;
  final double percentage;

  WeeklyAttendancePoint({
    required this.label,
    required this.percentage,
  });

  factory WeeklyAttendancePoint.fromJson(Map<String, dynamic> json) {
    return WeeklyAttendancePoint(
      label: json['label'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TopPerformer {
  final String userId;
  final String name;
  final String role;
  final double attendancePercentage;

  TopPerformer({
    required this.userId,
    required this.name,
    required this.role,
    required this.attendancePercentage,
  });

  factory TopPerformer.fromJson(Map<String, dynamic> json) {
    return TopPerformer(
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AdminReportsService {
  static Future<AdminReportsOverview> getOverview() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/attendance/department-overview'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminReportsOverview.fromJson(data);
    } else {
      throw Exception(
        'Failed to load department overview: ${response.statusCode}',
      );
    }
  }

  static Future<List<WeeklyAttendancePoint>> getWeeklyAttendance() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/attendance/department-weekly'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['points'] as List<dynamic>? ?? [];
      return list
          .map((e) => WeeklyAttendancePoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load weekly department attendance: ${response.statusCode}',
      );
    }
  }

  static Future<List<TopPerformer>> getTopPerformers() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/attendance/department-top-performers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['performers'] as List<dynamic>? ?? [];
      return list
          .map((e) => TopPerformer.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load top performers: ${response.statusCode}',
      );
    }
  }
}
