import 'package:flutter/material.dart';

import '../state/chat_controller.dart';
import '../state/diet_log_controller.dart';
import '../state/settings_controller.dart';
import '../state/social_feed_controller.dart';
import '../state/workout_session_controller.dart';
import 'home_screen.dart';
import 'plan_screen.dart';
import 'profile_screen.dart';
import 'social_feed_screen.dart';
import 'training_screen.dart';

/// Hosts the 5 root tabs (训练 / 计划 / home / 社交 / 我的) behind the shared
/// bottom nav. Tab index mirrors AppBottomNav: 0=训练 1=计划 2=home 3=社交 4=我的.
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 2;
  final _socialFeedController = SocialFeedController();
  final _session = WorkoutSessionController();
  final _dietLog = DietLogController();
  final _chat = ChatController();
  final _settings = SettingsController();

  @override
  void initState() {
    super.initState();
    _dietLog.load();
    _chat.load();
    _settings.load();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _selectTab(int index) => setState(() => _tabIndex = index);

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _tabIndex,
      children: [
        TrainingScreen(onSelectTab: _selectTab),
        PlanScreen(onSelectTab: _selectTab),
        HomeScreen(session: _session, dietLog: _dietLog, onSelectTab: _selectTab),
        SocialFeedScreen(
          controller: _socialFeedController,
          onSelectTab: _selectTab,
          onBack: () => _selectTab(2),
        ),
        ProfileScreen(
          onSelectTab: _selectTab,
          dietLog: _dietLog,
          chat: _chat,
          settings: _settings,
          onLogout: widget.onLogout,
        ),
      ],
    );
  }
}
