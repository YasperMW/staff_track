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

  static Future<List<AttendanceRecord>> getTodayAttendance() async {
    try {
      debugPrint('🔍 [AttendanceController] Fetching today\'s attendance...');
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('📡 [AttendanceController] Making request to: ${AppConfig.apiBaseUrl}/attendance/today');
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/today'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📊 [AttendanceController] Response status: ${response.statusCode}');
      debugPrint('📄 [AttendanceController] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📋 [AttendanceController] Parsed data: $data');
        
        // Check if response is null
        if (data == null) {
          debugPrint('⚠️ [AttendanceController] Response data is null');
          return [];
        }
        
        // Check if it's a "no record" message
        if (data.containsKey('message')) {
          debugPrint('📝 [AttendanceController] No record message: ${data['message']}');
          return [];
        }
        
        // Handle old backend format: single attendance object with attendance_log_id
        if (data.containsKey('attendance_log_id')) {
          debugPrint('✅ [AttendanceController] Found single attendance record (old format)');
          return [AttendanceRecord.fromJson(data)];
        }
        
        // Handle very old backend format: single attendance object with attendance_id
        if (data.containsKey('attendance_id')) {
          debugPrint('✅ [AttendanceController] Found single attendance record (very old format)');
          return [AttendanceRecord.fromJson(data)];
        }
        
        // Handle new backend format: array of attendance records
        if (!data.containsKey('attendances')) {
          debugPrint('⚠️ [AttendanceController] Response missing "attendances" key and not a single record');
          return [];
        }
        
        final attendances = data['attendances'];
        if (attendances == null) {
          debugPrint('⚠️ [AttendanceController] "attendances" is null');
          return [];
        }
        
        if (attendances is! List) {
          debugPrint('⚠️ [AttendanceController] "attendances" is not a list: ${attendances.runtimeType}');
          return [];
        }
        
        debugPrint('✅ [AttendanceController] Found ${attendances.length} attendance records');
        return attendances.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        debugPrint('❌ [AttendanceController] HTTP error: ${response.statusCode}');
        throw Exception('Failed to get today\'s attendance: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 [AttendanceController] Exception: $e');
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
            'You are currently outside allowed work area. Please move closer and try again.',
      );
    }

    if (lower.contains('location data is required') ||
        lower.contains('location is required')) {
      return const ApiError(
        code: 'location_required',
        message:
            'Location is required. Please ensure location services are enabled and try again.',
      );
    }

    if (lower.contains('already checked in')) {
      return ApiError(
        code: 'already_checked_in',
        message: detail.isNotEmpty ? detail : 'You are already checked in.',
      );
    }

    if (lower.contains('unresolved night shift')) {
      return ApiError(
        code: 'unresolved_night_shift',
        message: detail.isNotEmpty ? detail : 'You have an unresolved night shift. Please check out first.',
      );
    }

    if (lower.contains('late check-in detected')) {
      return const ApiError(
        code: 'late_check_in',
        message: 'Late check-in detected. Please provide a reason for arriving late.',
      );
    }

    if (lower.contains('early check-in detected')) {
      return const ApiError(
        code: 'early_check_in',
        message: 'Early check-in detected. Please provide a reason for arriving early.',
      );
    }

    if (lower.contains('early check-out detected')) {
      return const ApiError(
        code: 'early_check_out',
        message: 'Early check-out detected. Please provide a reason for leaving early.',
      );
    }

    if (lower.contains('no active check-in')) {
      return const ApiError(
        code: 'no_active_check_in',
        message: 'No active check-in found. Please check in first.',
      );
    }

    if (lower.contains('already checked out')) {
      return const ApiError(
        code: 'already_checked_out',
        message: 'You have already checked out from this shift.',
      );
    }

    if (lower.contains('invalid shift')) {
      return const ApiError(
        code: 'invalid_shift',
        message: 'Invalid shift type specified.',
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return const ApiError(
        code: 'unauthorized',
        message: 'Your session has expired. Please log in again.',
      );
    }

    if (statusCode == 400) {
      return ApiError(
        code: 'bad_request',
        message: detail.isNotEmpty ? detail : 'Invalid request. Please check your input and try again.',
      );
    }

    if (statusCode == 500) {
      return const ApiError(
        code: 'server_error',
        message: 'Server error occurred. Please try again later.',
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
