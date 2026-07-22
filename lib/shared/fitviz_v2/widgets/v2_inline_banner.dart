import 'package:flutter/material.dart';
import '../icons/fitviz_v2_icon.dart';
import '../icons/fitviz_v2_icons.dart';
import '../theme/fitviz_v2_colors.dart';
import '../theme/fitviz_v2_metrics.dart';

enum V2BannerVariant { success, warning, danger }

/// Low-opacity semantic-tinted row — e.g. the "Check your WhatsApp" OTP
/// reassurance message.
class V2InlineBanner extends StatelessWidget {
  final String text;
  final FitVizV2Icon icon;
  final V2BannerVariant variant;

  const V2InlineBanner({
    super.key,
    required this.text,
    required this.icon,
    this.variant = V2BannerVariant.success,
  });

  ({Color bg, Color border, Color fg}) _colors() {
    switch (variant) {
      case V2BannerVariant.success:
        return (bg: const Color(0x1A4ADE80), border: const Color(0x404ADE80), fg: FitVizV2Colors.success);
      case V2BannerVariant.warning:
        return (bg: const Color(0x1AF5B942), border: const Color(0x40F5B942), fg: FitVizV2Colors.warning);
      case V2BannerVariant.danger:
        return (bg: const Color(0x1AF5595E), border: const Color(0x40F5595E), fg: FitVizV2Colors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(FitVizV2Radius.md),
      ),
      child: Row(
        children: [
          FitVizV2IconView(icon, size: 15, color: c.fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: c.fg, fontSize: 12))),
        ],
      ),
    );
  }
}
