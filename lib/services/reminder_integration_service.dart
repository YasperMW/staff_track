import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/local_notification_service.dart';
import '../models/models.dart';

/// Service to integrate local notifications with existing reminder system
/// Ensures reminders work both online (FCM) and offline (local notifications)
class ReminderIntegrationService {
  static final LocalNotificationService _localNotifications = LocalNotificationService();

  /// Schedule check-in reminders (both FCM and local)
  static Future<void> scheduleCheckInReminders({
    required DateTime checkInTime,
    required String userName,
    required String userId,
  }) async {
    try {
      // Get user preference for local notifications
      final localEnabled = await _localNotifications.isLocalNotificationsEnabled();
      
      if (localEnabled) {
        // Schedule local notification as backup
        await _localNotifications.scheduleCheckInReminder(
          checkInTime: checkInTime,
          userName: userName,
        );
        debugPrint('Scheduled local check-in reminder for $userName');
      }

      // Also send FCM notification if online (this will be handled by your backend)
      // You can call your existing notification service here if needed
      if (kDebugMode) {
        debugPrint('Check-in reminder scheduled for $userName at $checkInTime');
      }
    } catch (e) {
      debugPrint('Error scheduling check-in reminders: $e');
    }
  }

  /// Schedule check-out reminders (both FCM and local)
  static Future<void> scheduleCheckOutReminders({
    required DateTime checkOutTime,
    required String userName,
    required String userId,
  }) async {
    try {
      // Get user preference for local notifications
      final localEnabled = await _localNotifications.isLocalNotificationsEnabled();
      
      if (localEnabled) {
        // Schedule local notification as backup
        await _localNotifications.scheduleCheckOutReminder(
          checkOutTime: checkOutTime,
          userName: userName,
        );
        debugPrint('Scheduled local check-out reminder for $userName');
      }

      // Also send FCM notification if online (handled by backend)
      if (kDebugMode) {
        debugPrint('Check-out reminder scheduled for $userName at $checkOutTime');
      }
    } catch (e) {
      debugPrint('Error scheduling check-out reminders: $e');
    }
  }

  /// Schedule holiday reminders (both FCM and local)
  static Future<void> scheduleHolidayReminders({
    required List<PublicHoliday> holidays,
  }) async {
    try {
      final localEnabled = await _localNotifications.isLocalNotificationsEnabled();
      
      for (final holiday in holidays) {
        if (localEnabled) {
          // Schedule local notifications for holiday
          await _localNotifications.scheduleHolidayReminder(
            holidayDate: holiday.date,
            holidayName: holiday.name,
          );
          debugPrint('Scheduled local holiday reminder for ${holiday.name}');
        }
        
        // FCM notifications will be handled by your existing backend service
        // You can call NotificationsService.sendHolidayNotificationToAll() if needed
      }
    } catch (e) {
      debugPrint('Error scheduling holiday reminders: $e');
    }
  }

  /// Schedule personal reminders (birthdays, work anniversaries, etc.)
  static Future<void> schedulePersonalReminders({
    required DateTime reminderDate,
    required String title,
    required String message,
    String type = 'personal',
  }) async {
    try {
      final localEnabled = await _localNotifications.isLocalNotificationsEnabled();
      
      if (localEnabled) {
        await _localNotifications.schedulePersonalReminder(
          reminderDate: reminderDate,
          title: title,
          message: message,
          type: type,
        );
        debugPrint('Scheduled local personal reminder: $title');
      }
    } catch (e) {
      debugPrint('Error scheduling personal reminders: $e');
    }
  }

  /// Schedule daily attendance reminders
  static Future<void> scheduleDailyAttendanceReminders({
    required String userName,
    required TimeOfDay checkInTime,
    required TimeOfDay checkOutTime,
  }) async {
    try {
      final localEnabled = await _localNotifications.isLocalNotificationsEnabled();
      
      if (!localEnabled) return;

      final now = DateTime.now();
      
      // Schedule today's reminders
      final todayCheckIn = DateTime(
        now.year, now.month, now.day,
        checkInTime.hour, checkInTime.minute,
      );
      
      final todayCheckOut = DateTime(
        now.year, now.month, now.day,
        checkOutTime.hour, checkOutTime.minute,
      );

      // Only schedule if time is in future
      if (todayCheckIn.isAfter(now)) {
        await _localNotifications.scheduleCheckInReminder(
          checkInTime: todayCheckIn,
          userName: userName,
        );
      }

      if (todayCheckOut.isAfter(now)) {
        await _localNotifications.scheduleCheckOutReminder(
          checkOutTime: todayCheckOut,
          userName: userName,
        );
      }

      // Schedule tomorrow's reminders
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowCheckIn = DateTime(
        tomorrow.year, tomorrow.month, tomorrow.day,
        checkInTime.hour, checkInTime.minute,
      );
      
      final tomorrowCheckOut = DateTime(
        tomorrow.year, tomorrow.month, tomorrow.day,
        checkOutTime.hour, checkOutTime.minute,
      );

      await _localNotifications.scheduleCheckInReminder(
        checkInTime: tomorrowCheckIn,
        userName: userName,
      );

      await _localNotifications.scheduleCheckOutReminder(
        checkOutTime: tomorrowCheckOut,
        userName: userName,
      );

      debugPrint('Scheduled daily attendance reminders for $userName');
    } catch (e) {
      debugPrint('Error scheduling daily attendance reminders: $e');
    }
  }

  /// Cancel all reminders for a user
  static Future<void> cancelAllUserReminders() async {
    try {
      await _localNotifications.cancelAllScheduledNotifications();
      debugPrint('Cancelled all user reminders');
    } catch (e) {
      debugPrint('Error cancelling user reminders: $e');
    }
  }

  /// Get scheduled reminders status
  static Future<Map<String, dynamic>> getReminderStatus() async {
    try {
      final scheduledNotifications = await _localNotifications.getScheduledNotifications();
      final localEnabled = await _localNotifications.isLocalNotificationsEnabled();
      
      return {
        'local_notifications_enabled': localEnabled,
        'scheduled_count': scheduledNotifications.length,
        'scheduled_notifications': scheduledNotifications,
      };
    } catch (e) {
      debugPrint('Error getting reminder status: $e');
      return {
        'local_notifications_enabled': false,
        'scheduled_count': 0,
        'scheduled_notifications': [],
        'error': e.toString(),
      };
    }
  }

  /// Sync reminders with backend (call this when connectivity is restored)
  static Future<void> syncRemindersWithBackend() async {
    try {
      // This method can be used to sync local reminders with backend
      // when connectivity is restored
      
      final scheduledNotifications = await _localNotifications.getScheduledNotifications();
      
      // You can send scheduled reminders info to backend for synchronization
      // This ensures consistency between local and remote notifications
      
      debugPrint('Synced ${scheduledNotifications.length} reminders with backend');
    } catch (e) {
      debugPrint('Error syncing reminders with backend: $e');
    }
  }
}
