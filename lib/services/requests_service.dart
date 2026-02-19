import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_storage.dart';

class RequestsSummaryItem {
  final String type;
  final int count;

  RequestsSummaryItem({
    required this.type,
    required this.count,
  });

  factory RequestsSummaryItem.fromJson(Map<String, dynamic> json) {
    return RequestsSummaryItem(
      type: json['type'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class RequestsSummaryResponse {
  final int totalPending;
  final List<RequestsSummaryItem> byType;

  RequestsSummaryResponse({
    required this.totalPending,
    required this.byType,
  });

  factory RequestsSummaryResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['by_type'] as List<dynamic>? ?? [])
        .map((e) => RequestsSummaryItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return RequestsSummaryResponse(
      totalPending: (json['total_pending'] as num?)?.toInt() ?? 0,
      byType: items,
    );
  }
}

class AdminTeamRequest {
  final String id;
  final String userId;
  final String userName;
  final String type;
  final String status;
  final String dateRange;
  final String duration;
  final bool isOwn;

  AdminTeamRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.status,
    required this.dateRange,
    required this.duration,
    required this.isOwn,
  });

  factory AdminTeamRequest.fromJson(Map<String, dynamic> json, String currentUserId) {
    final userId = json['user_id'] as String? ?? '';
    return AdminTeamRequest(
      id: json['id'] as String? ?? '',
      userId: userId,
      userName: json['user_name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      dateRange: json['date_range'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      isOwn: userId == currentUserId,
    );
  }
}

class RequestsService {
  static Future<RequestsSummaryResponse> getRequestsSummary() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/summary'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RequestsSummaryResponse.fromJson(data);
    } else {
      throw Exception(
        'Failed to load requests summary: ${response.statusCode}',
      );
    }
  }

  static Future<void> createRequest({
    required String type,
    required String startDate,
    required String endDate,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
        'start_date': startDate,
        'end_date': endDate,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to create request: ${response.statusCode}',
      );
    }
  }

  static Future<List<AdminTeamRequest>> getAdminPendingRequests() async {
    final token = await AuthStorage.getToken();
    final userId = await AuthStorage.getUserId();
    if (token == null || userId == null) {
      throw Exception('No authentication context found');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/admin/pending-list'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => AdminTeamRequest.fromJson(e as Map<String, dynamic>, userId))
          .toList();
    } else {
      throw Exception(
        'Failed to load admin pending requests: ${response.statusCode}',
      );
    }
  }

  static Future<void> approveRequest(String requestId) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/admin/$requestId/approve'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to approve request: ${response.statusCode}',
      );
    }
  }

  static Future<void> denyRequest(String requestId) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/admin/$requestId/deny'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to deny request: ${response.statusCode}',
      );
    }
  }
}
