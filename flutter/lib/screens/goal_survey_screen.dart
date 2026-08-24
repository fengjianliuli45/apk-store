import 'package:flutter/material.dart';

import '../state/goal_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';

/// One-time post-login survey: 增肌 or 减脂. Feeds the personalized
/// welcome animation (see WelcomeAnimationScreen, shown next by _AppGate
/// once goalController notifies a choice was made) and, later, can steer
/// default training/diet recommendations.
class GoalSurveyScreen extends StatefulWidget {
  const GoalSurveyScreen({
    super.key,
    required this.goalController,
    this.allowExit = false,
    this.checkInWeek,
    this.onExit,
    this.onContinue,
  });

  final GoalController goalController;
  final bool allowExit;
  final int? checkInWeek;
  final VoidCallback? onExit;
  final VoidCallback? onContinue;

  @override
  State<GoalSurveyScreen> createState() => _GoalSurveyScreenState();
}

class _GoalSurveyScreenState extends State<GoalSurveyScreen> {
  late FitnessGoal? _selected = widget.goalController.goal;

  Future<void> _continue() async {
    final selected = _selected;
    if (selected == null) return;
    await widget.goalController.choose(selected);
    widget.onContinue?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.allowExit)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: widget.onExit ?? () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: AppColors.ink),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              widget.checkInWeek == null ? '你的健身目标是？' : '第 ${widget.checkInWeek} 周检查',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 4),
            Text(
              widget.checkInWeek == null
                  ? '选一个，我们会据此生成专属欢迎动画和训练建议'
                  : '到检查周了。请确认目标，并在下一步更新体重和训练条件，我们会按新数据重算计划。',
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final option in FitnessGoal.values) ...[
                      _GoalCard(
                        goal: option,
                        selected: _selected == option,
                        onTap: () => setState(() => _selected = option),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: AppColors.ink,
                  disabledBackgroundColor: AppColors.brandGreen.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _selected == null ? null : _continue,
                child: const Text('继续', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.selected, required this.onTap});

  final FitnessGoal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.ink : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.label, style: AppTextStyles.cardName),
                  const SizedBox(height: 2),
                  Text(goal.description, style: AppTextStyles.cardMeta),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: AppColors.ink,
            ),
          ],
        ),
      ),
    );
  }
}
