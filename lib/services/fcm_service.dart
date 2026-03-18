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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'staff_track_channel';
  static const String _channelName = 'Staff Track Notifications';
  
  static String? _lastSentToken;
  static bool _isRequesting = false;
  static BuildContext? _appContext;
  static bool _hasShownPermissionDialog = false;

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

    // 2. Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Initialize local notifications for foreground messages
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick(response.payload);
      },
    );

    // 4. Create Android Notification Channel
    if (defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Notifications for staff track app',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 5. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 6. Handle notification clicks when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data.toString());
    });

    // 7. Check if app was opened from a notification when terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data.toString());
    }

    // 8. Get and save FCM token (only if permissions granted)
    final currentStatus = await getNotificationPermissionStatus();
    if (currentStatus == NotificationPermissionStatus.granted) {
      await updateToken();
      
      // 9. Listen for token refresh
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
        results['fcmToken'] = token != null ? '${token!.substring(0, 20)}...' : 'null';
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
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifications for staff track app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher', // Use app launcher icon
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new notification',
      platformDetails,
      payload: message.data.toString(),
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
