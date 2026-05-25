// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutEntry _$WorkoutEntryFromJson(Map<String, dynamic> json) => WorkoutEntry(
      id: json['id'] as String,
      workoutTitle: json['workoutTitle'] as String?,
      workoutDetail: json['workoutDetail'] as String?,
      focus: json['focus'] as String?,
      dayName: json['dayName'] as String?,
      isRestDay: json['isRestDay'] as bool? ?? false,
    );

Map<String, dynamic> _$WorkoutEntryToJson(WorkoutEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workoutTitle': instance.workoutTitle,
      'workoutDetail': instance.workoutDetail,
      'focus': instance.focus,
      'dayName': instance.dayName,
      'isRestDay': instance.isRestDay,
    };

DietEntry _$DietEntryFromJson(Map<String, dynamic> json) => DietEntry(
      id: json['id'] as String,
      dietType: json['dietType'] as String?,
      dayName: json['dayName'] as String?,
      meals: json['meals'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DietEntryToJson(DietEntry instance) => <String, dynamic>{
      'id': instance.id,
      'dietType': instance.dietType,
      'dayName': instance.dayName,
      'meals': instance.meals,
    };

DailyPlan _$DailyPlanFromJson(Map<String, dynamic> json) => DailyPlan(
      id: json['id'] as String,
      planDate: json['planDate'] as String,
      status: json['status'] as String,
      isRestDay: json['isRestDay'] as bool? ?? false,
      workoutEntry: json['workoutEntry'] == null
          ? null
          : WorkoutEntry.fromJson(json['workoutEntry'] as Map<String, dynamic>),
      dietEntry: json['dietEntry'] == null
          ? null
          : DietEntry.fromJson(json['dietEntry'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DailyPlanToJson(DailyPlan instance) => <String, dynamic>{
      'id': instance.id,
      'planDate': instance.planDate,
      'status': instance.status,
      'isRestDay': instance.isRestDay,
      'workoutEntry': instance.workoutEntry,
      'dietEntry': instance.dietEntry,
    };
