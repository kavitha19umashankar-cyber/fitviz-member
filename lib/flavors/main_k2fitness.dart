import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../app.dart';
import '../core/notifications/notification_service.dart';
import 'flavor_config.dart';

// Runs in a separate isolate — cannot use NotificationService static instance.
// Only handles data-only messages; notification-type messages are auto-displayed
// by the FCM system tray (Android) or APNs (iOS).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackground(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) return;

  final title = message.data['title'] as String?;
  final body = message.data['body'] as String?;
  if (title == null && body == null) return;

  // flutter_local_notifications uses platform channels which are not available
  // in background isolates on iOS — only show the local notification on Android.
  if (Platform.isIOS) return;

  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await local.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'fitviz_main',
        'FitViz Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

Future<void> main() async {
  FlavorConfig.instance = const FlavorConfig(
    flavor: Flavor.k2fitness,
    appName: 'K2 Fitness Studio',
    appTagline: 'Train Hard. Stay Fit.',
    brandParentGymId: 'GYM-002', // K2 brand root — scopes gym list to GYM-002 + its child branches
    primaryColor: Color(0xFFEFBE02),
    logoAssetPath: 'assets/k2fitness/images/logo.png',
  );

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackground);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await NotificationService.initialize();
  } catch (_) {}

  runApp(const ProviderScope(child: FitVizApp()));
}
