import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'roommate_match_channel',
    'RoomMate Match Notifications',
    description: 'Notifications for RoomMate Match app',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Create notification channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Configure FCM
    await _configureFirebaseMessaging();

    if (kDebugMode) {
      print('Notification service initialized');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    // FCM permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Notification permission status: ${settings.authorizationStatus}');
    }

    // Local notification permissions for Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // Configure Firebase Messaging
  Future<void> _configureFirebaseMessaging() async {
    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
      if (kDebugMode) {
        print('FCM Token: $token');
      }
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _saveFCMToken(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showForegroundNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });

    // Handle initial message (app opened from notification)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Show foreground notification
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon,
            color: const Color(0xFF4A90E2),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // Handle notification tap
  void _handleNotificationResponse(NotificationResponse response) {
    // Handle notification tap logic
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
  }

  // Handle notification tap from FCM
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen based on notification data
    if (kDebugMode) {
      print('Notification opened: ${message.data}');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  // Send local notification (for testing)
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          color: const Color(0xFF4A90E2),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return {};

      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      final data = doc.data();

      return {
        'matches': data?['notificationPreferences']?['matches'] ?? true,
        'messages': data?['notificationPreferences']?['messages'] ?? true,
        'likes': data?['notificationPreferences']?['likes'] ?? true,
        'promotions': data?['notificationPreferences']?['promotions'] ?? false,
      };
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return {};
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences(Map<String, bool> preferences) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'notificationPreferences': preferences,
      });

      // Subscribe/unsubscribe based on preferences
      if (preferences['matches'] == true) {
        await subscribeToTopic('matches');
      } else {
        await unsubscribeFromTopic('matches');
      }

      if (preferences['messages'] == true) {
        await subscribeToTopic('messages');
      } else {
        await unsubscribeFromTopic('messages');
      }
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Clear specific notification
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
