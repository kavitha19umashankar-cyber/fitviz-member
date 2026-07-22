import 'package:flutter/material.dart';
import '../icons/fitviz_v2_icon.dart';
import '../icons/fitviz_v2_icons.dart';
import '../theme/fitviz_v2_colors.dart';
import '../theme/fitviz_v2_typography.dart';

/// Underline-style field: transparent background, 1px bottom border,
/// leading icon, ink-dim placeholder — not a filled pill.
class V2UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final FitVizV2Icon leadingIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final int? maxLength;

  const V2UnderlineField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.leadingIcon,
    this.obscureText = false,
    this.keyboardType,
    this.trailing,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FitVizV2Colors.border)),
      ),
      child: Row(
        children: [
          FitVizV2IconView(leadingIcon, size: 18, color: FitVizV2Colors.inkDim),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              validator: validator,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              maxLength: maxLength,
              style: FitVizV2Text.body(size: 15),
              cursorColor: FitVizV2Colors.accent,
              decoration: InputDecoration(
                counterText: '',
                hintText: placeholder,
                hintStyle: FitVizV2Text.body(size: 15, color: FitVizV2Colors.inkDim),
                border: InputBorder.none,
                errorStyle: const TextStyle(color: FitVizV2Colors.danger, fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
