import 'package:flutter/material.dart';

import '../planner/plan_copy.dart';
import '../state/auth_controller.dart';
import '../state/chat_controller.dart';
import '../state/diet_log_controller.dart';
import '../state/goal_controller.dart';
import '../state/plan_controller.dart';
import '../state/settings_controller.dart';
import '../state/social_feed_controller.dart';
import '../state/workout_log_controller.dart';
import '../state/workout_session_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';
import 'plan_input_flow.dart';
import 'social_shell.dart';

/// App root: owns the controllers that need to survive across screens, and
/// hosts Home as the single root widget (screen home-with-fab, node
/// 207:236). 我的 and the social module (screen-social-feed, node 193:65)
/// are pushed on top via Navigator, not sibling tabs behind a shared bottom
/// nav — see the Figma reference, each module has its own chrome.
class RootShell extends StatefulWidget {
  const RootShell({
    super.key,
    required this.onLogout,
    required this.plan,
    required this.goal,
    required this.auth,
  });

  final VoidCallback onLogout;
  final PlanController plan;
  final GoalController goal;
  final AuthController auth;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final _socialFeedController = SocialFeedController();
  final _session = WorkoutSessionController();
  final _dietLog = DietLogController();
  final _workoutLog = WorkoutLogController();
  final _chat = ChatController();
  final _settings = SettingsController();
  bool _checkPromptOpen = false;

  @override
  void initState() {
    super.initState();
    widget.plan.addListener(_syncPlan);
    _session.attachLog(_workoutLog);
    _dietLog.load();
    _workoutLog.load();
    _syncPlan();
    _chat.load();
    _settings.load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptCheckIn());
  }

  void _syncPlan() {
    _dietLog.bindPlan(widget.plan.plan);
    _session.applyToday(widget.plan.plan);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.plan.removeListener(_syncPlan);
    _session.dispose();
    super.dispose();
  }

  Future<void> _maybePromptCheckIn() async {
    if (!mounted || _checkPromptOpen || !widget.plan.needsCheckInPrompt) return;
    final generated = widget.plan.plan;
    if (generated == null) return;
    _checkPromptOpen = true;
    final week = planWeekNumber(generated.generatedAt);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanInputFlow(
          goalController: widget.goal,
          planController: widget.plan,
          allowExit: true,
          checkInWeek: week,
          onSkip: () => widget.plan.markCheckPrompted(
            generatedAt: generated.generatedAt,
            week: week,
          ),
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
    _checkPromptOpen = false;
  }

  void _openPlanInput(BuildContext context, {int? checkInWeek}) {
    final generated = widget.plan.plan;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanInputFlow(
          goalController: widget.goal,
          planController: widget.plan,
          allowExit: true,
          checkInWeek: checkInWeek,
          onSkip: checkInWeek == null || generated == null
              ? null
              : () => widget.plan.markCheckPrompted(
                    generatedAt: generated.generatedAt,
                    week: checkInWeek,
                  ),
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    _openSocial(context, initialTab: 4);
  }

  void _openSocial(BuildContext context, {int initialTab = 3}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialShell(
          controller: _socialFeedController,
          chat: _chat,
          settings: _settings,
          plan: widget.plan,
          goal: widget.goal,
          auth: widget.auth,
          workoutLog: _workoutLog,
          dietLog: _dietLog,
          onLogout: widget.onLogout,
          onEditPlan: () => _openPlanInput(context),
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
      workoutLog: _workoutLog,
      plannedDaysPerWeek: widget.plan.plan?.profile.daysPerWeek ?? 3,
      onOpenProfile: () => _openProfile(context),
      onOpenSocial: () => _openSocial(context),
      onEditPlan: () => _openPlanInput(context),
    );
  }
}
