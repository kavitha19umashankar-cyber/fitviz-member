import 'package:flutter/material.dart';
import '../theme/fitviz_v2_colors.dart';
import '../theme/fitviz_v2_metrics.dart';

enum V2PillButtonVariant { accent, outline, disabled }

/// Full-width pill button. `accent` = primary action, `disabled` = inactive
/// state (e.g. OTP screen until all digits entered), `outline` = secondary.
class V2PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final V2PillButtonVariant variant;
  final Widget? leading;
  final bool loading;

  const V2PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = V2PillButtonVariant.accent,
    this.leading,
    this.loading = false,
  });

  bool get _isDisabled => variant == V2PillButtonVariant.disabled || onTap == null;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    BoxBorder? border;
    switch (variant) {
      case V2PillButtonVariant.accent:
        bg = FitVizV2Colors.accent;
        fg = FitVizV2Colors.accentInk;
        break;
      case V2PillButtonVariant.outline:
        bg = Colors.transparent;
        fg = FitVizV2Colors.ink;
        border = Border.all(color: FitVizV2Colors.border);
        break;
      case V2PillButtonVariant.disabled:
        bg = FitVizV2Colors.surface2;
        fg = FitVizV2Colors.inkDim;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(FitVizV2Radius.pill),
        onTap: _isDisabled ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(FitVizV2Radius.pill),
            border: border,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else ...[
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Text(
                  label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 52px circular action button — the auth flow's "continue" affordance.
class V2CircularActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;

  const V2CircularActionButton({super.key, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: FitVizV2Colors.accent,
            boxShadow: const [
              BoxShadow(
                color: Color(0x59C9FF4D), // rgba(201,255,77,.35)
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
