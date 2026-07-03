import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'bottom_nav_bar.dart';

/// Root of the authenticated area: 5 tabs backed by an indexed stack so each
/// tab keeps its own navigation state.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
