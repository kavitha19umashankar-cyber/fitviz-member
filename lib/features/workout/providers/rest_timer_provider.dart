import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/notifications/notification_service.dart';

class RestTimerState {
  final List<int> presets;
  final int selectedSeconds;
  final bool running;
  final Duration remaining;

  const RestTimerState({
    this.presets = const [30, 45, 60, 90, 120],
    this.selectedSeconds = 60,
    this.running = false,
    this.remaining = Duration.zero,
  });

  RestTimerState copyWith({
    int? selectedSeconds,
    bool? running,
    Duration? remaining,
  }) {
    return RestTimerState(
      presets: presets,
      selectedSeconds: selectedSeconds ?? this.selectedSeconds,
      running: running ?? this.running,
      remaining: remaining ?? this.remaining,
    );
  }
}

// Shared by both the K2 and FitViz workout timer screens so the rest timer
// keeps running (and its completion notification stays scheduled) no matter
// which screen is on top, or whether the app is backgrounded entirely.
// Mirrors SessionTimerNotifier: remaining time is derived from a stored
// wall-clock end time rather than counted via Timer.periodic ticks, so it's
// correct the instant the UI next rebuilds regardless of how many ticks were
// delivered while the app was suspended. The end time is persisted so the
// on-screen countdown also survives the process being killed mid-rest; the
// completion notification itself is scheduled at the OS level independently.
class RestTimerNotifier extends Notifier<RestTimerState> {
  static const _kEndAtMs = 'rest_timer_end_at_ms';
  static const _kSelectedSeconds = 'rest_timer_selected_seconds';

  Timer? _ticker;
  DateTime? _endAt;

  @override
  RestTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    unawaited(_restore());
    return const RestTimerState();
  }

  Duration get _currentRemaining {
    final end = _endAt;
    if (end == null) return Duration.zero;
    final diff = end.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedSeconds = prefs.getInt(_kSelectedSeconds);
    final endAtMs = prefs.getInt(_kEndAtMs);

    if (selectedSeconds != null) {
      state = state.copyWith(selectedSeconds: selectedSeconds);
    }
    if (endAtMs == null) return;

    _endAt = DateTime.fromMillisecondsSinceEpoch(endAtMs);
    if (_currentRemaining == Duration.zero) {
      _endAt = null;
      await prefs.remove(_kEndAtMs);
      return;
    }

    state = state.copyWith(running: true, remaining: _currentRemaining);
    _startTicker();
  }

  void selectPreset(int seconds) {
    if (state.running) return;
    state = state.copyWith(selectedSeconds: seconds);
    unawaited(_persistSelected());
  }

  void start() {
    HapticFeedback.mediumImpact();
    _ticker?.cancel();
    _endAt = DateTime.now().add(Duration(seconds: state.selectedSeconds));
    state = state.copyWith(running: true, remaining: _currentRemaining);
    unawaited(_persistEndAt());
    unawaited(NotificationService.scheduleRestTimerDone(
        Duration(seconds: state.selectedSeconds)));
    _startTicker();
  }

  void cancel() {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    _endAt = null;
    state = state.copyWith(running: false, remaining: Duration.zero);
    unawaited(_clearEndAt());
    unawaited(NotificationService.cancelRestTimerNotification());
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final remaining = _currentRemaining;
      if (remaining == Duration.zero) {
        t.cancel();
        _endAt = null;
        state = state.copyWith(running: false, remaining: Duration.zero);
        unawaited(_clearEndAt());
        HapticFeedback.heavyImpact();
        return;
      }
      state = state.copyWith(remaining: remaining);
    });
  }

  Future<void> _persistSelected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSelectedSeconds, state.selectedSeconds);
  }

  Future<void> _persistEndAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kEndAtMs, _endAt!.millisecondsSinceEpoch);
  }

  Future<void> _clearEndAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEndAtMs);
  }
}

final restTimerProvider =
    NotifierProvider<RestTimerNotifier, RestTimerState>(RestTimerNotifier.new);
