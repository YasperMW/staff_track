import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  final int approvalLevel;
  final bool leaveGrantRequired;
  final String? contactAddress;
  final bool userHasActed;
  // Trip fields
  final String? reasonForLeaving;
  final String? travelDate;
  final String? travelPlace;
  final double? costAccommodation;
  final double? costBreakfast;
  final double? costLunch;
  final double? costSupper;
  final double? costPublicTransport;
  final double? costFuelLubricants;
  final double? costTotal;

  AdminTeamRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.status,
    required this.dateRange,
    required this.duration,
    required this.isOwn,
    this.approvalLevel = 1,
    this.leaveGrantRequired = false,
    this.contactAddress,
    this.userHasActed = false,
    this.reasonForLeaving,
    this.travelDate,
    this.travelPlace,
    this.costAccommodation,
    this.costBreakfast,
    this.costLunch,
    this.costSupper,
    this.costPublicTransport,
    this.costFuelLubricants,
    this.costTotal,
  });

  factory AdminTeamRequest.fromJson(Map<String, dynamic> json, String currentUserId) {
    final apiUserId = json['user_id'] as String? ?? '';
    final apiUserName = json['user_name'] as String? ?? '';
    
    // Simple logic: use email to identify own requests
    // Extract name from email (user@example.com -> yankhochisale4)
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
      approvalLevel: (json['approval_level'] as num?)?.toInt() ?? 1,
      leaveGrantRequired: json['leave_grant_required'] == true,
      contactAddress: json['contact_address'] as String?,
      userHasActed: json['user_has_acted'] == true,
      reasonForLeaving: json['reason_for_leaving'] as String?,
      travelDate: json['travel_date'] as String?,
      travelPlace: json['travel_place'] as String?,
      costAccommodation: (json['cost_accommodation'] as num?)?.toDouble(),
      costBreakfast: (json['cost_breakfast'] as num?)?.toDouble(),
      costLunch: (json['cost_lunch'] as num?)?.toDouble(),
      costSupper: (json['cost_supper'] as num?)?.toDouble(),
      costPublicTransport: (json['cost_public_transport'] as num?)?.toDouble(),
      costFuelLubricants: (json['cost_fuel_lubricants'] as num?)?.toDouble(),
      costTotal: (json['cost_total'] as num?)?.toDouble(),
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

class LeaveBalance {
  final String leaveType;
  final int allocatedDays;
  final int usedDays;
  final int bonusDays;
  final int remainingDays;
  final String updatedAt;

  LeaveBalance({
    required this.leaveType,
    required this.allocatedDays,
    required this.usedDays,
    required this.bonusDays,
    required this.remainingDays,
    required this.updatedAt,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveType: json['leave_type'] as String? ?? '',
      allocatedDays: (json['allocated_days'] as num?)?.toInt() ?? 0,
      usedDays: (json['used_days'] as num?)?.toInt() ?? 0,
      bonusDays: (json['bonus_days'] as num?)?.toInt() ?? 0,
      remainingDays: (json['remaining_days'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class RequestsService {
  static Future<List<LeaveBalance>> getLeaveBalances() async {
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

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception(
        'Failed to load leave balances: ${response.statusCode}',
      );
    }
  }

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
    bool leaveGrantRequired = false,
    String? contactAddress,
    // Trip fields
    String? reasonForLeaving,
    String? travelDate,
    String? travelPlace,
    double? costAccommodation,
    double? costBreakfast,
    double? costLunch,
    double? costSupper,
    double? costPublicTransport,
    double? costFuelLubricants,
    double? costTotal,
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
        'leave_grant_required': leaveGrantRequired,
        'contact_address': contactAddress,
        'reason_for_leaving': reasonForLeaving,
        'travel_date': travelDate,
        'travel_place': travelPlace,
        'cost_accommodation': costAccommodation,
        'cost_breakfast': costBreakfast,
        'cost_lunch': costLunch,
        'cost_supper': costSupper,
        'cost_public_transport': costPublicTransport,
        'cost_fuel_lubricants': costFuelLubricants,
        'cost_total': costTotal,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to create request: ${response.statusCode}',
      );
    }
  }

  static Future<List<AdminTeamRequest>> getAdminPendingRequests({
    String? status,
    String? type,
    String? departmentId,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final token = await AuthStorage.getToken();
    final userId = await AuthStorage.getUserId();
    if (kDebugMode) {
      print('Getting admin pending requests for user ID: $userId');
    }
    if (token == null || userId == null) {
      throw Exception('No authentication context found');
    }

    final qs = <String, String>{};
    if (status != null) qs['status_filter'] = status;
    if (type != null) qs['type_filter'] = type;
    if (departmentId != null) qs['department_id'] = departmentId;
    qs['page'] = page.toString();
    qs['page_size'] = pageSize.toString();
    qs['sort_by'] = sortBy;
    qs['sort_order'] = sortOrder;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/requests/admin/pending-list').replace(queryParameters: qs.isEmpty ? null : qs);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (kDebugMode) {
      print('Admin requests response status: ${response.statusCode}');
    print('Admin requests response headers: ${response.headers}');
    print('Admin requests response body preview: ${response.body.substring(0, min(200, response.body.length))}');

    }
    if (response.statusCode == 200) {
      // Check if response is actually JSON
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Server returned HTML instead of JSON. Response body: ${response.body.substring(0, 200)}...');
      }
      
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (kDebugMode) {
        print('Admin requests data length: ${data.length}');
      }
      return data
          .map((e) => AdminTeamRequest.fromJson(e as Map<String, dynamic>, userId))
          .toList();
    } else {
      if (kDebugMode) {
        print('Admin requests response body: ${response.body}');
      }
      throw Exception(
        'Failed to load admin pending requests: ${response.statusCode} - ${response.body}',
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

    if (kDebugMode) {
      print('My admin requests response status: ${response.statusCode}');

    print('My admin requests response headers: ${response.headers}');
    print('My admin requests response body preview: ${response.body.substring(0, min(200, response.body.length))}');
    }

    if (response.statusCode == 200) {
      // Check if response is actually JSON
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Server returned HTML instead of JSON. Response body: ${response.body.substring(0, 200)}...');
      }
      
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (kDebugMode) {
        print('My admin requests data length: ${data.length}');
      }
      // For own requests, always set isOwn to true since they're all from current user
      return data
          .map((e) => AdminTeamRequest.fromJson(e as Map<String, dynamic>, ''))
          .map((req) => req.copyWith(isOwn: true))
          .toList();
    } else {
      if (kDebugMode) {
        print('My admin requests response body: ${response.body}');
      }
      throw Exception(
        'Failed to load my admin requests: ${response.statusCode} - ${response.body}',
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


    if (response.statusCode == 200) {
      // Check if response is actually JSON
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Server returned HTML instead of JSON. Response body: ${response.body.substring(0, 200)}...');
      }
      
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (kDebugMode) {
        print('Debug all pending requests data length: ${data.length}');
      }
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      if (kDebugMode) {
        print('Debug all pending requests response body: ${response.body}');
      }
      throw Exception(
        'Failed to load debug pending requests: ${response.statusCode} - ${response.body}',
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

  static Future<List<Map<String, dynamic>>> getRequestApprovals(String requestId) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/$requestId/approvals'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load approval history: ${response.statusCode}');
    }
  }

  static Future<void> withdrawRequest(String requestId) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/$requestId/withdraw'),
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

  static Future<void> approveRequest(String requestId, {Map<String, dynamic>? extraFields}) async {
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
      body: jsonEncode(extraFields ?? {}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to approve request: ${response.statusCode} - ${response.body}',
      );
    }
  }

  static Future<void> approveRequestWithComment(String requestId, String comment) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/admin/$requestId/approve?comment=${Uri.encodeComponent(comment)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve request: ${response.statusCode}');
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

  static Future<void> denyRequestWithComment(String requestId, String comment) async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/requests/admin/$requestId/deny?comment=${Uri.encodeComponent(comment)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to deny request: ${response.statusCode}');
    }
  }
}
