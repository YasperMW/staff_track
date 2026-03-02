import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import 'auth_storage.dart';

class HolidaysService {

  static Future<List<PublicHoliday>> getHolidays({int? year, String? category}) async {
    try {
      // Debug: Print request details
      print('=== GET HOLIDAYS DEBUG ===');
      print('Year filter: $year');
      print('Category filter: $category');
      
      final token = await AuthStorage.getToken();
      String url = '${AppConfig.apiBaseUrl}/api/holidays/';
      
      // Add query parameters
      List<String> queryParams = [];
      if (year != null) queryParams.add('year=$year');
      if (category != null) queryParams.add('category=$category');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      print('Request URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Debug: Print response details
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully parsed ${data.length} holidays');
        
        final holidays = data.map((json) {
          final holiday = PublicHoliday.fromJson(json);
          print('Parsed holiday: ${holiday.name} (${holiday.category})');
          return holiday;
        }).toList();
        
        print('Final holidays list length: ${holidays.length}');
        return holidays;
      } else {
        print('Failed to load holidays: ${response.statusCode}');
        throw Exception('Failed to load holidays: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getHolidays: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error loading holidays: $e');
    }
  }

  static Future<PublicHoliday> createHoliday({
    required String name,
    required DateTime date,
    String? description,
    String? type,
    String category = 'institutional',
    bool isRecurring = false,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      
      // Debug: Print request details
      print('=== CREATE HOLIDAY DEBUG ===');
      print('Token: ${token != null ? "Found" : "Not found"}');
      print('URL: ${AppConfig.apiBaseUrl}/api/holidays/');
      
      final requestBody = json.encode({
        'name': name,
        'date': date.toIso8601String().split('T')[0],
        'description': description,
        'type': type,
        'category': category,
        'isRecurring': isRecurring,
      });
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/holidays/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      // Debug: Print response details
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      print('Response body length: ${response.body.length}');
      
      // Try to parse the response body to see if it's valid JSON
      try {
        final parsedBody = json.decode(response.body);
        print('Parsed response body: $parsedBody');
      } catch (e) {
        print('Failed to parse response body as JSON: $e');
        print('Raw response body: "${response.body}"');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Status code is in success range, attempting to parse holiday...');
        try {
          final holiday = PublicHoliday.fromJson(json.decode(response.body));
          print('Successfully parsed holiday: ${holiday.name}');
          return holiday;
        } catch (e) {
          print('Failed to parse holiday from response: $e');
          print('Response body that failed to parse: ${response.body}');
          rethrow;
        }
      } else {
        print('Status code indicates error: ${response.statusCode}');
        throw Exception('Failed to create holiday: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createHoliday: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error creating holiday: $e');
    }
  }

  static Future<PublicHoliday> updateHoliday({
    required String id,
    String? name,
    DateTime? date,
    String? description,
    String? type,
    bool? isRecurring,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/api/holidays/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (name != null) 'name': name,
          if (date != null) 'date': date.toIso8601String().split('T')[0],
          if (description != null) 'description': description,
          if (type != null) 'type': type,
          if (isRecurring != null) 'isRecurring': isRecurring,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PublicHoliday.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update holiday');
      }
    } catch (e) {
      throw Exception('Failed to update holiday: $e');
    }
  }

  static Future<void> deleteHoliday(String id) async {
    try {
      final token = await AuthStorage.getToken();
      
      // Debug: Print request details
      print('=== DELETE HOLIDAY DEBUG ===');
      print('Token: ${token != null ? "Found" : "Not found"}');
      print('URL: ${AppConfig.apiBaseUrl}/api/holidays/$id');
      print('Holiday ID to delete: $id');
      
      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/api/holidays/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Debug: Print response details
      print('Delete response status code: ${response.statusCode}');
      print('Delete response headers: ${response.headers}');
      print('Delete response body: ${response.body}');
      print('Delete response body length: ${response.body.length}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('Delete failed with status: ${response.statusCode}');
        throw Exception('Failed to delete holiday: ${response.statusCode}');
      } else {
        print('Delete successful with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteHoliday: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Failed to delete holiday: $e');
    }
  }

  static Future<List<PublicHoliday>> getUpcomingHolidays({int monthsAhead = 3, String? category}) async {
    try {
      final token = await AuthStorage.getToken();
      String url = '${AppConfig.apiBaseUrl}/api/holidays/upcoming?months=$monthsAhead';
      
      if (category != null) {
        url += '&category=$category';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PublicHoliday.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load upcoming holidays: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading upcoming holidays: $e');
    }
  }

  static Future<void> sendHolidayNotifications(PublicHoliday holiday) async {
    try {
      final token = await AuthStorage.getToken();
      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/holidays/${holiday.id}/notify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': 'Upcoming holiday: ${holiday.name} on ${holiday.date}',
        }),
      );
    } catch (e) {
      // Mock notification for development
      print('Holiday notification sent: ${holiday.name} on ${holiday.date}');
    }
  }

  
  // Helper to check if a date is a holiday
  static Future<bool> isHoliday(DateTime date) async {
    final holidays = await getHolidays(year: date.year);
    return holidays.any((holiday) => holiday.matchesDate(date));
  }

  // Helper to get holiday for a specific date
  static Future<PublicHoliday?> getHolidayForDate(DateTime date) async {
    final holidays = await getHolidays(year: date.year);
    try {
      return holidays.firstWhere((holiday) => holiday.matchesDate(date));
    } catch (e) {
      return null;
    }
  }

  // New method to fetch public holidays from external API
  static Future<List<PublicHoliday>> fetchPublicHolidays(int year, {String countryCode = 'MW'}) async {
    try {
      final token = await AuthStorage.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/holidays/fetch-public'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'year': year,
          'country_code': countryCode,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PublicHoliday.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch public holidays: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching public holidays: $e');
    }
  }

  // Helper methods to get specific types of holidays
  static Future<List<PublicHoliday>> getInstitutionalHolidays({int? year}) async {
    return getHolidays(year: year, category: 'institutional');
  }

  static Future<List<PublicHoliday>> getPublicHolidays({int? year}) async {
    return getHolidays(year: year, category: 'public');
  }

  static Future<List<PublicHoliday>> getUpcomingInstitutionalHolidays({int monthsAhead = 3}) async {
    return getUpcomingHolidays(monthsAhead: monthsAhead, category: 'institutional');
  }

  static Future<List<PublicHoliday>> getUpcomingPublicHolidays({int monthsAhead = 3}) async {
    return getUpcomingHolidays(monthsAhead: monthsAhead, category: 'public');
  }
}
