import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'flavors/flavor_config.dart';
import 'shared/theme/app_theme.dart';

class FitVizApp extends ConsumerWidget {
  const FitVizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final config = FlavorConfig.instance;

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildDark(primaryColor: config.primaryColor),
      routerConfig: router,
    );
  }
}
