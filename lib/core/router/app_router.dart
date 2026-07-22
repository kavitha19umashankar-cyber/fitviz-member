import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/workout/presentation/workout_screen.dart';
import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/classes/presentation/classes_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../../features/inbox/inbox_screen.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/about/presentation/why_k2_screen.dart';
import '../../features/about/presentation/privacy_policy_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../flavors/flavor_config.dart';
import '../../shared/fitviz_v2/main_shell_v2.dart';
import '../../features/auth/presentation/login_screen_v2.dart';
import '../../features/auth/presentation/forgot_password_screen_v2.dart';
import '../../features/profile/presentation/profile_screen_v2.dart';
import '../../features/dashboard/presentation/dashboard_screen_v2.dart';
import '../../features/workout/presentation/workout_screen_v2.dart';
import '../../features/attendance/presentation/attendance_screen_v2.dart';
import '../../features/classes/presentation/classes_screen_v2.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthStateNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authNotifier.isAuthenticated;
      final isInitial =
          authState.maybeWhen(initial: () => true, orElse: () => false);
      final isOnAuth = state.uri.path.startsWith('/auth');

      // Still initializing (checking stored session)
      if (isInitial) return null;

      if (!isAuthenticated && !isOnAuth) return '/auth/login';
      if (isAuthenticated && isOnAuth) return '/dashboard';
      return null;
    },
    routes: [
      // ── Auth (no shell) ───────────────────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => FlavorConfig.instance.flavor == Flavor.fitviz
            ? const LoginScreenV2()
            : const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, __) => FlavorConfig.instance.flavor == Flavor.fitviz
            ? const ForgotPasswordScreenV2()
            : const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (_, __) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/inbox',
        builder: (_, __) => const InboxScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (_, __) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/about/why-k2',
        builder: (_, __) => const WhyK2Screen(),
      ),
      GoRoute(
        path: '/about/privacy-policy',
        builder: (_, __) => const PrivacyPolicyScreen(),
      ),
      // ── Main app (bottom nav shell) ───────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            FlavorConfig.instance.flavor == Flavor.fitviz
                ? MainShellV2(child: child)
                : MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => FlavorConfig.instance.flavor == Flavor.fitviz
                ? const DashboardScreenV2()
                : const DashboardScreen(),
          ),
          GoRoute(
            path: '/workout',
            builder: (_, __) => FlavorConfig.instance.flavor == Flavor.fitviz
                ? const WorkoutScreenV2()
                : const WorkoutScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (_, __) => FlavorConfig.instance.flavor == Flavor.fitviz
                ? const AttendanceScreenV2()
                : const AttendanceScreen(),
          ),
          GoRoute(
            path: '/classes',
            builder: (_, __) => FlavorConfig.instance.flavor == Flavor.fitviz
                ? const ClassesScreenV2()
                : const ClassesScreen(),
          ),
          GoRoute(
            path: '/subscription',
            builder: (_, __) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: '/progress',
            builder: (_, __) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => FlavorConfig.instance.flavor == Flavor.fitviz
                ? const ProfileScreenV2()
                : const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: Center(
        child: Text('Page not found: ${state.uri.path}',
            style: const TextStyle(color: Colors.white)),
      ),
    ),
  );
});

/// Bridges Riverpod state changes into a [Listenable] so go_router
/// re-evaluates its redirect whenever auth state changes.
class _AuthStateNotifier extends ChangeNotifier {
  late final ProviderSubscription<AuthState> _authSub;

  _AuthStateNotifier(Ref ref) {
    _authSub = ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _authSub.close();
    super.dispose();
  }
}
