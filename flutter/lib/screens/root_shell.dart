import 'package:flutter/material.dart';

import '../state/social_feed_controller.dart';
import 'home_screen.dart';
import 'placeholder_screens.dart';
import 'profile_screen.dart';
import 'social_feed_screen.dart';

/// Hosts the 5 root tabs (训练 / 计划 / home / 社交 / 我的) behind the shared
/// bottom nav. Tab index mirrors AppBottomNav: 0=训练 1=计划 2=home 3=社交 4=我的.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 2;
  final _socialFeedController = SocialFeedController();

  void _selectTab(int index) => setState(() => _tabIndex = index);

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _tabIndex,
      children: [
        TabPlaceholderScreen(
          title: '训练',
          subtitle: '训练计划开发中',
          icon: Icons.fitness_center,
          tabIndex: 0,
          onSelectTab: _selectTab,
        ),
        TabPlaceholderScreen(
          title: '计划',
          subtitle: '训练日历开发中',
          icon: Icons.calendar_today,
          tabIndex: 1,
          onSelectTab: _selectTab,
        ),
        HomeScreen(onSelectTab: _selectTab),
        SocialFeedScreen(
          controller: _socialFeedController,
          onSelectTab: _selectTab,
          onBack: () => _selectTab(2),
        ),
        ProfileScreen(onSelectTab: _selectTab),
      ],
    );
  }
}
