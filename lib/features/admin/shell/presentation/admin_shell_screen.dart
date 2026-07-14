import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';

/// Root of the admin area: five destinations over an indexed stack, so each
/// tab keeps its own navigation and list state.
///
/// Phones get the app's Material 3 bottom bar; from a tablet width the same
/// destinations become a `NavigationRail`. The destinations, the index and the
/// branch switching are shared — only the chrome changes.
class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _AdminDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Tổng quan',
    ),
    _AdminDestination(
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check_rounded,
      label: 'Phê duyệt',
    ),
    _AdminDestination(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      label: 'Tài chính',
    ),
    _AdminDestination(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Người dùng',
    ),
    _AdminDestination(
      icon: Icons.more_horiz_rounded,
      selectedIcon: Icons.more_horiz_rounded,
      label: 'Thêm',
    ),
  ];

  void _onSelect(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.surfaceContainerLowest,
              indicatorColor: AppColors.primaryFixed,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, color: AppColors.borderSoft),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _AdminDestination {
  const _AdminDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
