import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented on every login and logout.
/// Any FutureProvider that watches this will automatically re-fetch
/// when the active user changes.
final sessionVersionProvider = StateProvider<int>((ref) => 0);
