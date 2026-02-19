import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/auth_storage.dart';

class AttendanceController {
  static Future<String?> _getAuthToken() async {
    return await AuthStorage.getToken();
  }

  static Future<Map<String, dynamic>> checkIn({
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, dynamic> requestBody = {};
      if (location != null) requestBody['location'] = location;
      if (latitude != null) requestBody['latitude'] = latitude;
      if (longitude != null) requestBody['longitude'] = longitude;

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Check-in failed');
      }
    } catch (e) {
      throw Exception('Failed to check in: $e');
    }
  }

  static Future<Map<String, dynamic>> checkOut({
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, dynamic> requestBody = {};
      if (location != null) requestBody['location'] = location;
      if (latitude != null) requestBody['latitude'] = latitude;
      if (longitude != null) requestBody['longitude'] = longitude;

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/attendance/check-out'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Check-out failed');
      }
    } catch (e) {
      throw Exception('Failed to check out: $e');
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
}
