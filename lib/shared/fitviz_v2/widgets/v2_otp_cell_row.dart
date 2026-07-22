import 'package:flutter/material.dart';
import '../theme/fitviz_v2_colors.dart';

/// 6-cell tabular OTP digit row. `filled` = accent border+text, `active`
/// (currently-typing) = accent border + soft glow ring, no digit yet.
class V2OtpCellRow extends StatelessWidget {
  final String value; // up to 6 digits
  final int length;

  const V2OtpCellRow({super.key, required this.value, this.length = 6});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final filled = i < value.length;
        final active = i == value.length;
        return Padding(
          padding: EdgeInsets.only(right: i < length - 1 ? 10 : 0),
          child: _V2OtpCell(
            digit: filled ? value[i] : null,
            filled: filled,
            active: active,
          ),
        );
      }),
    );
  }
}

class _V2OtpCell extends StatelessWidget {
  final String? digit;
  final bool filled;
  final bool active;

  const _V2OtpCell({required this.digit, required this.filled, required this.active});

  @override
  Widget build(BuildContext context) {
    final borderColor = (filled || active) ? FitVizV2Colors.accent : FitVizV2Colors.border;
    return Container(
      width: 42,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FitVizV2Colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x2EC9FF4D), blurRadius: 0, spreadRadius: 3)]
            : null,
      ),
      child: Text(
        digit ?? '',
        style: TextStyle(
          fontFamily: 'monospace',
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w700,
          fontSize: 19,
          color: filled ? FitVizV2Colors.accent : FitVizV2Colors.ink,
        ),
      ),
    );
  }
}
