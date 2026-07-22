import 'package:flutter/material.dart';
import '../icons/fitviz_v2_icon.dart';
import '../icons/fitviz_v2_icons.dart';
import '../theme/fitviz_v2_colors.dart';

class V2NavItem {
  final String path;
  final FitVizV2Icon icon;
  const V2NavItem({required this.path, required this.icon});
}

/// Flat-docked capsule bottom nav, rounded top corners only, 4 icon-only
/// tabs split 2-and-2, with a raised center FAB (Attendance) elevated
/// above the bar line. Active side-tabs get a 4px accent dot; the FAB
/// gets an outer accent ring when the Attendance section is active.
class V2BottomNav extends StatelessWidget {
  final List<V2NavItem> sideTabs; // exactly 4: 2 left, 2 right
  final V2NavItem centerFab;
  final int activeIndex; // index into sideTabs, or -1 if FAB section active
  final bool fabActive;
  final ValueChanged<int> onTabTap;
  final VoidCallback onFabTap;

  const V2BottomNav({
    super.key,
    required this.sideTabs,
    required this.centerFab,
    required this.activeIndex,
    required this.fabActive,
    required this.onTabTap,
    required this.onFabTap,
  }) : assert(sideTabs.length == 4);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xF00E110B), // rgba(14,17,11,.94)
                border: const Border(top: BorderSide(color: FitVizV2Colors.border)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _tab(sideTabs[0], 0),
                        _tab(sideTabs[1], 1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 58),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _tab(sideTabs[2], 2),
                        _tab(sideTabs[3], 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            child: GestureDetector(
              onTap: onFabTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FitVizV2Colors.accent,
                  border: Border.all(color: FitVizV2Colors.bg, width: 4),
                  boxShadow: [
                    if (fabActive)
                      const BoxShadow(color: Color(0x4DC9FF4D), blurRadius: 0, spreadRadius: 3),
                    const BoxShadow(color: Color(0x59C9FF4D), blurRadius: 22, offset: Offset(0, 10)),
                    const BoxShadow(color: Color(0x73000000), blurRadius: 14, offset: Offset(0, 6)),
                  ],
                ),
                child: Center(
                  child: FitVizV2IconView(centerFab.icon, size: 22, color: FitVizV2Colors.accentInk),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(V2NavItem item, int index) {
    final active = index == activeIndex;
    return GestureDetector(
      onTap: () => onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FitVizV2IconView(
              item.icon,
              size: 19,
              color: active ? FitVizV2Colors.ink : FitVizV2Colors.inkDim,
            ),
            const SizedBox(height: 5),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? FitVizV2Colors.accent : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
