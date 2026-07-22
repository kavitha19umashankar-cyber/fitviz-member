import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/fitviz_v2_colors.dart';
import '../theme/fitviz_v2_typography.dart';

enum V2RingSize { sm, md, lg }

/// Circular progress "ring" — Flutter has no conic-gradient primitive, so
/// this sweeps an arc via CustomPainter: accent over a surface-2 track,
/// punched surface-color center, numeral label in the data font.
class V2ProgressRing extends StatelessWidget {
  final double progress; // 0..100
  final String label;
  final V2RingSize size;
  final Color sweepColor;
  final Color? labelColor;

  const V2ProgressRing({
    super.key,
    required this.progress,
    required this.label,
    this.size = V2RingSize.md,
    this.sweepColor = FitVizV2Colors.accent,
    this.labelColor,
  });

  double get _dim {
    switch (size) {
      case V2RingSize.sm:
        return 60;
      case V2RingSize.md:
        return 88;
      case V2RingSize.lg:
        return 150;
    }
  }

  double get _fontSize {
    switch (size) {
      case V2RingSize.sm:
        return 12;
      case V2RingSize.md:
        return 16;
      case V2RingSize.lg:
        return 30;
    }
  }

  double get _strokeWidth {
    switch (size) {
      case V2RingSize.sm:
        return 6;
      case V2RingSize.md:
        return 9;
      case V2RingSize.lg:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _dim;
    return SizedBox(
      width: d,
      height: d,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0, 100) / 100,
          trackColor: FitVizV2Colors.surface2,
          sweepColor: sweepColor,
          centerColor: FitVizV2Colors.surface,
          strokeWidth: _strokeWidth,
        ),
        child: Center(
          child: Text(
            label,
            style: FitVizV2Text.stat(size: _fontSize, color: labelColor ?? FitVizV2Colors.ink),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color sweepColor;
  final Color centerColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.sweepColor,
    required this.centerColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final sweepPaint = Paint()
        ..color = sweepColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        sweepPaint,
      );
    }

    final centerPaint = Paint()..color = centerColor;
    canvas.drawCircle(center, radius - strokeWidth / 2, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.sweepColor != sweepColor ||
      oldDelegate.trackColor != trackColor;
}
