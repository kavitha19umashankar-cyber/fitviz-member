// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceRecord _$AttendanceRecordFromJson(Map<String, dynamic> json) =>
    AttendanceRecord(
      id: json['id'] as String,
      date: json['date'] as String,
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$AttendanceRecordToJson(AttendanceRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'checkIn': instance.checkIn,
      'checkOut': instance.checkOut,
      'notes': instance.notes,
    };
