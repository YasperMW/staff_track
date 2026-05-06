
import 'package:flutter/material.dart';
import '../../services/holidays_service.dart';
import '../../services/reminder_integration_service.dart';
import '../../models/models.dart';

/// Example of how to schedule holiday reminders
/// You can use this in admin screens or testing
class HolidayReminderExample {
  
  /// Schedule reminders for a specific holiday
  static Future<void> scheduleSingleHolidayReminder(PublicHoliday holiday) async {
    try {
      debugPrint('Scheduling reminders for holiday: ${holiday.name}');
      
      // This will create multiple reminders:
      // - 7 days before holiday
      // - 3 days before holiday  
      // - 1 day before holiday
      await ReminderIntegrationService.scheduleHolidayReminders(
        holidays: [holiday],
      );
      
      debugPrint('Holiday reminders scheduled successfully!');
    } catch (e) {
      debugPrint('Error scheduling holiday reminders: $e');
    }
  }
  
  /// Schedule reminders for all upcoming holidays
  static Future<void> scheduleAllUpcomingHolidays() async {
    try {
      debugPrint('Loading upcoming holidays...');
      
      // Get holidays for next 6 months
      final upcomingHolidays = await HolidaysService.getUpcomingHolidays(monthsAhead: 6);
      
      debugPrint('Found ${upcomingHolidays.length} upcoming holidays');
      
      // Schedule reminders for all of them
      await ReminderIntegrationService.scheduleHolidayReminders(
        holidays: upcomingHolidays,
      );
      
      debugPrint('Scheduled reminders for all upcoming holidays!');
      
      // Print what was scheduled
      for (final holiday in upcomingHolidays) {
        debugPrint('  - ${holiday.name} on ${holiday.date}');
      }
      
    } catch (e) {
      debugPrint('Error scheduling upcoming holidays: $e');
    }
  }
  
  /// Example: Schedule reminders for Christmas
  static Future<void> scheduleChristmasReminder() async {
    final christmas = PublicHoliday(
      id: 'christmas-example',
      name: 'Christmas Day',
      date: DateTime(DateTime.now().year, 12, 25),
      type: 'public',
      category: 'public',
      isRecurring: true,
    );
    
    await scheduleSingleHolidayReminder(christmas);
  }
  
  /// Example: Schedule reminders for New Year
  static Future<void> scheduleNewYearReminder() async {
    final newYear = PublicHoliday(
      id: 'newyear-example',
      name: 'New Year\'s Day',
      date: DateTime(DateTime.now().year + 1, 1, 1), // Next year
      type: 'public',
      category: 'public',
      isRecurring: true,
    );
    
    await scheduleSingleHolidayReminder(newYear);
  }
}

/// Widget to test holiday reminders (for development)
class HolidayReminderTestWidget extends StatelessWidget {
  const HolidayReminderTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Holiday Reminder Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => HolidayReminderExample.scheduleChristmasReminder(),
              child: const Text('Schedule Christmas Reminder'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => HolidayReminderExample.scheduleNewYearReminder(),
              child: const Text('Schedule New Year Reminder'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => HolidayReminderExample.scheduleAllUpcomingHolidays(),
              child: const Text('Schedule All Upcoming Holidays'),
            ),
          ],
        ),
      ),
    );
  }
}
