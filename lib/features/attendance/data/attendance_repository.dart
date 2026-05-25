import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

part 'attendance_repository.g.dart';

@JsonSerializable()
class AttendanceRecord {
  final String id;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.notes,
  });

  bool get isCheckedIn => checkIn != null && checkOut == null;
  bool get isComplete => checkIn != null && checkOut != null;

  DateTime? get checkInTime =>
      checkIn != null ? DateTime.tryParse(checkIn!)?.toLocal() : null;
  DateTime? get checkOutTime =>
      checkOut != null ? DateTime.tryParse(checkOut!)?.toLocal() : null;

  DateTime get localDate =>
      (DateTime.tryParse(date) ?? DateTime.now()).toLocal();

  bool get isToday {
    final d = localDate;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Duration? get duration {
    final ci = checkInTime;
    final co = checkOutTime;
    if (ci == null || co == null) return null;
    final diff = co.difference(ci);
    return diff.isNegative ? null : diff;
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordFromJson(json);
}

class AttendanceStats {
  final int totalDays;
  final double totalHours;
  final int month;
  final int year;

  const AttendanceStats({
    required this.totalDays,
    required this.totalHours,
    required this.month,
    required this.year,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) =>
      AttendanceStats(
        totalDays: (json['totalDays'] as num?)?.toInt() ?? 0,
        totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0,
        month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
        year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      );
}

class AttendanceResult {
  final List<AttendanceRecord> records;
  final AttendanceStats? stats;
  const AttendanceResult({required this.records, this.stats});
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.read(dioProvider));
});

class AttendanceRepository {
  final Dio _dio;

  AttendanceRepository(this._dio);

  Future<AttendanceResult> getMyAttendance({int? month, int? year}) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    final res = await _dio.get(
      ApiConstants.myAttendance,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final raw = res.data;
    final list = (raw is Map ? raw['records'] : raw) as List<dynamic>? ?? [];
    final records = list
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    AttendanceStats? stats;
    if (raw is Map && raw['stats'] != null) {
      stats = AttendanceStats.fromJson(raw['stats'] as Map<String, dynamic>);
    }
    return AttendanceResult(records: records, stats: stats);
  }

  Future<AttendanceRecord> checkIn() async {
    final res = await _dio.post(ApiConstants.checkin);
    return AttendanceRecord.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AttendanceRecord> checkOut() async {
    final res = await _dio.post(ApiConstants.checkout);
    return AttendanceRecord.fromJson(res.data as Map<String, dynamic>);
  }
}
