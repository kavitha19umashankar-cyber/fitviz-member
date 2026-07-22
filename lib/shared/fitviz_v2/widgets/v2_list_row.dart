import 'package:flutter/material.dart';
import '../icons/fitviz_v2_icon.dart';
import '../icons/fitviz_v2_icons.dart';
import '../theme/fitviz_v2_colors.dart';
import '../theme/fitviz_v2_typography.dart';

/// Grouped account/security list row (used on Profile) — not a stacked
/// boxed field.
class V2ListRow extends StatelessWidget {
  final FitVizV2Icon icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const V2ListRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: FitVizV2Colors.border))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: FitVizV2Colors.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: FitVizV2IconView(icon, size: 16, color: FitVizV2Colors.accent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: FitVizV2Text.caption()),
                  const SizedBox(height: 2),
                  Text(value, style: FitVizV2Text.body(size: 14, weight: FontWeight.w600)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
