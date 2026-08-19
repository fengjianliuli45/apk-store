import 'package:flutter/material.dart';

import '../state/chat_controller.dart';
import '../state/diet_log_controller.dart';
import '../state/plan_controller.dart';
import '../state/settings_controller.dart';
import '../state/social_feed_controller.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';
import 'plan_screen.dart';
import 'profile_screen.dart';
import 'social_feed_screen.dart';
import 'training_screen.dart';

/// The social module (screen screen-social-feed, node 193:65) — pushed from
/// Home, never a Home tab. Owns its own 5-slot bottom bar (训练 / 计划 /
/// [center] / 社交 / 我的); the center lime circle and the feed's back arrow
/// both pop this whole shell back out to Home instead of switching tabs.
class SocialShell extends StatefulWidget {
  const SocialShell({
    super.key,
    required this.controller,
    required this.dietLog,
    required this.chat,
    required this.settings,
    required this.plan,
    required this.onLogout,
    this.initialTab = 3,
  });

  final SocialFeedController controller;
  final DietLogController dietLog;
  final ChatController chat;
  final SettingsController settings;
  final PlanController plan;
  final VoidCallback onLogout;

  /// One of 0 (训练), 1 (计划), 3 (社交) or 4 (我的).
  final int initialTab;

  @override
  State<SocialShell> createState() => _SocialShellState();
}

class _SocialShellState extends State<SocialShell> {
  late int _tabIndex = widget.initialTab;

  void _selectTab(int index) => setState(() => _tabIndex = index);

  static int _localIndex(int tab) => switch (tab) {
        0 => 0,
        1 => 1,
        4 => 3,
        _ => 2,
      };

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _localIndex(_tabIndex),
              children: [
                TrainingScreen(plan: widget.plan),
                PlanScreen(plan: widget.plan),
                SocialFeedScreen(
                  controller: widget.controller,
                  onBack: () => Navigator.of(context).pop(),
                ),
                ProfileScreen(
                  dietLog: widget.dietLog,
                  chat: widget.chat,
                  settings: widget.settings,
                  onLogout: widget.onLogout,
                  onOpenSocial: () => _selectTab(3),
                ),
              ],
            ),
          ),
          AppBottomNav(
            currentIndex: _tabIndex,
            onSelect: _selectTab,
            onCenterTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
