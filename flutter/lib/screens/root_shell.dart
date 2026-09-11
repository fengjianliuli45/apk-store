import 'dart:async';

import 'package:flutter/material.dart';

import '../data/workout_database.dart';
import '../planner/plan_copy.dart';
import '../planner/plan_adapter.dart';
import '../planner/plan_overview.dart';
import '../state/auth_controller.dart';
import '../state/chat_controller.dart';
import '../state/diet_log_controller.dart';
import '../state/goal_controller.dart';
import '../state/plan_controller.dart';
import '../state/settings_controller.dart';
import '../state/social_feed_controller.dart';
import '../state/workout_log_controller.dart';
import '../state/workout_session_controller.dart';
import 'home_screen.dart';
import 'cycle_review_screen.dart';
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

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  final _socialFeedController = SocialFeedController();
  final _session = WorkoutSessionController();
  final _dietLog = DietLogController();
  final _workoutLog = WorkoutLogController();
  final _chat = ChatController();
  final _settings = SettingsController();
  bool _checkPromptOpen = false;
  Timer? _dayTimer;
  DateTime _boundDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshDay(),
    );
    widget.plan.addListener(_syncPlan);
    _session.attachLog(_workoutLog);
    _session.attachStoreFactory(() => WorkoutDatabase.instance);
    _dietLog.load();
    _workoutLog.load();
    _syncPlan();
    unawaited(_restoreSession());
    _chat.load();
    _settings.load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptCheckIn());
  }

  void _syncPlan() {
    _boundDay = DateTime.now();
    _dietLog.bindPlan(widget.plan.plan);
    if (!_session.hasResumableSession) {
      _session.applyToday(widget.plan.plan);
    }
    if (mounted) setState(() {});
  }

  void _refreshDay() {
    final now = DateTime.now();
    if (now.year != _boundDay.year ||
        now.month != _boundDay.month ||
        now.day != _boundDay.day) {
      _syncPlan();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDay();
  }

  Future<void> _restoreSession() async {
    if (!await WorkoutDatabase.hasResumableMarker()) return;
    await _session.restoreResumableSession();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.plan.removeListener(_syncPlan);
    _session.dispose();
    super.dispose();
  }

  Future<void> _maybePromptCheckIn() async {
    if (!mounted || _checkPromptOpen || !widget.plan.needsCheckInPrompt) return;
    final generated = widget.plan.plan;
    if (generated == null) return;
    await _workoutLog.load();
    _checkPromptOpen = true;
    final week = planWeekNumber(generated.generatedAt);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CycleReviewScreen(
          overview: PlanOverview.from(
            plan: generated,
            logs: _workoutLog.entries,
          ),
          plan: widget.plan,
          workoutLog: _workoutLog,
        ),
      ),
    );
    await widget.plan.markCheckPrompted(
      generatedAt: generated.generatedAt,
      week: week,
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
          onCycleCheckIn: (week) => _openPlanInput(context, checkInWeek: week),
          initialTab: initialTab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final generated = widget.plan.plan;
    String? nextTraining;
    final exercises = <String, SetPlan>{};
    if (generated != null && generated.sessions.isNotEmpty) {
      final now = DateTime.now();
      for (var offset = 1; offset <= 7; offset++) {
        final date = DateTime(now.year, now.month, now.day + offset);
        final day = sessionForDate(generated, date);
        if (!day.isRest && day.exercises.isNotEmpty) {
          nextTraining =
              '下次训练：${date.month}月${date.day}日 ${day.day} · ${sessionTypeLabels[day.type] ?? day.type}';
          break;
        }
      }
      for (final day in generated.sessions) {
        for (final e in day.exercises) {
          exercises.putIfAbsent(
            e.exerciseId,
            () => SetPlan(e.exerciseId, e.name, 0, formCues: e.formCues),
          );
        }
      }
    }
    return HomeScreen(
      nextTrainingLabel: nextTraining,
      previewExercises: exercises.values.toList(),
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
