import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(ref.read(dioProvider));
});

class FeedbackRepository {
  final Dio _dio;
  FeedbackRepository(this._dio);

  Future<void> submitFeedback({
    required int npsScore,
    required int overallRating,
    int? cleanliness,
    int? equipment,
    int? staff,
    int? trainers,
    String? comment,
  }) async {
    await _dio.post(ApiConstants.feedback, data: {
      'npsScore': npsScore,
      'overallRating': overallRating,
      if (cleanliness != null) 'cleanliness': cleanliness,
      if (equipment != null) 'equipment': equipment,
      if (staff != null) 'staff': staff,
      if (trainers != null) 'trainers': trainers,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  Future<String?> getReferralCode() async {
    try {
      final res = await _dio.get(ApiConstants.referralCode);
      final data = res.data;
      if (data is Map) return data['code'] as String? ?? data['referralCode'] as String?;
      return null;
    } catch (_) {
      return null;
    }
  }
}
