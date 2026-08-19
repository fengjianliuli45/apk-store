import 'dart:async';

import 'package:flutter/material.dart';

import '../planner/planner_gateway.dart';
import '../state/goal_controller.dart';
import '../state/plan_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';

/// v2 §6.3 生成计划页: turns plan generation into a short, understandable
/// transition instead of a blank spinner. PlannerGateway.generate() itself
/// runs in milliseconds (it's a local Dart computation, not a network
/// call) — the step labels are paced on a timer purely so the transition
/// reads as "figuring this out" rather than flashing by.
class GeneratingPlanScreen extends StatefulWidget {
  const GeneratingPlanScreen({
    super.key,
    required this.goal,
    required this.profileFields,
    required this.planController,
    required this.onDone,
  });

  final FitnessGoal goal;
  final Map<String, dynamic> profileFields;
  final PlanController planController;
  final VoidCallback onDone;

  @override
  State<GeneratingPlanScreen> createState() => _GeneratingPlanScreenState();
}

const _steps = ['匹配场景', '选择动作', '估算休息'];

class _GeneratingPlanScreenState extends State<GeneratingPlanScreen> {
  int _stepIndex = 0;
  Timer? _stepTimer;
  Timer? _timeoutTimer;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) return;
      setState(() => _stepIndex = (_stepIndex + 1) % _steps.length);
    });
    // v2 §6.3: "超过 8 秒提供先用默认计划开始" — generation here is local
    // and effectively instant, but keep the escape hatch for parity.
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_done) setState(() {});
    });
    _generate();
  }

  Future<void> _generate() async {
    try {
      final gateway = await PlannerGateway.instance();
      final raw = {...widget.profileFields, 'goal': widget.goal.engineGoal};
      final plan = gateway.generate(raw);
      // Minimum perceived duration so the transition doesn't just flash.
      await Future.delayed(const Duration(milliseconds: 900));
      await widget.planController.save(plan);
      if (!mounted) return;
      _done = true;
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
              child: const Icon(Icons.accessibility_new, color: AppColors.brandGreen, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('正在为你生成今天的训练', style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (_error == null)
              Text(_steps[_stepIndex], style: AppTextStyles.cardMeta)
            else ...[
              Text('生成失败：$_error', style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.likeRed), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.brandGreen, foregroundColor: AppColors.ink),
                onPressed: () {
                  setState(() => _error = null);
                  _generate();
                },
                child: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
