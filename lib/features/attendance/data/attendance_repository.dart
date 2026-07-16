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

/// A single check-in/check-out cycle. A day can have more than one of these
/// (e.g. a member visiting the gym twice in one day).
class AttendanceSession {
  final String id;
  final String? checkIn;
  final String? checkOut;

  const AttendanceSession({required this.id, this.checkIn, this.checkOut});

  bool get isComplete => checkIn != null && checkOut != null;

  DateTime? get checkInTime =>
      checkIn != null ? DateTime.tryParse(checkIn!)?.toLocal() : null;
  DateTime? get checkOutTime =>
      checkOut != null ? DateTime.tryParse(checkOut!)?.toLocal() : null;

  factory AttendanceSession.fromJson(Map<String, dynamic> json) =>
      AttendanceSession(
        id: json['id'] as String,
        checkIn: json['checkIn'] as String?,
        checkOut: json['checkOut'] as String?,
      );
}

/// All of a member's sessions on a single calendar day, with the day's
/// combined duration already summed up.
class AttendanceDay {
  final String date;
  final List<AttendanceSession> sessions;
  final int totalMinutes;

  const AttendanceDay({
    required this.date,
    required this.sessions,
    required this.totalMinutes,
  });

  DateTime get localDate => (DateTime.tryParse(date) ?? DateTime.now()).toLocal();

  bool get isToday {
    final d = localDate;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// True once every session on this day has been checked out.
  bool get isComplete => sessions.isNotEmpty && sessions.every((s) => s.isComplete);

  Duration get totalDuration => Duration(minutes: totalMinutes);

  factory AttendanceDay.fromJson(Map<String, dynamic> json) => AttendanceDay(
        date: json['date'] as String,
        sessions: (json['sessions'] as List<dynamic>? ?? [])
            .map((e) => AttendanceSession.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      );
}

class AttendanceResult {
  final List<AttendanceRecord> records;
  final List<AttendanceDay> days;
  final AttendanceStats? stats;
  const AttendanceResult({required this.records, this.days = const [], this.stats});
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
    final dayList = (raw is Map ? raw['days'] : null) as List<dynamic>? ?? [];
    final days = dayList
        .map((e) => AttendanceDay.fromJson(e as Map<String, dynamic>))
        .toList();
    AttendanceStats? stats;
    if (raw is Map && raw['stats'] != null) {
      stats = AttendanceStats.fromJson(raw['stats'] as Map<String, dynamic>);
    }
    return AttendanceResult(records: records, days: days, stats: stats);
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
