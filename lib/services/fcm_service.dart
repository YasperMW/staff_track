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

  static Future<void> initialize(BuildContext context) async {
    _appContext = context;
    
    if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    // 1. Request permissions (Android 13+ and iOS)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    }
    
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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

    // 8. Get and save FCM token
    await updateToken();
    
    // 9. Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _sendTokenToBackend(newToken);
    });
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
