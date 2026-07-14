import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String role;
  final String? gymId;
  final String? profilePhoto;
  final bool isActive;
  @JsonKey(defaultValue: true)
  final bool mobileAppEnabled;
  final Map<String, dynamic>? memberProfile;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.gymId,
    this.profilePhoto,
    this.isActive = true,
    this.mobileAppEnabled = true,
    this.memberProfile,
  });

  int? get membershipId => (memberProfile?['membershipId'] as num?)?.toInt();

  String? get fullProfilePhotoUrl =>
      profilePhoto != null ? 'https://fitviz.in$profilePhoto' : null;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class GymModel {
  final String id;
  @JsonKey(name: 'gymId')
  final String gymCode;
  final String name;
  final String? slug;
  final String? area;
  final String? address;
  final String? city;
  final String? phone;
  final String? loginToken;
  // null = this is a standalone/parent gym; non-null = this is a child branch
  final String? parentGymId;
  @JsonKey(name: 'brandingConfig')
  final Map<String, dynamic>? branding;

  const GymModel({
    required this.id,
    required this.gymCode,
    required this.name,
    this.slug,
    this.area,
    this.address,
    this.city,
    this.phone,
    this.loginToken,
    this.parentGymId,
    this.branding,
  });

  bool get isChildBranch => parentGymId != null;

  String? get logoUrl => branding?['logoUrl'] as String?;
  String? get fullLogoUrl =>
      logoUrl != null ? 'https://fitviz.in$logoUrl' : null;
  String? get primaryColor => branding?['primaryColor'] as String?;

  factory GymModel.fromJson(Map<String, dynamic> json) =>
      _$GymModelFromJson(json);
  Map<String, dynamic> toJson() => _$GymModelToJson(this);
}
