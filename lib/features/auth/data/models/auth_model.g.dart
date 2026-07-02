// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      gymId: json['gymId'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      mobileAppEnabled: json['mobileAppEnabled'] as bool? ?? true,
      memberProfile: json['memberProfile'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.role,
      'gymId': instance.gymId,
      'profilePhoto': instance.profilePhoto,
      'isActive': instance.isActive,
      'mobileAppEnabled': instance.mobileAppEnabled,
      'memberProfile': instance.memberProfile,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'user': instance.user,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };

GymModel _$GymModelFromJson(Map<String, dynamic> json) => GymModel(
      id: json['id'] as String,
      gymCode: json['gymId'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      area: json['area'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      loginToken: json['loginToken'] as String?,
      parentGymId: json['parentGymId'] as String?,
      branding: json['brandingConfig'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GymModelToJson(GymModel instance) => <String, dynamic>{
      'id': instance.id,
      'gymId': instance.gymCode,
      'name': instance.name,
      'slug': instance.slug,
      'area': instance.area,
      'address': instance.address,
      'city': instance.city,
      'phone': instance.phone,
      'loginToken': instance.loginToken,
      'parentGymId': instance.parentGymId,
      'brandingConfig': instance.branding,
    };
