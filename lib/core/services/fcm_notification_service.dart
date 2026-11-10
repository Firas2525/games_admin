import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../constants/api_constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  debugPrint('[FCM Background] Handling background message: ${message.messageId} | ${message.notification?.title}');
}

class FcmNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'admin_notifications',
    'إشعارات الإدارة',
    description: 'تنبيهات فورية لطلبات المزود الخاص وسحب الرواتب والتوثيق',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugPrint('[FCM] Firebase initialized successfully.');

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Initialize Flutter Local Notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[FCM Local Notification] Clicked: ${response.payload}');
        },
      );

      // 4. Create Android High Importance Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          await androidImplementation.createNotificationChannel(_channel);
          await androidImplementation.requestNotificationsPermission();
        }
      }

      // 5. Request permissions from Firebase Messaging
      final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[FCM] Notification authorization status: ${settings.authorizationStatus}');

      // 6. Subscribe to 'admin_orders' topic
      await FirebaseMessaging.instance.subscribeToTopic('admin_orders');
      debugPrint('[FCM] Subscribed to topic: admin_orders');

      // 7. Sync device FCM token to backend (for instant direct push)
      await syncDeviceTokenToServer();

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        syncDeviceTokenToServer();
      });

      // 8. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Received: ${message.notification?.title} - ${message.notification?.body}');

        final RemoteNotification? notification = message.notification;
        final AndroidNotification? android = message.notification?.android;

        if (notification != null && !kIsWeb) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title ?? 'طلب جديد',
            body: notification.body ?? '',
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                playSound: true,
                enableVibration: true,
                styleInformation: const DefaultStyleInformation(true, true),
              ),
            ),
            payload: message.data.toString(),
          );
        }
      });

      // 9. Handle app opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM Open] App opened from message: ${message.data}');
      });

      _isInitialized = true;
    } catch (e, stack) {
      debugPrint('[FCM Init Error] $e\n$stack');
    }
  }

  /// Manually sync FCM token to server (called upon login or start)
  static Future<void> syncDeviceTokenToServer() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      debugPrint('[FCM] Current Device Token: $token');

      final prefs = await SharedPreferences.getInstance();
      final adminToken = prefs.getString('admin_token');
      if (adminToken != null && adminToken.isNotEmpty) {
        final dio = Dio();
        await dio.post(
          '${ApiConstants.baseUrl}/users/fcm-token',
          data: {'token': token},
          options: Options(
            headers: {'Authorization': 'Bearer $adminToken'},
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );
        debugPrint('[FCM] Successfully synced FCM device token to backend user profile.');
      }
    } catch (e) {
      debugPrint('[FCM Sync Error] $e');
    }
  }

  /// Manually re-ensure subscription (e.g. after admin logs in)
  static Future<void> subscribeToAdminTopics() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('admin_orders');
      await syncDeviceTokenToServer();
      debugPrint('[FCM] Re-subscribed to admin_orders and synced token.');
    } catch (e) {
      debugPrint('[FCM Subscribe Error] $e');
    }
  }
}
