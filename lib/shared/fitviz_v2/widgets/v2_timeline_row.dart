import 'package:flutter/material.dart';
import '../theme/fitviz_v2_colors.dart';

enum V2TimelineDotState { on, off, pending, neutral }

/// One row of a connected vertical timeline — a dot with a connecting line
/// down to the next item, plus arbitrary body content.
class V2TimelineRow extends StatelessWidget {
  final V2TimelineDotState dotState;
  final Widget body;
  final bool isLast;

  const V2TimelineRow({
    super.key,
    required this.dotState,
    required this.body,
    this.isLast = false,
  });

  Color get _dotColor {
    switch (dotState) {
      case V2TimelineDotState.on:
        return FitVizV2Colors.success;
      case V2TimelineDotState.off:
        return FitVizV2Colors.danger;
      case V2TimelineDotState.pending:
        return FitVizV2Colors.warning;
      case V2TimelineDotState.neutral:
        return FitVizV2Colors.inkDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 11,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _dotColor),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.only(top: 2),
                        color: FitVizV2Colors.border,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
