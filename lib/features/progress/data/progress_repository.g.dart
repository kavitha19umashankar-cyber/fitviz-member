// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BodyMetricModel _$BodyMetricModelFromJson(Map<String, dynamic> json) =>
    BodyMetricModel(
      id: json['id'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      bodyFat: (json['bodyFat'] as num?)?.toDouble(),
      muscleMass: (json['muscleMass'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$BodyMetricModelToJson(BodyMetricModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weight': instance.weight,
      'height': instance.height,
      'bmi': instance.bmi,
      'bodyFat': instance.bodyFat,
      'muscleMass': instance.muscleMass,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
    };
