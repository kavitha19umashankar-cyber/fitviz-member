import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'icons/fitviz_v2_icons.dart';
import 'theme/fitviz_v2_colors.dart';
import 'widgets/v2_bottom_nav.dart';

/// FitViz v2 shell: capsule bottom nav with a raised center FAB for
/// Attendance, replacing the legacy 5-tab Material BottomNavigationBar.
/// Parallel to shared/widgets/main_shell.dart — used only when
/// FlavorConfig.instance.flavor == Flavor.fitviz.
class MainShellV2 extends StatelessWidget {
  final Widget child;

  const MainShellV2({super.key, required this.child});

  static const _sideTabs = [
    V2NavItem(path: '/dashboard', icon: FitVizV2Icon.home),
    V2NavItem(path: '/workout', icon: FitVizV2Icon.dumbbell),
    V2NavItem(path: '/classes', icon: FitVizV2Icon.calendar),
    V2NavItem(path: '/profile', icon: FitVizV2Icon.user),
  ];
  static const _fabTab = V2NavItem(path: '/attendance', icon: FitVizV2Icon.grid);

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final fabActive = location.startsWith(_fabTab.path);
    final activeIndex = fabActive
        ? -1
        : _sideTabs.indexWhere((t) => location.startsWith(t.path));

    return Scaffold(
      backgroundColor: FitVizV2Colors.bg,
      extendBody: true,
      body: child,
      bottomNavigationBar: V2BottomNav(
        sideTabs: _sideTabs,
        centerFab: _fabTab,
        activeIndex: activeIndex,
        fabActive: fabActive,
        onTabTap: (i) => context.go(_sideTabs[i].path),
        onFabTap: () => context.go(_fabTab.path),
      ),
    );
  }
}
