import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/auth_storage.dart';
import '../services/api_result.dart';

class AttendanceController {
  static Future<String?> _getAuthToken() async {
    return await AuthStorage.getToken();
  }

  static Future<ApiResult<Map<String, dynamic>>> checkIn({
    String? location,
    double? latitude,
    double? longitude,
    String? shiftType,
    String? lateReason,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return ApiResult.failure(
        const ApiError(
          code: 'unauthenticated',
          message: 'User not authenticated',
        ),
      );
    }

    final Map<String, dynamic> requestBody = {};
    if (location != null) requestBody['location'] = location;
    if (latitude != null) requestBody['latitude'] = latitude;
    if (longitude != null) requestBody['longitude'] = longitude;
    if (shiftType != null) requestBody['shift_type'] = shiftType;
    if (lateReason != null) requestBody['late_reason'] = lateReason;

    // Debug logging
    if (kDebugMode) {
      debugPrint('DEBUG: AttendanceController.checkIn called with:');
      debugPrint('  location: $location');
      debugPrint('  latitude: $latitude');
      debugPrint('  longitude: $longitude');
      debugPrint('  shiftType: $shiftType');
      debugPrint('  requestBody: $requestBody');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return ApiResult.success(jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = body['detail']?.toString() ?? 'Check-in failed';
        return ApiResult.failure(
          _mapAttendanceError(
            detail: detail,
            statusCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      return ApiResult.failure(
        const ApiError(
          code: 'network_error',
          message:
              'Failed to check in. Please check your connection and try again.',
        ),
      );
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> checkOut({
    String? location,
    double? latitude,
    double? longitude,
    String? earlyCheckoutReason,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return ApiResult.failure(
        const ApiError(
          code: 'unauthenticated',
          message: 'User not authenticated',
        ),
      );
    }

    final Map<String, dynamic> requestBody = {};
    if (location != null) requestBody['location'] = location;
    if (latitude != null) requestBody['latitude'] = latitude;
    if (longitude != null) requestBody['longitude'] = longitude;
    if (earlyCheckoutReason != null) requestBody['early_checkout_reason'] = earlyCheckoutReason;

    // Debug logging
    if (kDebugMode) {
      debugPrint('DEBUG: AttendanceController.checkOut called with:');
      debugPrint('  location: $location');
      debugPrint('  latitude: $latitude');
      debugPrint('  longitude: $longitude');
      debugPrint('  requestBody: $requestBody');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/check-out'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return ApiResult.success(jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = body['detail']?.toString() ?? 'Check-out failed';
        return ApiResult.failure(
          _mapAttendanceError(
            detail: detail,
            statusCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      return ApiResult.failure(
        const ApiError(
          code: 'network_error',
          message:
              'Failed to check out. Please check your connection and try again.',
        ),
      );
    }
  }

  static Future<AttendanceRecord?> getTodayAttendance() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/today'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if it's a "no record" message
        if (data.containsKey('message')) {
          return null;
        }
        
        return AttendanceRecord.fromJson(data);
      } else {
        throw Exception('Failed to get today\'s attendance');
      }
    } catch (e) {
      throw Exception('Failed to get today\'s attendance: $e');
    }
  }

  static Future<List<AttendanceRecord>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    int limit = 30,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, String> queryParams = {
        'limit': limit.toString(),
      };
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/attendance/history')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get attendance history');
      }
    } catch (e) {
      throw Exception('Failed to get attendance history: $e');
    }
  }

  static Future<Map<String, dynamic>> getAttendanceSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, String> queryParams = {};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/attendance/summary')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get attendance summary');
      }
    } catch (e) {
      throw Exception('Failed to get attendance summary: $e');
    }
  }

  static Future<Map<String, dynamic>> getTeamTodaySummary() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/team-today-summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get team attendance summary');
      }
    } catch (e) {
      throw Exception('Failed to get team attendance summary: $e');
    }
  }

  static Future<List<TeamAttendanceMember>> getTeamTodayList() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/team-today-list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => TeamAttendanceMember.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get team attendance list');
      }
    } catch (e) {
      throw Exception('Failed to get team attendance list: $e');
    }
  }

  static Future<Map<String, dynamic>> getMyProfileMetrics() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/my-profile-metrics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get profile metrics');
      }
    } catch (e) {
      throw Exception('Failed to get profile metrics: $e');
    }
  }

  static ApiError _mapAttendanceError({
    required String detail,
    required int statusCode,
  }) {
    final lower = detail.toLowerCase();

    if (lower.contains('outside allowed work area')) {
      return const ApiError(
        code: 'outside_work_area',
        message:
            'You are currently outside the allowed work area. Please move closer and try again.',
      );
    }

    if (lower.contains('location data is required') ||
        lower.contains('location')) {
      return const ApiError(
        code: 'location_required',
        message:
            'Location is required. Please ensure location services are enabled and try again.',
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return const ApiError(
        code: 'unauthorized',
        message: 'Your session has expired. Please log in again.',
      );
    }

    return ApiError(
      code: 'unknown',
      message: detail.isNotEmpty
          ? detail
          : 'Attendance request failed. Please try again.',
    );
  }
}
