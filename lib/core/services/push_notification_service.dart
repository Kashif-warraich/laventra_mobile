import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';
import '../constants/api_constants.dart';

/// Must be a top-level function for Firebase background message handling.
/// Flutter requires this to be outside any class so the isolate can find it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised in main.dart before this can fire.
  // Nothing to do here — the notification is displayed by the OS automatically
  // when the app is in the background/terminated.
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  /// Call once after Firebase.initializeApp() and after the user is logged in.
  Future<void> initialize() async {
    if (_initialised) return;
    _initialised = true;

    // Request permissions (iOS — Android grants by default on API < 33)
    await requestPermissions();

    // Set up local notifications for foreground display
    await _initLocalNotifications();

    // Listen for foreground messages and show them as local notifications
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Listen for token refresh and re-register with backend
    _messaging.onTokenRefresh.listen((token) {
      _sendTokenToBackend(token);
    });
  }

  /// Request notification permissions from the OS.
  Future<void> requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // iOS: register for remote notifications via APNs
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Get the current FCM registration token.
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Get the FCM token and send it to the backend.
  /// Safe to call multiple times — the backend just overwrites.
  Future<void> registerToken() async {
    final token = await getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiClient.instance.dio.patch(
        ApiConstants.pushToken,
        data: {'push_token': token},
      );
    } catch (e) {
      // Non-fatal: token registration can be retried on next app launch
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already handled by Firebase
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Create a high-importance Android notification channel
    const channel = AndroidNotificationChannel(
      'laventra_device_alerts',
      'Device Alerts',
      description: 'Notifications for device online/offline status changes',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'laventra_device_alerts',
          'Device Alerts',
          channelDescription: 'Notifications for device online/offline status changes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
