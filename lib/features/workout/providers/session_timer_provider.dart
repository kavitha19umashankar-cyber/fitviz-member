import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class SessionTimerNotifier extends Notifier<SessionTimerState> {
  Timer? _ticker;

  @override
  SessionTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const SessionTimerState();
  }

  void toggle() {
    HapticFeedback.mediumImpact();
    if (state.running) {
      _ticker?.cancel();
      state = state.copyWith(running: false);
    } else {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        state =
            state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
      });
      state = state.copyWith(running: true);
    }
  }

  void reset() {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    state = const SessionTimerState();
  }
}

final sessionTimerProvider =
    NotifierProvider<SessionTimerNotifier, SessionTimerState>(
        SessionTimerNotifier.new);
