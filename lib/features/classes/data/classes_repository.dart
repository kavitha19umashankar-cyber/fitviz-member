import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

part 'classes_repository.g.dart';

const _dayNames = [
  'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
];

String? _dayOfWeekFromJson(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is int && v >= 0 && v < _dayNames.length) return _dayNames[v];
  return v.toString();
}

@JsonSerializable()
class ClassScheduleModel {
  final String id;
  final String name;
  final String? description;
  final String? trainerName;
  final String? room;
  final String startTime;
  final String? endTime;
  final int? capacity;
  final int? bookedCount;
  @JsonKey(fromJson: _dayOfWeekFromJson)
  final String? dayOfWeek;
  final String? nextDate;
  final bool isBooked;
  final String? bookingId;

  const ClassScheduleModel({
    required this.id,
    required this.name,
    this.description,
    this.trainerName,
    this.room,
    required this.startTime,
    this.endTime,
    this.capacity,
    this.bookedCount,
    this.dayOfWeek,
    this.nextDate,
    this.isBooked = false,
    this.bookingId,
  });

  bool get isFull =>
      capacity != null && bookedCount != null && bookedCount! >= capacity!;
  int get spotsLeft => capacity != null && bookedCount != null
      ? capacity! - bookedCount!
      : 99;

  factory ClassScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ClassScheduleModelFromJson(json);
  Map<String, dynamic> toJson() => _$ClassScheduleModelToJson(this);
}

@JsonSerializable()
class BookingModel {
  final String id;
  @JsonKey(name: 'class')
  final ClassScheduleModel? classInfo;
  final String? status;
  final String? bookedAt;

  const BookingModel({
    required this.id,
    this.classInfo,
    this.status,
    this.bookedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);
  Map<String, dynamic> toJson() => _$BookingModelToJson(this);
}

final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  return ClassesRepository(ref.read(dioProvider));
});

class ClassesRepository {
  final Dio _dio;
  ClassesRepository(this._dio);

  Future<List<ClassScheduleModel>> getSchedule() async {
    final res = await _dio.get(ApiConstants.classSchedule);
    final list = (res.data as List<dynamic>?) ?? [];
    return list
        .map((e) => ClassScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> bookClass(String classId, String classDate) async {
    await _dio.post(ApiConstants.bookClass, data: {'classId': classId, 'classDate': classDate});
  }

  Future<List<BookingModel>> getMyBookings() async {
    final res = await _dio.get(ApiConstants.myBookings);
    final list = (res.data as List<dynamic>?) ?? [];
    return list
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelBooking(String bookingId) async {
    await _dio.delete(ApiConstants.cancelBookingById(bookingId));
  }
}
