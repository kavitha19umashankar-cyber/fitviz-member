// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanModel _$PlanModelFromJson(Map<String, dynamic> json) => PlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      durationDays: (json['durationDays'] as num?)?.toInt(),
      category: json['category'] as String?,
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PlanModelToJson(PlanModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'durationDays': instance.durationDays,
      'category': instance.category,
      'features': instance.features,
    };

RazorpayOrderModel _$RazorpayOrderModelFromJson(Map<String, dynamic> json) =>
    RazorpayOrderModel(
      orderId: json['orderId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      planId: json['planId'] as String?,
    );

Map<String, dynamic> _$RazorpayOrderModelToJson(RazorpayOrderModel instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'amount': instance.amount,
      'currency': instance.currency,
      'planId': instance.planId,
    };

PaymentHistoryModel _$PaymentHistoryModelFromJson(Map<String, dynamic> json) =>
    PaymentHistoryModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['createdAt'] as String?,
      subscription: json['subscription'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PaymentHistoryModelToJson(
        PaymentHistoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'subscription': instance.subscription,
    };
