import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app.dart';
import 'flavors/flavor_config.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/notifications/notification_service.dart';

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
  // For iOS, the backend FCM payload must include a `notification` key so APNs
  // auto-displays it, AND set apns-priority=10 so it is not batched/delayed.
  if (!Platform.isAndroid) return;

  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    ),
  );
  await local.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'fitviz_main',
        'App Notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ),
    ),
  );
}

// Single entry point for all flavors.
// Detects the brand at runtime from the installed package name so the correct
// FlavorConfig is loaded regardless of which --target was used at build time.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final info = await PackageInfo.fromPlatform();
  if (info.packageName == 'in.k2fitness.member') {
    FlavorConfig.instance = const FlavorConfig(
      flavor: Flavor.k2fitness,
      appName: 'K2 Fitness Studio',
      appTagline: 'Train Hard. Stay Fit.',
      brandParentGymId: 'GYM-002',
      primaryColor: Color(0xFFEFBE02),
      logoAssetPath: 'assets/k2fitness/images/logo.png',
    );
  } else {
    FlavorConfig.instance = const FlavorConfig(
      flavor: Flavor.fitviz,
      appName: 'FitViz',
      appTagline: 'Your Fitness Journey',
      primaryColor: Color(0xFFC8FF00),
      logoAssetPath: 'assets/fitviz/images/logo.png',
    );
  }

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

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackground);
  await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true,
  );
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: FitVizApp(),
    ),
  );
}
