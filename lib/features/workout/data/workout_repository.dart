import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

part 'workout_repository.g.dart';

@JsonSerializable()
class WorkoutEntry {
  final String id;
  final String? workoutTitle;
  final String? workoutDetail;
  final String? focus;
  final String? dayName;
  final bool isRestDay;

  const WorkoutEntry({
    required this.id,
    this.workoutTitle,
    this.workoutDetail,
    this.focus,
    this.dayName,
    this.isRestDay = false,
  });

  List<String> get exercises {
    if (workoutDetail == null) return [];
    return workoutDetail!
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) =>
      _$WorkoutEntryFromJson(json);
}

@JsonSerializable()
class DietEntry {
  final String id;
  final String? dietType;
  final String? dayName;
  final Map<String, dynamic>? meals;

  const DietEntry({
    required this.id,
    this.dietType,
    this.dayName,
    this.meals,
  });

  factory DietEntry.fromJson(Map<String, dynamic> json) =>
      _$DietEntryFromJson(json);
}

@JsonSerializable()
class DailyPlan {
  final String id;
  final String planDate;
  final String status;
  final bool isRestDay;
  final WorkoutEntry? workoutEntry;
  final DietEntry? dietEntry;

  const DailyPlan({
    required this.id,
    required this.planDate,
    required this.status,
    this.isRestDay = false,
    this.workoutEntry,
    this.dietEntry,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) =>
      _$DailyPlanFromJson(json);
}

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.read(dioProvider));
});

class WorkoutRepository {
  final Dio _dio;

  WorkoutRepository(this._dio);

  Future<DailyPlan?> getTodayPlan() async {
    try {
      final res = await _dio.get(ApiConstants.todayPlan);
      if (res.data == null) return null;
      return DailyPlan.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<DailyPlan>> getPlanHistory({int? month, int? year}) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    final res = await _dio.get(
      ApiConstants.planHistory,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final list = (res.data as List<dynamic>?) ?? [];
    // History returns flat objects: { planDate, workoutTitle, workoutDetail,
    // dietType, meals, status, isRestDay } — no id, no nested entry objects.
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final hasWorkout =
          m['workoutTitle'] != null || m['workoutDetail'] != null;
      final hasDiet = m['dietType'] != null || m['meals'] != null;
      return DailyPlan(
        id: m['planDate'] as String? ?? '',
        planDate: m['planDate'] as String? ?? '',
        status: m['status'] as String? ?? 'PENDING',
        isRestDay: m['isRestDay'] as bool? ?? false,
        workoutEntry: hasWorkout
            ? WorkoutEntry(
                id: '',
                workoutTitle: m['workoutTitle'] as String?,
                workoutDetail: m['workoutDetail'] as String?,
                isRestDay: m['isRestDay'] as bool? ?? false,
              )
            : null,
        dietEntry: hasDiet
            ? DietEntry(
                id: '',
                dietType: m['dietType'] as String?,
                meals: m['meals'] as Map<String, dynamic>?,
              )
            : null,
      );
    }).toList();
  }
}
