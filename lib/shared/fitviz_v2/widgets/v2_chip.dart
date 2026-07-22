import 'package:flutter/material.dart';
import '../theme/fitviz_v2_colors.dart';
import '../theme/fitviz_v2_metrics.dart';

enum V2ChipVariant { neutral, accent, success, warning, danger }

class V2Chip extends StatelessWidget {
  final String label;
  final V2ChipVariant variant;
  final Widget? leading;

  const V2Chip({
    super.key,
    required this.label,
    this.variant = V2ChipVariant.neutral,
    this.leading,
  });

  ({Color bg, Color fg}) _colors() {
    switch (variant) {
      case V2ChipVariant.neutral:
        return (bg: FitVizV2Colors.surface2, fg: FitVizV2Colors.inkDim);
      case V2ChipVariant.accent:
        return (bg: const Color(0x24C9FF4D), fg: FitVizV2Colors.accent);
      case V2ChipVariant.success:
        return (bg: const Color(0x294ADE80), fg: FitVizV2Colors.success);
      case V2ChipVariant.warning:
        return (bg: const Color(0x29F5B942), fg: FitVizV2Colors.warning);
      case V2ChipVariant.danger:
        return (bg: const Color(0x29F5595E), fg: FitVizV2Colors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(FitVizV2Radius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              color: c.fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
