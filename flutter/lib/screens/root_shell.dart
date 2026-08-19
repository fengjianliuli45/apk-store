import 'package:flutter/material.dart';

import '../state/chat_controller.dart';
import '../state/diet_log_controller.dart';
import '../state/plan_controller.dart';
import '../state/settings_controller.dart';
import '../state/social_feed_controller.dart';
import '../state/workout_session_controller.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'social_shell.dart';

/// App root: owns the controllers that need to survive across screens, and
/// hosts Home as the single root widget (screen home-with-fab, node
/// 207:236). 我的 and the social module (screen-social-feed, node 193:65)
/// are pushed on top via Navigator, not sibling tabs behind a shared bottom
/// nav — see the Figma reference, each module has its own chrome.
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.onLogout, required this.plan});

  final VoidCallback onLogout;
  final PlanController plan;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
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

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          dietLog: _dietLog,
          chat: _chat,
          settings: _settings,
          onLogout: widget.onLogout,
          onBack: () => Navigator.of(context).pop(),
          onOpenSocial: () => _openSocial(context),
        ),
      ),
    );
  }

  void _openSocial(BuildContext context, {int initialTab = 3}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialShell(
          controller: _socialFeedController,
          dietLog: _dietLog,
          chat: _chat,
          settings: _settings,
          plan: widget.plan,
          onLogout: widget.onLogout,
          initialTab: initialTab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      session: _session,
      dietLog: _dietLog,
      onOpenProfile: () => _openProfile(context),
      onOpenSocial: () => _openSocial(context),
    );
  }
}
