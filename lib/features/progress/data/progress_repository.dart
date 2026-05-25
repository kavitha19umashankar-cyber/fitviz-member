import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

part 'progress_repository.g.dart';

@JsonSerializable()
class BodyMetricModel {
  final String id;
  final double? weight;
  final double? height;
  final double? bmi;
  final double? bodyFat;
  final double? muscleMass;
  final String? notes;
  final String createdAt;

  const BodyMetricModel({
    required this.id,
    this.weight,
    this.height,
    this.bmi,
    this.bodyFat,
    this.muscleMass,
    this.notes,
    required this.createdAt,
  });

  factory BodyMetricModel.fromJson(Map<String, dynamic> json) =>
      _$BodyMetricModelFromJson(json);
  Map<String, dynamic> toJson() => _$BodyMetricModelToJson(this);
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.read(dioProvider));
});

class ProgressRepository {
  final Dio _dio;
  ProgressRepository(this._dio);

  Future<List<BodyMetricModel>> getMyMetrics() async {
    final res = await _dio.get(ApiConstants.myMetrics);
    final list = (res.data as List<dynamic>?) ?? [];
    return list
        .map((e) => BodyMetricModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BodyMetricModel> addMetric({
    double? weight,
    double? height,
    double? bodyFat,
    double? muscleMass,
    String? notes,
  }) async {
    final res = await _dio.post(ApiConstants.bodyMetrics, data: {
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (bodyFat != null) 'bodyFat': bodyFat,
      if (muscleMass != null) 'muscleMass': muscleMass,
      if (notes != null) 'notes': notes,
    });
    return BodyMetricModel.fromJson(res.data as Map<String, dynamic>);
  }
}
