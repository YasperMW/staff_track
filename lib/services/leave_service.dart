import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_storage.dart';

class LeaveBalanceItem {
  final String leaveType;
  final int allocatedDays;
  final int usedDays;
  final int bonusDays;
  final int remainingDays;
  final String updatedAt;

  LeaveBalanceItem({
    required this.leaveType,
    required this.allocatedDays,
    required this.usedDays,
    required this.bonusDays,
    required this.remainingDays,
    required this.updatedAt,
  });

  factory LeaveBalanceItem.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceItem(
      leaveType: json['leave_type'] as String,
      allocatedDays: (json['allocated_days'] as num?)?.toInt() ?? 0,
      usedDays: (json['used_days'] as num?)?.toInt() ?? 0,
      bonusDays: (json['bonus_days'] as num?)?.toInt() ?? 0,
      remainingDays: (json['remaining_days'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class LeaveService {
  static Future<List<LeaveBalanceItem>> getBalances() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/leave/balances'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => LeaveBalanceItem.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load leave balances: ${response.statusCode}');
    }
  }
}
