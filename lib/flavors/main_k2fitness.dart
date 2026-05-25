import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../app.dart';
import '../core/notifications/notification_service.dart';
import 'flavor_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackground(RemoteMessage message) async {
  await Firebase.initializeApp();
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

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackground);
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  await NotificationService.initialize();

  runApp(const ProviderScope(child: FitVizApp()));
}
