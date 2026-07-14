import 'package:flutter/material.dart';

enum Flavor { fitviz, k2fitness }

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String appTagline;
  // null = show ALL gyms (FitViz generic app).
  // non-null = restrict gym list to this parent + its child branches.
  // The user still selects their specific home branch at registration.
  final String? brandParentGymId;
  final Color primaryColor;
  final String logoAssetPath;
  // null = no support contact shown on the login screen.
  final String? contactPhone;

  const FlavorConfig({
    required this.flavor,
    required this.appName,
    this.appTagline = 'Your Fitness Journey',
    this.brandParentGymId,
    required this.primaryColor,
    required this.logoAssetPath,
    this.contactPhone,
  });

  static late FlavorConfig instance;

  bool get hasBrandFilter => brandParentGymId != null;
}
