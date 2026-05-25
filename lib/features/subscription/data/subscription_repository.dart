import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

part 'subscription_repository.g.dart';

@JsonSerializable()
class PlanModel {
  final String id;
  final String name;
  final String? description;
  final double? price;
  final int? durationDays;
  final String? category;
  final List<String>? features;

  const PlanModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.durationDays,
    this.category,
    this.features,
  });

  String get durationLabel {
    final days = durationDays;
    if (days == null) return 'N/A';
    if (days >= 365) return '${(days / 365).round()} Year';
    if (days >= 30) return '${(days / 30).round()} Month';
    return '$days Days';
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) =>
      _$PlanModelFromJson(json);
  Map<String, dynamic> toJson() => _$PlanModelToJson(this);
}

@JsonSerializable()
class RazorpayOrderModel {
  final String orderId;
  final double amount;
  final String currency;
  final String? planId;

  const RazorpayOrderModel({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.planId,
  });

  factory RazorpayOrderModel.fromJson(Map<String, dynamic> json) =>
      _$RazorpayOrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$RazorpayOrderModelToJson(this);
}

@JsonSerializable()
class PaymentHistoryModel {
  final String id;
  final double amount;
  final String status;
  final String? createdAt;
  final Map<String, dynamic>? subscription;

  const PaymentHistoryModel({
    required this.id,
    required this.amount,
    required this.status,
    this.createdAt,
    this.subscription,
  });

  String get planName =>
      (subscription?['plan']?['name'] as String?) ?? 'Subscription';

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentHistoryModelFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentHistoryModelToJson(this);
}

class SubscriptionHistoryModel {
  final String id;
  final String? startDate;
  final String? endDate;
  final String status;
  final String? paymentStatus;
  final double? amountPaid;
  final Map<String, dynamic>? plan;

  const SubscriptionHistoryModel({
    required this.id,
    this.startDate,
    this.endDate,
    required this.status,
    this.paymentStatus,
    this.amountPaid,
    this.plan,
  });

  String get planName => (plan?['name'] as String?) ?? 'Unknown Plan';

  factory SubscriptionHistoryModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionHistoryModel(
        id: json['id'] as String,
        startDate: json['startDate'] as String?,
        endDate: json['endDate'] as String?,
        status: json['status'] as String? ?? '',
        paymentStatus: json['paymentStatus'] as String?,
        amountPaid: (json['amountPaid'] as num?)?.toDouble(),
        plan: json['plan'] as Map<String, dynamic>?,
      );
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.read(dioProvider));
});

class SubscriptionRepository {
  final Dio _dio;
  SubscriptionRepository(this._dio);

  Future<List<PlanModel>> getPlans() async {
    final res = await _dio.get(ApiConstants.subscriptionPlans);
    final list = (res.data as List<dynamic>?) ?? [];
    return list
        .map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RazorpayOrderModel> createOrder(String planId) async {
    final res = await _dio
        .post(ApiConstants.createOrder, data: {'planId': planId});
    return RazorpayOrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> verifyPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required String planId,
  }) async {
    await _dio.post(ApiConstants.verifyPayment, data: {
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
      'planId': planId,
    });
  }

  Future<List<PaymentHistoryModel>> getPaymentHistory() async {
    final res = await _dio.get(ApiConstants.paymentHistory);
    final list = (res.data as List<dynamic>?) ?? [];
    return list
        .map((e) => PaymentHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SubscriptionHistoryModel>> getSubscriptionHistory() async {
    final res = await _dio.get(ApiConstants.mySubscriptionHistory);
    final list = (res.data as List<dynamic>?) ?? [];
    return list
        .map((e) =>
            SubscriptionHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
