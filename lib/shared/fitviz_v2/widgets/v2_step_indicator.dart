import 'package:flutter/material.dart';
import '../theme/fitviz_v2_colors.dart';

/// Dot-and-connecting-line stepper for the password-reset flow.
/// `done` fills dot/line accent; `active` is a hollow dot with an accent
/// glow ring; upcoming steps stay on surface-2/border.
class V2StepIndicator extends StatelessWidget {
  final int stepCount;
  final int currentStep; // 0-indexed

  const V2StepIndicator({super.key, this.stepCount = 3, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < stepCount; i++) {
      final done = i < currentStep;
      final active = i == currentStep;
      children.add(_Dot(done: done, active: active));
      if (i < stepCount - 1) {
        children.add(_Line(done: i < currentStep));
      }
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }
}

class _Dot extends StatelessWidget {
  final bool done;
  final bool active;
  const _Dot({required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? FitVizV2Colors.accent : (active ? FitVizV2Colors.bg : FitVizV2Colors.surface2),
        border: Border.all(
          color: (done || active) ? FitVizV2Colors.accent : FitVizV2Colors.border,
          width: 2,
        ),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x2EC9FF4D), blurRadius: 0, spreadRadius: 3)]
            : null,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final bool done;
  const _Line({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 2,
      color: done ? FitVizV2Colors.accent : FitVizV2Colors.border,
    );
  }
}
