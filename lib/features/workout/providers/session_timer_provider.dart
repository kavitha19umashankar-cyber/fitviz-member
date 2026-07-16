import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTimerState {
  final bool running;
  final Duration elapsed;

  const SessionTimerState({
    this.running = false,
    this.elapsed = Duration.zero,
  });

  SessionTimerState copyWith({bool? running, Duration? elapsed}) {
    return SessionTimerState(
      running: running ?? this.running,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

// Elapsed time is derived from a stored wall-clock start time rather than
// counted via Timer.periodic ticks. Android throttles/delays periodic
// timers while the screen is locked or the app is backgrounded, which made
// the old tick-counting version appear to freeze; computing from
// DateTime.now() difference is correct the instant the UI next rebuilds,
// regardless of how many ticks were actually delivered while suspended.
// The running segment's start time is persisted so the session survives
// the OS killing the app process during a long lock, not just throttling.
class SessionTimerNotifier extends Notifier<SessionTimerState> {
  static const _kAccumulatedMs = 'session_timer_accumulated_ms';
  static const _kRunStartedAtMs = 'session_timer_run_started_at_ms';

  Timer? _ticker;
  Duration _accumulated = Duration.zero;
  DateTime? _runStartedAt;

  @override
  SessionTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    unawaited(_restore());
    return const SessionTimerState();
  }

  Duration get _currentElapsed {
    final start = _runStartedAt;
    if (start == null) return _accumulated;
    return _accumulated + DateTime.now().difference(start);
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final accumulatedMs = prefs.getInt(_kAccumulatedMs);
    final runStartedAtMs = prefs.getInt(_kRunStartedAtMs);
    if (accumulatedMs == null && runStartedAtMs == null) return;

    _accumulated = Duration(milliseconds: accumulatedMs ?? 0);
    _runStartedAt = runStartedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(runStartedAtMs)
        : null;

    state = state.copyWith(
      running: _runStartedAt != null,
      elapsed: _currentElapsed,
    );
    if (_runStartedAt != null) _startTicker();
  }

  void toggle() {
    HapticFeedback.mediumImpact();
    if (state.running) {
      _accumulated = _currentElapsed;
      _runStartedAt = null;
      _ticker?.cancel();
      state = state.copyWith(running: false, elapsed: _accumulated);
    } else {
      _runStartedAt = DateTime.now();
      _startTicker();
      state = state.copyWith(running: true, elapsed: _currentElapsed);
    }
    unawaited(_persist());
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsed: _currentElapsed);
    });
  }

  void reset() {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    _accumulated = Duration.zero;
    _runStartedAt = null;
    state = const SessionTimerState();
    unawaited(_persist(clear: true));
  }

  Future<void> _persist({bool clear = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (clear) {
      await prefs.remove(_kAccumulatedMs);
      await prefs.remove(_kRunStartedAtMs);
      return;
    }
    await prefs.setInt(_kAccumulatedMs, _accumulated.inMilliseconds);
    if (_runStartedAt != null) {
      await prefs.setInt(
          _kRunStartedAtMs, _runStartedAt!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_kRunStartedAtMs);
    }
  }
}

final sessionTimerProvider =
    NotifierProvider<SessionTimerNotifier, SessionTimerState>(
        SessionTimerNotifier.new);
