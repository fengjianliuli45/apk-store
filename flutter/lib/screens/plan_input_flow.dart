import 'package:flutter/material.dart';

import '../planner/plan_sync.dart';
import '../state/goal_controller.dart';
import '../state/plan_controller.dart';
import 'generating_plan_screen.dart';
import 'goal_survey_screen.dart';
import 'profile_survey_screen.dart';

/// Goal → body/training inputs → generate. Used both for first-run
/// onboarding and for later edits from Home / 我的 / 设置.
class PlanInputFlow extends StatefulWidget {
  const PlanInputFlow({
    super.key,
    required this.goalController,
    required this.planController,
    this.allowExit = false,
    this.checkInWeek,
    this.onSkip,
    this.onDone,
  });

  final GoalController goalController;
  final PlanController planController;
  final bool allowExit;
  final int? checkInWeek;
  final VoidCallback? onSkip;
  final VoidCallback? onDone;

  @override
  State<PlanInputFlow> createState() => _PlanInputFlowState();
}

enum _Phase { goal, profile, generating }

class _PlanInputFlowState extends State<PlanInputFlow> {
  late _Phase _phase = _Phase.goal;
  Map<String, dynamic>? _fields;

  Map<String, dynamic>? get _initialFields {
    final plan = widget.planController.plan;
    if (plan == null) return null;
    return profileFieldsFrom(plan.profile);
  }

  bool _completed = false;

  void _finish() {
    _completed = true;
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_completed) widget.onSkip?.call();
      },
      child: switch (_phase) {
        _Phase.goal => GoalSurveyScreen(
            goalController: widget.goalController,
            allowExit: widget.allowExit,
            checkInWeek: widget.checkInWeek,
            onExit: () => Navigator.of(context).maybePop(),
            onContinue: () => setState(() => _phase = _Phase.profile),
          ),
        _Phase.profile => ProfileSurveyScreen(
            initialFields: _fields ?? _initialFields,
            allowExit: widget.allowExit,
            onBackToGoal: () => setState(() => _phase = _Phase.goal),
            onSubmit: (fields) => setState(() {
              _fields = fields;
              _phase = _Phase.generating;
            }),
          ),
        _Phase.generating => GeneratingPlanScreen(
            goal: widget.goalController.goal!,
            profileFields: _fields!,
            planController: widget.planController,
            onDone: _finish,
          ),
      },
    );
  }
}
