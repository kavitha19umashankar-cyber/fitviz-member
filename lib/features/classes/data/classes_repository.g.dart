// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classes_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassScheduleModel _$ClassScheduleModelFromJson(Map<String, dynamic> json) =>
    ClassScheduleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      trainerName: json['trainerName'] as String?,
      room: json['room'] as String?,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      bookedCount: (json['bookedCount'] as num?)?.toInt(),
      dayOfWeek: _dayOfWeekFromJson(json['dayOfWeek']),
      nextDate: json['nextDate'] as String?,
      isBooked: json['isBooked'] as bool? ?? false,
      bookingId: json['bookingId'] as String?,
    );

Map<String, dynamic> _$ClassScheduleModelToJson(ClassScheduleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'trainerName': instance.trainerName,
      'room': instance.room,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'capacity': instance.capacity,
      'bookedCount': instance.bookedCount,
      'dayOfWeek': instance.dayOfWeek,
      'nextDate': instance.nextDate,
      'isBooked': instance.isBooked,
      'bookingId': instance.bookingId,
    };

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) => BookingModel(
      id: json['id'] as String,
      classInfo: json['class'] == null
          ? null
          : ClassScheduleModel.fromJson(json['class'] as Map<String, dynamic>),
      status: json['status'] as String?,
      bookedAt: json['bookedAt'] as String?,
    );

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'class': instance.classInfo,
      'status': instance.status,
      'bookedAt': instance.bookedAt,
    };
