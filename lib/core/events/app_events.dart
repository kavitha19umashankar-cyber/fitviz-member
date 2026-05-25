import 'dart:async';

/// Fired by AuthInterceptor when the refresh token is invalid/expired.
/// AuthNotifier listens to this and transitions to unauthenticated.
final forceLogoutEvents = StreamController<void>.broadcast();
