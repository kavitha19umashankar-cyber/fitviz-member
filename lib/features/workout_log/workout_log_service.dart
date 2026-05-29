import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyLogs = 'workout_logs';

class ExerciseSet {
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final int? durationSeconds;

  const ExerciseSet({
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'set': setNumber,
        'weight': weightKg,
        'reps': reps,
        'duration': durationSeconds,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> j) => ExerciseSet(
        setNumber: j['set'] as int,
        weightKg: (j['weight'] as num?)?.toDouble(),
        reps: j['reps'] as int?,
        durationSeconds: j['duration'] as int?,
      );
}

class ExerciseLog {
  final String exerciseName;
  final List<ExerciseSet> sets;
  final DateTime loggedAt;
  final String planDate; // yyyy-MM-dd

  const ExerciseLog({
    required this.exerciseName,
    required this.sets,
    required this.loggedAt,
    required this.planDate,
  });

  Map<String, dynamic> toJson() => {
        'exercise': exerciseName,
        'sets': sets.map((s) => s.toJson()).toList(),
        'loggedAt': loggedAt.toIso8601String(),
        'planDate': planDate,
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> j) => ExerciseLog(
        exerciseName: j['exercise'] as String,
        sets: (j['sets'] as List)
            .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
            .toList(),
        loggedAt: DateTime.parse(j['loggedAt'] as String),
        planDate: j['planDate'] as String,
      );

  double? get maxWeight {
    final weights = sets.map((s) => s.weightKg).whereType<double>().toList();
    if (weights.isEmpty) return null;
    return weights.reduce((a, b) => a > b ? a : b);
  }
}

class PersonalRecord {
  final String exerciseName;
  final double weightKg;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.exerciseName,
    required this.weightKg,
    required this.achievedAt,
  });

  Map<String, dynamic> toJson() => {
        'exercise': exerciseName,
        'weight': weightKg,
        'achievedAt': achievedAt.toIso8601String(),
      };

  factory PersonalRecord.fromJson(Map<String, dynamic> j) => PersonalRecord(
        exerciseName: j['exercise'] as String,
        weightKg: (j['weight'] as num).toDouble(),
        achievedAt: DateTime.parse(j['achievedAt'] as String),
      );
}

class WorkoutLogState {
  final List<ExerciseLog> logs;
  final List<PersonalRecord> records;

  const WorkoutLogState({required this.logs, required this.records});
}

class WorkoutLogNotifier extends Notifier<WorkoutLogState> {
  @override
  WorkoutLogState build() {
    _load();
    return const WorkoutLogState(logs: [], records: []);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_keyLogs);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final logs = (data['logs'] as List? ?? [])
          .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList();
      final records = (data['records'] as List? ?? [])
          .map((e) => PersonalRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      state = WorkoutLogState(logs: logs, records: records);
    } catch (_) {}
  }

  Future<bool> logExercise(ExerciseLog log) async {
    // Check for personal record
    bool isNewPR = false;
    final existingRecord = state.records
        .where((r) => r.exerciseName == log.exerciseName)
        .toList();
    final maxWeight = log.maxWeight;
    List<PersonalRecord> updatedRecords = List.of(state.records);

    if (maxWeight != null) {
      if (existingRecord.isEmpty || maxWeight > existingRecord.first.weightKg) {
        isNewPR = true;
        updatedRecords.removeWhere((r) => r.exerciseName == log.exerciseName);
        updatedRecords.add(PersonalRecord(
          exerciseName: log.exerciseName,
          weightKg: maxWeight,
          achievedAt: DateTime.now(),
        ));
      }
    }

    final updatedLogs = [log, ...state.logs];
    state = WorkoutLogState(logs: updatedLogs, records: updatedRecords);
    await _persist();
    return isNewPR;
  }

  List<ExerciseLog> logsForExercise(String name) =>
      state.logs.where((l) => l.exerciseName == name).toList();

  PersonalRecord? recordForExercise(String name) {
    try {
      return state.records.firstWhere((r) => r.exerciseName == name);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLogs,
      jsonEncode({
        'logs': state.logs.map((l) => l.toJson()).toList(),
        'records': state.records.map((r) => r.toJson()).toList(),
      }),
    );
  }
}

final workoutLogProvider =
    NotifierProvider<WorkoutLogNotifier, WorkoutLogState>(
        WorkoutLogNotifier.new);
