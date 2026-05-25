import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'flavors/flavor_config.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/notifications/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackground(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// Default entry point — FitViz flavor.
// Use lib/flavors/main_k2fitness.dart (or other) for white-label builds.
Future<void> main() async {
  FlavorConfig.instance = const FlavorConfig(
    flavor: Flavor.fitviz,
    appName: 'FitViz',
    appTagline: 'Your Fitness Journey',
    primaryColor: Color(0xFFC8FF00),
    logoAssetPath: 'assets/fitviz/images/logo.png',
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
