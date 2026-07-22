import 'package:flutter/material.dart';
import 'fitviz_v2_colors.dart';

/// FitViz v2 typography — system-stack fonts only (no custom font files to
/// license/embed), matching the design spec's three font roles:
///   display — headings/wordmark/hero numerals, weight 800, tight tracking
///   body    — body copy, labels, buttons, system default
///   data    — timers, stat numbers, OTP digits; monospace + tabular figures
class FitVizV2Text {
  FitVizV2Text._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle display({
    double size = 21,
    Color color = FitVizV2Colors.ink,
    double letterSpacing = -0.3,
  }) =>
      TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: size,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.15,
      );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = FitVizV2Colors.ink,
  }) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.4);

  static TextStyle caption({
    Color color = FitVizV2Colors.inkDim,
    double letterSpacing = 0.08,
  }) =>
      TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.2,
      );

  static TextStyle data({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = FitVizV2Colors.ink,
  }) =>
      TextStyle(
        fontFamily: 'monospace',
        fontFeatures: _tabular,
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  // ── Named scale (H1/H2/Body/Caption/Stat) ──────────────────────────────
  static TextStyle h1({Color color = FitVizV2Colors.ink}) =>
      display(size: 23, color: color, letterSpacing: -0.35);
  static TextStyle h2({Color color = FitVizV2Colors.ink}) =>
      display(size: 18, color: color, letterSpacing: -0.2);
  static TextStyle stat({double size = 20, Color color = FitVizV2Colors.ink}) =>
      data(size: size, weight: FontWeight.w700, color: color);
}
