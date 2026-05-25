import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<String>? _tokenRefreshSub;

  static const _channelId = 'fitviz_main';
  static const _channelName = 'FitViz Notifications';

  /// Call once from main() after Firebase.initializeApp().
  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Show notification banner even when app is in foreground (iOS).
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Display a local notification for every foreground FCM message.
    FirebaseMessaging.onMessage.listen(_show);
  }

  /// Call after login or session restore.
  /// Sends the FCM token to the backend and subscribes to the gym's broadcast
  /// topic so the backend can push announcements via topic messaging.
  static Future<void> registerDeviceForGym(
    String gymId,
    Future<void> Function(String token) updateToken,
  ) async {
    await _tokenRefreshSub?.cancel();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      try {
        await updateToken(token);
      } catch (_) {}
    }

    await Future.wait([
      FirebaseMessaging.instance.subscribeToTopic('gym_$gymId'),
      FirebaseMessaging.instance.subscribeToTopic('announcements'),
    ]);

    // Re-register whenever the device gets a new FCM token.
    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await updateToken(newToken);
      } catch (_) {}
    });
  }

  /// Call before logout — unsubscribes from topics and cancels token refresh.
  static Future<void> unregisterDevice(String gymId) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    try {
      await Future.wait([
        FirebaseMessaging.instance.unsubscribeFromTopic('gym_$gymId'),
        FirebaseMessaging.instance.unsubscribeFromTopic('announcements'),
      ]);
    } catch (_) {}
  }

  static void _show(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      message.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
