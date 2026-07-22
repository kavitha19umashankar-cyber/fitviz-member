import 'package:flutter/material.dart';
import '../theme/fitviz_v2_colors.dart';
import '../theme/fitviz_v2_metrics.dart';

/// 2-segment pill control — active segment gets accent fill + accent-ink
/// text. Used for Today/History, Check In/History, Schedule/My Bookings.
class V2SegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const V2SegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FitVizV2Colors.surface,
        borderRadius: BorderRadius.circular(FitVizV2Radius.pill),
        border: Border.all(color: FitVizV2Colors.border),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? FitVizV2Colors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(FitVizV2Radius.pill),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? FitVizV2Colors.accentInk : FitVizV2Colors.inkDim,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
