import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyDate = 'hydration_date';
const _keyCount = 'hydration_count';
const _keyGoal = 'hydration_goal';

// ml per tap
const int kMlPerGlass = 250;
const int kDefaultGoalMl = 2500;

class HydrationNotifier extends Notifier<HydrationState> {
  @override
  HydrationState build() {
    _load();
    return const HydrationState(consumed: 0, goalMl: kDefaultGoalMl);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final savedDate = prefs.getString(_keyDate) ?? '';
    final goal = prefs.getInt(_keyGoal) ?? kDefaultGoalMl;

    if (savedDate != today) {
      // New day — reset count
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCount, 0);
      state = HydrationState(consumed: 0, goalMl: goal);
    } else {
      final count = prefs.getInt(_keyCount) ?? 0;
      state = HydrationState(consumed: count * kMlPerGlass, goalMl: goal);
    }
  }

  Future<void> addGlass() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    await prefs.setString(_keyDate, today);
    final count = (prefs.getInt(_keyCount) ?? 0) + 1;
    await prefs.setInt(_keyCount, count);
    state = state.copyWith(consumed: count * kMlPerGlass);
  }

  Future<void> removeGlass() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyCount) ?? 0) - 1;
    if (count < 0) return;
    await prefs.setInt(_keyCount, count);
    state = state.copyWith(consumed: count * kMlPerGlass);
  }

  Future<void> setGoal(int goalMl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGoal, goalMl);
    state = state.copyWith(goalMl: goalMl);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}

class HydrationState {
  final int consumed;
  final int goalMl;

  const HydrationState({required this.consumed, required this.goalMl});

  double get fraction => goalMl > 0 ? (consumed / goalMl).clamp(0.0, 1.0) : 0;
  bool get isGoalMet => consumed >= goalMl;
  int get glasses => consumed ~/ kMlPerGlass;

  HydrationState copyWith({int? consumed, int? goalMl}) {
    return HydrationState(
      consumed: consumed ?? this.consumed,
      goalMl: goalMl ?? this.goalMl,
    );
  }
}

final hydrationProvider =
    NotifierProvider<HydrationNotifier, HydrationState>(HydrationNotifier.new);
