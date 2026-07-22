import 'package:flutter/material.dart';

/// FitViz v2 spacing / radius / elevation tokens.
class FitVizV2Spacing {
  FitVizV2Spacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class FitVizV2Radius {
  FitVizV2Radius._();

  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double pill = 999;
}

class FitVizV2Shadows {
  FitVizV2Shadows._();

  /// Soft directional shadow — the only elevation style in the v2 system.
  /// No flat drop-shadows; cards otherwise sit on a 1px border hairline.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x73000000), // rgba(0,0,0,.45)
      offset: Offset(0, 10),
      blurRadius: 26,
    ),
  ];
}
