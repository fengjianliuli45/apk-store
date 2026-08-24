import 'package:flutter/material.dart';

import '../models/workout_log.dart';
import '../planner/models.dart';
import '../planner/plan_copy.dart';
import '../state/auth_controller.dart';
import '../state/diet_log_controller.dart';
import '../state/goal_controller.dart';
import '../state/identity.dart';
import '../state/plan_controller.dart';
import '../state/settings_controller.dart';
import '../state/workout_log_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/fitness_radar.dart';
import '../widgets/gradient_background.dart';
import 'settings_screen.dart';

/// “我的”主界面。身份、累计、雷达、最近训练都读本机记录，不再用写死示例。
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.settings,
    required this.plan,
    required this.goal,
    required this.auth,
    required this.workoutLog,
    required this.dietLog,
    required this.onLogout,
    required this.onEditPlan,
  });

  final SettingsController settings;
  final PlanController plan;
  final GoalController goal;
  final AuthController auth;
  final WorkoutLogController workoutLog;
  final DietLogController dietLog;
  final VoidCallback onLogout;
  final VoidCallback onEditPlan;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: GradientBackground(
        showHudTexture: true,
        child: AnimatedBuilder(
          animation: Listenable.merge([plan, goal, auth, workoutLog, dietLog]),
          builder: (context, _) {
            final generated = plan.plan;
            final profile = generated?.profile;
            final plannedDays = profile?.daysPerWeek ?? 3;
            final plannedMinutes = profile?.minutesPerSession ?? 45;
            final scores = workoutLog.radar(
              plannedDaysPerWeek: plannedDays,
              plannedMinutes: plannedMinutes,
              dietGoalKcal: dietLog.goals.kcal,
              lastSevenDayKcals: dietLog.lastDayKcals(),
            );
            final streak = workoutLog.streakDays();
            final planDays = generated == null
                ? 0
                : DateTime.now().difference(generated.generatedAt).inDays.clamp(0, 3650) + 1;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    badge: goal.goal?.label ?? '我的',
                    onOpenSettings: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          settings: settings,
                          auth: auth,
                          onLogout: onLogout,
                          onEditPlan: onEditPlan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _IdentityBlock(
                    glyph: auth.avatarGlyph(goal.goal),
                    name: auth.displayName(goal.goal),
                    subtitle: streak > 0
                        ? '连续训练 $streak 天'
                        : planDays > 0
                            ? '计划已运行 $planDays 天 · 还没开练'
                            : '还没有训练记录',
                  ),
                  const SizedBox(height: 14),
                  _PlanDataCard(plan: plan, goal: goal, onEdit: onEditPlan),
                  const SizedBox(height: 14),
                  _PerformanceCard(
                    sessions: workoutLog.sessionCount,
                    durationLabel: formatWorkoutDuration(workoutLog.totalDurationMs),
                    kcalLabel: formatWorkoutKcal(workoutLog.totalKcal),
                    scores: scores,
                  ),
                  if (generated != null) ...[
                    const SizedBox(height: 14),
                    _PlanInsightsCard(plan: generated),
                  ],
                  const SizedBox(height: 14),
                  _RecentTrainingCard(entries: workoutLog.recent),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.badge, required this.onOpenSettings});

  final String badge;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '我的',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppColors.ink,
          ),
        ),
        const Spacer(),
        Container(
          width: 52,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontFamily: AppFonts.jetBrainsMono,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.4,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onOpenSettings,
          tooltip: '设置',
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(
            Icons.settings_outlined,
            size: 29,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.glyph,
    required this.name,
    required this.subtitle,
  });

  final String glyph;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 68,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: Text(
            glyph,
            style: const TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: AppFonts.inter,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanDataCard extends StatelessWidget {
  const _PlanDataCard({
    required this.plan,
    required this.goal,
    required this.onEdit,
  });

  final PlanController plan;
  final GoalController goal;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final profile = plan.plan?.profile;
    final goalLabel = goal.goal?.label ?? '未选择';
    final detail = profile == null
        ? '还没有填写身体数据和训练条件'
        : '${profile.weightKg.round()}kg · 每周${profile.daysPerWeek}天 · 每次${profile.minutesPerSession}分钟';
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.brandGreen, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.brandGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '规划数据',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$goalLabel · $detail',
                    style: const TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '填写',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.ink,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.sessions,
    required this.durationLabel,
    required this.kcalLabel,
    required this.scores,
  });

  final int sessions;
  final String durationLabel;
  final String kcalLabel;
  final FitnessRadarScores scores;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 268,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatBlock(value: '$sessions次', label: '累计训练'),
              _StatBlock(value: durationLabel, label: '累计时长'),
              _StatBlock(value: kcalLabel, label: '累计消耗'),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x180D1112)),
          const SizedBox(height: 8),
          const Text(
            '体能维度雷达图',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: FitnessRadar(scores: scores)),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.bold,
              fontSize: 23,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanInsightsCard extends StatelessWidget {
  const _PlanInsightsCard({required this.plan});

  final GeneratedPlan plan;

  @override
  Widget build(BuildContext context) {
    final week = planWeekNumber(plan.generatedAt);
    final progression = plan.progression;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '计划要点',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '第 $week 周 · ${progressionStrategyLabel(progression.strategy)} · 下次检查第 ${progression.nextCheckWeek} 周',
            style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            '上肢 +${progression.incrementUpperKg}kg · 下肢 +${progression.incrementLowerKg}kg · ${progression.progressionFreq}',
            style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            '补剂  ${supplementLine(plan.supplements)}',
            style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            '餐次  ${mealPlanLine(plan.mealPlan)}',
            style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _RecentTrainingCard extends StatelessWidget {
  const _RecentTrainingCard({required this.entries});

  final List<WorkoutLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近训练记录',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const Text(
              '完成一组训练后会出现在这里',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            )
          else
            for (var index = 0; index < entries.length; index++) ...[
              _RecentTrainingRow(
                title: entries[index].title,
                meta:
                    '${formatWorkoutDuration(entries[index].durationMs)}  ${relativeWorkoutDay(entries[index].at, now)}',
              ),
              if (index != entries.length - 1) const SizedBox(height: 13),
            ],
        ],
      ),
    );
  }
}

class _RecentTrainingRow extends StatelessWidget {
  const _RecentTrainingRow({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(
          meta,
          style: const TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
