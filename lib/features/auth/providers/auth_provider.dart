import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_model.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/biometric_service.dart';
import '../../../core/events/app_events.dart';
import '../../../core/providers/session_provider.dart';
import '../../../flavors/flavor_config.dart';

part 'auth_provider.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({required UserModel user}) =
      _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error({required String message}) = _Error;
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;
  late final StreamSubscription<void> _logoutSub;

  AuthNotifier(this._repo, this._ref) : super(const AuthState.initial()) {
    _checkSession();
    _logoutSub = forceLogoutEvents.stream.listen((_) {
      if (state is! _Unauthenticated) {
        state = const AuthState.unauthenticated();
      }
    });
  }

  @override
  void dispose() {
    _logoutSub.cancel();
    super.dispose();
  }

  Future<void> _checkSession() async {
    final hasSession = await SecureStorage.hasSession();
    if (!hasSession) {
      state = const AuthState.unauthenticated();
      return;
    }

    // If biometric is enabled, signal the login screen to prompt the user
    // instead of silently restoring the session.
    final biometricEnabled = await BiometricService.isEnabled();
    final biometricAvailable = await BiometricService.isAvailable();
    if (biometricEnabled && biometricAvailable) {
      _ref.read(biometricPendingProvider.notifier).state = true;
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await _repo.getProfile();
      state = AuthState.authenticated(user: user);
      final gymId = user.gymId ?? '';
      if (gymId.isNotEmpty) {
        unawaited(NotificationService.registerDeviceForGym(
            gymId, _repo.updateFcmToken));
      }
    } catch (_) {
      await SecureStorage.clearAll();
      state = const AuthState.unauthenticated();
    }
  }

  /// Called from the login screen when biometric is pending.
  /// Authenticates with biometrics then restores the stored session.
  Future<void> loginWithBiometric() async {
    state = const AuthState.loading();
    final passed = await BiometricService.authenticate(
      reason: 'Use biometric to unlock ${FlavorConfig.instance.appName}',
    );
    if (!passed) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final user = await _repo.getProfile();
      _ref.read(biometricPendingProvider.notifier).state = false;
      _ref.read(sessionVersionProvider.notifier).state++;
      state = AuthState.authenticated(user: user);
      final gymId = user.gymId ?? '';
      if (gymId.isNotEmpty) {
        unawaited(NotificationService.registerDeviceForGym(
            gymId, _repo.updateFcmToken));
      }
    } catch (_) {
      await SecureStorage.clearAll();
      _ref.read(biometricPendingProvider.notifier).state = false;
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String phone, String password) async {
    state = const AuthState.loading();
    try {
      final result = await _repo.login(phone, password);

      // Branded flavors must reject members from other gym brands.
      if (FlavorConfig.instance.hasBrandFilter) {
        final allowed = await _isBrandMember(result.user.gymId);
        if (!allowed) {
          state = AuthState.error(
            message:
                'This app is only for ${FlavorConfig.instance.appName} members. '
                'Please contact your gym.',
          );
          return;
        }
      }

      await SecureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await SecureStorage.saveUserInfo(
        userId: result.user.id,
        role: result.user.role,
        gymId: result.user.gymId ?? '',
        name: result.user.name,
        email: result.user.email ?? '',
      );
      _ref.read(sessionVersionProvider.notifier).state++;
      state = AuthState.authenticated(user: result.user);
      final gymId = result.user.gymId ?? '';
      if (gymId.isNotEmpty) {
        unawaited(NotificationService.registerDeviceForGym(
            gymId, _repo.updateFcmToken));
      }
    } catch (e, st) {
      debugPrint('[AUTH] login error: $e\n$st');
      state = AuthState.error(message: _friendlyError(e));
    }
  }

  // Checks whether the user's gym belongs to the brand's parent+child family.
  // Fails open (returns true) on network errors so a transient failure doesn't
  // lock out a legitimate member.
  Future<bool> _isBrandMember(String? userGymId) async {
    if (userGymId == null || userGymId.isEmpty) return false;
    try {
      final allGyms = await _repo.getActiveGyms();
      final parentCode = FlavorConfig.instance.brandParentGymId!;
      final parent = allGyms.cast<GymModel?>().firstWhere(
        (g) => g?.gymCode == parentCode,
        orElse: () => null,
      );
      if (parent == null) return true; // parent not found — fail open
      final allowedIds = {
        parent.id,
        ...allGyms
            .where((g) => g.parentGymId == parent.id)
            .map((g) => g.id),
      };
      return allowedIds.contains(userGymId);
    } catch (_) {
      return true; // fail open on network / parse errors
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String gymId,
  }) async {
    state = const AuthState.loading();
    try {
      final result = await _repo.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        gymId: gymId,
      );
      await SecureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await SecureStorage.saveUserInfo(
        userId: result.user.id,
        role: result.user.role,
        gymId: result.user.gymId ?? '',
        name: result.user.name,
        email: result.user.email ?? '',
      );
      state = AuthState.authenticated(user: result.user);
      final resolvedGymId = result.user.gymId ?? gymId;
      if (resolvedGymId.isNotEmpty) {
        unawaited(NotificationService.registerDeviceForGym(
            resolvedGymId, _repo.updateFcmToken));
      }
    } catch (e) {
      state = AuthState.error(message: _friendlyError(e));
    }
  }

  Future<void> logout() async {
    final gymId = await SecureStorage.getGymId() ?? '';
    if (gymId.isNotEmpty) {
      await NotificationService.unregisterDevice(gymId);
    }
    await _repo.logout();
    _ref.read(sessionVersionProvider.notifier).state++;
    state = const AuthState.unauthenticated();
  }

  bool get isAuthenticated =>
      state is _Authenticated;

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('invalid credentials')) {
      return 'Invalid phone number or password. Please try again.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('429')) {
      return 'Too many attempts. Please wait a moment.';
    }
    return 'Something went wrong. Please try again.';
  }
}
