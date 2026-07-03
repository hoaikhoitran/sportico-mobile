import 'package:flutter/material.dart';

/// Balanced 5-tab bottom navigation. Styling comes from
/// [NavigationBarThemeData] in the app theme.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelect,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center_rounded),
          label: 'Gói tập',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Lịch tập',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Tin nhắn',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}
