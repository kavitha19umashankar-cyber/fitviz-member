import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented on every login and logout.
/// Any FutureProvider that watches this will automatically re-fetch
/// when the active user changes.
final sessionVersionProvider = StateProvider<int>((ref) => 0);

/// True when the app has a stored session but is waiting for the user
/// to pass biometric authentication before restoring it.
final biometricPendingProvider = StateProvider<bool>((ref) => false);

