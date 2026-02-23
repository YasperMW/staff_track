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
    final apiUserId = json['user_id'] as String? ?? '';
    final apiUserName = json['user_name'] as String? ?? '';
    
    // Simple logic: use email to identify own requests
    // Extract name from email (yankhochisale4@gmail.com -> yankhochisale4)
    final emailName = currentUserId.contains('@') 
        ? currentUserId.split('@')[0].toLowerCase()
        : currentUserId.toLowerCase();
    
    // Check if user name contains the email name or matches exactly
    bool isOwnRequest = apiUserName.toLowerCase().contains(emailName) ||
                       apiUserName.toLowerCase() == emailName;
    
    return AdminTeamRequest(
      id: json['id'] as String? ?? '',
      userId: apiUserId,
      userName: apiUserName,
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      dateRange: json['date_range'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      isOwn: isOwnRequest,
    );
  }

  AdminTeamRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? type,
    String? status,
    String? dateRange,
    String? duration,
    bool? isOwn,
  }) {
    return AdminTeamRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      status: status ?? this.status,
      dateRange: dateRange ?? this.dateRange,
      duration: duration ?? this.duration,
      isOwn: isOwn ?? this.isOwn,
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
    print('Getting admin pending requests for user ID: $userId');
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

    print('Admin requests response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      print('Admin requests data length: ${data.length}');
      return data
          .map((e) => AdminTeamRequest.fromJson(e as Map<String, dynamic>, userId))
          .toList();
    } else {
      print('Admin requests response body: ${response.body}');
      throw Exception(
        'Failed to load admin pending requests: ${response.statusCode}',
      );
    }
  }

  static Future<List<AdminTeamRequest>> getMyAdminRequests() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/admin/my-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('My admin requests response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      print('My admin requests data length: ${data.length}');
      // For own requests, always set isOwn to true since they're all from current user
      return data
          .map((e) => AdminTeamRequest.fromJson(e as Map<String, dynamic>, ''))
          .map((req) => req.copyWith(isOwn: true))
          .toList();
    } else {
      print('My admin requests response body: ${response.body}');
      throw Exception(
        'Failed to load my admin requests: ${response.statusCode}',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getAllPendingRequestsDebug() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/admin/all-pending-debug'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Debug all pending requests response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      print('Debug all pending requests data length: ${data.length}');
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      print('Debug all pending requests response body: ${response.body}');
      throw Exception(
        'Failed to load debug pending requests: ${response.statusCode}',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getMyRequests() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/my-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception(
        'Failed to load my requests: ${response.statusCode}',
      );
    }
  }

  static Future<void> withdrawRequest(String requestId) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/admin/$requestId/withdraw'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to withdraw request: ${response.statusCode}',
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
