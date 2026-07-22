import 'package:flutter/material.dart';

/// FitViz v2 design-system color tokens.
/// Fixed dark product theme (intentional, not a light/dark switch) — used
/// exclusively by the FitViz-flavor v2 screens/widgets under
/// lib/shared/fitviz_v2/ and their corresponding *_v2.dart screens.
/// Never referenced by K2 or by legacy (non-redesigned) FitViz screens.
class FitVizV2Colors {
  FitVizV2Colors._();

  static const Color bg = Color(0xFF0A0D09);
  static const Color surface = Color(0xFF151A13);
  static const Color surface2 = Color(0xFF1E2419);
  static const Color border = Color(0xFF2A331F);
  static const Color ink = Color(0xFFF3F5EC);
  static const Color inkDim = Color(0xFF9AA394);
  static const Color accent = Color(0xFFC9FF4D);
  static const Color accentInk = Color(0xFF10150A);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF5B942);
  static const Color danger = Color(0xFFF5595E);
}
