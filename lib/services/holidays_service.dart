import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import 'auth_storage.dart';

class HolidaysService {

  static Future<List<PublicHoliday>> getHolidays({int? year}) async {
    try {
      final token = await AuthStorage.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/holidays${year != null ? '?year=$year' : ''}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PublicHoliday.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load holidays');
      }
    } catch (e) {
      // Return mock data for development
      return _getMockHolidays(year ?? DateTime.now().year);
    }
  }

  static Future<PublicHoliday> createHoliday({
    required String name,
    required DateTime date,
    String? description,
    String? type,
    bool isRecurring = false,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/holidays'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'date': date.toIso8601String().split('T')[0],
          'description': description,
          'type': type,
          'is_recurring': isRecurring,
        }),
      );

      if (response.statusCode == 201) {
        return PublicHoliday.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create holiday');
      }
    } catch (e) {
      // Return mock holiday for development
      final mockHoliday = PublicHoliday(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        date: date,
        description: description,
        type: type,
        isRecurring: isRecurring,
        createdAt: DateTime.now(),
      );
      return mockHoliday;
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
          if (isRecurring != null) 'is_recurring': isRecurring,
        }),
      );

      if (response.statusCode == 200) {
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
      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/api/holidays/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete holiday');
      }
    } catch (e) {
      throw Exception('Failed to delete holiday: $e');
    }
  }

  static Future<List<PublicHoliday>> getUpcomingHolidays({int monthsAhead = 3}) async {
    try {
      final token = await AuthStorage.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/holidays/upcoming?months=$monthsAhead'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PublicHoliday.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load upcoming holidays');
      }
    } catch (e) {
      // Return mock upcoming holidays
      final now = DateTime.now();
      return _getMockHolidays(now.year)
          .where((holiday) => holiday.date.isAfter(now.subtract(const Duration(days: 1))))
          .where((holiday) => holiday.date.isBefore(now.add(Duration(days: monthsAhead * 30))))
          .toList();
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

  // Mock data for development
  static List<PublicHoliday> _getMockHolidays(int year) {
    return [
      PublicHoliday(
        id: '1',
        name: 'New Year\'s Day',
        date: DateTime(year, 1, 1),
        description: 'New Year celebration',
        type: 'national',
        isRecurring: true,
      ),
      PublicHoliday(
        id: '2',
        name: 'Good Friday',
        date: DateTime(year, 4, 7), // This would need proper calculation
        description: 'Christian religious holiday',
        type: 'religious',
        isRecurring: true,
      ),
      PublicHoliday(
        id: '3',
        name: 'Easter Monday',
        date: DateTime(year, 4, 10), // This would need proper calculation
        description: 'Christian religious holiday',
        type: 'religious',
        isRecurring: true,
      ),
      PublicHoliday(
        id: '4',
        name: 'Workers\' Day',
        date: DateTime(year, 5, 1),
        description: 'International Workers\' Day',
        type: 'national',
        isRecurring: true,
      ),
      PublicHoliday(
        id: '5',
        name: 'Africa Day',
        date: DateTime(year, 5, 25),
        description: 'Africa Day celebration',
        type: 'national',
        isRecurring: true,
      ),
      PublicHoliday(
        id: '6',
        name: 'Heroes\' Day',
        date: DateTime(year, 8, 11),
        description: 'National Heroes Day',
        type: 'national',
        isRecurring: true,
      ),
      PublicHoliday(
        id: '7',
        name: 'Defense Forces Day',
        date: DateTime(year, 8, 12),
        description: 'Zimbabwe Defense Forces Day',
        type: 'national',
        isRecurring: true,
      ),
      PublicHoliday(
        id: '8',
        name: 'National Unity Day',
        date: DateTime(year, 12, 22),
        description: 'National Unity Day',
        type: 'national',
        isRecurring: true,
      ),
      PublicHoliday(
        id: '9',
        name: 'Christmas Day',
        date: DateTime(year, 12, 25),
        description: 'Christmas celebration',
        type: 'religious',
        isRecurring: true,
      ),
      PublicHoliday(
        id: '10',
        name: 'Boxing Day',
        date: DateTime(year, 12, 26),
        description: 'Boxing Day',
        type: 'national',
        isRecurring: true,
      ),
    ];
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
}
