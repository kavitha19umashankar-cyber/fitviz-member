import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/fitviz_v2_colors.dart';
import 'fitviz_v2_icons.dart';

/// Renders a [FitVizV2Icon] tinted via ColorFilter (doesn't rely on
/// `currentColor` propagation through flutter_svg's asset loader).
class FitVizV2IconView extends StatelessWidget {
  final FitVizV2Icon icon;
  final double size;
  final Color color;

  const FitVizV2IconView(
    this.icon, {
    super.key,
    this.size = 18,
    this.color = FitVizV2Colors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
