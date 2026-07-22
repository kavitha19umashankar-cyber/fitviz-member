import 'package:flutter/material.dart';
import '../icons/fitviz_v2_icon.dart';
import '../icons/fitviz_v2_icons.dart';
import '../theme/fitviz_v2_colors.dart';
import '../theme/fitviz_v2_typography.dart';
import 'v2_pill_button.dart';

/// Actionable empty state: icon + explanation + CTA, not bare centered text.
class V2EmptyState extends StatelessWidget {
  final FitVizV2Icon icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const V2EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FitVizV2Colors.surface,
                border: Border.all(color: FitVizV2Colors.border),
              ),
              child: Center(child: FitVizV2IconView(icon, size: 24, color: FitVizV2Colors.inkDim)),
            ),
            const SizedBox(height: 14),
            Text(title, style: FitVizV2Text.body(size: 15, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim),
            ),
            if (ctaLabel != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 200,
                child: V2PillButton(label: ctaLabel!, onTap: onCta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
