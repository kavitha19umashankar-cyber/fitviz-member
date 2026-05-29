import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyDate = 'wellness_date';
const _keyEnergy = 'wellness_energy';
const _keyMood = 'wellness_mood';

class WellnessState {
  final bool checkedInToday;
  final int? energy;  // 1-5
  final int? mood;    // 1-5

  const WellnessState({
    required this.checkedInToday,
    this.energy,
    this.mood,
  });

  String get workoutRecommendation {
    final avg = ((energy ?? 3) + (mood ?? 3)) / 2;
    if (avg >= 4) return 'Feeling great — push hard today!';
    if (avg >= 3) return 'Moderate energy — good session ahead.';
    return 'Low energy — consider a lighter workout or rest.';
  }

  WellnessState copyWith({bool? checkedInToday, int? energy, int? mood}) {
    return WellnessState(
      checkedInToday: checkedInToday ?? this.checkedInToday,
      energy: energy ?? this.energy,
      mood: mood ?? this.mood,
    );
  }
}

class WellnessNotifier extends Notifier<WellnessState> {
  @override
  WellnessState build() {
    _load();
    return const WellnessState(checkedInToday: false);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final savedDate = prefs.getString(_keyDate) ?? '';
    if (savedDate == today) {
      state = WellnessState(
        checkedInToday: true,
        energy: prefs.getInt(_keyEnergy),
        mood: prefs.getInt(_keyMood),
      );
    }
  }

  Future<void> checkIn({required int energy, required int mood}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDate, _todayKey());
    await prefs.setInt(_keyEnergy, energy);
    await prefs.setInt(_keyMood, mood);
    state = WellnessState(checkedInToday: true, energy: energy, mood: mood);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}

final wellnessProvider =
    NotifierProvider<WellnessNotifier, WellnessState>(WellnessNotifier.new);
