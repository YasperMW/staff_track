import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:timezone/timezone.dart' as tz;

/// Local notification service for offline reminders
/// Works alongside FCM to ensure notifications reach users even without internet
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _localNotificationsEnabledKey = 'local_notifications_enabled';
  static const String _scheduledNotificationsKey = 'scheduled_notifications';
  
  // Notification channels for offline reminders
  static const String _offlineRemindersChannelId = 'offline_reminders';
  static const String _offlineRemindersChannelName = 'Offline Reminders';
  
  bool _isInitialized = false;
  Timer? _connectivityCheckTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Initialize the local notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/launcher_icon');
      
      // iOS initialization
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
      );
      
      const InitializationSettings initSettings = 
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      if (defaultTargetPlatform == TargetPlatform.android) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _offlineRemindersChannelId,
          _offlineRemindersChannelName,
          description: 'Local reminders that work without internet connection',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Start connectivity monitoring
      _startConnectivityMonitoring();
      
      // Restore scheduled notifications after app restart
      await _restoreScheduledNotifications();
      
      _isInitialized = true;
      debugPrint('LocalNotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LocalNotificationService: $e');
    }
  }

  /// Check if local notifications are enabled by user
  Future<bool> isLocalNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_localNotificationsEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error checking local notifications enabled: $e');
      return false;
    }
  }

  /// Enable or disable local notifications
  Future<void> setLocalNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_localNotificationsEnabledKey, enabled);
      
      if (!enabled) {
        // Cancel all scheduled notifications when disabled
        await cancelAllScheduledNotifications();
      }
      
      debugPrint('Local notifications ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('Error setting local notifications enabled: $e');
    }
  }

  /// Schedule a local notification for offline reminders
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? payload,
    String type = 'reminder',
  }) async {
    if (!await isLocalNotificationsEnabled()) {
      debugPrint('Local notifications disabled, skipping schedule');
      return;
    }

    try {
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _offlineRemindersChannelId,
          _offlineRemindersChannelName,
          channelDescription: 'Local reminders that work without internet connection',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableLights: true,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/launcher_icon',
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      // Calculate scheduled time
      final scheduledTimeUtc = scheduledTime.isUtc ? scheduledTime : scheduledTime.toUtc();

      await _notifications.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(scheduledTimeUtc, tz.local),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
        payload: jsonEncode({
          'id': id,
          'type': type,
          'scheduled_time': scheduledTimeUtc.toIso8601String(),
          if (payload != null) ...payload,
        }),
      );

      // Save notification info for persistence
      await _saveScheduledNotification({
        'id': id,
        'title': title,
        'body': body,
        'scheduled_time': scheduledTimeUtc.toIso8601String(),
        'type': type,
        'payload': payload,
      });

      debugPrint('Scheduled local notification: $title at $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling local notification: $e');
    }
  }

  /// Schedule check-in reminder notifications
  Future<void> scheduleCheckInReminder({
    required DateTime checkInTime,
    required String userName,
  }) async {
    final reminderTime = checkInTime.subtract(const Duration(minutes: 15));
    final id = _generateNotificationId('check_in_reminder', checkInTime);
    
    await scheduleNotification(
      id: id,
      title: 'Check-in Reminder',
      body: 'Hi $userName, don\'t forget to check in at ${_formatTime(checkInTime)}',
      scheduledTime: reminderTime,
      payload: {
        'type': 'check_in_reminder',
        'check_in_time': checkInTime.toIso8601String(),
        'action': 'check_in',
      },
      type: 'check_in_reminder',
    );
  }

  /// Schedule check-out reminder notifications
  Future<void> scheduleCheckOutReminder({
    required DateTime checkOutTime,
    required String userName,
  }) async {
    final reminderTime = checkOutTime.subtract(const Duration(minutes: 15));
    final id = _generateNotificationId('check_out_reminder', checkOutTime);
    
    await scheduleNotification(
      id: id,
      title: 'Check-out Reminder',
      body: 'Hi $userName, don\'t forget to check out at ${_formatTime(checkOutTime)}',
      scheduledTime: reminderTime,
      payload: {
        'type': 'check_out_reminder',
        'check_out_time': checkOutTime.toIso8601String(),
        'action': 'check_out',
      },
      type: 'check_out_reminder',
    );
  }

  /// Schedule holiday reminder notifications
  Future<void> scheduleHolidayReminder({
    required DateTime holidayDate,
    required String holidayName,
  }) async {
    // Schedule reminders at different intervals
    final reminders = [
      holidayDate.subtract(const Duration(days: 7)),
      holidayDate.subtract(const Duration(days: 3)),
      holidayDate.subtract(const Duration(days: 1)),
    ];

    for (int i = 0; i < reminders.length; i++) {
      final reminderTime = reminders[i];
      if (reminderTime.isAfter(DateTime.now())) {
        final id = _generateNotificationId('holiday_reminder', holidayDate, index: i);
        final daysUntil = holidayDate.difference(reminderTime).inDays;
        
        await scheduleNotification(
          id: id,
          title: 'Holiday Reminder',
          body: '$holidayName is coming up in $daysUntil day${daysUntil == 1 ? '' : 's'}!',
          scheduledTime: reminderTime,
          payload: {
            'type': 'holiday_reminder',
            'holiday_name': holidayName,
            'holiday_date': holidayDate.toIso8601String(),
          },
          type: 'holiday_reminder',
        );
      }
    }
  }

  /// Schedule work anniversary/birthday reminders
  Future<void> schedulePersonalReminder({
    required DateTime reminderDate,
    required String title,
    required String message,
    String type = 'personal',
  }) async {
    final id = _generateNotificationId(type, reminderDate);
    
    await scheduleNotification(
      id: id,
      title: title,
      body: message,
      scheduledTime: reminderDate,
      payload: {
        'type': type,
        'reminder_date': reminderDate.toIso8601String(),
      },
      type: type,
    );
  }

  /// Cancel a specific scheduled notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id: id);
      await _removeScheduledNotification(id);
      debugPrint('Cancelled notification: $id');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    try {
      await _notifications.cancelAll();
      await _clearAllScheduledNotifications();
      debugPrint('Cancelled all scheduled notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Get list of scheduled notifications
  Future<List<Map<String, dynamic>>> getScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_scheduledNotificationsKey) ?? [];
      
      return notificationsJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error getting scheduled notifications: $e');
      return [];
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final payload = Map<String, dynamic>.from(jsonDecode(response.payload!));
        _handleNotificationAction(payload);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Handle notification actions
  void _handleNotificationAction(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    final action = payload['action'] as String?;
    
    debugPrint('Handling notification action: type=$type, action=$action');
    
  }

  /// Start monitoring connectivity to backup FCM notifications
  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result == ConnectivityResult.none) {
        // No internet - ensure local notifications are ready
        debugPrint('No internet connection - local notifications active');
      } else {
        // Internet restored - can rely on FCM again
        debugPrint('Internet connection restored - FCM notifications active');
      }
    });
  }

  /// Save scheduled notification info for persistence
  Future<void> _saveScheduledNotification(Map<String, dynamic> notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList(_scheduledNotificationsKey) ?? [];
      
      // Remove existing notification with same ID if exists
      notifications.removeWhere((json) {
        final existing = Map<String, dynamic>.from(jsonDecode(json));
        return existing['id'] == notification['id'];
      });
      
      notifications.add(jsonEncode(notification));
      await prefs.setStringList(_scheduledNotificationsKey, notifications);
    } catch (e) {
      debugPrint('Error saving scheduled notification: $e');
    }
  }

  /// Remove scheduled notification from storage
  Future<void> _removeScheduledNotification(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList(_scheduledNotificationsKey) ?? [];
      
      notifications.removeWhere((json) {
        final existing = Map<String, dynamic>.from(jsonDecode(json));
        return existing['id'] == id;
      });
      
      await prefs.setStringList(_scheduledNotificationsKey, notifications);
    } catch (e) {
      debugPrint('Error removing scheduled notification: $e');
    }
  }

  /// Clear all scheduled notifications from storage
  Future<void> _clearAllScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scheduledNotificationsKey);
    } catch (e) {
      debugPrint('Error clearing scheduled notifications: $e');
    }
  }

  /// Restore scheduled notifications after app restart
  Future<void> _restoreScheduledNotifications() async {
    try {
      final notifications = await getScheduledNotifications();
      final now = DateTime.now();
      
      for (final notification in notifications) {
        final scheduledTime = DateTime.parse(notification['scheduled_time']);
        
        // Only restore if scheduled time is in the future
        if (scheduledTime.isAfter(now)) {
          await scheduleNotification(
            id: notification['id'],
            title: notification['title'],
            body: notification['body'],
            scheduledTime: scheduledTime,
            payload: notification['payload'],
            type: notification['type'],
          );
        } else {
          // Remove expired notifications
          await _removeScheduledNotification(notification['id']);
        }
      }
      
      debugPrint('Restored ${notifications.length} scheduled notifications');
    } catch (e) {
      debugPrint('Error restoring scheduled notifications: $e');
    }
  }

  /// Generate unique notification ID
  int _generateNotificationId(String type, DateTime dateTime, {int? index}) {
    final baseId = '${type}_${dateTime.year}_${dateTime.month}_${dateTime.day}';
    if (index != null) {
      return '${baseId}_$index'.hashCode;
    }
    return baseId.hashCode;
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityCheckTimer?.cancel();
  }
}
