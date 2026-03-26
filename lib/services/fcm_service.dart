import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'auth_storage.dart';
import 'navigation_service.dart';
import '../screens/SharedScreens/notifications_screen.dart';

enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  limited,
  unknown,
}

/// Background message handler - MUST be top-level function
/// This runs when app is terminated or in background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background isolate
  await Firebase.initializeApp();
  debugPrint("Background message received: ${message.messageId}");

  // Create notification channel if needed (Android 8.0+)
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'staff_track_channel',
    'Staff Track Notifications',
    description: 'Notifications for staff track app',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Show the notification
  final RemoteNotification? notification = message.notification;
  final AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    await notifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'staff_track_channel',
          'Staff Track Notifications',
          channelDescription: 'Notifications for staff track app',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/launcher_icon',
        ),
      ),
      payload: message.data.toString(),
    );
  }
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Standard notification channel
  static const String _channelId = 'staff_track_channel';
  static const String _channelName = 'Staff Track Notifications';

  // High-priority channel for instant/critical notifications
  static const String _highPriorityChannelId = 'staff_track_urgent';
  static const String _highPriorityChannelName = 'Urgent Alerts';

  static String? _lastSentToken;
  static bool _isRequesting = false;
  static BuildContext? _appContext;
  static bool _hasShownPermissionDialog = false;
  static bool _batteryOptimizationRequested = false;

  /// Check current notification permission status
  static Future<NotificationPermissionStatus> getNotificationPermissionStatus() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        return NotificationPermissionStatus.granted;
      } else if (status.isDenied) {
        return NotificationPermissionStatus.denied;
      } else if (status.isPermanentlyDenied) {
        return NotificationPermissionStatus.permanentlyDenied;
      } else if (status.isLimited) {
        return NotificationPermissionStatus.limited;
      } else {
        return NotificationPermissionStatus.unknown;
      }
    } else {
      // iOS permissions are handled by Firebase
      final settings = await _firebaseMessaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        return NotificationPermissionStatus.granted;
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return NotificationPermissionStatus.denied;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        return NotificationPermissionStatus.limited;
      } else {
        return NotificationPermissionStatus.denied;
      }
    }
  }

  /// Request notification permissions with user-friendly dialog
  static Future<bool> requestNotificationPermissions({bool showRationale = false}) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.status;

        // Show rationale dialog if permission was denied before
        if (showRationale && (status.isDenied || status.isPermanentlyDenied) && !_hasShownPermissionDialog) {
          await _showPermissionRationaleDialog();
          _hasShownPermissionDialog = true;
        }

        if (status.isPermanentlyDenied) {
          // Open app settings for permanently denied permissions
          await _openAppSettings();
          return false;
        }

        final newStatus = await Permission.notification.request();
        return newStatus.isGranted;
      } else {
        // iOS - use Firebase permission request
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Request battery optimization exemption for instant notification delivery
  /// This allows the app to receive notifications without delay on Android 6+
  static Future<bool> requestBatteryOptimizationExemption({BuildContext? context}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;

      if (status.isGranted) {
        debugPrint('FCM: Battery optimization exemption already granted');
        return true;
      }

      // Only request once per session
      if (_batteryOptimizationRequested) return false;
      _batteryOptimizationRequested = true;

      // Show explanation dialog before requesting
      final ctx = context ?? _appContext;
      if (ctx != null) {
        final shouldRequest = await showDialog<bool>(
          context: ctx,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Enable Instant Notifications'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('For instant delivery of important notifications (check-in reminders, urgent alerts), we need to exclude the app from battery optimization.'),
                  SizedBox(height: 12),
                  Text('This ensures you receive time-sensitive notifications immediately, even when the app is in the background.'),
                  SizedBox(height: 12),
                  Text('Tap "Allow" and select "All apps" → "Staff Track" → "Don\'t optimize"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        ) ?? false;

        if (!shouldRequest) return false;
      }

      final result = await Permission.ignoreBatteryOptimizations.request();
      debugPrint('FCM: Battery optimization request result: $result');
      return result.isGranted;
    } catch (e) {
      debugPrint('FCM: Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  /// Show educational dialog about notification permissions
  static Future<void> _showPermissionRationaleDialog() async {
    if (_appContext == null) return;
    
    return showDialog<void>(
      context: _appContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stay updated with important alerts:'),
              SizedBox(height: 8),
              Text('• Check-in/out reminders'),
              Text('• Attendance alerts'),
              Text('• Important announcements'),
              Text('• Request status updates'),
              SizedBox(height: 12),
              Text('Don\'t miss important work-related notifications!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                requestNotificationPermissions();
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  /// Open app settings for notification permissions
  static Future<void> _openAppSettings() async {
    if (_appContext == null) return;
    
    return showDialog<void>(
      context: _appContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications Disabled'),
          content: const Text(
            'To receive important work notifications, please enable them in your device settings:\n\n'
            'Settings → Apps → Staff Track → Notifications → Allow',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> initialize(BuildContext context) async {
    _appContext = context;

    if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    // 1. Check and request permissions with proper flow
    final permissionStatus = await getNotificationPermissionStatus();
    debugPrint('FCM: Initial permission status: $permissionStatus');

    if (permissionStatus == NotificationPermissionStatus.denied ||
        permissionStatus == NotificationPermissionStatus.permanentlyDenied) {
      // Try to request permissions with rationale
      final granted = await requestNotificationPermissions(showRationale: true);
      if (!granted) {
        debugPrint('FCM: Notification permissions not granted');
        return;
      }
    } else if (permissionStatus == NotificationPermissionStatus.limited) {
      // Try to upgrade limited permissions to full
      await requestNotificationPermissions();
    }

    // 2. Set background message handler (must be called before Firebase init)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Initialize local notifications for foreground messages
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick(response.payload);
      },
    );

    // 4. Create Android Notification Channels
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Standard channel for regular notifications
      const AndroidNotificationChannel standardChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'General notifications for staff track app',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      // High-priority channel for instant/critical notifications
      const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
        _highPriorityChannelId,
        _highPriorityChannelName,
        description: 'Urgent alerts requiring immediate attention (check-ins, important reminders)',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(standardChannel);
      await androidPlugin?.createNotificationChannel(urgentChannel);

      debugPrint('FCM: Notification channels created');
    }

    // 5. Request battery optimization exemption for instant delivery (Android 6+)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await requestBatteryOptimizationExemption();
    }

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 7. Handle notification clicks when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data.toString());
    });

    // 8. Check if app was opened from a notification when terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data.toString());
    }

    // 9. Get and save FCM token (only if permissions granted)
    final currentStatus = await getNotificationPermissionStatus();
    if (currentStatus == NotificationPermissionStatus.granted) {
      await updateToken();

      // 10. Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });
    } else {
      debugPrint('FCM: Skipping token registration due to insufficient permissions');
    }
  }

  /// Retry FCM initialization after permissions are granted
  static Future<void> retryInitialization() async {
    if (_appContext == null) {
      debugPrint('FCM: Cannot retry - no context available');
      return;
    }
    
    debugPrint('FCM: Retrying initialization...');
    
    // Check if permissions are now granted
    final status = await getNotificationPermissionStatus();
    if (status == NotificationPermissionStatus.granted) {
      // Re-initialize FCM components
      await updateToken();
      debugPrint('FCM: Successfully re-initialized after permission grant');
    } else {
      debugPrint('FCM: Retry failed - permissions still not granted: $status');
    }
  }

  /// Check if notifications are enabled and show appropriate UI
  static Future<bool> checkAndRequestPermissions({BuildContext? context}) async {
    final ctx = context ?? _appContext;
    if (ctx == null) return false;
    
    final status = await getNotificationPermissionStatus();
    
    switch (status) {
      case NotificationPermissionStatus.granted:
        return true;
        
      case NotificationPermissionStatus.denied:
        await _showPermissionRationaleDialog();
        return false;
        
      case NotificationPermissionStatus.permanentlyDenied:
        await _openAppSettings();
        return false;
        
      case NotificationPermissionStatus.limited:
        await requestNotificationPermissions();
        return false;
        
      case NotificationPermissionStatus.unknown:
        await requestNotificationPermissions(showRationale: true);
        return false;
    }
  }

  /// Get notification settings for debugging
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final firebaseSettings = await _firebaseMessaging.getNotificationSettings();
      final permissionStatus = await getNotificationPermissionStatus();
      
      return {
        'firebaseAuthorization': firebaseSettings.authorizationStatus.toString(),
        'permissionStatus': permissionStatus.toString(),
        'platform': defaultTargetPlatform.toString(),
        'tokenRegistered': _lastSentToken != null,
        'hasContext': _appContext != null,
      };
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      return {'error': e.toString()};
    }
  }

  /// Test notification permissions and FCM setup
  static Future<Map<String, dynamic>> testNotificationSetup() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Check permissions
      final permissionStatus = await getNotificationPermissionStatus();
      results['permissionStatus'] = permissionStatus.toString();
      results['permissionsGranted'] = permissionStatus == NotificationPermissionStatus.granted;
      
      // 2. Try to get FCM token
      if (permissionStatus == NotificationPermissionStatus.granted) {
        final token = await _firebaseMessaging.getToken();
        results['fcmToken'] = token != null ? '${token.substring(0, 20)}...' : 'null';
        results['tokenAvailable'] = token != null;
        
        // 3. Test local notification
        await _showLocalNotification(RemoteMessage(
          messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
          notification: const RemoteNotification(
            title: 'Test Notification',
            body: 'FCM setup test successful!',
          ),
          data: {'test': 'local_notification'},
        ));
        results['localNotificationTest'] = 'success';
      } else {
        results['fcmToken'] = 'skipped (no permission)';
        results['tokenAvailable'] = false;
        results['localNotificationTest'] = 'skipped (no permission)';
      }
      
      results['overall'] = permissionStatus == NotificationPermissionStatus.granted ? 'success' : 'permission_denied';
      
    } catch (e) {
      results['error'] = e.toString();
      results['overall'] = 'error';
    }
    
    return results;
  }

  static Future<void> updateToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('Error getting FCM token: $e');
      }
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    // Prevent redundant requests if already sending or if token hasn't changed
    if (_isRequesting || token == _lastSentToken) return;

    try {
      final authToken = await AuthStorage.getToken();
      if (authToken == null) {
        debugPrint('FCM: No auth token, skipping token registration');
        return;
      }

      _isRequesting = true;
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _lastSentToken = token;
        if (!kReleaseMode) {
          debugPrint('FCM token registered successfully: ${token.substring(0, 10)}...');
        }
      } else {
        if (!kReleaseMode) {
          debugPrint('Failed to register FCM token: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('Error sending FCM token to backend: $e');
      }
    } finally {
      _isRequesting = false;
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    // Check if this is an urgent notification (check-in reminders, etc.)
    final bool isUrgent = _isUrgentNotification(message.data);
    final String channelId = isUrgent ? _highPriorityChannelId : _channelId;
    final String channelName = isUrgent ? _highPriorityChannelName : _channelName;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: isUrgent
          ? 'Urgent alerts requiring immediate attention'
          : 'General notifications for staff track app',
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.max : Priority.high,
      showWhen: true,
      enableLights: true,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
      category: isUrgent ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.message,
      fullScreenIntent: isUrgent, // Show full-screen for urgent notifications
      visibility: NotificationVisibility.public,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        interruptionLevel: isUrgent ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
      ),
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new notification',
      platformDetails,
      payload: message.data.toString(),
    );
  }

  /// Determine if a notification should be treated as urgent
  static bool _isUrgentNotification(Map<String, dynamic> data) {
    // Check for urgent notification types
    final type = data['type']?.toString().toLowerCase() ?? '';
    final priority = data['priority']?.toString().toLowerCase() ?? '';

    final urgentTypes = [
      'check_in_reminder',
      'check_out_reminder',
      'attendance_alert',
      'urgent',
      'urgent_request',
    ];

    final urgentPriorities = ['high', 'urgent', 'critical'];

    return urgentTypes.contains(type) || urgentPriorities.contains(priority);
  }

  /// Show a local notification programmatically (for testing or in-app alerts)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool isUrgent = false,
  }) async {
    final String channelId = isUrgent ? _highPriorityChannelId : _channelId;
    final String channelName = isUrgent ? _highPriorityChannelName : _channelName;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: isUrgent
          ? 'Urgent alerts requiring immediate attention'
          : 'General notifications for staff track app',
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.max : Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformDetails,
      payload: data?.toString(),
    );
  }

  static void _handleNotificationClick(String? payload) {
    if (_appContext == null || payload == null) return;
    
    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        jsonDecode(payload) as Map
      );
      
      NotificationNavigationService.handleNotificationClick(_appContext!, data);
    } catch (e) {
      debugPrint('Error handling notification click: $e');
      // Fallback to notifications screen
      Navigator.push(
        _appContext!,
        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
      );
    }
  }

  /// Call this on logout to clear the local token cache 
  /// so it can be re-registered for the next user.
  static void clearTokenCache() {
    _lastSentToken = null;
  }
}
