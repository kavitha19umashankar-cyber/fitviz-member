import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../features/inbox/inbox_service.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<String>? _tokenRefreshSub;

  static const _channelId = 'fitviz_main';
  static const _channelName = 'FitViz Notifications';

  static const _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    importance: Importance.high,
    enableVibration: true,
  );

  /// Call once from main() after Firebase.initializeApp().
  static Future<void> initialize() async {
    // The rest timer only ever schedules a short relative delay ("N seconds
    // from now"), never an absolute wall-clock time-of-day, so using UTC as
    // the local location is safe and avoids needing a device-timezone lookup.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    // Permissions are already requested via FirebaseMessaging.requestPermission()
    // in main(). Setting these to false avoids a conflicting second prompt on iOS.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Pre-register the channel so Android 8+ doesn't silently drop incoming
    // FCM notifications that target this channel ID.
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Do NOT call setForegroundNotificationPresentationOptions here.
    // That method tells FCM to show a native banner AND onMessage also fires _show,
    // resulting in duplicate notifications on iOS foreground. Using only
    // flutter_local_notifications via _show is consistent across both platforms.

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

  /// Toggle the gym announcements & offers FCM topics.
  /// Call when the user flips the in-app "Offers & Announcements" toggle.
  static Future<void> toggleAnnouncementTopic(
      bool enable, String gymId) async {
    if (enable) {
      await Future.wait([
        FirebaseMessaging.instance.subscribeToTopic('gym_$gymId'),
        FirebaseMessaging.instance.subscribeToTopic('announcements'),
      ]);
    } else {
      await Future.wait([
        FirebaseMessaging.instance.unsubscribeFromTopic('gym_$gymId'),
        FirebaseMessaging.instance.unsubscribeFromTopic('announcements'),
      ]);
    }
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

  static const _restTimerNotificationId = 9001;

  /// Schedules a local notification to fire after [remaining], so the rest
  /// timer completion is surfaced even if the user has navigated away from
  /// the timer screen or backgrounded the app entirely. Uses inexact
  /// scheduling — no SCHEDULE_EXACT_ALARM permission required — which is
  /// accurate to within a few seconds while the app was recently active,
  /// which is always true for an in-progress workout.
  static Future<void> scheduleRestTimerDone(Duration remaining) async {
    await _local.zonedSchedule(
      _restTimerNotificationId,
      'Rest complete',
      'Rest over — back to it!',
      tz.TZDateTime.now(tz.UTC).add(remaining),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a pending rest-timer notification — call when the timer is
  /// cancelled early, or replaced by a new one, so a stale notification
  /// never fires later.
  static Future<void> cancelRestTimerNotification() =>
      _local.cancel(_restTimerNotificationId);

  static Future<void> _show(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    // Persist to the in-app inbox (SharedPreferences — no Riverpod needed here).
    await saveInboxMessageFromFcm(
      id: message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: n.title ?? 'Notification',
      body: n.body ?? '',
      route: message.data['route'] as String?,
    );

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
          icon: '@drawable/ic_notification',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
