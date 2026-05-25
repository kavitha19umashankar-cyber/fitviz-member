import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

part 'dashboard_repository.g.dart';

// ── Models ──────────────────────────────────────────────────────────────────

@JsonSerializable()
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final bool isPinned;
  final String? category;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.isPinned = false,
    this.category,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementModelFromJson(json);
}

@JsonSerializable()
class OfferModel {
  final String id;
  final String title;
  final String? description;
  final double? discount;
  final String? validTo;
  final String? badge;
  final String? image;

  const OfferModel({
    required this.id,
    required this.title,
    this.description,
    this.discount,
    this.validTo,
    this.badge,
    this.image,
  });

  // image is a relative server path — prepend base URL for display
  String? get imageUrl => image != null ? 'https://fitviz.in$image' : null;

  factory OfferModel.fromJson(Map<String, dynamic> json) =>
      _$OfferModelFromJson(json);
}

@JsonSerializable()
class SubscriptionStatusModel {
  final String id;
  final String status;
  final String? startDate;
  final String? endDate;
  final Map<String, dynamic>? plan;

  const SubscriptionStatusModel({
    required this.id,
    required this.status,
    this.startDate,
    this.endDate,
    this.plan,
  });

  String get planName => (plan?['name'] as String?) ?? 'Unknown Plan';

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusModelFromJson(json);
}

// ── Repository ───────────────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(dioProvider));
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<List<AnnouncementModel>> getAnnouncements() async {
    final res = await _dio.get(ApiConstants.activeAnnouncements);
    final list = (res.data as List<dynamic>?) ?? [];
    return list
        .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OfferModel>> getOffers() async {
    final res = await _dio.get(ApiConstants.activeOffers);
    debugPrint('[OFFERS] raw response: ${res.data}');
    final list = (res.data as List<dynamic>?) ?? [];
    return list
        .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionStatusModel?> getMySubscription() async {
    try {
      final res = await _dio.get(ApiConstants.mySubscription);
      if (res.data == null) return null;
      return SubscriptionStatusModel.fromJson(
          res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
