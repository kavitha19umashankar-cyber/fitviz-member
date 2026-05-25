// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnnouncementModel _$AnnouncementModelFromJson(Map<String, dynamic> json) =>
    AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isPinned: json['isPinned'] as bool? ?? false,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$AnnouncementModelToJson(AnnouncementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'isPinned': instance.isPinned,
      'category': instance.category,
    };

OfferModel _$OfferModelFromJson(Map<String, dynamic> json) => OfferModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      discount: (json['discount'] as num?)?.toDouble(),
      validTo: json['validTo'] as String?,
      badge: json['badge'] as String?,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$OfferModelToJson(OfferModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'discount': instance.discount,
      'validTo': instance.validTo,
      'badge': instance.badge,
      'image': instance.image,
    };

SubscriptionStatusModel _$SubscriptionStatusModelFromJson(
        Map<String, dynamic> json) =>
    SubscriptionStatusModel(
      id: json['id'] as String,
      status: json['status'] as String,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      plan: json['plan'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SubscriptionStatusModelToJson(
        SubscriptionStatusModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'plan': instance.plan,
    };
